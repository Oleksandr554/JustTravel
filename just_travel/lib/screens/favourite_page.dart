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
import '../screens/statistic_page.dart';
import '../screens/profile_screen.dart';
import '../screens/journey_detail_screen.dart';
import '../widgets/navigation_bar_widget.dart';
import '../screens/home_screen.dart';

class FavouritePage extends StatefulWidget {
  final String username;
  const FavouritePage({super.key, required this.username});

  @override
  State<FavouritePage> createState() => _FavouritePageState();
}

class _FavouritePageState extends State<FavouritePage> {
  int _selectedIndex = 2;
  List<Journey> _favoriteJourneys = []; 
  bool _isLoading = true;
  Timer? _timer;
  int _currentBigImageIndex = 0; 
  UserProfile? _profileData;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 2;
    _profileData = userProfileService.currentUserProfile ?? UserProfile.initial(widget.username);
    userProfileService.addListener(_onProfileDataChanged); 
    favoritesService.addListener(_loadFavoriteJourneys); 
    _loadFavoriteJourneys(); 
  }

   void _onProfileDataChanged() {
    if (mounted) {
      setState(() {
        _profileData = userProfileService.currentUserProfile ?? UserProfile.initial(widget.username);
      });
    }
  }


  Future<void> _loadFavoriteJourneys() async {
  if (!mounted) return;
  setState(() => _isLoading = true); 

  final dbHelper = DatabaseHelper();
  
  
  final List<Journey> userSpecificJourneys = await dbHelper.getJourneysForUser(widget.username);
  
  if (mounted) {
    
    final Set<String> favIds = await favoritesService.getFavoriteJourneyIdsForUser(widget.username);
    
    setState(() {
      
      _favoriteJourneys = userSpecificJourneys.where((journey) => favIds.contains(journey.stringId)).toList();
      _isLoading = false;
      _currentBigImageIndex = 0;
      if (_favoriteJourneys.isNotEmpty) {
        _startImageTimer();
      } else {
        _timer?.cancel();
      }
    });
  }
}
  
  void _startImageTimer() {
    _timer?.cancel(); 
    if (_favoriteJourneys.isNotEmpty) {
      _timer = Timer.periodic(const Duration(seconds: 7), (timer) {
        if (mounted && _favoriteJourneys.isNotEmpty) {
          setState(() {
            _currentBigImageIndex = (_currentBigImageIndex + 1) % _favoriteJourneys.length;
          });
        } else {
          timer.cancel(); 
        }
      });
    }
  }


  @override
  void dispose() {
    userProfileService.removeListener(_onProfileDataChanged); 
    favoritesService.removeListener(_loadFavoriteJourneys);
    _timer?.cancel();
    super.dispose();
  }

  void _onNavIndexChanged(int index) {
    if (_selectedIndex == index) {
      if (index == 2 && mounted) { 
          _loadFavoriteJourneys(); 
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
                        "Favorite",
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
                        MaterialPageRoute(
                            builder: (context) =>
                                ProfileScreen(username: widget.username)),
                      );
                    },
                    child: CircleAvatar( 
              radius: 34,
              backgroundImage: _profileData?.imagePath != null && _profileData!.imagePath!.isNotEmpty
                  ? FileImage(File(_profileData!.imagePath!))
                  : const AssetImage("assets/profile1.png") as ImageProvider,
              onBackgroundImageError: _profileData?.imagePath != null && _profileData!.imagePath!.isNotEmpty
                  ? (exception, stackTrace) {
                      print('Error loading profile image in GalleryScreen: ${_profileData!.imagePath} $exception');
                    }
                  : null,
            ),
                  ),
                ],
              ),
            ),
            _isLoading
                ? const Expanded(child: Center(child: CircularProgressIndicator()))
                : _favoriteJourneys.isEmpty
                    ? Expanded(
                        child: Center(
                          child: Container( 
                            width: 410,
                            height: 388,
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.grey[200], 
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                )
                              ],
                            ),
                            child: const Center(
                                child: Text(
                              "No favorite journeys yet.",
                              style: TextStyle(fontSize: 18, color: Colors.black54),
                            )),
                          ),
                        ),
                      )
                    : GestureDetector( 
                        onTap: () {
                           if (_favoriteJourneys.isNotEmpty) {
                             final journey = _favoriteJourneys[_currentBigImageIndex];
                             final String formattedDate = "${DateFormat('dd.MM.yy').format(journey.startDate)} - ${DateFormat('dd.MM.yy').format(journey.endDate)}";
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
                                  _loadFavoriteJourneys(); 
                                }
                              });
                           }
                        },
                        child: Container(
                          width: 410,
                          height: 388,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            image: DecorationImage(
                              image: FileImage(File(_favoriteJourneys[_currentBigImageIndex].mainImagePath)),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {
                                 print('Error loading big favorite image: ${_favoriteJourneys[_currentBigImageIndex].mainImagePath} $exception');
                              }
                            ),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 4))
                            ],
                          ),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column( 
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _favoriteJourneys[_currentBigImageIndex].city,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      shadows: [Shadow(blurRadius: 2.0, color: Colors.black87)]
                                    ),
                                  ),
                                  Text(
                                    _favoriteJourneys[_currentBigImageIndex].country,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                       shadows: [Shadow(blurRadius: 2.0, color: Colors.black87)]
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  
                                  GestureDetector(
                                    onTap: () {
                                      if (_favoriteJourneys.isNotEmpty) {
                                        favoritesService.toggleFavorite(
                                          _favoriteJourneys[_currentBigImageIndex].stringId,
                                          widget.username
                                        );
                                        
                                      }
                                    },
                                    child: const Icon(Icons.favorite, color: Colors.white, size: 30)
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const SizedBox.shrink() 
                  : _favoriteJourneys.isEmpty
                      ? const Center(child: Text("")) 
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4, 
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1, 
                            ),
                            itemCount: _favoriteJourneys.length,
                            itemBuilder: (context, index) {
                              final journey = _favoriteJourneys[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          JourneyDetailScreen(
                                        journeyId: journey.id!,
                                        username: widget.username,
                                      ),
                                    ),
                                  ).then((_){
                                     if (mounted) {
                                      _loadFavoriteJourneys();
                                    }
                                  });
                                },
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.file(
                                        File(journey.mainImagePath),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => 
                                          Container(color: Colors.grey[300], child: Icon(Icons.image_not_supported, color: Colors.grey[500])),
                                      ),
                                    ),
                                    const Positioned(
                                      bottom: 6,
                                      left: 6,
                                      child: Icon(Icons.favorite,
                                          color: Colors.white70, size: 16),
                                    ),
                                    Positioned(
                                      top: 6,
                                      left: 6,
                                      right: 6,
                                      child: Text(
                                        journey.city,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          shadows: [Shadow(blurRadius: 1.0, color: Colors.black)]
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
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