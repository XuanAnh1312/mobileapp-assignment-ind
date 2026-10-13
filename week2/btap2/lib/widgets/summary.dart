import 'package:flutter/material.dart';
import '../screens/student_list.dart';

class Summary extends StatelessWidget {
  final int totalStudent;
  final int noEmail;


  const Summary({
    super.key,
    required this.totalStudent,
    required this.noEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(207, 107, 174, 230),
        borderRadius: BorderRadius.circular(8.0),
      ),
      
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        
        children: [
          Text('Tổng: $totalStudent sinh viên',
          style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        
          Row(
            children: [
              const Text('Thiếu email: '),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(207, 79, 166, 237), 
                  borderRadius: BorderRadius.circular(4.0),
                ),
                  
                  child: Text(
                    '$noEmail',
                    style: TextStyle(fontWeight: FontWeight.bold,
                    color: Colors.red),
                  )
                ),
              ],
          ),
        ],
      ),
    );
  }
}