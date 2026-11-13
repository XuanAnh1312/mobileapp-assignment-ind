import 'package:flutter/material.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});



  @override
  Widget build(BuildContext context) {
    String _message="Hello";
    void _sayHi(){
      setState((){
        _message = "I am Xuan Anh";
      });
    }
    return Scaffold( 
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0), 
          child: Column(
            
            children: [
              
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  children: [
                      Text(
                        'TextView',
                        style: TextStyle(
                          fontSize: 23,
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 40),
                      Text(
                        _message,
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _sayHi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Say Hi'),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

  void setState(Null Function() param0) {}
  }