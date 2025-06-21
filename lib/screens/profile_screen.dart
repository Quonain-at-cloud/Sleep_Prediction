import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/app_constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/stat_card.dart';
import '../widgets/custom_bottom_navigation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Stats for display
  int _totalSleepEntries = 0;
  double _avgSleepDuration = 0;
  double _avgSleepQuality = 0;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final user = await _authService.getCurrentUserModel();
      final stats = await _authService.getUserStats();
      
      setState(() {
        _user = user;
        
        // Set stats if available
        if (stats != null) {
          _totalSleepEntries = stats['totalEntries'] ?? 0;
          _avgSleepDuration = stats['avgSleepDuration'] ?? 0;
          _avgSleepQuality = stats['avgSleepQuality'] ?? 0;
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load user data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _editProfile() async {
    // Navigate to edit profile screen and refresh data if returned with success
    final result = await Navigator.of(context).pushNamed(AppConstants.editProfileRoute);
    if (result == true) {
      _loadUserData();
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppConstants.loginRoute);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to logout: ${e.toString()}';
      });
    }
  }

  Widget _buildMenuItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D2041),
      body: SafeArea(
        child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadUserData,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: const Color(0xFF2D2041),
                        backgroundColor: Colors.white,
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  const SizedBox(height: 40),
                  // Profile Image and Name
                  Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: _user?.profileImageUrl != null && _user!.profileImageUrl!.isNotEmpty
                            ? Image.network(
                                _user!.profileImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              )
                            : Image.asset(
                                'assets/images/profile.png',
                                fit: BoxFit.cover,
                              ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _user?.name ?? 'User',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Menu Items
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          title: 'Settings',
                          icon: Icons.settings_outlined,
                          onTap: () {
                            Navigator.pushNamed(context, AppConstants.settingsRoute);
                          },
                        ),
                        _buildMenuItem(
                          title: 'Schedule',
                          icon: Icons.calendar_today_outlined,
                          onTap: () {
                            // Navigate to schedule
                          },
                        ),
                        _buildMenuItem(
                          title: 'Report',
                          icon: Icons.description_outlined,
                          onTap: () {
                            // Navigate to report
                          },
                        ),
                        _buildMenuItem(
                          title: 'Notification',
                          icon: Icons.notifications_outlined,
                          onTap: () {
                            // Navigate to notifications
                          },
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Logout Button
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildMenuItem(
                      title: 'Log out',
                      icon: Icons.logout,
                      onTap: _logout,
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: const CustomBottomNavigation(
        currentIndex: 2,
        onTap: null,
      ),
    );
  }

  Widget _buildProfileHeader() {
    final user = _user;
    if (user == null) return const SizedBox.shrink();
    
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: AppConstants.primaryColor.withOpacity(0.2),
          backgroundImage: _user?.profileImageUrl != null && _user!.profileImageUrl!.isNotEmpty
              ? NetworkImage(_user!.profileImageUrl!)
              : null,
          child: _user?.profileImageUrl == null || _user!.profileImageUrl!.isEmpty
              ? Icon(
                  Icons.person,
                  size: 80,
                  color: AppConstants.primaryColor,
                )
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          _user?.name ?? 'User',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _user?.email ?? '',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: 'Edit Profile',
          onPressed: _editProfile,
          isFullWidth: false,
          color: AppConstants.secondaryColor,
        ),
      ],
    );
  }

  Widget _buildStatsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sleep Statistics',
          style: AppConstants.headingStyle,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Entries',
                value: _totalSleepEntries.toString(),
                icon: Icons.list_alt,
                iconColor: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'Avg. Sleep',
                value: _formatDuration(_avgSleepDuration),
                icon: Icons.nightlight_round,
                iconColor: Colors.indigo,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'Avg. Quality',
                value: _avgSleepQuality.toStringAsFixed(1),
                icon: Icons.star,
                iconColor: Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account',
          style: AppConstants.headingStyle,
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Change Password'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).pushNamed(AppConstants.changePasswordRoute),
        ),
        ListTile(
          leading: const Icon(Icons.notifications_active_outlined),
          title: const Text('Notification Preferences'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).pushNamed(AppConstants.notificationPreferencesRoute),
        ),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: const Text('Export Sleep Data'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).pushNamed(AppConstants.exportDataRoute),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy Settings'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).pushNamed(AppConstants.privacySettingsRoute),
        ),
      ],
    );
  }

  String _formatDuration(double hours) {
    final int hrs = hours.floor();
    final int mins = ((hours - hrs) * 60).round();
    
    if (hrs > 0) {
      return '$hrs hr $mins min';
    } else {
      return '$mins min';
    }
  }
} 