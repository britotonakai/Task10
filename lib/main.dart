import 'package:flutter/material.dart';
import 'package:task10_call/screen/mainScreen.dart';
import 'package:task10_call/screen/loginScreen.dart';
import 'package:task10_call/screen/videoScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.web);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: _videoApp(),
      ),
      routes: {
        '/login': (context) => loginScreen(),
        '/home': (context) => const mainScreen(),
        '/video': (context) => const videoScreen(),
      },
    );
  }

  Widget _videoApp() {
    // int _numOfParticipants = 2;
    // int _column = 0, _row = 0;

    return Scaffold(
      body: loginScreen(),
    );

    // return GridView.count(
    //   crossAxisCount: _numOfParticipants,
    //   children: List.generate(_numOfParticipants, (index) => videoScreen()),
    // );
  }
}
