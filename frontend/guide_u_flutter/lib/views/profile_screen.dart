import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../services/session_service.dart';
import '../services/user_profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _brandMain = Color(0xFF1F7A5A);
  static const Color _brandAccent = Color(0xFF4FBF8F);
  static const Color _brandSoft = Color(0xFFE6F4EF);
  static const Color _pageBg = Color(0xFFF5F7FA);

  bool _checkingAdmin = true;
  bool _isAdmin = false;
  final SessionService _sessionService = SessionService();
  final UserProfileService _userProfileService = UserProfileService();

  Widget _buildProfileAvatar(String? avatarUrl, {double size = 60}) {
    const accent = _brandMain;
    final iconSize = size * 0.56;

    if (avatarUrl == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.person, color: accent, size: iconSize),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent.withValues(alpha: 0.16), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            color: accent.withValues(alpha: 0.10),
            child: Icon(Icons.person, color: accent, size: iconSize),
          );
        },
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign out?'),
          content: const Text('You will need to log in again to continue.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _brandMain),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) return;

    await _sessionService.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  Widget _buildActionTile({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
    Color? iconColor,
  }) {
    final tile = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _brandSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor ?? _brandMain, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B1B1B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _brandSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: _brandMain,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.black45,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 230 + (index * 90)),
      curve: Curves.easeOut,
      tween: Tween<double>(begin: 14, end: 0),
      builder: (context, value, child) {
        return Opacity(
          opacity: (1 - (value / 14)).clamp(0, 1),
          child: Transform.translate(offset: Offset(0, value), child: child),
        );
      },
      child: tile,
    );
  }

  @override
  void initState() {
    super.initState();
    _refreshAdminStatus();
  }

  Future<void> _refreshAdminStatus() async {
    if (!mounted) return;
    setState(() {
      _checkingAdmin = true;
    });

    final isAdmin = await _userProfileService.isCurrentUserAdmin();

    if (!mounted) return;
    setState(() {
      _isAdmin = isAdmin;
      _checkingAdmin = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = _userProfileService.currentProfile();
    final userName = profile.displayName;
    final userEmail = profile.email;
    final avatarUrl = profile.avatarUrl;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4BB285), _brandMain],
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
              'Profile',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
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
                    tooltip: 'Refresh access',
                    padding: EdgeInsets.zero,
                    onPressed: _refreshAdminStatus,
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        physics: const BouncingScrollPhysics(),
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            tween: Tween<double>(begin: 14, end: 0),
            builder: (context, value, child) {
              return Opacity(
                opacity: (1 - (value / 14)).clamp(0, 1),
                child: Transform.translate(
                  offset: Offset(0, value),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [_brandSoft, _brandAccent.withValues(alpha: 0.20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: _brandAccent.withValues(alpha: 0.22)),
              ),
              child: Row(
                children: [
                  _buildProfileAvatar(avatarUrl, size: 68),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: _brandMain,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12.5,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'GuideU Account',
                            style: TextStyle(
                              color: _brandMain,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Account Actions',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (_checkingAdmin)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isAdmin) ...[
            _buildActionTile(
              index: 0,
              icon: Icons.admin_panel_settings_outlined,
              title: 'Admin Dashboard',
              subtitle: 'Manage admin user access',
              badge: 'Admin',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.adminDashboard);
              },
            ),
            const SizedBox(height: 10),
          ],
          _buildActionTile(
            index: 1,
            icon: Icons.logout_rounded,
            title: 'Logout',
            subtitle: 'Securely sign out of your account',
            onTap: _confirmLogout,
          ),
        ],
      ),
    );
  }
}
