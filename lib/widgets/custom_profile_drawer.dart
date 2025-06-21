import 'package:flutter/material.dart';
import '../utils/app_constants.dart';
import '../services/service_locator.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CustomProfileDrawer extends StatefulWidget {
  const CustomProfileDrawer({super.key});

  @override
  State<CustomProfileDrawer> createState() => _CustomProfileDrawerState();
}

class _CustomProfileDrawerState extends State<CustomProfileDrawer> {
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh user data each time the drawer becomes visible
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Force a fresh fetch from the server by not using cached data
      final user = await serviceLocator.auth.getCurrentUserModel();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // Transparent tap area
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.45,
                color: Colors.transparent,
                height: double.infinity,
              ),
            ),
          ),
          // Drawer content
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.55,
              color: const Color(0xFF262135),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    // Profile picture with gradient border and edit icon
                    Stack(
                      children: [
                        // Profile picture with gradient border
                        Container(
                          height: 88, // Diameter = 2 * radius
                          width: 88,  // Diameter = 2 * radius
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFFFC9E9), // Pink
                                Color(0xFFF5F2B8), // Yellow
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0), // Border thickness
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: const Color(0xFF2D2041),
                              backgroundImage: (_currentUser?.profileImageUrl != null && _currentUser!.profileImageUrl!.isNotEmpty)
                                ? CachedNetworkImageProvider(_currentUser!.profileImageUrl!)
                                : null,
                              child: (_currentUser?.profileImageUrl == null || _currentUser!.profileImageUrl!.isEmpty)
                                ? const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 40,
                                  )
                                : null,
                            ),
                          ),
                        ),
                        // Edit button
                        Positioned(
                          right: 0,
                          bottom: 5,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushNamed('/settings');
                            },
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F2B8), // Yellow background color
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF262135), // Dark border matching background
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.edit_outlined, // Outlined icon
                                color: Colors.black,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                      _currentUser?.name ?? 'User',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Menu options
                    _DrawerOption(
                      icon: Icons.settings,
                      label: 'Setting',
                      onTap: () {
                        final currentRoute = ModalRoute.of(context)?.settings.name;
                        if (currentRoute != '/settings') {
                          Navigator.of(context).pushNamed('/settings');
                        }
                        Navigator.of(context).maybePop();
                      },
                    ),
                    _DrawerOption(
                      icon: Icons.calendar_today,
                      label: 'Schedule',
                      onTap: () {
                        final currentRoute = ModalRoute.of(context)?.settings.name;
                        if (currentRoute != AppConstants.scheduleRoute) {
                          Navigator.of(context).pushNamed(AppConstants.scheduleRoute);
                        }
                        Navigator.of(context).maybePop();
                      },
                    ),
                    _DrawerOption(
                      icon: Icons.description,
                      label: 'Report',
                      onTap: () {
                        final currentRoute = ModalRoute.of(context)?.settings.name;
                        if (currentRoute != '/progress-report') {
                          Navigator.of(context).pushNamed('/progress-report');
                        }
                        Navigator.of(context).maybePop();
                      },
                    ),
                    _DrawerOption(
                      icon: Icons.notifications_none,
                      label: 'Notification',
                      onTap: () {
                        final currentRoute = ModalRoute.of(context)?.settings.name;
                        if (currentRoute != '/notifications') {
                          Navigator.of(context).pushNamed('/notifications');
                        }
                        Navigator.of(context).maybePop();
                      },
                    ),
                    const Spacer(),
                    // Logout
                    _DrawerOption(
                      icon: Icons.logout,
                      label: '   Log out',
                      onTap: () async {
                        // Execute logout logic
                        await serviceLocator<AuthService>().logout();
                        
                        // Then navigate to login screen
                        if (mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AppConstants.loginRoute,
                            (route) => false,
                          );
                        }
                      },
                      isLogout: true,
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLogout;

  const _DrawerOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 28),
      title: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: isLogout ? FontWeight.w500 : FontWeight.normal,
          fontFamily: 'Montaga',
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 0),
      horizontalTitleGap: 16,
    );
  }
} 