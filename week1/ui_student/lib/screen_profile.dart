import 'package:flutter/material.dart';

const Color _backgroundColor = Color(0xFFFFFFFF);
const Color _transparentColor = Color(0x00000000);
const Color _foregroundColor = Color(0xFF000000);
const Color _secondaryTextColor = Color(0xFF9E9E9E);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    //Scaffold 
      //appBar
      //body
      //floatingActionButton
    
    
    return Scaffold( 
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0), 
          child: Column(
            
            children: [
              
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _transparentColor,
                        border: Border.all(color: _foregroundColor),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, size: 30, color: _foregroundColor),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                        onPressed: () {},
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _transparentColor,
                        border: Border.all(color: _foregroundColor),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit_note, size: 30, color: _foregroundColor),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 67,
                        backgroundImage: AssetImage('assets/089306017838_XuanAnh.png'),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Nguyễn Phạm Xuân Anh',
                        style: TextStyle(
                          fontSize: 23,
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.bold,
                          color: _foregroundColor,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '089306017838',
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'Arial',
                          color: _secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}