import 'package:cropai/LanguageSelectionScreen.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Activity_Monitoring.dart';
import 'Activitypage.dart';
import 'AreaLevelingScreen.dart';
import 'CropProtection.dart';
import 'Fertilizer_Soil_Treatment.dart';
import 'Harvesting_Updates.dart';
import 'Hay_Making.dart';
import 'InterCulture.dart';
import 'Land_Preperation.dart';
import 'NotificationPage.dart';
import 'NotificationService.dart';
import 'Post_Irrigation.dart';
import 'Pre_Irrigation.dart';
import 'Pre_Land_Preperation.dart';
import 'Silage_Making.dart';
import 'Sowing.dart';
import 'Loinpage/login_screen.dart';
import 'weather_model.dart';
import 'weather_service.dart';
import 'package:badges/badges.dart' as badges;
import 'dart:math' as math;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Weather data
  WeatherData? _weatherData;
  bool _isLoading = true;
  String _errorMessage = '';

  

  // Location coordinates for Lucknow
  final double _latitude = 26.8682246;
  final double _longitude = 80.9933125;

String? userName;
String? userEmail;


Future<void> _loadUserData() async{
  SharedPreferences prefs = await SharedPreferences.getInstance();

setState(() {
  userName = prefs.getString('user_name')?? 'Unknown User';
  userEmail = prefs.getString('user_email')?? 'No Email';
});

}


  // Weather service
  final WeatherService _weatherService = WeatherService();

  // Sun position control (0.0 to 1.0, where 0.5 is noon)
  double _sunPosition = 0.5;
  double _actualSunPosition = 0.5; // Real sun position based on time
  bool _isUserInteracting = false; // Track user interaction


  int notificationCount = 0;
  bool isLoadingNotifications = true;

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
    _calculateCurrentSunPosition();
_loadUserData();
    _loadNotificationCount(); // Add this line
  }


  Future<void> _loadNotificationCount() async {
    try {
      final count = await NotificationService.getUnreadNotificationCount();
      setState(() {
        notificationCount = count;
        isLoadingNotifications = false;
      });
    } catch (e) {
      setState(() {
        notificationCount = 0;
        isLoadingNotifications = false;
      });
    }
  }





  void _calculateCurrentSunPosition() {
    final now = DateTime.now();
    final currentHour = now.hour + (now.minute / 60.0);

    // Assuming sunrise at 6 AM and sunset at 6 PM (12 hours of daylight)
    const sunriseHour = 6.0;
    const sunsetHour = 18.0;
    const dayDuration = sunsetHour - sunriseHour;

    double calculatedPosition;
    if (currentHour >= sunriseHour && currentHour <= sunsetHour) {
      calculatedPosition = (currentHour - sunriseHour) / dayDuration;
    } else if (currentHour < sunriseHour) {
      calculatedPosition = 0.0; // Before sunrise
    } else {
      calculatedPosition = 1.0; // After sunset
    }

    // Clamp between 0 and 1
    _actualSunPosition = calculatedPosition.clamp(0.0, 1.0);

    // Only update display position if user is not interacting
    if (!_isUserInteracting) {
      setState(() {
        _sunPosition = _actualSunPosition;
      });
    }
  }

  Future<void> _fetchWeatherData() async {
    try {
      final weatherData = await _weatherService.getWeatherData(_latitude, _longitude);
      setState(() {
        _weatherData = weatherData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Get weather icon based on condition
  IconData _getWeatherIcon(String condition) {
    condition = condition.toLowerCase();
    if (condition.contains('rain') || condition.contains('drizzle')) {
      return Icons.grain;
    } else if (condition.contains('cloud')) {
      return Icons.cloud;
    } else if (condition.contains('snow')) {
      return Icons.ac_unit;
    } else if (condition.contains('thunder') || condition.contains('storm')) {
      return Icons.flash_on;
    } else if (condition.contains('fog') || condition.contains('mist')) {
      return Icons.cloud_queue;
    } else {
      return Icons.wb_sunny;
    }
  }

  // Get time string based on sun position
  String _getTimeFromSunPosition(double position) {
    const sunriseHour = 6.0;
    const sunsetHour = 18.0;
    const dayDuration = sunsetHour - sunriseHour;

    final currentHour = sunriseHour + (position * dayDuration);
    final hour = currentHour.floor();
    final minute = ((currentHour - hour) * 60).round();

    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final period = hour >= 12 ? 'PM' : 'AM';

    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  // Handle user interaction with sun
  void _onSunInteractionStart() {
    setState(() {
      _isUserInteracting = true;
    });
  }

  void _onSunInteractionEnd() {
    setState(() {
      _isUserInteracting = false;
    });

    // Return to actual position after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (!_isUserInteracting) {
        setState(() {
          _sunPosition = _actualSunPosition;
        });
      }
    });
  }

  void _onSunPositionChanged(double position) {
    if (_isUserInteracting) {
      setState(() {
        _sunPosition = position;
      });
    }
  }

  String _getNotificationCountText() {
    if (notificationCount > 99) {
      return '99+';
    }
    return notificationCount.toString();
  }

  // Card data model for cleaner implementation
  final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': 'assets/images/land_area_level.png',
      'label': 'area_leveling',
      'color': Colors.deepOrange.shade100,
      'onTap': null,
      'screen': const Arealevelingscreen(),
    },
    {
      'icon': 'assets/images/pre_landed.png',
      'label': 'pre_land_preparation',
      'color': Colors.red.shade100,
      'onTap': null,
      'screen': const Pre_Land_Preperation(),
    },
    {
      'icon': 'assets/images/pre_irrigationed.png',
      'label': 'pre_irrigation',
      'color': Colors.blue.shade100,
      'onTap': null,
      'screen': const Pre_Irrigation(),
    },
    {
      'icon': 'assets/images/landed_preparationed.png',
      'label': 'land_preparation',
      'color': Colors.green.shade100,
      'onTap': null,
      'screen': const Land_Preperation(),
    },
    {
      'icon': 'assets/images/sowing_imaged.png',
      'label': 'sowing',
      'color': Colors.purple.shade100,
      'onTap': null,
      'screen': const Sowing(),
    },
    {
      'icon': 'assets/images/posted.png',
      'label': 'post_irrigation',
      'color': Colors.orange.shade100,
      'onTap': null,
      'screen': const PostIrrigation(),
    },
    {
      'icon': 'assets/images/fertilizered.png',
      'label': 'fertilizer',
      'color': Colors.teal.shade100,
      'onTap': null,
      'screen': const FertilizerSoilTreatment(),
    },
    {
      'icon': 'assets/images/protectioned_crop.png',
      'label': 'crop_protection',
      'color': Colors.pink.shade100,
      'onTap': null,
      'screen': const Cropprotection(),
    },
    {
      'icon': 'assets/images/monitored.png',
      'label': 'activity_monitoring',
      'color': Colors.amber.shade100,
      'onTap': null,
      'screen': const Activity_Monitoring(),
    },
    {
      'icon': 'assets/images/cultured.png',
      'label': 'inter_culture',
      'color': Colors.indigo.shade100,
      'onTap': null,
      'screen': const Interculture(),
    },
    {
      'icon': 'assets/images/havested.png',
      'label': 'harvest',
      'color': Colors.cyan.shade100,
      'onTap': null,
      'screen': const Harvesting_Updates(),
    },
    {
      'icon': 'assets/images/making_hayed.png',
      'label': 'hay_making',
      'color': Colors.lime.shade100,
      'onTap': null,
      'screen': const Hay_Making(),
    },
    {
      'icon': 'assets/images/hayed.png',
      'label': 'silage_making',
      'color': Colors.lightGreen.shade100,
      'onTap': null,
      'screen': const Silage_Making(),
    },
    //  {
    //   'icon': 'assets/images/reviewpage.png',
    //   'label': 'Agriculture Form Review',
    //   'color': Colors.red.shade100,
    //   'onTap': null,
    //   'screen': const AgricultureSummaryPage(),
    // },
  ];


  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    for (int i = 0; i < _menuItems.length; i++) {
      final item = _menuItems[i];
      _menuItems[i]['onTap'] = () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => item['screen']),
        );
      };
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: screenSize.height,
              width: screenSize.width,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6B8E23),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 30),
                        Row(
                          children: [
                            Text(
                              'Dashboard'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(
                              height: 30,
                              child: Chip(
                                backgroundColor: Colors.white,
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'CROP-AI',
                                      style: TextStyle(
                                        color: Color(0xFF6B8E23),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                              ),
                            ),
                            const Spacer(),
GestureDetector(
  onTap: (){
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => 
            const LanguageSelectionScreen()),
          );
  },
  child: CircleAvatar(
    radius: 15,
    backgroundColor: Colors.white,
  child: Icon(Icons.language ,color: Color(0xFF6B8E23),),
  ),
),

SizedBox(width: 10,),
                            GestureDetector(
                              onTap: () async {
                                // Navigate to notification page
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const NotificationPage(),
                                  ),
                                );
                                // Refresh notification count when coming back
                                _loadNotificationCount();
                              },
                              child: badges.Badge(
                                badgeContent: Text(
                                  _getNotificationCountText(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                showBadge: notificationCount > 0 && !isLoadingNotifications,
                                badgeStyle: const badges.BadgeStyle(
                                  badgeColor: Colors.red,
                                  padding: EdgeInsets.all(4),
                                ),
                                child: const CircleAvatar(
                                  backgroundColor: Colors.white,
                                  radius: 15,
                                  child: Icon(
                                    Icons.notifications,
                                    color: Color(0xFF6B8E23),
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 15, // Slightly bigger for better spacing
                              child: IconButton(
                                onPressed: () {
                                 _DisplayBottomsheet(context);
                                },
                                icon: const Icon(
                                  Icons.person,
                                  color: Color(0xFF6B8E23),
                                ),
                                iconSize: 20,
                                padding: EdgeInsets.zero, // Remove extra padding
                                alignment: Alignment.center, // Center the icon
                              ),
                            ),

                          ],
                        ),
                        const SizedBox(height: 45),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                    child: Transform.translate(
                      offset: const Offset(0, -30),
                      child: _buildWeatherCard(),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                      child: _buildGridCards(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

    );
  }

Future _DisplayBottomsheet(BuildContext context){
  return showModalBottomSheet(context: context, builder:(context)=>
  Container(
height: 240,
 width: double.infinity,
decoration: BoxDecoration(
  borderRadius: BorderRadius.only(topLeft: Radius.circular(12),topRight: Radius.circular(12)),
),

child: Column(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    SizedBox(
  height: 20,
 
),
    CircleAvatar(
      radius: 40,
      backgroundColor: Colors.grey.shade100,
      child: Icon(Icons.person,color: Colors.black,size: 30,),
    ),
Text('$userName'),
Text('$userEmail'),

SizedBox(
  height: 20,
 
),

ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
  ),
  onPressed: (){
  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text(
                                          'Confirm Logout',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                        ),
                                        content: const Text(
                                          'Are you sure you want to logout?',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        backgroundColor: Colors.white,
                                        actions: [
                                          TextButton(
                                            onPressed: () async {
                                              final prefs = await SharedPreferences.getInstance();
                                              await prefs.remove('auth_token');
                                              print('renovedToken: ${prefs.getString('auth_token')}');

                                              // Navigate to LoginScreen and remove all previous routes
                                              Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                                                    (route) => false,
                                              );
                                            },
                                            child: const Text(
                                              'Yes',
                                              style: TextStyle(color: Colors.green),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context); // Just close the dialog
                                            },
                                            child: const Text(
                                              'No',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          ),

                                        ],
                                      );
                                    },
                                  );

  }, child: Text('Logout',style: TextStyle(color: Colors.white),))


  ],
),
  )
  
   );
}

//

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }


  Widget _buildWeatherCard() {
    if (_isLoading) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: CircularProgressIndicator(
              color: Color(0xFF6B8E23),
            ),
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 32),
              const SizedBox(height: 8),
              Text(
                'could_not_load_weather_data'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'check_connection'.tr(),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.lightBlue.shade100, Colors.white],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF6B8E23),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _weatherData?.location ?? 'lucknow'.tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.lightBlue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.lightBlue.shade200, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getWeatherIcon(_weatherData?.weatherCondition ?? 'clear'),
                        color: Colors.blue.shade700,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_weatherData?.temperature.toStringAsFixed(0) ?? '21'}°C',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _weatherInfoColumn(
                    Icons.water_drop,
                    '${_weatherData?.humidity ?? '28'}%',
                    'humidity'.tr()
                ),
                _weatherInfoColumn(
                    Icons.air,
                    '${_weatherData?.windSpeed.toStringAsFixed(1) ?? '4'} km/h',
                    'wind'.tr()
                ),
                _weatherInfoColumn(
                    Icons.cloudy_snowing,
                    '${_weatherData?.precipitation ?? '46'}%',
                    'precipitation'.tr()
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 1, color: Colors.black12),
            const SizedBox(height: 10),

            // Interactive Sunrise/Sunset section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text(
                      _weatherData?.sunrise ?? '7:00 am',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'sunrise'.tr(),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                // Interactive Sun Path
                SizedBox(
                  width: 150,
                  height: 50,
                  child: InteractiveSunPath(
                    sunPosition: _sunPosition,
                    onSunPositionChanged: _onSunPositionChanged,
                    onInteractionStart: _onSunInteractionStart,
                    onInteractionEnd: _onSunInteractionEnd,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      _weatherData?.sunset ?? '6:00 pm',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'sunset'.tr(),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Show current time based on sun position
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _isUserInteracting
                    ? 'Selected Time: ${_getTimeFromSunPosition(_sunPosition)}'
                    : 'Current Time: ${_getTimeFromSunPosition(_sunPosition)}',
                style: TextStyle(
                  color: _isUserInteracting ? Colors.orange.shade700 : Colors.blue.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '24_hours'.tr(),
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        const crossAxisCount = 3;
        const spacing = 10.0;
        final cardWidth = (availableWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;
        final aspectRatio = cardWidth / (cardWidth * 1.0);

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: _menuItems.length,
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final item = _menuItems[index];
            return _menuItemCard(
              item['icon'],
              item['label'],
              item['color'],
              item['onTap'],
            );
          },
        );
      },
    );
  }

  Widget _weatherInfoColumn(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.grey,
          size: 16,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _menuItemCard(String iconPath, String label, Color bgColor, VoidCallback? onTap) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Image.asset(
                  iconPath,
                  width: 20,
                  height: 20,
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  label.tr(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

// Interactive Sun Path Widget
class InteractiveSunPath extends StatefulWidget {
  final double sunPosition;
  final Function(double) onSunPositionChanged;
  final VoidCallback onInteractionStart;
  final VoidCallback onInteractionEnd;

  const InteractiveSunPath({
    super.key,
    required this.sunPosition,
    required this.onSunPositionChanged,
    required this.onInteractionStart,
    required this.onInteractionEnd,
  });

  @override
  _InteractiveSunPathState createState() => _InteractiveSunPathState();
}

class _InteractiveSunPathState extends State<InteractiveSunPath> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        widget.onInteractionStart();
        _handlePanUpdate(details.localPosition);
      },
      onPanUpdate: (details) => _handlePanUpdate(details.localPosition),
      onPanEnd: (details) => widget.onInteractionEnd(),
      onTapDown: (details) {
        widget.onInteractionStart();
        _handlePanUpdate(details.localPosition);
      },
      onTapUp: (details) => widget.onInteractionEnd(),
      child: CustomPaint(
        painter: InteractiveSunPathPainter(
          sunPosition: widget.sunPosition,
        ),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }

  void _handlePanUpdate(Offset localPosition) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;

    // Convert touch position to sun position (0.0 to 1.0)
    double newPosition = (localPosition.dx / size.width).clamp(0.0, 1.0);

    widget.onSunPositionChanged(newPosition);
  }
}

// Interactive Sun Path Painter
class InteractiveSunPathPainter extends CustomPainter {
  final double sunPosition;

  InteractiveSunPathPainter({
    required this.sunPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the curve path
    final pathPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height - 10);
    path.quadraticBezierTo(
        size.width / 2,
        -10,
        size.width,
        size.height - 10
    );

    canvas.drawPath(path, pathPaint);

    // Calculate sun position on curve
    final sunOffset = _calculateSunPositionOnCurve(sunPosition, size);

    // Draw sun shadow/glow effect
    final glowPaint = Paint()
      ..color = Colors.orange.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(sunOffset, 15, glowPaint);

    // Draw the sun
    final sunPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    canvas.drawCircle(sunOffset, 12, sunPaint);

    // Draw sun rays
    final rayPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2) / 8;
      final startX = sunOffset.dx + math.cos(angle) * 16;
      final startY = sunOffset.dy + math.sin(angle) * 16;
      final endX = sunOffset.dx + math.cos(angle) * 20;
      final endY = sunOffset.dy + math.sin(angle) * 20;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        rayPaint,
      );
    }

    // Draw sun face
    final facePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Eyes
    canvas.drawCircle(Offset(sunOffset.dx - 4, sunOffset.dy - 2), 1.5, facePaint);
    canvas.drawCircle(Offset(sunOffset.dx + 4, sunOffset.dy - 2), 1.5, facePaint);

    // Smile
    final smilePath = Path();
    smilePath.addArc(
      Rect.fromCenter(
        center: Offset(sunOffset.dx, sunOffset.dy + 2),
        width: 8,
        height: 4,
      ),
      0,
      math.pi,
    );
    canvas.drawPath(smilePath, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round);
  }

  Offset _calculateSunPositionOnCurve(double t, Size size) {
    // Quadratic bezier curve calculation
    final p0 = Offset(0, size.height - 10);
    final p1 = Offset(size.width / 2, -10);
    final p2 = Offset(size.width, size.height - 10);

    final x = math.pow(1 - t, 2) * p0.dx + 2 * (1 - t) * t * p1.dx + math.pow(t, 2) * p2.dx;
    final y = math.pow(1 - t, 2) * p0.dy + 2 * (1 - t) * t * p1.dy + math.pow(t, 2) * p2.dy;

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

