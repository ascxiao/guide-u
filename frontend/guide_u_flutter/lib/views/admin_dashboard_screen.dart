import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final TextEditingController _userIdController = TextEditingController();
  String _activeView = 'users';

  bool _checkingAccess = true;
  bool _hasAccess = false;
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _users = [];
  String _usersInfo = 'Loading users...';
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserEmail;

  String? _resolveUserIdFromInput(String value) {
    final input = value.trim();
    if (input.isEmpty) return null;

    // If this looks like an email, resolve it through loaded profiles data.
    if (input.contains('@')) {
      final currentEmail = (_currentUserEmail ?? '').trim().toLowerCase();
      if (currentEmail.isNotEmpty && input.toLowerCase() == currentEmail) {
        final currentId = (_currentUserId ?? '').trim();
        if (currentId.isNotEmpty) {
          return currentId;
        }
      }

      for (final row in _users) {
        final email = (row['email'] ?? '').toString().trim().toLowerCase();
        if (email == input.toLowerCase()) {
          final id = (row['id'] ?? '').toString().trim();
          if (id.isNotEmpty) {
            return id;
          }
        }
      }
      return null;
    }

    // Otherwise assume it is already a UUID user id.
    return input;
  }

  Map<String, dynamic>? _profileForUserId(String userId) {
    for (final row in _users) {
      final id = (row['id'] ?? '').toString();
      if (id == userId) {
        return row;
      }
    }
    return null;
  }

  String _displayNameForUserId(String userId) {
    final profile = _profileForUserId(userId);
    if (profile != null) {
      final fullName = (profile['full_name'] ?? '').toString().trim();
      if (fullName.isNotEmpty) {
        return fullName;
      }

      final email = (profile['email'] ?? '').toString().trim();
      if (email.isNotEmpty) {
        return email;
      }
    }

    if (_currentUserId == userId) {
      final currentName = (_currentUserName ?? '').trim();
      if (currentName.isNotEmpty) {
        return currentName;
      }

      final currentEmail = (_currentUserEmail ?? '').trim();
      if (currentEmail.isNotEmpty) {
        return currentEmail;
      }
    }

    return userId;
  }

  String _subtitleForAdmin(String userId, String role) {
    final profile = _profileForUserId(userId);
    var email = (profile?['email'] ?? '').toString().trim();

    if (email.isEmpty && _currentUserId == userId) {
      email = (_currentUserEmail ?? '').trim();
    }

    if (email.isNotEmpty) {
      return 'Email: $email\nRole: $role\nUser ID: $userId';
    }

    return 'Role: $role\nUser ID: $userId';
  }

  @override
  void initState() {
    super.initState();
    final currentUser = Supabase.instance.client.auth.currentUser;
    _currentUserId = currentUser?.id;
    _currentUserName =
        (currentUser?.userMetadata?['name'] ??
                currentUser?.userMetadata?['full_name'])
            ?.toString();
    _currentUserEmail = currentUser?.email;
    _initialize();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _checkAccess();
    if (_hasAccess) {
      await Future.wait([_fetchAdmins(), _fetchUsers()]);
    }
  }

  Future<void> _checkAccess() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _checkingAccess = false;
        _hasAccess = false;
      });
      return;
    }

    try {
      final List<dynamic> rows = await supabase
          .from('admins')
          .select('role')
          .eq('user_id', userId)
          .limit(20);

      final hasAdminRole = rows.any((row) {
        final role = (Map<String, dynamic>.from(row)['role'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        return role == 'admin' || role == 'super_admin';
      });

      if (!mounted) return;
      setState(() {
        _checkingAccess = false;
        _hasAccess = hasAdminRole;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checkingAccess = false;
        _hasAccess = false;
      });
    }
  }

  Future<void> _fetchAdmins() async {
    try {
      final List<dynamic> rows = await Supabase.instance.client
          .from('admins')
          .select('id, user_id, role, created_at')
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _admins = rows
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _fetchUsers() async {
    // Flutter client cannot securely list auth.users directly.
    // If a public profiles table exists, use that as a lightweight user list.
    try {
      final List<dynamic> rows = await Supabase.instance.client
          .from('profiles')
          .select('id, email, full_name')
          .limit(200);

      if (!mounted) return;
      setState(() {
        _users = rows
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
        _usersInfo = _users.isEmpty
            ? 'No users found in profiles table.'
            : 'Showing users from profiles table.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _users = [];
        _usersInfo =
            'All auth users are not directly readable from mobile client. To show all users, add a secure backend endpoint or Supabase Edge Function.';
      });
    }
  }

  Future<void> _grantAdmin() async {
    final rawInput = _userIdController.text.trim();
    if (rawInput.isEmpty) {
      setState(() {
        _error = 'Please enter a user UUID or email.';
      });
      return;
    }

    final userId = _resolveUserIdFromInput(rawInput);
    if (userId == null || userId.isEmpty) {
      setState(() {
        _error =
            'Could not resolve that email to a user. Use UUID directly, or ensure profiles table has id/email rows.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final List<dynamic> existing = await supabase
          .from('admins')
          .select('id')
          .eq('user_id', userId)
          .limit(1);

      if (existing.isEmpty) {
        await supabase.from('admins').insert({
          'user_id': userId,
          'role': 'admin',
        });
      } else {
        final existingId = Map<String, dynamic>.from(existing.first)['id'];
        await supabase
            .from('admins')
            .update({'role': 'admin'})
            .eq('id', existingId);
      }

      _userIdController.clear();
      await _fetchAdmins();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _revokeAdmin(String userId) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Supabase.instance.client
          .from('admins')
          .delete()
          .eq('user_id', userId);
      await _fetchAdmins();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _reloadAll() async {
    await Future.wait([_fetchAdmins(), _fetchUsers()]);
  }

  Widget _buildViewToggle() {
    final usersActive = _activeView == 'users';
    final adminsActive = _activeView == 'admins';

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: () {
                setState(() {
                  _activeView = 'users';
                });
              },
              style: FilledButton.styleFrom(
                elevation: 0,
                backgroundColor: usersActive
                    ? const Color(0xFF006633)
                    : Colors.transparent,
                foregroundColor: usersActive ? Colors.white : Colors.black87,
              ),
              child: const Text('View Users'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              onPressed: () {
                setState(() {
                  _activeView = 'admins';
                });
              },
              style: FilledButton.styleFrom(
                elevation: 0,
                backgroundColor: adminsActive
                    ? const Color(0xFF006633)
                    : Colors.transparent,
                foregroundColor: adminsActive ? Colors.white : Colors.black87,
              ),
              child: const Text('View Admins'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Users',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(_usersInfo),
          if (_users.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._users.map((row) {
              final id = (row['id'] ?? '').toString();
              final email = (row['email'] ?? '-').toString();
              final fullName = (row['full_name'] ?? '').toString();
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(email),
                subtitle: Text(
                  '${fullName.isEmpty ? 'No name' : fullName}\n$id',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  tooltip: 'Grant admin',
                  onPressed: _loading
                      ? null
                      : () async {
                          _userIdController.text = id;
                          await _grantAdmin();
                        },
                  icon: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: Color(0xFF006633),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Admin',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF006633),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _userIdController,
                decoration: const InputDecoration(
                  labelText: 'User UUID or Email',
                  hintText: 'e.g. 60bb...f3b5a or user@school.edu',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _grantAdmin,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF006633),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(_loading ? 'Saving...' : 'Set as Admin'),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Current Admins',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (_admins.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('No admins found.'),
          ),
        ..._admins.map((row) {
          final userId = (row['user_id'] ?? '').toString();
          final role = (row['role'] ?? '').toString();
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              title: Text(
                _displayNameForUserId(userId),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(_subtitleForAdmin(userId, role)),
              isThreeLine: true,
              trailing: IconButton(
                tooltip: 'Remove admin',
                onPressed: _loading ? null : () => _revokeAdmin(userId),
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.redAccent,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F4),
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF006633),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _checkingAccess ? null : _reloadAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _checkingAccess
          ? const Center(child: CircularProgressIndicator())
          : !_hasAccess
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'You do not have permission to view this page.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _reloadAll,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _buildViewToggle(),
                  const SizedBox(height: 16),
                  if (_activeView == 'users') _buildUsersSection(),
                  if (_activeView == 'admins') _buildAdminsSection(context),
                ],
              ),
            ),
    );
  }
}
