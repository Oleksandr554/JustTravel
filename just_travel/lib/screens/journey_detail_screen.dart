import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import 'package:intl/intl.dart'; 
import '../models/journey.dart';
import '../services/favorites_service.dart';
import '../services/database_helper.dart';

class JourneyDetailScreen extends StatefulWidget {
  
  final int journeyId; 
  final String username;

  const JourneyDetailScreen({
    super.key,
    required this.journeyId, 
    required this.username,
  });

  @override
  State<JourneyDetailScreen> createState() => _JourneyDetailScreenState();
}

class _JourneyDetailScreenState extends State<JourneyDetailScreen> {
  Journey? _journey; 
  bool _isLoading = true;
  Map<String, bool> _additionalImageLikes = {};
  bool _isCurrentJourneyFavorite = false; 

  @override
  void initState() {
    super.initState();
    favoritesService.addListener(_onFavoritesChanged);
    _loadJourneyDetails();
  }

  
  Future<void> _loadJourneyDetails() async {
  if (!mounted) return;
  setState(() => _isLoading = true);
  final dbHelper = DatabaseHelper();
  
  final journeyFromDb = await dbHelper.getJourneyById(widget.journeyId, widget.username);
    if (mounted) {
      setState(() {
        _journey = journeyFromDb;
        if (_journey != null) {
          
          favoritesService.isFavorite(_journey!.stringId, widget.username).then((isFav) {
            if (mounted) {
              setState(() {
                _isCurrentJourneyFavorite = isFav;
              });
            }
          });
          _additionalImageLikes = {
            for (var path in _journey!.additionalImagePaths) path: false
          };
        }
        _isLoading = false;
      });
    }
  }


  @override
  void dispose() {
    favoritesService.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  
  void _onFavoritesChanged() {
    if (mounted && _journey != null) {
      favoritesService.isFavorite(_journey!.stringId, widget.username).then((isFav) {
        if (mounted) {
          setState(() {
            _isCurrentJourneyFavorite = isFav;
          });
        }
      });
    }
    if (mounted) setState(() {}); 
  }
  
  void _toggleAdditionalImageLike(String imagePath) {
    if (mounted && _journey != null) {
      setState(() {
        _additionalImageLikes[imagePath] = !(_additionalImageLikes[imagePath] ?? false);
      });
    }
  }

  
  void _toggleMainFavorite() {
    if (_journey != null) {
      favoritesService.toggleFavorite(_journey!.stringId, widget.username);
    }
  }
  

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    const double whitePanelHeight = 596; 
    const double whitePanelWidth = 440;
    final double actualDisplayPanelWidth = min(screenWidth, whitePanelWidth);

    const double imageScaleFactor = 1.2;
    const double imageOffsetY = -200.0;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_journey == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Journey not found.")),
      );
    }

    
    final bool isMainFavorite = _isCurrentJourneyFavorite;
    final String formattedDate =
        "${DateFormat('dd.MM.yy').format(_journey!.startDate)} - ${DateFormat('dd.MM.yy').format(_journey!.endDate)}";

    return Scaffold(
      extendBodyBehindAppBar: true, 
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.center,
                maxWidth: screenWidth * imageScaleFactor * 1.5,
                maxHeight: screenHeight * imageScaleFactor * 1.5,
                child: Transform.translate(
                  offset: Offset(0, imageOffsetY),
                  child: Transform.scale(
                    scale: imageScaleFactor,
                    alignment: Alignment.center,
                    child: Image.file( 
                      File(_journey!.mainImagePath),
                      width: screenWidth,
                      height: screenHeight,
                      fit: BoxFit.cover, 
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey,
                        child: Center(
                            child: Text(
                                'Image not found: ${_journey!.mainImagePath}')),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: statusBarHeight + 10,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.black, size: 20),
              ),
            ),
          ),
          Positioned(
            top: statusBarHeight + 10,
            right: 20,
            child: GestureDetector(
              onTap: _toggleMainFavorite,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                    isMainFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isMainFavorite ? Colors.red : Colors.black,
                    size: 24),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: (screenWidth - actualDisplayPanelWidth) / 2,
            right: (screenWidth - actualDisplayPanelWidth) / 2,
            child: Container(
              width: actualDisplayPanelWidth,
              height: whitePanelHeight, 
              padding: const EdgeInsets.only(
                  top: 30, left: 25, right: 25, bottom: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _journey!.city,
                                style: const TextStyle(
                                  fontFamily: 'Inter-Bold',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 32,
                                ),
                              ),
                              Text(
                                _journey!.country,
                                style: const TextStyle(
                                  fontFamily: 'Inter-bold',
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 45.0),
                          child: Text(
                            formattedDate,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Text( 
                      _journey!.description.isNotEmpty
                          ? _journey!.description
                          : "No description available.",
                      style: const TextStyle(fontSize: 16, fontFamily: 'Inter'),
                      textAlign: TextAlign.justify, 
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Yours memory",
                          style: TextStyle(
                            fontFamily: 'Inter-Bold',
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _journey!.additionalImagePaths.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                            child: Center(
                                child: Text("No additional memories added.",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey))),
                          )
                        : SizedBox(
                            height: 180, 
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _journey!.additionalImagePaths.length,
                              itemBuilder: (context, index) {
                                final imagePath = _journey!.additionalImagePaths[index];
                                final isLiked = _additionalImageLikes[imagePath] ?? false;
                                return Container(
                                  width: 240, 
                                  margin: const EdgeInsets.only(right: 15),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Image.file(
                                          File(imagePath),
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            color: Colors.grey[300],
                                            child: const Center(
                                                child: Icon(Icons.broken_image,
                                                    color: Colors.grey)),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 10,
                                        left: 10,
                                        child: GestureDetector(
                                          onTap: () => _toggleAdditionalImageLike(imagePath),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: const BoxDecoration(
                                              color: Colors.white70, 
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              isLiked ? Icons.favorite : Icons.favorite_border,
                                              color: isLiked ? Colors.red : Colors.black,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                    const SizedBox(height: 20), 
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
