import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/session_manager.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => SessionManager(),
      child: const OasthApp(),
    ),
  );
}

class OasthApp extends StatelessWidget {
  const OasthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OASTH Live',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Color(0xFFFF9500),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            fontFamily: 'Courier',
            color: Color(0xFFFFAA00),
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Courier',
            color: Color(0xFFFFAA00),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
