import 'package:flutter/material.dart';

import '../services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const Color _brandMain = Color(0xFF1F7A5A);
  static const Color _brandAccent = Color(0xFF4FBF8F);
  static const Color _brandSoft = Color(0xFFE6F4EF);
  static const Color _pageBg = Color(0xFFF5F7FA);

  final AdminService _adminService = AdminService();
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

  @override
  void initState() {
    super.initState();
    final currentUser = _adminService.currentUser;
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
    if (_adminService.currentUser == null) {
      if (!mounted) return;
      setState(() {
        _checkingAccess = false;
        _hasAccess = false;
      });
      return;
    }

    try {
      final hasAdminRole = await _adminService.hasCurrentUserAdminAccess();
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
      final rows = await _adminService.fetchAdmins();
      if (!mounted) return;
      setState(() {
        _admins = rows;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final rows = await _adminService.fetchProfiles(limit: 200);
      if (!mounted) return;
      setState(() {
        _users = rows;
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

  Future<void> _reloadAll() async {
    await Future.wait([_fetchAdmins(), _fetchUsers()]);
  }

  String? _resolveUserIdFromInput(String value) {
    final input = value.trim();
    if (input.isEmpty) return null;

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
      await _adminService.grantAdmin(userId);
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
      await _adminService.revokeAdmin(userId);
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

  Widget _buildViewToggle() {
    final usersActive = _activeView == 'users';
    final adminsActive = _activeView == 'admins';

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDEBE3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                backgroundColor: usersActive ? _brandMain : Colors.transparent,
                foregroundColor: usersActive ? Colors.white : Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
                backgroundColor: adminsActive ? _brandMain : Colors.transparent,
                foregroundColor: adminsActive ? Colors.white : Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
      key: const ValueKey('users_view'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDEBE3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Users',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _brandSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_users.length}',
                  style: const TextStyle(
                    color: _brandMain,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _brandSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _usersInfo,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
          if (_users.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._users.map((row) {
              final id = (row['id'] ?? '').toString();
              final email = (row['email'] ?? '-').toString();
              final fullName = (row['full_name'] ?? '').toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FCFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE3EEE8)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${fullName.isEmpty ? 'No name' : fullName}\n$id',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Grant admin',
                      onPressed: _loading
                          ? null
                          : () async {
                              _userIdController.text = id;
                              await _grantAdmin();
                            },
                      icon: const Icon(
                        Icons.admin_panel_settings_outlined,
                        color: _brandMain,
                      ),
                    ),
                  ],
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
      key: const ValueKey('admins_view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDDEBE3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
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
                  color: _brandMain,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter a user UUID or email from profiles to grant admin access.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _userIdController,
                decoration: InputDecoration(
                  labelText: 'User UUID or Email',
                  hintText: 'e.g. 60bb...f3b5a or user@school.edu',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: _brandMain),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _grantAdmin,
                  style: FilledButton.styleFrom(
                    backgroundColor: _brandMain,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: Text(_loading ? 'Saving...' : 'Set as Admin'),
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
        Row(
          children: [
            const Text(
              'Current Admins',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _brandSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_admins.length}',
                style: const TextStyle(
                  color: _brandMain,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_admins.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE1ECE6)),
            ),
            child: const Text(
              'No admins found.',
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ..._admins.map((row) {
          final userId = (row['user_id'] ?? '').toString();
          final role = (row['role'] ?? '').toString();
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE1ECE6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
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
      backgroundColor: _pageBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_brandAccent, _brandMain],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: AppBar(
            automaticallyImplyLeading: false,
            leading: IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            title: const Text(
              'Admin Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            foregroundColor: Colors.white,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                  child: IconButton(
                    tooltip: 'Refresh',
                    padding: EdgeInsets.zero,
                    onPressed: _checkingAccess ? null : _reloadAll,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _checkingAccess
          ? const Center(child: CircularProgressIndicator(color: _brandMain))
          : !_hasAccess
          ? Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2ECE6)),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      color: _brandMain,
                      size: 30,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'You do not have permission to view this page.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _reloadAll,
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_brandSoft, Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDDEBE3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _brandMain.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_outlined,
                            color: _brandMain,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _activeView == 'users'
                                ? 'Review user profiles and grant admin access.'
                                : 'Manage current admin accounts and roles.',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildViewToggle(),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _activeView == 'users'
                        ? _buildUsersSection()
                        : _buildAdminsSection(context),
                  ),
                ],
              ),
            ),
    );
  }
}
