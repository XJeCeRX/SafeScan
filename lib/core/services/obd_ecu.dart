import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/obd_data.dart';
import 'obd_response_parser.dart';

class DiscoveredDevice {
  final String ip;
  final int port;
  const DiscoveredDevice(this.ip, this.port);

  @override
  String toString() => '$ip:$port';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredDevice && ip == other.ip && port == other.port;

  @override
  int get hashCode => ip.hashCode ^ port.hashCode;
}

class ObdEcu {
  static const List<int> _scanPorts = [35000, 23];
  static const int _scanConcurrency = 32;
  static const Duration _probeTimeout = Duration(milliseconds: 450);
  static const Duration _probeReadDelay = Duration(milliseconds: 350);

  static const List<String> _commonIps = [
    '192.168.0.10',
    '192.168.0.11',
    '192.168.0.1',
    '192.168.0.100',
    '192.168.0.200',
    '192.168.1.10',
    '192.168.1.1',
    '192.168.4.1',
    '192.168.4.10',
    '192.168.10.1',
    '192.168.10.10',
    '192.168.0.20',
    '192.168.0.50',
    '192.168.0.150',
  ];

  static Future<List<DiscoveredDevice>> scanNetwork() async {
    final results = <DiscoveredDevice>{};
    final localPrefixes = await _localIpv4Prefixes();
    final firstPassIps = <String>{
      ..._commonIps,
      for (final prefix in localPrefixes) ...[
        '$prefix.1',
        '$prefix.10',
        '$prefix.11',
        '$prefix.100',
        '$prefix.200',
      ],
    }.toList();

    await _scanIps(firstPassIps, results);

    if (results.isEmpty) {
      for (final prefix in localPrefixes) {
        await _scanIps([
          for (var host = 1; host <= 254; host++) '$prefix.$host',
        ], results);
      }
    }

    final sorted = results.toList()
      ..sort((a, b) {
        final byIp = a.ip.compareTo(b.ip);
        return byIp != 0 ? byIp : a.port.compareTo(b.port);
      });
    return sorted;
  }

  static Future<void> _scanIps(
    List<String> ips,
    Set<DiscoveredDevice> results,
  ) async {
    for (final port in _scanPorts) {
      for (var start = 0; start < ips.length; start += _scanConcurrency) {
        final end = (start + _scanConcurrency < ips.length)
            ? start + _scanConcurrency
            : ips.length;
        final batch = ips.sublist(start, end);
        await Future.wait(batch.map((ip) => _probe(ip, port, results)));
      }
    }
  }

  static Future<Set<String>> _localIpv4Prefixes() async {
    final prefixes = <String>{};
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          final parts = address.address.split('.');
          if (parts.length != 4) continue;
          prefixes.add('${parts[0]}.${parts[1]}.${parts[2]}');
        }
      }
    } catch (_) {}
    return prefixes;
  }

  static Future<void> _probe(
    String ip,
    int port,
    Set<DiscoveredDevice> results,
  ) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: _probeTimeout);
      var response = '';
      final subscription = socket.listen((data) {
        response += ascii.decode(data, allowInvalid: true);
      });
      socket.write('AT\r');
      await socket.flush();
      await Future.delayed(_probeReadDelay);
      await subscription.cancel();
      socket.destroy();

      final normalized = response.toUpperCase();
      if (normalized.contains('OK') ||
          normalized.contains('ELM') ||
          normalized.contains('>')) {
        results.add(DiscoveredDevice(ip, port));
      }
    } catch (_) {}
  }

  Socket? _connection;
  bool _initialized = false;
  String _buffer = '';
  bool _disconnecting = false;
  Future<void> _commandQueue = Future.value();

  bool get isConnected => _connection != null && !_disconnecting;
  bool get isInitialized => _initialized;

  final List<String> _atCommands = [
    'ATZ',
    'ATE0',
    'ATH0',
    'ATL0',
    'ATS0',
    'ATAT1',
    'ATSP0',
  ];

  Future<void> connect(String host, int port) async {
    await disconnect();
    _disconnecting = false;
    _connection = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 10),
    );
    _connection!.listen(
      (data) {
        _buffer += ascii.decode(data, allowInvalid: true);
      },
      onDone: () {
        if (!_disconnecting) {
          _connection = null;
          _initialized = false;
        }
      },
      onError: (_) {
        _connection = null;
        _initialized = false;
      },
    );
    _buffer = '';
    _initialized = false;
  }

  Future<void> disconnect() async {
    _disconnecting = true;
    _initialized = false;
    try {
      await _connection?.close();
    } catch (_) {}
    _connection = null;
    _buffer = '';
  }

  Future<void> initialize() async {
    if (!isConnected) throw Exception('No connected');
    _initialized = false;

    final resetResp = await _sendCommand('ATZ', timeoutMs: 3000);
    if (resetResp == null) {
      throw Exception('El adaptador no responde al reset');
    }
    await Future.delayed(const Duration(milliseconds: 500));

    for (final cmd in _atCommands.skip(1)) {
      final resp = await _sendCommand(cmd);
      if (resp == null) {
        throw Exception('Error en comando $cmd');
      }
    }

    final protocolResp = await _sendCommand('0100', timeoutMs: 7000);
    if (protocolResp == null ||
        ObdResponseParser.hasObdError(protocolResp) ||
        !ObdResponseParser.hasPositivePidResponse(protocolResp, 0x00)) {
      throw Exception(
        'El adaptador responde, pero la ECU del vehículo no respondió',
      );
    }

    _initialized = true;
  }

  Future<String?> _sendCommand(String cmd, {int timeoutMs = 2000}) async {
    final operation = _commandQueue.then(
      (_) => _sendCommandUnlocked(cmd, timeoutMs: timeoutMs),
    );
    _commandQueue = operation.catchError((_) => null).then((_) {});
    return operation;
  }

  Future<String?> _sendCommandUnlocked(
    String cmd, {
    int timeoutMs = 2000,
  }) async {
    if (!isConnected) return null;
    try {
      _buffer = '';
      _connection!.write('$cmd\r');
      await _connection!.flush();
      await Future.delayed(const Duration(milliseconds: 200));
      final response = await _readResponse(timeoutMs: timeoutMs);
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<String> _readResponse({int timeoutMs = 2000}) async {
    final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
    while (DateTime.now().isBefore(deadline)) {
      final promptIndex = _buffer.indexOf('>');
      if (promptIndex >= 0) {
        final result = _buffer.substring(0, promptIndex);
        _buffer = _buffer.substring(promptIndex + 1);
        return result.replaceAll(RegExp(r'[\r\n]'), ' ').trim();
      }
      await Future.delayed(const Duration(milliseconds: 50));
    }

    final result = _buffer;
    _buffer = '';
    return result.replaceAll(RegExp(r'[\r\n>]'), ' ').trim();
  }

  Future<List<DtcCode>> readDtc() async {
    if (!isConnected || !_initialized) return [];
    final response = await _sendCommand('03');
    if (response == null || response.isEmpty) return [];
    return ObdResponseParser.dtcCodes(response);
  }

  Future<int> readRpm() async {
    final resp = await _sendCommand('010C');
    if (resp == null) return 0;
    final vals = ObdResponseParser.twoBytePayload(resp, 0x0C);
    if (vals == null) return 0;
    return ((vals.$1 * 256) + vals.$2) ~/ 4;
  }

  Future<int> readCoolantTemp() async {
    final resp = await _sendCommand('0105');
    if (resp == null) return 0;
    final vals = ObdResponseParser.singleBytePayload(resp, 0x05);
    if (vals == null) return 0;
    return vals - 40;
  }

  Future<int> readSpeed() async {
    final resp = await _sendCommand('010D');
    if (resp == null) return 0;
    final vals = ObdResponseParser.singleBytePayload(resp, 0x0D);
    return vals ?? 0;
  }

  Future<double> readBatteryVoltage() async {
    final resp = await _sendCommand('ATRV');
    if (resp == null) return 0.0;
    final match = RegExp(r'(\d+\.?\d*)').firstMatch(resp);
    if (match == null) return 0.0;
    return double.tryParse(match.group(1)!) ?? 0.0;
  }

  Future<int> readEngineLoad() async {
    final resp = await _sendCommand('0104');
    if (resp == null) return 0;
    final vals = ObdResponseParser.singleBytePayload(resp, 0x04);
    if (vals == null) return 0;
    return (vals * 100) ~/ 255;
  }

  Future<int> readIntakeTemp() async {
    final resp = await _sendCommand('010F');
    if (resp == null) return 0;
    final vals = ObdResponseParser.singleBytePayload(resp, 0x0F);
    if (vals == null) return 0;
    return vals - 40;
  }

  Future<int> readThrottlePosition() async {
    final resp = await _sendCommand('0111');
    if (resp == null) return 0;
    final vals = ObdResponseParser.singleBytePayload(resp, 0x11);
    if (vals == null) return 0;
    return (vals * 100) ~/ 255;
  }

  Future<double> readFuelLevel() async {
    final resp = await _sendCommand('012F');
    if (resp == null) return 0.0;
    final vals = ObdResponseParser.singleBytePayload(resp, 0x2F);
    if (vals == null) return 0.0;
    return (vals * 100.0) / 255.0;
  }

  Future<int> readDtcCount() async {
    final resp = await _sendCommand('0101');
    if (resp == null) return 0;
    return ObdResponseParser.dtcCount(resp);
  }

  Future<VehicleData> readAllData() async {
    if (!isConnected || !_initialized) return VehicleData.empty;
    try {
      final rpm = await readRpm();
      final coolantTemp = await readCoolantTemp();
      final speed = await readSpeed();
      final batteryVoltage = await readBatteryVoltage();
      final engineLoad = await readEngineLoad();
      final intakeTemp = await readIntakeTemp();
      final throttlePosition = await readThrottlePosition();
      final fuelLevel = await readFuelLevel();
      return VehicleData(
        rpm: rpm,
        coolantTemp: coolantTemp,
        speed: speed,
        batteryVoltage: batteryVoltage,
        engineLoad: engineLoad,
        intakeTemp: intakeTemp,
        throttlePosition: throttlePosition,
        fuelLevel: fuelLevel,
        timestamp: Duration(
          milliseconds: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } catch (_) {
      return VehicleData.empty;
    }
  }
}
