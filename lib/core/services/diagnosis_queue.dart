import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/obd_data.dart';
import '../models/diagnosis_request.dart';

class DiagnosisQueue extends ChangeNotifier {
  static const String _boxName = 'diagnosis_queue';
  late final Box<String> _box;
  final _uuid = const Uuid();

  List<DiagnosisRequest> _requests = [];

  List<DiagnosisRequest> get requests => List.unmodifiable(_requests);
  List<DiagnosisRequest> get pending =>
      _requests.where((r) => r.status == DiagnosisStatus.pending).toList();

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
    _loadFromBox();
  }

  void _loadFromBox() {
    final values = _box.values.toList();
    _requests = values
        .map((raw) {
          try {
            return DiagnosisRequest.fromJson(raw);
          } catch (_) {
            return null;
          }
        })
        .whereType<DiagnosisRequest>()
        .toList();
    _requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  String addRequest({
    required VehicleData vehicleData,
    required List<DtcCode> dtcCodes,
  }) {
    final id = _uuid.v4();
    final request = DiagnosisRequest(
      id: id,
      createdAt: DateTime.now(),
      vehicleData: vehicleData,
      dtcCodes: dtcCodes,
    );
    _requests.insert(0, request);
    _box.put(id, request.toJson());
    notifyListeners();
    return id;
  }

  void markCompleted(String id, String resultJson) {
    final index = _requests.indexWhere((r) => r.id == id);
    if (index == -1) return;
    _requests[index] = _requests[index].copyWith(
      status: DiagnosisStatus.completed,
      resultJson: resultJson,
      completedAt: DateTime.now(),
    );
    _box.put(id, _requests[index].toJson());
    notifyListeners();
  }

  void markFailed(String id) {
    final index = _requests.indexWhere((r) => r.id == id);
    if (index == -1) return;
    _requests[index] = _requests[index].copyWith(
      status: DiagnosisStatus.failed,
      completedAt: DateTime.now(),
    );
    _box.put(id, _requests[index].toJson());
    notifyListeners();
  }

  void markSending(String id) {
    final index = _requests.indexWhere((r) => r.id == id);
    if (index == -1) return;
    _requests[index] = _requests[index].copyWith(
      status: DiagnosisStatus.sending,
    );
    _box.put(id, _requests[index].toJson());
    notifyListeners();
  }
}
