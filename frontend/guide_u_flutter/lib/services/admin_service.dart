import 'package:supabase_flutter/supabase_flutter.dart';

import 'session_service.dart';

class AdminService {
  AdminService({SupabaseClient? client, SessionService? sessionService})
    : _client = client ?? Supabase.instance.client,
      _sessionService = sessionService ?? SessionService(client: client);

  final SupabaseClient _client;
  final SessionService _sessionService;

  User? get currentUser => _sessionService.currentUser;

  Future<bool> hasCurrentUserAdminAccess() async {
    final userId = currentUser?.id;
    if (userId == null) return false;

    try {
      final List<dynamic> rows = await _client
          .from('admins')
          .select('role')
          .eq('user_id', userId)
          .limit(20);

      return rows.any((row) {
        final role = (Map<String, dynamic>.from(row)['role'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        return role == 'admin' || role == 'super_admin';
      });
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAdmins() async {
    final List<dynamic> rows = await _client
        .from('admins')
        .select('id, user_id, role, created_at')
        .order('created_at', ascending: false);

    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchProfiles({int limit = 200}) async {
    final List<dynamic> rows = await _client
        .from('profiles')
        .select('id, email, full_name')
        .limit(limit);

    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<void> grantAdmin(String userId) async {
    final List<dynamic> existing = await _client
        .from('admins')
        .select('id')
        .eq('user_id', userId)
        .limit(1);

    if (existing.isEmpty) {
      await _client.from('admins').insert({'user_id': userId, 'role': 'admin'});
      return;
    }

    final existingId = Map<String, dynamic>.from(existing.first)['id'];
    await _client.from('admins').update({'role': 'admin'}).eq('id', existingId);
  }

  Future<void> revokeAdmin(String userId) async {
    await _client.from('admins').delete().eq('user_id', userId);
  }
}
