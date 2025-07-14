import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io'; 
import 'package:intl/intl.dart'; 
import '../services/user_profile_service.dart';
import '../models/journey.dart';
import '../models/user_profile.dart';
import '../services/favorites_service.dart';
import '../services/database_helper.dart';
import '../screens/gallery_screen.dart';
import '../screens/favourite_page.dart';
import '../screens/statistic_page.dart';
import '../screens/profile_screen.dart';
import '../screens/add_journey_screen.dart';
import '../screens/journey_detail_screen.dart';
import '../widgets/navigation_bar_widget.dart';
class HomeScreen extends StatefulWidget {
  final String username; 

  const HomeScreen({super.key, required this.username}); 

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _selectedChipIndex = 0;
  UserProfile? _profileData;

  List<Journey> _allJourneys = [];
  bool _isLoading = true;
  Set<String> _currentUserFavorites = {};

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;

    _profileData = userProfileService.currentUserProfile ?? UserProfile.initial(widget.username);
    userProfileService.addListener(_onProfileDataChanged);

    
    favoritesService.addListener(_onFavoritesChanged);

    _loadJourneys();
    _loadInitialFavorites();
  }

  @override
  void dispose() {
    userProfileService.removeListener(_onProfileDataChanged);
    
    favoritesService.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onProfileDataChanged() {
    if (mounted) {
    
      setState(() {
        _profileData = userProfileService.currentUserProfile ?? UserProfile.initial(widget.username);
      });
      
    }
  }

  Future<void> _loadJourneys() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final dbHelper = DatabaseHelper();
   
    final journeysFromDb = await dbHelper.getJourneysForUser(widget.username);
    if (mounted) {
      setState(() {
        _allJourneys = journeysFromDb;
        _isLoading = false;
      });
    }
  }

  
  void _onFavoritesChanged() {
    _loadInitialFavorites(); 
  }

  Future<void> _loadInitialFavorites() async {
    if (!mounted) return;
    
    _currentUserFavorites = await favoritesService.getFavoriteJourneyIdsForUser(widget.username);
    if (mounted) {
      setState(() {}); 
    }
  }

  void _toggleFavoriteStatus(String journeyId) {
   
    favoritesService.toggleFavorite(journeyId, widget.username);
   
   
  }

  void _onNavIndexChanged(int index) {
    if (_selectedIndex == index && index != 0) return;

  
    final String currentUserLoginId = widget.username;

    if (_selectedIndex != index) {
       if (mounted) {
        setState(() {
          _selectedIndex = index;
        });
      }
    }

    Widget nextPage;
    switch (index) {
      case 0:
        nextPage = HomeScreen(username: currentUserLoginId);
        break;
      case 1:
        nextPage = GalleryScreen(username: currentUserLoginId);
        break;
      case 2:
        nextPage = FavouritePage(username: currentUserLoginId);
        break;
      case 3:
        nextPage = StatisticPage(username: currentUserLoginId);
        break;
      default:
        nextPage = HomeScreen(username: currentUserLoginId);
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello, ${_profileData?.username ?? widget.username}",
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Pacifico',
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Welcome to JustTravel",
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Inter',
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
            ElevatedButton(
              onPressed: () async {
                
                final String currentUserId = widget.username;
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddJourneyScreen(currentUserId: currentUserId)),
                );
                if (result == true && mounted) {
                  _loadJourneys();
                  _loadInitialFavorites();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA8D5BA),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 110, vertical: 12),
                child: Text(
                  "+ Add journey",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'inter',
                      fontSize: 20),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    "Journeys",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: List.generate(4, (idx) {
                  final labels = ["Ongoing", "Past", "Draft", "Upcoming"];
                  return GestureDetector(
                    onTap: () {
                      if (mounted) setState(() => _selectedChipIndex = idx);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedChipIndex == idx
                            ? const Color(0xFFA8D5BA)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        labels[idx],
                        style: TextStyle(
                          color: _selectedChipIndex == idx ? Colors.white : Colors.black,
                          fontSize: 16,
                          fontFamily: 'Inter-bold',
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 44),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final List<List<Journey>> journeysByCategory = [
                        _allJourneys.where((j) => j.status == 'Ongoing').toList(),
                        _allJourneys.where((j) => j.status == 'Past').toList(),
                        _allJourneys.where((j) => j.status == 'Draft').toList(),
                        _allJourneys.where((j) => j.status == 'Upcoming').toList(),
                      ];

                      final journeys = journeysByCategory[_selectedChipIndex];

                      if (journeys.isEmpty) {
                        return const Center(
                          child: Text(
                            "No journeys available for this category.",
                            style: TextStyle(fontSize: 18),
                          ),
                        );
                      }

                      return PageView.builder(
                        controller: PageController(viewportFraction: constraints.maxWidth > 400 ? 0.8 : 0.9),
                        itemCount: journeys.length,
                        itemBuilder: (context, pageViewIndex) {
                          final journey = journeys[pageViewIndex];
                          final String journeyId = journey.stringId;
                          final bool isFav = _currentUserFavorites.contains(journeyId);
                          final String formattedDate =
                            "${DateFormat('dd.MM.yy').format(journey.startDate)} - ${DateFormat('dd.MM.yy').format(journey.endDate)}";

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: FileImage(File(journey.mainImagePath)),
                                  fit: BoxFit.cover,
                                  onError: (exception, stackTrace) {
                                     print('Error loading image: ${journey.mainImagePath} $exception');
                                  },
                                ),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0,4))],
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 15,
                                    right: 15,
                                    bottom: 75,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                journey.country,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  shadows: [Shadow(blurRadius: 2.0, color: Colors.black54)]
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                journey.city,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  shadows: [Shadow(blurRadius: 2.0, color: Colors.black54)]
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          formattedDate,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'inter',
                                            fontSize: 16,
                                            shadows: [Shadow(blurRadius: 2.0, color: Colors.black54)]
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    left: 15,
                                    right: 15,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.all(Radius.circular(30)),
                                      child: Material(
                                        color: Colors.white54,
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => JourneyDetailScreen(
                                                  journeyId: journey.id!,
                                                  username: widget.username,
                                                ),
                                              ),
                                            ).then((_){
                                              if(mounted) {
                                                _loadInitialFavorites();
                                              }
                                            });
                                          },
                                          child: SizedBox(
                                            height: 60,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Padding(
                                                  padding: EdgeInsets.only(left: 100),
                                                  child: Text(
                                                    "See more",
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontFamily: 'Inter-Bold',
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.only(right: 7),
                                                  child: CircleAvatar(
                                                    radius: 25,
                                                    backgroundColor: Colors.white,
                                                    child: const Icon(Icons.arrow_forward,
                                                        size: 25, color: Colors.black),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 20,
                                    child: GestureDetector(
                                      onTap: () {
                                        _toggleFavoriteStatus(journeyId);
                                      },
                                      child: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.white54,
                                        child: Icon(
                                          isFav ? Icons.favorite : Icons.favorite_border,
                                          color: isFav ? Colors.red : Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
