import 'dart:math';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/report_models.dart';

class ReporterDefaults {
  ReporterDefaults({required this.email, required this.studentId});

  final String email;
  final String studentId;
}

class ReportingService {
  ReportingService({SupabaseClient? client})
    : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  static const String _networkErrorMessage =
      'Unable to connect to Guide-U services right now. Please check your internet connection and try again.';

  Future<ReporterDefaults> getReporterDefaults() async {
    final user = _getCurrentUser();
    if (user == null) {
      return ReporterDefaults(email: '', studentId: '');
    }

    var studentId = '';
    try {
      final List<dynamic> rows = await _supabase
          .from('profiles')
          .select('student_id, student_number, id_number')
          .eq('id', user.id)
          .limit(1);

      if (rows.isNotEmpty) {
        final map = Map<String, dynamic>.from(rows.first as Map);
        studentId =
            (map['student_id'] ??
                    map['student_number'] ??
                    map['id_number'] ??
                    '')
                .toString()
                .trim();
      }
    } catch (e) {
      if (_isNetworkAuthError(e)) {
        throw Exception(_networkErrorMessage);
      }
      // Profiles shape is deployment-specific, so missing fields are tolerated.
    }

    return ReporterDefaults(
      email: (user.email ?? '').trim(),
      studentId: studentId,
    );
  }

  Future<void> submitIncidentReport({
    required String title,
    required String description,
    required String location,
    required String reporterEmail,
    required String reporterStudentId,
    required List<XFile> images,
  }) async {
    final user = _getCurrentUser();
    if (user == null) {
      throw Exception('Please sign in before submitting a report.');
    }

    List<String> imagePaths;
    try {
      imagePaths = await _uploadImages(
        bucket: 'incident-report-images',
        userId: user.id,
        images: images,
      );
    } catch (e) {
      if (_isNetworkAuthError(e)) {
        throw Exception(_networkErrorMessage);
      }
      rethrow;
    }

    try {
      await _supabase.from('incident_reports').insert({
        'user_id': user.id,
        'title': title.trim(),
        'description': _nullIfEmpty(description),
        'location': _nullIfEmpty(location),
        'reporter_email': _nullIfEmpty(reporterEmail),
        'reporter_student_id': _nullIfEmpty(reporterStudentId),
        'status': 'pending',
        'image_urls': imagePaths,
      });
    } on PostgrestException catch (e) {
      throw _friendlyRlsException(e, table: 'incident_reports');
    } catch (e) {
      if (_isNetworkAuthError(e)) {
        throw Exception(_networkErrorMessage);
      }
      rethrow;
    }
  }

  Future<void> submitLostFoundReport({
    required String itemName,
    required String description,
    required String location,
    required String reportType,
    required String reporterEmail,
    required String reporterStudentId,
    required List<XFile> images,
  }) async {
    final user = _getCurrentUser();
    if (user == null) {
      throw Exception('Please sign in before submitting a report.');
    }

    final normalizedType = reportType.toLowerCase().trim();
    if (normalizedType != 'lost' && normalizedType != 'found') {
      throw Exception('Report type must be Lost or Found.');
    }

    List<String> imagePaths;
    try {
      imagePaths = await _uploadImages(
        bucket: 'lost-found-images',
        userId: user.id,
        images: images,
      );
    } catch (e) {
      if (_isNetworkAuthError(e)) {
        throw Exception(_networkErrorMessage);
      }
      rethrow;
    }

    try {
      await _supabase.from('lost_found_reports').insert({
        'user_id': user.id,
        'item_name': itemName.trim(),
        'description': _nullIfEmpty(description),
        'location': _nullIfEmpty(location),
        'report_type': normalizedType,
        'reporter_email': _nullIfEmpty(reporterEmail),
        'reporter_student_id': _nullIfEmpty(reporterStudentId),
        'status': 'open',
        'image_urls': imagePaths,
      });
    } on PostgrestException catch (e) {
      throw _friendlyRlsException(e, table: 'lost_found_reports');
    } catch (e) {
      if (_isNetworkAuthError(e)) {
        throw Exception(_networkErrorMessage);
      }
      rethrow;
    }
  }

  Future<List<IncidentReportItem>> fetchMyIncidentReports() async {
    final user = _getCurrentUser();
    if (user == null) return const [];

    dynamic response;
    try {
      response = await _supabase
          .from('incident_reports')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
    } catch (e) {
      if (_isNetworkAuthError(e)) {
        throw Exception(_networkErrorMessage);
      }
      rethrow;
    }

    final rows = List<Map<String, dynamic>>.from(response as List);
    return rows.map(IncidentReportItem.fromJson).toList();
  }

  Future<List<LostFoundReportItem>> fetchMyLostFoundReports() async {
    final user = _getCurrentUser();
    if (user == null) return const [];

    dynamic response;
    try {
      response = await _supabase
          .from('lost_found_reports')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
    } catch (e) {
      if (_isNetworkAuthError(e)) {
        throw Exception(_networkErrorMessage);
      }
      rethrow;
    }

    final rows = List<Map<String, dynamic>>.from(response as List);
    return rows.map(LostFoundReportItem.fromJson).toList();
  }

  Future<List<String>> _uploadImages({
    required String bucket,
    required String userId,
    required List<XFile> images,
  }) async {
    if (images.isEmpty) return const [];

    final uploaded = <String>[];
    for (final image in images) {
      final bytes = await image.readAsBytes();
      final objectPath = _storagePath(userId, image.name);

      await _supabase.storage
          .from(bucket)
          .uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(
              upsert: false,
              contentType: _contentType(image.name, bytes),
            ),
          );

      uploaded.add(objectPath);
    }
    return uploaded;
  }

  String _storagePath(String userId, String fileName) {
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(1 << 32).toRadixString(16);
    return '$userId/$ts-$rand-$safeName';
  }

  String _contentType(String fileName, Uint8List bytes) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }

  String? _nullIfEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Exception _friendlyRlsException(
    PostgrestException e, {
    required String table,
  }) {
    final message = (e.message).toLowerCase();
    final isRls =
        e.code == '42501' ||
        message.contains('row-level security') ||
        message.contains('violates row-level security policy');

    if (!isRls) {
      return Exception(e.message);
    }

    return Exception(
      'Upload blocked by database permissions for $table. '
      'Apply web/src/lib/supabase/mobile_reports_rls_patch.sql in Supabase SQL Editor, then try again.',
    );
  }

  User? _getCurrentUser() {
    try {
      return _supabase.auth.currentUser;
    } catch (e) {
      if (_isNetworkAuthError(e)) {
        throw Exception(_networkErrorMessage);
      }
      rethrow;
    }
  }

  bool _isNetworkAuthError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('authretryablefetchexception') ||
        message.contains('failed host lookup') ||
        message.contains('socketexception') ||
        message.contains('no address associated with hostname') ||
        message.contains('clientexception');
  }
}
