import 'home.dart';
import 'package:flutter/material.dart';

import 'components/theme_button.dart';
import 'components/color_button.dart';

import 'constants.dart';

void main() {
  // 1
  runApp(const Yummy());
}

class Yummy extends StatefulWidget {
  // TODO: Setup default theme
  // 2
  const Yummy({super.key});

  @override
  State<Yummy> createState() => _YummyState();
}

class _YummyState extends State<Yummy> {
  ThemeMode themeMode = ThemeMode.light;
  ColorSelection colorSelected = ColorSelection.pink;

  // TODO: Add changeTheme above here
  void changeThemeMode(bool useLightMode) {
    setState(() {
      // 1
      themeMode = useLightMode
        ? ThemeMode.light //
        : ThemeMode.dark;
    });
  }
  void changeColor(int value) {
    setState(() {
      // 2
      colorSelected = ColorSelection.values[value];
    });
  }  

  @override
  Widget build(BuildContext context) {
    // TODO: Setup default theme
  
    //3
    return MaterialApp(
      title: 'Yummy',
      debugShowCheckedModeBanner: false,
      // Uncomment to remove Debug banner
      themeMode: themeMode,
      theme: ThemeData(
        colorSchemeSeed: colorSelected.color,
        useMaterial3: true,
        brightness: Brightness.light,
      ),

      darkTheme: ThemeData(
        colorSchemeSeed: colorSelected.color,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      // TODO: Add theme


 // TODO: Replace Scaffold with Home widget
 // 4
      home: Home(
        changeTheme: changeThemeMode,
        changeColor: changeColor,
        colorSelected: ColorSelection.pink,
      ),
    );
  }
}