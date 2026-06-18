import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wifi_scan/wifi_scan.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../core/services/obd_manager.dart';

class ConnectionScreen extends StatefulWidget {
  final ObdManager? obdManager;

  const ConnectionScreen({super.key, this.obdManager});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen>
    with WidgetsBindingObserver {
  static const _wifiChannel = MethodChannel('com.example.safescan/wifi');
  static const _wifiScanUnavailableMessage =
      'Escaneo WiFi automatico disponible solo en Android. '
      'Conectate a la red OBD desde ajustes WiFi y luego busca el adaptador.';

  List<WiFiAccessPoint> _networks = [];
  bool _isScanning = false;
  bool _isConnectingWifi = false;
  String? _connectingSsid;
  String? _currentSsid;

  ObdManager get _obd => widget.obdManager!;

  bool get _supportsNativeWifiScan =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkCurrentSsid();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkCurrentSsid();
    }
  }

  Future<void> _checkCurrentSsid() async {
    if (!_supportsNativeWifiScan) return;

    try {
      final ssid = await _wifiChannel.invokeMethod<String>('getCurrentSsid');
      if (!mounted) return;
      setState(() {
        _currentSsid = (ssid == null || ssid == '<unknown ssid>') ? '' : ssid;
      });
    } catch (_) {}
  }

  Future<bool> _requestWifiPermissions() async {
    if (!_supportsNativeWifiScan) return false;

    try {
      final result = await _wifiChannel.invokeMapMethod<String, dynamic>(
        'requestWifiPermissions',
      );
      return result == null || result['granted'] == true;
    } on MissingPluginException {
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<void> _scanWifi() async {
    if (!_supportsNativeWifiScan) {
      setState(() {
        _isScanning = false;
        _networks = [];
      });
      _showSnackBar(
        _wifiScanUnavailableMessage,
        backgroundColor: AppTheme.severityMedium,
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _networks = [];
    });

    try {
      final permissionGranted = await _requestWifiPermissions();
      if (!permissionGranted) {
        if (mounted) {
          setState(() => _isScanning = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permisos WiFi/ubicación necesarios para escanear'),
              backgroundColor: AppTheme.severityUrgent,
            ),
          );
        }
        return;
      }

      final canStart = await WiFiScan.instance.canStartScan();
      final startMessage = _messageForCanStartScan(canStart);
      if (startMessage != null) {
        _finishWifiScanWithMessage(startMessage);
        return;
      }

      final scanStarted = await WiFiScan.instance.startScan();

      final canGetResults = await WiFiScan.instance.canGetScannedResults();
      final resultsMessage = _messageForCanGetResults(canGetResults);
      if (resultsMessage != null) {
        _finishWifiScanWithMessage(resultsMessage);
        return;
      }

      final networks = await WiFiScan.instance.getScannedResults();
      final strongestBySsid = <String, WiFiAccessPoint>{};
      for (final network in networks.where((n) => n.ssid.isNotEmpty)) {
        final current = strongestBySsid[network.ssid];
        if (current == null || network.level > current.level) {
          strongestBySsid[network.ssid] = network;
        }
      }
      if (mounted) {
        setState(() {
          _networks = strongestBySsid.values.toList()
            ..sort((a, b) => b.level.compareTo(a.level));
          _isScanning = false;
        });
      }
      if (!scanStarted && strongestBySsid.isEmpty) {
        _showSnackBar(
          'Android no inicio un escaneo nuevo. Abre ajustes WiFi, espera unos '
          'segundos y vuelve a intentar.',
          backgroundColor: AppTheme.severityMedium,
        );
      } else if (strongestBySsid.isEmpty) {
        _showSnackBar(
          'No se encontraron redes WiFi cercanas.',
          backgroundColor: AppTheme.severityMedium,
        );
      }
    } on MissingPluginException {
      if (mounted) {
        setState(() => _isScanning = false);
      }
      _showSnackBar(
        _wifiScanUnavailableMessage,
        backgroundColor: AppTheme.severityMedium,
      );
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
      }
      _showSnackBar(
        'No se pudo escanear WiFi: ${e.message ?? e.code}',
        backgroundColor: AppTheme.severityUrgent,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
      }
      _showSnackBar(
        'No se pudo escanear WiFi. Intenta de nuevo.',
        backgroundColor: AppTheme.severityUrgent,
      );
    }
  }

  void _finishWifiScanWithMessage(String message) {
    if (mounted) {
      setState(() => _isScanning = false);
    }
    _showSnackBar(message, backgroundColor: AppTheme.severityUrgent);
  }

  void _showSnackBar(String message, {required Color backgroundColor}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  String? _messageForCanStartScan(CanStartScan result) {
    switch (result) {
      case CanStartScan.yes:
        return null;
      case CanStartScan.notSupported:
        return 'Este dispositivo no permite iniciar escaneos WiFi desde la app.';
      case CanStartScan.noLocationPermissionRequired:
        return 'Concede el permiso de ubicacion para escanear redes WiFi.';
      case CanStartScan.noLocationPermissionDenied:
        return 'Activa el permiso de ubicacion de SafeScan desde ajustes.';
      case CanStartScan.noLocationPermissionUpgradeAccuracy:
        return 'Activa ubicacion precisa para SafeScan.';
      case CanStartScan.noLocationServiceDisabled:
        return 'Activa la ubicacion del telefono para escanear WiFi.';
      case CanStartScan.failed:
        return 'Android no pudo iniciar el escaneo WiFi. Intenta de nuevo.';
    }
  }

  String? _messageForCanGetResults(CanGetScannedResults result) {
    switch (result) {
      case CanGetScannedResults.yes:
        return null;
      case CanGetScannedResults.notSupported:
        return 'Este dispositivo no permite leer redes WiFi desde la app.';
      case CanGetScannedResults.noLocationPermissionRequired:
        return 'Concede el permiso de ubicacion para ver redes WiFi.';
      case CanGetScannedResults.noLocationPermissionDenied:
        return 'Activa el permiso de ubicacion de SafeScan desde ajustes.';
      case CanGetScannedResults.noLocationPermissionUpgradeAccuracy:
        return 'Activa ubicacion precisa para SafeScan.';
      case CanGetScannedResults.noLocationServiceDisabled:
        return 'Activa la ubicacion del telefono para ver redes WiFi.';
    }
  }

  Future<void> _onTapNetwork(WiFiAccessPoint network) async {
    final ssid = network.ssid;
    if (ssid.isEmpty) return;

    final password = await _showWifiPasswordDialog(network);
    if (!mounted || password == null) return;

    if (password == _openSettingsToken) {
      await _wifiChannel.invokeMethod('openWifiSettings');
      return;
    }

    setState(() {
      _isConnectingWifi = true;
      _connectingSsid = ssid;
    });

    try {
      final connected = await _connectToWifiNetwork(ssid, password);
      if (!mounted) return;

      if (connected) {
        setState(() => _currentSsid = ssid);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conectado a $ssid. Buscando adaptador OBD...'),
            backgroundColor: AppTheme.primary,
          ),
        );
        await _autoDetectObd();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo conectar a $ssid. Revisa la clave WiFi.'),
            backgroundColor: AppTheme.severityUrgent,
          ),
        );
      }
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conexión WiFi directa disponible solo en Android'),
          backgroundColor: AppTheme.severityMedium,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al conectar WiFi: $e'),
          backgroundColor: AppTheme.severityUrgent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isConnectingWifi = false;
          _connectingSsid = null;
        });
      }
    }
  }

  static const _openSettingsToken = '__open_settings__';

  bool _networkNeedsPassword(WiFiAccessPoint network) {
    final capabilities = network.capabilities.toUpperCase();
    return capabilities.contains('WEP') ||
        capabilities.contains('WPA') ||
        capabilities.contains('SAE');
  }

  Future<String?> _showWifiPasswordDialog(WiFiAccessPoint network) async {
    final needsPassword = _networkNeedsPassword(network);
    final passwordController = TextEditingController(
      text: needsPassword ? '12345678' : '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Conectar a ${network.ssid}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (needsPassword)
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Clave WiFi',
                  hintText: '12345678',
                  filled: true,
                  fillColor: AppTheme.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              )
            else
              const Text('Esta red parece abierta.'),
            const SizedBox(height: 12),
            Text(
              'Si Android no permite la conexión directa, abre WiFi y vuelve a SafeScan.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _openSettingsToken),
            child: const Text('Abrir WiFi'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, passwordController.text.trim()),
            child: const Text('Conectar'),
          ),
        ],
      ),
    );

    passwordController.dispose();
    return result;
  }

  Future<bool> _connectToWifiNetwork(String ssid, String password) async {
    await _requestWifiPermissions();
    final result = await _wifiChannel.invokeMapMethod<String, dynamic>(
      'connectToWifi',
      {'ssid': ssid, 'password': password},
    );
    return result?['connected'] == true;
  }

  Future<void> _autoDetectObd() async {
    await _obd.scanNetwork();

    if (!mounted) return;

    if (_obd.discoveredDevices.isNotEmpty) {
      final device = _obd.discoveredDevices.first;
      _connect(ip: device.ip, port: device.port);
    } else {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se encontró el adaptador. Verifica la conexión WiFi.',
          ),
          backgroundColor: AppTheme.severityUrgent,
        ),
      );
    }
  }

  Future<void> _connect({required String ip, required int port}) async {
    final success = await _obd.connectToDevice(ip, port);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              const Text('Conectado al adaptador OBD'),
            ],
          ),
          backgroundColor: AppTheme.primary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRouter.dashboard,
        arguments: _obd,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnecting = _obd.status == ObdStatus.connecting;
    final isError = _obd.status == ObdStatus.error;
    final error = _obd.errorMessage;
    final step = _obd.connectionStep;
    final devices = _obd.discoveredDevices;
    final isDetecting = _obd.isScanning;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Conectar OBD',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Conecta tu dispositivo',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Busca la red WiFi del adaptador OBD y conéctate.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              if (_currentSsid != null && _currentSsid!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Conectado a: $_currentSsid',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (isError && error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.severityUrgent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.severityUrgent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.error_outline,
                          color: AppTheme.severityUrgent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Error',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppTheme.severityUrgent,
                                    fontSize: 14,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              error,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.severityUrgent,
                                    fontSize: 13,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              if (isConnecting || _isConnectingWifi || isDetecting)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        const SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                            strokeWidth: 4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _isConnectingWifi
                              ? 'Conectando a $_connectingSsid...'
                              : isDetecting
                              ? 'Buscando adaptador OBD...'
                              : step.isNotEmpty
                              ? step
                              : 'Conectando...',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),

              if (!isConnecting && !_isConnectingWifi && !isDetecting) ...[
                if (_networks.isEmpty && !_isScanning) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _scanWifi,
                      icon: const Icon(Icons.wifi_find_outlined),
                      label: const Text('Buscar redes WiFi'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (_isScanning)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Column(
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              color: AppTheme.primary,
                              strokeWidth: 3,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Buscando redes WiFi...',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_networks.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Redes WiFi disponibles',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton.icon(
                        onPressed: _scanWifi,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Actualizar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._networks
                      .where((n) => n.ssid.isNotEmpty)
                      .map(
                        (n) => _WifiNetworkCard(
                          ssid: n.ssid,
                          level: n.level,
                          isCurrentSsid: n.ssid == _currentSsid,
                          onTap: () => _onTapNetwork(n),
                        ),
                      ),
                  const SizedBox(height: 16),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _autoDetectObd,
                    icon: const Icon(Icons.search_outlined),
                    label: const Text('Buscar adaptador OBD'),
                  ),
                ),
                const SizedBox(height: 12),

                if (devices.isNotEmpty) ...[
                  Text(
                    'Adaptador OBD encontrado',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...devices.map(
                    (d) => _ObdDeviceCard(
                      onTap: () => _connect(ip: d.ip, port: d.port),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'El adaptador OBD crea su propia red WiFi. '
                          'Conéctate a esa red y la app buscará el adaptador '
                          'automáticamente.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _WifiNetworkCard extends StatelessWidget {
  final String ssid;
  final int level;
  final bool isCurrentSsid;
  final VoidCallback onTap;

  const _WifiNetworkCard({
    required this.ssid,
    required this.level,
    required this.isCurrentSsid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bars = level >= -50
        ? 4
        : level >= -65
        ? 3
        : level >= -80
        ? 2
        : 1;

    return Card(
      color: isCurrentSsid
          ? AppTheme.primary.withValues(alpha: 0.08)
          : AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrentSsid
              ? AppTheme.primary.withValues(alpha: 0.4)
              : AppTheme.surfaceLight,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(
          bars >= 3
              ? Icons.wifi
              : bars == 2
              ? Icons.wifi_2_bar
              : Icons.wifi_1_bar,
          color: isCurrentSsid ? AppTheme.primary : AppTheme.textSecondary,
          size: 24,
        ),
        title: Text(
          ssid,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isCurrentSsid ? AppTheme.primary : null,
          ),
        ),
        subtitle: Text(
          isCurrentSsid ? 'Conectado actualmente' : 'Tocar para conectar',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isCurrentSsid ? AppTheme.primary : AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: isCurrentSsid
            ? const Icon(Icons.check_circle, color: AppTheme.primary, size: 22)
            : Text(
                '$bars',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 11),
              ),
        onTap: isCurrentSsid ? null : onTap,
      ),
    );
  }
}

class _ObdDeviceCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ObdDeviceCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.surfaceLight),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.directions_car_outlined,
            color: AppTheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          'Adaptador OBD-II',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Tocar para conectar',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppTheme.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}
