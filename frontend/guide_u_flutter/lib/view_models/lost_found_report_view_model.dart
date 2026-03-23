import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/report_models.dart';
import '../services/reporting_service.dart';

class LostFoundReportViewModel extends ChangeNotifier {
  LostFoundReportViewModel({ReportingService? service})
      : _service = service ?? ReportingService();

  final ReportingService _service;
  final ImagePicker _picker = ImagePicker();

  bool _loading = false;
  bool _submitting = false;
  bool _useProfileInfo = false;
  String? _error;
  String? _success;
  String _defaultEmail = '';
  String _defaultStudentId = '';

  final List<XFile> _images = [];
  List<LostFoundReportItem> _history = [];

  bool get loading => _loading;
  bool get submitting => _submitting;
  bool get useProfileInfo => _useProfileInfo;
  String? get error => _error;
  String? get success => _success;
  String get defaultEmail => _defaultEmail;
  String get defaultStudentId => _defaultStudentId;
  List<XFile> get images => List.unmodifiable(_images);
  List<LostFoundReportItem> get history => _history;

  Future<void> initialize() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final defaults = await _service.getReporterDefaults();
      _defaultEmail = defaults.email;
      _defaultStudentId = defaults.studentId;
      _history = await _service.fetchMyLostFoundReports();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshHistory() async {
    try {
      _history = await _service.fetchMyLostFoundReports();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void setUseProfileInfo(bool value) {
    _useProfileInfo = value;
    notifyListeners();
  }

  Future<void> pickImages() async {
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 85);
      if (picked.isNotEmpty) {
        _images
          ..clear()
          ..addAll(picked);
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void removeImageAt(int index) {
    if (index < 0 || index >= _images.length) return;
    _images.removeAt(index);
    notifyListeners();
  }

  Future<bool> submit({
    required String itemName,
    required String description,
    required String location,
    required String reportType,
    required String reporterEmail,
    required String reporterStudentId,
  }) async {
    _submitting = true;
    _error = null;
    _success = null;
    notifyListeners();

    try {
      final email = _useProfileInfo ? _defaultEmail : reporterEmail;
      final studentId = _useProfileInfo ? _defaultStudentId : reporterStudentId;

      await _service.submitLostFoundReport(
        itemName: itemName,
        description: description,
        location: location,
        reportType: reportType,
        reporterEmail: email,
        reporterStudentId: studentId,
        images: _images,
      );

      _images.clear();
      _success = 'Lost and found report submitted successfully.';
      _history = await _service.fetchMyLostFoundReports();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
