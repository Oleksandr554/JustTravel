import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/favorites_service.dart';
import '../services/user_profile_service.dart';
import 'edit_profile_screen.dart';
import 'splash_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String username;

  const ProfileScreen({super.key, required this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _profile = userProfileService.currentUserProfile ??
        UserProfile.initial(widget.username);
    userProfileService.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    userProfileService.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) {
      setState(() {
        _profile = userProfileService.currentUserProfile ??
            UserProfile.initial(widget.username);
      });
    }
  }

  Future<void> _navigateToEditProfile() async {
    if (_profile == null ||
        userProfileService.currentUserProfile == null ||
        userProfileService.currentLoginIdentifier != widget.username) {
      print(
          "ProfileScreen: _profile is null or mismatched. Attempting to load for ${widget.username}");
      await userProfileService.loadProfileForExistingUser(widget.username);

      if (!mounted) return;

      if (userProfileService.currentUserProfile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile data not available. Please try again.')),
        );
        return;
      }
      setState(() {
        _profile = userProfileService.currentUserProfile;
      });
    }

    if (_profile == null) {
      print(
          "ProfileScreen: _profile is still null after attempting load. Cannot navigate to edit.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Profile data is missing.')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(initialProfile: _profile!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final String displayName = _profile?.username ?? widget.username;
    final String displayEmail = _profile?.email ??
        "${widget.username.toLowerCase().replaceAll(' ', '_')}@example.com";
    final String? displayImagePath = _profile?.imagePath;

    ImageProvider<Object>? avatarImageProvider;
    if (displayImagePath != null && displayImagePath.isNotEmpty) {
      avatarImageProvider = FileImage(File(displayImagePath));
    } else {
      avatarImageProvider = const AssetImage("assets/profile1.png");
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding:
                    EdgeInsets.only(left: 20, top: statusBarHeight > 20 ? 10 : 20),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          )
                        ]),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.black, size: 20),
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
            CircleAvatar(
              radius: 50,
              backgroundImage: avatarImageProvider,
              onBackgroundImageError: (exception, stackTrace) {
                print(
                    'Error loading profile image on ProfileScreen: $displayImagePath $exception');
              },
            ),
            const SizedBox(height: 10),
            Text(
              displayName,
              style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Text(
              displayEmail,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  color: Colors.black54.withOpacity(0.7)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _navigateToEditProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB2D8B6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Edit profile",
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: screenWidth * 0.9 > 410 ? 410 : screenWidth * 0.9,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildProfileOptionRow(
                    icon: Icons.calendar_today_outlined,
                    text: "Joined",
                    trailing: const Text("2022.03.01",
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            color: Colors.grey)),
                    onTap: () {},
                  ),
                  _buildProfileOptionRow(
                    icon: Icons.notifications_none_outlined,
                    text: "Notification",
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (bool value) {
                        if (mounted)
                          setState(() => _notificationsEnabled = value);
                      },
                      activeColor: Colors.green,
                    ),
                    onTap: () {
                      if (mounted)
                        setState(
                            () => _notificationsEnabled = !_notificationsEnabled);
                    },
                  ),
                  _buildProfileOptionRow(
                    icon: Icons.language_outlined,
                    text: "Support",
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 18, color: Colors.grey),
                    onTap: () {},
                  ),
                  _buildProfileOptionRow(
                    icon: Icons.settings_outlined,
                    text: "Settings",
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 18, color: Colors.grey),
                    onTap: () {},
                  ),
                  _buildProfileOptionRow(
                    icon: Icons.logout_outlined,
                    text: "Logout",
                    textColor: const Color(0xFFAD1010),
                    onTap: () async {
                      final String? currentLoginId =
                          userProfileService.currentLoginIdentifier;

                      await userProfileService.clearCurrentProfileData();

                      if (currentLoginId != null) {
                        await favoritesService
                            .clearFavoritesForUser(currentLoginId);
                      }

                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => const SplashScreen()),
                          (Route<dynamic> route) => false,
                        );
                      }
                    },
                    hideDivider: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOptionRow({
    required IconData icon,
    required String text,
    Widget? trailing,
    VoidCallback? onTap,
    Color textColor = Colors.black87,
    bool hideDivider = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: textColor == const Color(0xFFAD1010)
                        ? textColor.withOpacity(0.1)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon,
                      size: 18,
                      color: textColor == const Color(0xFFAD1010)
                          ? textColor
                          : Colors.black54),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        color: textColor,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            if (!hideDivider) const SizedBox(height: 12),
            if (!hideDivider)
              Divider(
                height: 1,
                color: Colors.grey.shade300,
                indent: 45,
                endIndent: 0,
              )
          ],
        ),
      ),
    );
  }
}