import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import '../services/user_profile_service.dart';
import '../models/journey.dart';
import '../models/user_profile.dart';
import '../services/database_helper.dart';
import '../screens/gallery_screen.dart';
import '../screens/favourite_page.dart';
import '../screens/profile_screen.dart';
import '../screens/home_screen.dart';
import '../widgets/navigation_bar_widget.dart';
import '../widgets/pie_chart_painter.dart';

class StatisticPage extends StatefulWidget {
  final String username;
  const StatisticPage({super.key, required this.username});

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  int _selectedIndex = 3;
  
  List<Journey> _allJourneysForStats = [];
  bool _isLoadingStats = true;

  Map<String, int> _calculatedTripStatusData = {};
  List<Map<String, dynamic>> _calculatedMostVisitedCountries = [];
  List<Map<String, dynamic>> _calculatedActivityPerYear = [];
  UserProfile? _profileData;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 3;
    _profileData = userProfileService.currentUserProfile ?? UserProfile.initial(widget.username);
    userProfileService.addListener(_onProfileDataChanged);
    _loadJourneysForStats();
  }

  void _onProfileDataChanged() {
    if (mounted) {
      setState(() {
        _profileData = userProfileService.currentUserProfile ?? UserProfile.initial(widget.username);
      });
    }
  }

  Future<void> _loadJourneysForStats() async {
  if (!mounted) return;
  setState(() => _isLoadingStats = true);
  final dbHelper = DatabaseHelper();

  
  _allJourneysForStats = await dbHelper.getJourneysForUser(widget.username);
  _calculateStatistics(); 
  
  if (mounted) { 
    setState(() => _isLoadingStats = false);
  }
}

  void _calculateStatistics() {
    _calculatedTripStatusData = {
      'Ongoing': 0, 'Draft': 0, 'Past': 0, 'Upcoming': 0,
    };
    for (var journey in _allJourneysForStats) {
      final status = journey.status;
      if (_calculatedTripStatusData.containsKey(status)) {
        _calculatedTripStatusData[status] = _calculatedTripStatusData[status]! + 1;
      }
    }

    Map<String, int> countryVisits = {};
    for (var journey in _allJourneysForStats) {
      final country = journey.country;
      countryVisits[country] = (countryVisits[country] ?? 0) + 1;
    }
    var sortedCountries = countryVisits.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final List<Color> countryColors = [ 
      Colors.red.shade400, Colors.blue.shade400, Colors.green.shade400, 
      Colors.orange.shade400, Colors.purple.shade400, Colors.teal.shade400
    ];
    _calculatedMostVisitedCountries = sortedCountries.take(5).map((entry) {
      return {'name': entry.key, 'visits': entry.value, 'color': countryColors[(_calculatedMostVisitedCountries.length % countryColors.length)]};
    }).toList();


    Map<int, int> activityCountPerYear = {};
    for (var journey in _allJourneysForStats) {
      final year = journey.startDate.year;
      activityCountPerYear[year] = (activityCountPerYear[year] ?? 0) + 1;
    }
    final yearColors = [
      const Color(0xFFCDB4DB), const Color(0xFF3E4A53), const Color(0xFF80D8EA),
      const Color(0xFFFFB74D), const Color(0xFFE57373),
    ];
    int colorIndex = 0;
    _calculatedActivityPerYear = activityCountPerYear.entries
      .map((entry) {
        final color = yearColors[colorIndex % yearColors.length];
        colorIndex++;
        return {'year': entry.key, 'activity': entry.value.toDouble(), 'color': color};
      })
      .toList()
      ..sort((a, b) => (a['year'] as int).compareTo(b['year'] as int));
  }

  void _onNavIndexChanged(int index) {
     if (_selectedIndex == index) {
      if (index == 3 && mounted) { 
          _loadJourneysForStats(); 
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
    final screenWidth = MediaQuery.of(context).size.width;
    final totalJourneys = _calculatedTripStatusData.values.fold(0, (sum, item) => sum + item);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: SafeArea(
        child: _isLoadingStats
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Statistic",
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
                      print('Error loading profile image in GalleryScreen: ${_profileData!.imagePath} $exception');
                    }
                  : null,
            ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildStatisticCard(
                width: screenWidth - 40,
                height: 219,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 20.0, top: 18.0, bottom: 10.0),
                      child: Text(
                        "All your trips",
                        style: TextStyle(fontFamily: 'Inter-bold', fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Padding(
                              padding: const EdgeInsets.all(1),
                              child: CustomPaint(
                                painter: PieChartPainter(data: _calculatedTripStatusData),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        totalJourneys.toString(),
                                        style: const TextStyle(fontFamily: 'Inter', fontSize: 36, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        "Journeys",
                                        style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 15.0, top:10, bottom:10, left: 5),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _calculatedTripStatusData.entries.map((entry) {
                                  return _buildLegendItem(
                                      _getColorForStatus(entry.key), entry.key, entry.value);
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildStatisticCard(
                width: screenWidth - 40,
                height: 180, 
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Most visited country",
                        style: TextStyle(fontFamily: 'Inter-Bold', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _calculatedMostVisitedCountries.isEmpty
                          ? const Center(child: Text("No country data available."))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: _calculatedMostVisitedCountries.map((countryData) {
                                final maxVisits = _calculatedMostVisitedCountries.map<int>((c) => c['visits']).fold(0, (prev, curr) => curr > prev ? curr : prev);
                                return _buildCountryVisitBar(
                                  countryData['name'],
                                  countryData['visits'],
                                  maxVisits == 0 ? 0.0 : (countryData['visits'] / maxVisits),
                                  countryData['color'],
                                );
                              }).toList(),
                            ),
                      ),
                    ],
                  ),
                )
              ),
              const SizedBox(height: 20),
              _buildStatisticCard(
                width: screenWidth - 40,
                height: 220,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Activity per year",
                        style: TextStyle(fontFamily: 'Inter-Bold', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 15),
                      Expanded(
                        child: _calculatedActivityPerYear.isEmpty
                         ? const Center(child: Text("No activity data available."))
                         : LayoutBuilder(
                            builder: (context, constraints) {
                              final double availableHeightForBars = constraints.maxHeight - 30; 
                              final maxActivity = _calculatedActivityPerYear.map<double>((y) => y['activity']).fold(0.0, (prev, curr) => curr > prev ? curr : prev);
                              
                              final int numberOfBars = _calculatedActivityPerYear.length;
                              final double totalHorizontalPaddingInCard = 40; 
                              final double spacingBetweenBars = 15.0;
                              final double chartContainerWidth = screenWidth - 40 - totalHorizontalPaddingInCard; 
                              final double totalSpacing = (numberOfBars - 1) * spacingBetweenBars;
                              double barWidth = (chartContainerWidth - totalSpacing) / max(1, numberOfBars); 
                              barWidth = max(10, barWidth * 0.8); 

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: _calculatedActivityPerYear.map((yearData) {
                                  return _buildActivityBar(
                                    context,
                                    yearData['year'].toString(),
                                    yearData['activity'],
                                    maxActivity,
                                    yearData['color'],
                                    availableHeightForBars,
                                    barWidth
                                  );
                                }).toList(),
                              );
                            }
                          ),
                      ),
                    ],
                  ),
                )
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBarWidget(
        selectedIndex: _selectedIndex,
        onIndexChanged: _onNavIndexChanged,
      ),
    );
  }

  Widget _buildStatisticCard({required double width, required double height, required Widget child}) {
    return Container(
      width: width,
      height: height,
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
        ],
      ),
      child: child,
    );
  }

  Widget _buildLegendItem(Color color, String label, int value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(2)
              ),
            ),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.black54)),
          ],
        ),
        Text(
          value.toString(),
          style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)
        ),
      ],
    );
  }

   Color _getColorForStatus(String status) {
    switch (status) {
      case 'Ongoing': return const Color(0xFFE53935); 
      case 'Draft': return const Color(0xFF7CB342);   
      case 'Past': return const Color(0xFF1E88E5);    
      case 'Upcoming': return const Color(0xFFFFB300); 
      default: return Colors.grey;
    }
  }

 Widget _buildCountryVisitBar(String country, int visits, double progress, Color barColor) {
    return Row(
      children: [
        SizedBox(
          width: 65, 
          child: Text(
            country,
            style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.grey[600]), 
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 6, 
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              if (progress > 0) 
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: barColor, 
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 25, 
          child: Text(
            visits.toString(),
            textAlign: TextAlign.right,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ),
      ],
    );
  }

 Widget _buildActivityBar(BuildContext context, String year, double activity, double maxActivity, Color color, double availableHeight, double barWidth) {
    final barHeightPercentage = maxActivity == 0 ? 0.0 : (activity / maxActivity);
    final barHeight = barHeightPercentage * (availableHeight * 0.9);

    return Column(
      mainAxisSize: MainAxisSize.min, 
      mainAxisAlignment: MainAxisAlignment.end, 
      children: [
        Container(
          width: barWidth, 
          height: barHeight.isFinite && barHeight > 5 ? barHeight : 5.0, 
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          year,
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.grey[600]),
        ),
      ],
    );
  }
}