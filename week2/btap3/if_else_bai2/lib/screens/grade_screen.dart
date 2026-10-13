import 'package:flutter/material.dart';
import '../main.dart';
import '../models/student.dart';
import '../services/grade_service.dart';

class GradeScreen extends StatelessWidget {
  const GradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Khai báo một biến điểm có giá trị 8.5
    double diem = 8.5;
    Student chinh = Student(score: diem, rank: GradeService.getRank(diem));

    // 4. Phần "Kiểm tra thêm" với các điểm 9, 7, 5.5, 3 và 11
    List<double> danhSachDiem = [9, 7, 5.5, 3, 11];
    List<Student> danhSachKiemTra = danhSachDiem.map((s) {
      return Student(score: s, rank: GradeService.getRank(s));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text(
          'Xếp loại học lực',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Khối hiển thị điểm chính (8.5)
            Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Điểm trung bình',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      chinh.score.toString(),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 3. Hiển thị điểm và xếp loại. Màu chữ chọn bằng if.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: GradeService.getRankBackgroundColor(chinh.rank),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Center(
                        child: Text(
                          chinh.rank,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: GradeService.getRankColor(chinh.rank),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'KIỂM TRA THÊM',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),

            // Hiển thị danh sách kiểm tra thêm từ model
            ...danhSachKiemTra.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8.0),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Điểm ${item.score % 1 == 0 ? item.score.toInt() : item.score}',
                      style: const TextStyle(fontSize: 15),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: GradeService.getRankBackgroundColor(item.rank),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.rank,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: GradeService.getRankColor(item.rank),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
