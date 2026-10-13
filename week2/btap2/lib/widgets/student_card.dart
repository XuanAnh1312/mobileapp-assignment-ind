import 'package:flutter/material.dart';
import '../models/student.dart';

class StudentCard extends StatelessWidget {
  final Student student;

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
        border: Border.all(color: Colors.grey.shade300, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            student.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            'Email: ${student.email ?? "Chưa cập nhật"}',
            style: TextStyle(
              fontSize: 13.0,
              color: student.email == null ? Colors.red[700] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            'SĐT: ${student.phone ?? "Chưa cập nhật"}',
            style: TextStyle(
              fontSize: 13.0,
              color: student.phone == null ? Colors.red[700] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
