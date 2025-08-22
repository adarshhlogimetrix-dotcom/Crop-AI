
import 'package:cropai/Activitypage.dart';
import 'package:cropai/SecondSplashScreen.dart';
import 'package:cropai/splash_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Activity_Monitoring.dart';
import 'AreaLevelingScreen.dart';
import 'CropProtection.dart';
import 'Fertilizer_Soil_Treatment.dart';
import 'Harvesting_Updates.dart';
import 'Hay_Making.dart';
import 'InterCulture.dart';
import 'Land_Preperation.dart';
import 'LanguageSelectionScreen.dart';
import 'NotificationPage.dart';
import 'Post_Irrigation.dart';
import 'Pre_Irrigation.dart';
import 'Pre_Land_Preperation.dart';
import 'Silage_Making.dart';
import 'Sowing.dart';
import 'Loinpage/login_screen.dart';
import 'dashboard_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('hi')],
      path: 'assets/translations', // Path to translation files
      fallbackLocale: const Locale('en'),
      child: const CropnetApp(),
    ),
  );
}

class CropnetApp extends StatelessWidget {
  const CropnetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cropnet',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        primaryColor: const Color(0xFF76A937),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF76A937),
          secondary: const Color(0xFF76A937),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/secondplashscreen':(context) => const SecondSplashScreen(),
        '/language': (context) => const LanguageSelectionScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/Arealevelingscreen': (context) => const Arealevelingscreen(),
        '/Pre_Land_Preperation': (context) => const Pre_Land_Preperation(),
        '/Pre_Irrigation': (context) => const Pre_Irrigation(),
        '/Land_Preperation': (context) => const Land_Preperation(),
        '/Sowing': (context) => const Sowing(),
        '/PostIrrigation': (context) => const PostIrrigation(),
        '/FertilizerSoilTreatment': (context) => const FertilizerSoilTreatment(),
        '/Interculture': (context) => const Interculture(),
        '/Cropprotection': (context) => const Cropprotection(),
        '/Activity_Monitoring': (context) => const Activity_Monitoring(),
        '/Harvesting_Updates': (context) => const Harvesting_Updates(),
        '/Hay_Making': (context) => const Hay_Making(),
        '/Silage_Making': (context) => const Silage_Making(),
        '/NotificationPage': (context) => const NotificationPage(),
        '/AgricultureSummaryPage': (context) => const AgricultureSummaryPage(),
      },
    );
  }
}







