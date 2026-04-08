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
  String _activeReportView = 'incident';

  bool _checkingAccess = true;
  bool _hasAccess = false;
  bool _loading = false;
  String? _error;
  String _userRole = ''; // 'admin' or 'super_admin'

  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _incidentReports = [];
  List<Map<String, dynamic>> _lostFoundReports = [];
  String _usersInfo = 'Loading users...';
  String _reportsInfo = 'Loading reports...';
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserEmail;

  static const List<String> _incidentStatuses = [
    'pending',
    'under_review',
    'resolved',
    'closed',
  ];
  static const List<String> _lostFoundStatuses = [
    'open',
    'under_review',
    'resolved',
    'closed',
  ];

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
      await Future.wait([
        _fetchAdmins(),
        _fetchUsers(),
        _fetchIncidentReports(),
        _fetchLostFoundReports(),
      ]);
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
        _userRole = '';
      });
      return;
    }

    try {
      final List<dynamic> rows = await supabase
          .from('admins')
          .select('role')
          .eq('user_id', userId)
          .limit(20);

      String detectedRole = '';
      final hasAdminRole = rows.any((row) {
        final role = (Map<String, dynamic>.from(row)['role'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        if (role == 'super_admin') {
          detectedRole = 'super_admin';
          return true;
        }
        if (role == 'admin' && detectedRole.isEmpty) {
          detectedRole = 'admin';
        }
        return role == 'admin' || role == 'super_admin';
      });

      if (!mounted) return;
      setState(() {
        _checkingAccess = false;
        _hasAccess = hasAdminRole;
        _userRole = detectedRole;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checkingAccess = false;
        _hasAccess = false;
        _userRole = '';
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
    if (_userRole != 'super_admin') {
      setState(() {
        _error = 'Only super admins can add admins.';
      });
      return;
    }

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
    if (_userRole != 'super_admin') {
      setState(() {
        _error = 'Only super admins can remove admins.';
      });
      return;
    }

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

  Future<void> _reloadAll() async {
    await Future.wait([
      _fetchAdmins(),
      _fetchUsers(),
      _fetchIncidentReports(),
      _fetchLostFoundReports(),
    ]);
  }

  Future<void> _fetchIncidentReports() async {
    try {
      final List<dynamic> rows = await Supabase.instance.client
          .from('incident_reports')
          .select(
            'id, user_id, title, description, location, status, reporter_email, reporter_student_id, created_at',
          )
          .order('created_at', ascending: false)
          .limit(200);

      if (!mounted) return;
      setState(() {
        _incidentReports = rows
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
        _reportsInfo =
            'Showing ${_incidentReports.length} incident and ${_lostFoundReports.length} lost/found reports.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _fetchLostFoundReports() async {
    try {
      final List<dynamic> rows = await Supabase.instance.client
          .from('lost_found_reports')
          .select(
            'id, user_id, item_name, description, location, report_type, status, reporter_email, reporter_student_id, created_at',
          )
          .order('created_at', ascending: false)
          .limit(200);

      if (!mounted) return;
      setState(() {
        _lostFoundReports = rows
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
        _reportsInfo =
            'Showing ${_incidentReports.length} incident and ${_lostFoundReports.length} lost/found reports.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  String _prettyStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  String _formatCreatedAt(dynamic value) {
    final raw = (value ?? '').toString();
    if (raw.isEmpty) return '-';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final local = parsed.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _updateIncidentStatus(String reportId, String newStatus) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final previous = _incidentReports.firstWhere(
        (row) => (row['id'] ?? '').toString() == reportId,
        orElse: () => <String, dynamic>{},
      );
      final oldStatus = (previous['status'] ?? '').toString();

      if (oldStatus == newStatus) {
        return;
      }

      await Supabase.instance.client
          .from('incident_reports')
          .update({'status': newStatus})
          .eq('id', reportId)
          .select('id')
          .single();

      await _fetchIncidentReports();
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

  Future<void> _updateLostFoundStatus(String reportId, String newStatus) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final previous = _lostFoundReports.firstWhere(
        (row) => (row['id'] ?? '').toString() == reportId,
        orElse: () => <String, dynamic>{},
      );
      final oldStatus = (previous['status'] ?? '').toString();

      if (oldStatus == newStatus) {
        return;
      }

      await Supabase.instance.client
          .from('lost_found_reports')
          .update({'status': newStatus})
          .eq('id', reportId)
          .select('id')
          .single();

      await _fetchLostFoundReports();
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

  Future<void> _deleteIncidentReport(String reportId) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Supabase.instance.client
          .from('incident_reports')
          .delete()
          .eq('id', reportId);
      await _fetchIncidentReports();
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

  Future<void> _deleteLostFoundReport(String reportId) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Supabase.instance.client
          .from('lost_found_reports')
          .delete()
          .eq('id', reportId);
      await _fetchLostFoundReports();
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

  Future<bool> _confirmDelete(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return shouldDelete ?? false;
  }

  Widget _buildViewToggle() {
    final usersActive = _activeView == 'users';
    final adminsActive = _activeView == 'admins';
    final reportsActive = _activeView == 'reports';

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
                backgroundColor: adminsActive
                    ? const Color(0xFF006633)
                    : Colors.transparent,
                foregroundColor: adminsActive ? Colors.white : Colors.black87,
              ),
              child: const Text('View Admins', textAlign: TextAlign.center),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              onPressed: () {
                setState(() {
                  _activeView = 'reports';
                });
              },
              style: FilledButton.styleFrom(
                elevation: 0,
                backgroundColor: reportsActive
                    ? const Color(0xFF006633)
                    : Colors.transparent,
                foregroundColor: reportsActive ? Colors.white : Colors.black87,
              ),
              child: const Text('View Reports', textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsSection(BuildContext context) {
    final incidentsActive = _activeReportView == 'incident';
    final lostFoundActive = _activeReportView == 'lost_found';

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
                'Report Moderation',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF006633),
                ),
              ),
              const SizedBox(height: 8),
              Text(_reportsInfo),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          _activeReportView = 'incident';
                        });
                      },
                      style: FilledButton.styleFrom(
                        elevation: 0,
                        backgroundColor: incidentsActive
                            ? const Color(0xFF006633)
                            : Colors.transparent,
                        foregroundColor: incidentsActive
                            ? Colors.white
                            : Colors.black87,
                      ),
                      child: const Text('Incident Reports'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          _activeReportView = 'lost_found';
                        });
                      },
                      style: FilledButton.styleFrom(
                        elevation: 0,
                        backgroundColor: lostFoundActive
                            ? const Color(0xFF006633)
                            : Colors.transparent,
                        foregroundColor: lostFoundActive
                            ? Colors.white
                            : Colors.black87,
                      ),
                      child: const Text('Lost & Found'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_activeReportView == 'incident') ...[
          if (_incidentReports.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No incident reports found.'),
            ),
          ..._incidentReports.map((row) {
            final id = (row['id'] ?? '').toString();
            final title = (row['title'] ?? 'Untitled incident').toString();
            final location = (row['location'] ?? '').toString();
            final reporterEmail = (row['reporter_email'] ?? '').toString();
            final reporterStudentId = (row['reporter_student_id'] ?? '')
                .toString();
            final createdAt = _formatCreatedAt(row['created_at']);
            final rawStatus = (row['status'] ?? 'pending').toString();
            final status = _incidentStatuses.contains(rawStatus)
                ? rawStatus
                : 'pending';

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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Location: ${location.isEmpty ? '-' : location}'),
                    Text('Reported: $createdAt'),
                    Text(
                      'Reporter: ${reporterEmail.isEmpty ? '-' : reporterEmail}${reporterStudentId.isEmpty ? '' : ' ($reporterStudentId)'}',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: status,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: _incidentStatuses
                                .map(
                                  (value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(_prettyStatus(value)),
                                  ),
                                )
                                .toList(),
                            onChanged: _loading
                                ? null
                                : (value) async {
                                    if (value == null) return;
                                    await _updateIncidentStatus(id, value);
                                  },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Delete incident report',
                          onPressed: _loading
                              ? null
                              : () async {
                                  final confirmed = await _confirmDelete(
                                    context,
                                    title: 'Delete incident report?',
                                    message:
                                        'This will permanently delete the selected incident report.',
                                  );
                                  if (!confirmed) return;
                                  await _deleteIncidentReport(id);
                                },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
        if (_activeReportView == 'lost_found') ...[
          if (_lostFoundReports.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No lost and found reports found.'),
            ),
          ..._lostFoundReports.map((row) {
            final id = (row['id'] ?? '').toString();
            final itemName = (row['item_name'] ?? 'Unnamed item').toString();
            final reportType = (row['report_type'] ?? '').toString();
            final location = (row['location'] ?? '').toString();
            final reporterEmail = (row['reporter_email'] ?? '').toString();
            final reporterStudentId = (row['reporter_student_id'] ?? '')
                .toString();
            final createdAt = _formatCreatedAt(row['created_at']);
            final rawStatus = (row['status'] ?? 'open').toString();
            final status = _lostFoundStatuses.contains(rawStatus)
                ? rawStatus
                : 'open';

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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Type: ${reportType.isEmpty ? '-' : _prettyStatus(reportType)}',
                    ),
                    Text('Location: ${location.isEmpty ? '-' : location}'),
                    Text('Reported: $createdAt'),
                    Text(
                      'Reporter: ${reporterEmail.isEmpty ? '-' : reporterEmail}${reporterStudentId.isEmpty ? '' : ' ($reporterStudentId)'}',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: status,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: _lostFoundStatuses
                                .map(
                                  (value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(_prettyStatus(value)),
                                  ),
                                )
                                .toList(),
                            onChanged: _loading
                                ? null
                                : (value) async {
                                    if (value == null) return;
                                    await _updateLostFoundStatus(id, value);
                                  },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Delete lost and found report',
                          onPressed: _loading
                              ? null
                              : () async {
                                  final confirmed = await _confirmDelete(
                                    context,
                                    title: 'Delete lost and found report?',
                                    message:
                                        'This will permanently delete the selected lost and found report.',
                                  );
                                  if (!confirmed) return;
                                  await _deleteLostFoundReport(id);
                                },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
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
    final isSuperAdmin = _userRole == 'super_admin';
    return Column(
      key: const ValueKey('admins_view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isSuperAdmin) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'You have view-only access to admin management. Contact a Super Admin to modify roles.',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ),
        ] else ...[
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        const Text(
          'Current Admins',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
              trailing: isSuperAdmin
                  ? IconButton(
                      tooltip: 'Remove admin',
                      onPressed: _loading ? null : () => _revokeAdmin(userId),
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.redAccent,
                      ),
                    )
                  : null,
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
                  if (_activeView == 'users') _buildUsersSection(),
                  if (_activeView == 'admins') _buildAdminsSection(context),
                  if (_activeView == 'reports') _buildReportsSection(context),
                ],
              ),
            ),
    );
  }
}
