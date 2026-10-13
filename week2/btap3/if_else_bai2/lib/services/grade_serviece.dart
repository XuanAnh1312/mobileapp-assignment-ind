import 'package:flutter/material.dart';

class GradeService {
  // Hàm nhận vào điểm và trả về xếp loại (dùng if / else)
  static String getRank(double score) {
    if (score < 0 || score > 10) {
      return 'Không hợp lệ';
    } else if (score >= 8.0) {
      return 'Giỏi';
    } else if (score >= 6.5) {
      return 'Khá';
    } else if (score >= 5.0) {
      return 'Trung bình';
    } else {
      return 'Yếu';
    }
  }

  // Hàm chọn màu chữ bằng if
  static Color getRankColor(String rank) {
    if (rank == 'Giỏi') {
      return Colors.green.shade700;
    } else if (rank == 'Khá') {
      return Colors.blue.shade700;
    } else if (rank == 'Trung bình') {
      return Colors.orange.shade800;
    } else if (rank == 'Yếu') {
      return Colors.red.shade700;
    } else {
      return Colors.grey.shade600;
    }
  }

  // Hàm chọn màu nền bằng if
  static Color getRankBackgroundColor(String rank) {
    if (rank == 'Giỏi') {
      return Colors.green.shade50;
    } else if (rank == 'Khá') {
      return Colors.blue.shade50;
    } else if (rank == 'Trung bình') {
      return Colors.orange.shade50;
    } else if (rank == 'Yếu') {
      return Colors.red.shade50;
    } else {
      return Colors.grey.shade100;
    }
  }
}
