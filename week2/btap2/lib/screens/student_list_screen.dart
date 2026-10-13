import 'package:flutter/material.dart';
import '../models/student.dart';
import '../widgets/student_card.dart';
import '../widgets/summary_footer.dart';

class StudentListScreen extends StatelessWidget {
  const StudentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Tạo danh sách 5 sinh viên theo yêu cầu
    List<Student> students = [
      Student(name: 'Nguyễn Văn An', email: 'an@sv.edu.vn', phone: '0901 234 567'),
      Student(name: 'Trần Thị Bình', email: null, phone: '0912 888 999'),
      Student(name: 'Lê Minh Chi', email: 'chi@sv.edu.vn', phone: null),
      Student(name: 'Phạm Quốc Dũng', email: null, phone: null),
      Student(name: 'Võ Thanh Em', email: 'em@sv.edu.vn', phone: '0933 111 222'),
    ];

    // Dùng vòng lặp for để đếm tổng số sinh viên và số sinh viên thiếu email
    int totalStudent = 0;
    int missingEmailCount = 0;

    for (var student in students) {
      totalStudent++;
      if (student.email == null) {
        missingEmailCount++;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách sinh viên'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFFF3F4F6),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dùng vòng lặp for để hiển thị các thẻ sinh viên
            for (var student in students) ...[
              StudentCard(student: student),
              const SizedBox(height: 12.0),
            ],

            // Phần tổng kết ở cuối danh sách
            SummaryFooter(
              totalStudent: totalStudent,
              missingEmailCount: missingEmailCount,
            ),
          ],
        ),
      ),
    );
  }
}
