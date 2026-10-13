import 'package:flutter/material.dart';
import '../models/student.dart';

class ClassScoreScreen extends StatelessWidget {
  const ClassScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dữ liệu mẫu theo yêu cầu bài tập[span_4](start_span)[span_4](end_span)
    final List<Student> students = [
      Student(name: 'Nguyễn Văn An', score: 9.0),
      Student(name: 'Trần Thị Bình', score: 7.2),
      Student(name: 'Lê Minh Chí', score: null),
      Student(name: 'Phạm Quốc Dũng', score: 4.5),
      Student(name: 'Võ Thanh Em', score: 5.8),
    ];

    // Khởi tạo các biến tính toán[span_5](start_span)[span_5](end_span)
    double totalScore = 0;
    int countScored = 0;
    int countGioi = 0;
    int countNoScore = 0;
    double maxScore = 0;

    // Sử dụng vòng lặp for + if để tính toán[span_6](start_span)[span_6](end_span)
    for (var student in students) {
      if (student.score == null) {
        countNoScore++;
      } else {
        totalScore += student.score!;
        countScored++;
        
        if (student.score! >= 8.0) {
          countGioi++;
        }
        
        if (student.score! > maxScore) {
          maxScore = student.score!;
        }
      }
    }

    // Tính điểm trung bình lớp (bỏ qua người chưa có điểm)[span_7](start_span)[span_7](end_span)
    double avgScore = countScored > 0 ? totalScore / countScored : 0;

    return Scaffold(
      backgroundColor: const Color(0xFF162238), // Màu nền xanh đậm giống mẫu
      appBar: AppBar(
        backgroundColor: const Color(0xFF162238),
        elevation: 0,
        title: const Text(
          'Bảng điểm lớp',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Phần thống kê tổng quan (Card phía trên)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2D4A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Điểm trung bình lớp',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  avgScore.toStringAsFixed(2), // Hiển thị 2 chữ số thập phân (6.63)[span_8](start_span)[span_8](end_span)
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.white24, height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem('Giỏi', '$countGioi'),
                    _buildStatItem('Chưa có điểm', '$countNoScore'),
                    _buildStatItem('Cao nhất', maxScore.toStringAsFixed(1)),
                  ],
                ),
              ],
            ),
          ),

          // Phần danh sách sinh viên
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'DANH SÁCH • 5 SINH VIÊN',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFF0F0F0)),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    student.rank,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: student.score == null
                                          ? Colors.grey
                                          : Colors.blueGrey,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                student.score != null
                                    ? student.score.toString()
                                    : '—',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
