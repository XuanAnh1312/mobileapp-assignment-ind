import 'package:flutter/material.dart';
import 'screens/class_score_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bảng Điểm Lớp UTH',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ClassScoreScreen(),
    );
  }
}
