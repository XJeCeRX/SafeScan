import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/obd_data.dart';
import 'obd_ecu.dart';

enum ObdStatus { disconnected, connecting, connected, error }

class ObdManager extends ChangeNotifier {
  final ObdEcu _ecu = ObdEcu();

  ObdStatus _status = ObdStatus.disconnected;
  VehicleData _vehicleData = VehicleData.empty;
  List<DtcCode> _dtcCodes = [];
  String? _connectedIp;
  int _connectedPort = 35000;
  String? _errorMessage;
  String _connectionStep = '';
  Timer? _pollingTimer;
  List<DiscoveredDevice> _discoveredDevices = [];
  bool _isScanning = false;
  bool _isPollingRead = false;
  bool _hasScannedDtc = false;

  ObdStatus get status => _status;
  VehicleData get vehicleData => _vehicleData;
  List<DtcCode> get dtcCodes => _dtcCodes;
  bool get hasScannedDtc => _hasScannedDtc;
  String? get connectedIp => _connectedIp;
  int get connectedPort => _connectedPort;
  String? get errorMessage => _errorMessage;
  String get connectionStep => _connectionStep;
  bool get isConnected => _status == ObdStatus.connected;
  bool get isPolling => _pollingTimer != null;
  List<DiscoveredDevice> get discoveredDevices => _discoveredDevices;
  bool get isScanning => _isScanning;

  Future<void> init() async {
    notifyListeners();
  }

  Future<bool> connectToDevice(String ip, int port) async {
    _errorMessage = null;
    _connectedIp = ip;
    _connectedPort = port;
    _status = ObdStatus.connecting;
    notifyListeners();

    try {
      await _doConnect(ip, port).timeout(const Duration(seconds: 25));
    } on TimeoutException {
      await _ecu.disconnect();
      _errorMessage =
          'No se pudo conectar en 25 segundos.\n'
          'Verifica que el adaptador esté encendido, el teléfono esté en su red WiFi y el switch del vehículo esté en ON.';
      _status = ObdStatus.error;
      _connectedIp = null;
      notifyListeners();
      return false;
    } catch (e) {
      final msg = e.toString();
      await _ecu.disconnect();
      _errorMessage = _friendlyError(msg);
      _status = ObdStatus.error;
      _connectedIp = null;
      notifyListeners();
      return false;
    }

    if (_status != ObdStatus.connected) {
      _errorMessage =
          'No se pudo conectar en 25 segundos.\n'
          'Verifica que el adaptador esté encendido, el teléfono esté en su red WiFi y el switch del vehículo esté en ON.';
      _status = ObdStatus.error;
      _connectedIp = null;
      notifyListeners();
      return false;
    }

    _startPolling();
    return true;
  }

  Future<void> _doConnect(String ip, int port) async {
    _connectionStep = 'Conectando...';
    notifyListeners();
    await _ecu.connect(ip, port);

    _connectionStep = 'Inicializando...';
    notifyListeners();
    await _ecu.initialize();

    _status = ObdStatus.connected;
    _connectionStep = '';
    _dtcCodes = [];
    _hasScannedDtc = false;
    notifyListeners();
  }

  String _friendlyError(String msg) {
    if (msg.contains('Connection refused') || msg.contains('No route')) {
      return 'No se pudo conectar al adaptador.\n'
          'Verifica que estés conectado a la red WiFi del adaptador y que esté encendido.';
    }
    if (msg.contains('SocketException') || msg.contains('timed out')) {
      return 'Tiempo de espera agotado.\n'
          'Verifica que el adaptador esté en la misma red WiFi.';
    }
    if (msg.contains('Failed at') || msg.contains('initialize')) {
      return 'El adaptador OBD no respondió.\n'
          'Verifica que el auto tenga el encendido en ON.';
    }
    if (msg.contains('ECU del vehículo no respondió')) {
      return 'El adaptador WiFi respondió, pero la computadora del vehículo no.\n'
          'Verifica que el adaptador esté bien conectado al puerto OBD y que el switch esté en ON.';
    }
    if (msg.contains('Error en comando') ||
        msg.contains('adaptador no responde')) {
      return 'El adaptador OBD no completó la inicialización.\n'
          'Prueba apagar y encender el adaptador o verifica el puerto correcto.';
    }
    return 'Error de conexión. Intenta de nuevo.';
  }

  Future<void> disconnect() async {
    _stopPolling();
    await _ecu.disconnect();
    _status = ObdStatus.disconnected;
    _connectedIp = null;
    _vehicleData = VehicleData.empty;
    _dtcCodes = [];
    _hasScannedDtc = false;
    _errorMessage = null;
    _connectionStep = '';
    notifyListeners();
  }

  Future<bool> reconnect() async {
    final ip = _connectedIp;
    if (ip == null) return false;
    return connectToDevice(ip, _connectedPort);
  }

  Future<void> scanNetwork() async {
    _isScanning = true;
    _discoveredDevices = [];
    _errorMessage = null;
    _connectionStep = 'Conectando a 192.168.0.10...';
    notifyListeners();

    try {
      _connectionStep = 'Buscando adaptador en la red local...';
      notifyListeners();
      _discoveredDevices = await ObdEcu.scanNetwork();
    } catch (e) {
      _errorMessage = 'Error al buscar dispositivos: $e';
    }

    _connectionStep = '';
    _isScanning = false;
    notifyListeners();
  }

  Future<bool> connectToKnownAdapter({
    String ip = '192.168.0.10',
    int port = 35000,
  }) {
    return connectToDevice(ip, port);
  }

  Future<void> scanDtc() async {
    if (!_ecu.isInitialized) return;
    try {
      _dtcCodes = await _ecu.readDtc();
      _hasScannedDtc = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al leer códigos: $e';
      notifyListeners();
    }
  }

  void _startPolling() {
    _stopPolling();
    unawaited(_pollVehicleData());
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => unawaited(_pollVehicleData()),
    );
  }

  Future<void> _pollVehicleData() async {
    if (_isPollingRead) return;
    if (!_ecu.isConnected) {
      _status = ObdStatus.disconnected;
      _errorMessage = 'Conexión perdida con el adaptador OBD.';
      notifyListeners();
      _stopPolling();
      return;
    }
    try {
      _isPollingRead = true;
      _vehicleData = await _ecu.readAllData();
      notifyListeners();
    } catch (_) {
    } finally {
      _isPollingRead = false;
    }
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    _stopPolling();
    _ecu.disconnect();
    super.dispose();
  }
}
