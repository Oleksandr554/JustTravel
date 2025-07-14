import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart'; 
import '../services/user_profile_service.dart';
import '../models/journey.dart';
import '../models/user_profile.dart';
import '../services/favorites_service.dart';
import '../services/database_helper.dart';
import '../screens/favourite_page.dart';
import '../screens/statistic_page.dart';
import '../screens/profile_screen.dart';
import '../screens/journey_detail_screen.dart';
import '../widgets/navigation_bar_widget.dart';
import '../screens/home_screen.dart';

class GalleryScreen extends StatefulWidget {
  final String username;
  const GalleryScreen({super.key, required this.username});
  

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  int _selectedIndex = 1;
  List<Journey> _allJourneysForGallery = []; 
  bool _isLoading = true; 
  Set<String> _currentUserFavorites = {};
  UserProfile? _profileData;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 1;
    _profileData = userProfileService.currentUserProfile ?? UserProfile.initial(widget.username);
    userProfileService.addListener(_onProfileDataChanged); 
    _loadInitialFavorites();
    favoritesService.addListener(_onFavoritesChanged);
    _loadJourneysForGallery(); 
  }
  
  void _onProfileDataChanged() {
    if (mounted) {
      setState(() {
        _profileData = userProfileService.currentUserProfile ?? UserProfile.initial(widget.username);
      });
    }
  }

  @override
  void dispose() {
    userProfileService.removeListener(_onProfileDataChanged); 
    favoritesService.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  
  Future<void> _loadInitialFavorites() async {
    if (!mounted) return;
    _currentUserFavorites = await favoritesService.getFavoriteJourneyIdsForUser(widget.username);
    if (mounted) setState(() {});
  }

  Future<void> _loadJourneysForGallery() async {
  if (!mounted) return;
  setState(() => _isLoading = true);
  final dbHelper = DatabaseHelper();

  
  final journeysFromDb = await dbHelper.getJourneysForUser(widget.username);

  if (mounted) { 
    setState(() {
      _allJourneysForGallery = journeysFromDb;
      _isLoading = false;
    });
  }
}

  @override
  
  void dispose1s() {
    favoritesService.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  
  void _onFavoritesChanged() {
    _loadInitialFavorites();
  }

  
  void _toggleFavoriteStatus(String journeyId) {
    favoritesService.toggleFavorite(journeyId, widget.username);
  }

  void _onNavIndexChanged(int index) {
    if (_selectedIndex == index) {
      if (index == 1 && mounted) {
         _loadJourneysForGallery();
         _loadInitialFavorites();
      }
      return;
    }

    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }

    Widget nextPage;
    switch (index) {
      case 0:
        nextPage = HomeScreen(username: widget.username);
        break;
      case 1:
        nextPage = GalleryScreen(username: widget.username);
        break;
      case 2:
        nextPage = FavouritePage(username: widget.username);
        break;
      case 3:
        nextPage = StatisticPage(username: widget.username);
        break;
      default:
        nextPage = HomeScreen(username: widget.username);
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextPage,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Gallery",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Pacifico',
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen(username: widget.username)),
    );
  },
  child: CircleAvatar( 
    radius: 34,
    backgroundImage: _profileData?.imagePath != null && _profileData!.imagePath!.isNotEmpty
        ? FileImage(File(_profileData!.imagePath!))
        : const AssetImage("assets/profile1.png") as ImageProvider,
    onBackgroundImageError: _profileData?.imagePath != null && _profileData!.imagePath!.isNotEmpty
        ? (exception, stackTrace) {
            print('Error loading profile image in HomeScreen: ${_profileData!.imagePath} $exception');
            
          }
        : null,
  ),
),
                ],
                
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _allJourneysForGallery.isEmpty
                      ? const Center(
                          child: Text("No journeys in gallery yet.",
                              style: TextStyle(fontSize: 18)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _allJourneysForGallery.length,
                          itemBuilder: (context, index) {
                            final journey = _allJourneysForGallery[index];
                            final String journeyId = journey.stringId;
                            
                            final bool isFav = _currentUserFavorites.contains(journeyId);
                            final String formattedDate =
                                "${DateFormat('dd.MM.yy').format(journey.startDate)} - ${DateFormat('dd.MM.yy').format(journey.endDate)}";

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => JourneyDetailScreen(
                                        
                                        journeyId: journey.id!, 
                                        username: widget.username,
                                      ),
                                    ),
                                  ).then((_) { 
                                    if (mounted) {
                                      _loadInitialFavorites();
                                    }
                                  });
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.file( 
                                        File(journey.mainImagePath),
                                        width: double.infinity,
                                        height: 200,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          height: 200,
                                          color: Colors.grey[300],
                                          child: const Center(
                                              child: Text('Image N/A')),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                journey.city,
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontFamily: 'Inter',
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                journey.country,
                                                style: const TextStyle(
                                                    fontSize: 15,
                                                    fontFamily: 'Inter',
                                                    color: Colors.black54),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                _toggleFavoriteStatus(
                                                    journeyId);
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color:
                                                        Colors.grey.shade300,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Icon(
                                                  isFav
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  size: 22,
                                                  color: isFav
                                                      ? Colors.red
                                                      : Colors.grey.shade600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              formattedDate,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBarWidget(
        selectedIndex: _selectedIndex,
        onIndexChanged: _onNavIndexChanged,
      ),
    );
  }
}