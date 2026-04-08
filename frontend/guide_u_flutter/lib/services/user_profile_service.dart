import 'package:supabase_flutter/supabase_flutter.dart';

import 'session_service.dart';

class UserProfileData {
  const UserProfileData({
    required this.displayName,
    required this.email,
    required this.avatarUrl,
  });

  final String displayName;
  final String email;
  final String? avatarUrl;
}

class UserProfileService {
  UserProfileService({SupabaseClient? client, SessionService? sessionService})
    : _client = client ?? Supabase.instance.client,
      _sessionService = sessionService ?? SessionService(client: client);

  final SupabaseClient _client;
  final SessionService _sessionService;

  User? get currentUser => _sessionService.currentUser;

  String _resolveDisplayName(User? user) {
    final raw =
        user?.userMetadata?['name'] ??
        user?.userMetadata?['full_name'] ??
        user?.userMetadata?['display_name'];
    final displayName = raw?.toString().trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = user?.email?.trim();
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return 'Unknown User';
  }

  String _resolveEmail(User? user) {
    final email = user?.email?.trim();
    if (email == null || email.isEmpty) {
      return 'No email available';
    }
    return email;
  }

  String? _readCandidateUrl(dynamic value) {
    final url = value?.toString().trim();
    if (url == null || url.isEmpty) return null;
    return url;
  }

  String? _resolveAvatarUrl(User? user) {
    if (user == null) return null;

    final metadata = user.userMetadata ?? <String, dynamic>{};
    final metadataCandidates = [
      metadata['avatar_url'],
      metadata['picture'],
      metadata['photo_url'],
      metadata['avatar'],
      metadata['image'],
    ];

    for (final candidate in metadataCandidates) {
      final value = _readCandidateUrl(candidate);
      if (value != null) return value;
    }

    final identities = user.identities;
    if (identities != null) {
      for (final identity in identities) {
        final identityData = identity.identityData;
        if (identityData == null) continue;

        final identityCandidates = [
          identityData['avatar_url'],
          identityData['picture'],
          identityData['photo_url'],
          identityData['avatar'],
          identityData['image'],
        ];

        for (final candidate in identityCandidates) {
          final value = _readCandidateUrl(candidate);
          if (value != null) return value;
        }
      }
    }

    return null;
  }

  UserProfileData currentProfile() {
    final user = currentUser;
    return UserProfileData(
      displayName: _resolveDisplayName(user),
      email: _resolveEmail(user),
      avatarUrl: _resolveAvatarUrl(user),
    );
  }

  String currentFirstName() {
    final profile = currentProfile().displayName.trim();
    if (profile.isEmpty) return 'Student';

    final first = profile.split(RegExp(r'\s+')).first;
    if (first.isEmpty) return 'Student';

    return first[0].toUpperCase() + first.substring(1).toLowerCase();
  }

  String? currentAvatarUrl() {
    return currentProfile().avatarUrl;
  }

  Future<bool> isCurrentUserAdmin() async {
    final userId = _sessionService.currentUser?.id;
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
}
