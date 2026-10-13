class Student {
  final String name;
  final double? score;

  Student ({required this.name, required this.score});

  String get rank {
    if (score == null) return 'Chưa có điểm';
    if (score! >= 8.0) return 'Giỏi';
    if (score! >= 6.5) return 'Khá';
    if (score! >= 5.0) return 'Trung bình';
    return 'Yếu';
  }
}