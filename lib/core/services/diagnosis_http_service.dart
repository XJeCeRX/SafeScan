import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

import '../config/chat_config.dart';
import '../models/obd_data.dart';
import 'diagnosis_queue.dart';

class DiagnosisHttpService extends ChangeNotifier {
  DiagnosisHttpService({required this.queue});

  final DiagnosisQueue queue;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _online = false;
  bool _processing = false;

  bool get online => _online;

  Future<void> init() async {
    final results = await _connectivity.checkConnectivity();
    _online = _hasInternet(results);
    _connectivitySub = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    if (_online) {
      unawaited(_processQueue());
    }
  }

  bool _hasInternet(List<ConnectivityResult> results) {
    return results.any((r) => r == ConnectivityResult.wifi || r == ConnectivityResult.mobile || r == ConnectivityResult.ethernet);
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _online;
    _online = _hasInternet(results);
    if (_online && !wasOnline) {
      unawaited(_processQueue());
    }
    notifyListeners();
  }

  Future<void> diagnose({
    required List<DtcCode> dtcCodes,
    required VehicleData vehicleData,
  }) async {
    final id = queue.addRequest(vehicleData: vehicleData, dtcCodes: dtcCodes);

    if (_online) {
      await _sendRequest(id, dtcCodes, vehicleData);
    }
  }

  Future<void> _sendRequest(
    String id,
    List<DtcCode> dtcCodes,
    VehicleData vehicleData,
  ) async {
    queue.markSending(id);

    try {
      final baseUrl = ChatConfig.httpBaseUrl;
      final codes = dtcCodes.map((c) => c.code).toList();

      final body = <String, dynamic>{
        'codes': codes,
        'sensors': vehicleData.toJson(),
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/codes/batch'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        queue.markCompleted(id, response.body);
      } else {
        queue.markFailed(id);
      }
    } catch (e) {
      queue.markFailed(id);
    }
  }

  Future<void> _processQueue() async {
    if (_processing) return;
    _processing = true;

    final pending = queue.pending.toList();
    for (final request in pending) {
      if (!_online) break;
      await _sendRequest(request.id, request.dtcCodes, request.vehicleData);
    }

    _processing = false;
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
