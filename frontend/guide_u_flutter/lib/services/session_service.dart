import 'package:supabase_flutter/supabase_flutter.dart';

class SessionService {
  SessionService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  String get currentUserIdOrDemo => _client.auth.currentUser?.id ?? 'demo-user';

  Future<void> signOut() {
    return _client.auth.signOut();
  }
}
