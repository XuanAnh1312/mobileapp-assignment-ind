import 'package:flutter/material.dart';
import '../model/students.dart';
import '../widgets/student_card.dart';
import '../widgets/summary.dart';


class StudentList extends StatelessWidget {
  const StudentList({super.key});

  @override
  Widget build(BuildContext context) {
    List<Students> student = [
      Students(name: 'Nguyễn Văn An', email: 'an@sv.edu.vn', phone: '0901 234 567'),
      Students(name: 'Trần Thị Bình', email: null, phone: '0912 888 999'),
      Students(name: 'Lê Minh Chi', email: 'chi@sv.edu.vn', phone: null),
      Students(name: 'Phạm Quốc Dũng', email: null, phone: null),
      Students(name: 'Võ Thanh Em', email: 'em@sv.edu.vn', phone: '0933 111 222'),
    ];
    int totalStudent = 0;
    int noEmail = 0;

    for (var studentItem in student) {
      totalStudent++;
      if (studentItem.email == null) {
        noEmail++;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student List'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: student.length,
              itemBuilder: (context, index) {
                return StudentCard(student: student[index]);
              },
            ),
          ),

          Summary(totalStudent: totalStudent, noEmail: noEmail),

        ],
      ),
    );
  }
}