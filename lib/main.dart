import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 1. Import package services
import 'package:motodashboard/dashboard_provider.dart';
import 'package:motodashboard/find_devices_screen.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown, // บังคับให้เป็นแนวนอนด้านขวา
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DashboardProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ApiTech Dashboard',
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.orange,
          scaffoldBackgroundColor: const Color(0xFF1a1a1a),
        ),
        home: const FindDevicesScreen(),
      ),
    );
  }
}