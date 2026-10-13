import 'package:flutter/material.dart';
import '../model/students.dart';
import '../screens/student_list.dart';

class StudentCard extends StatelessWidget {
  final Students student; //note

  const StudentCard({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(1.0),
            blurRadius: 4,
            offset: Offset(0, 2)
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            
            student.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
            ),
          ),

          const SizedBox(height: 5.0),

          Text(
            'Email: ${student.email ?? "Chưa cập nhật"}',
            style: TextStyle(
              fontSize: 15.0,
              color: student.email == null ? Colors.red : Colors.blueGrey,
            ),
          ),

          const SizedBox(height: 2.0),

          Text(
            'SĐT: ${student.phone ?? "Chưa cập nhật"}',
            style: TextStyle(
              fontSize: 15.0,
              color: student.phone == null ? Colors.red : Colors.blueGrey,
            ),
          ),
        ]
      ),
    );
  }
}


