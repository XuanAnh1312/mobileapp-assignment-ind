import 'package:flutter/material.dart';

class SummaryFooter extends StatelessWidget {
  final int totalStudent;
  final int missingEmailCount;

  const SummaryFooter({
    super.key,
    required this.totalStudent,
    required this.missingEmailCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tổng: $totalStudent sinh viên',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13.0,
            ),
          ),
          Row(
            children: [
              const Text(
                'Thiếu email: ',
                style: TextStyle(fontSize: 13.0),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF93C5FD),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  '$missingEmailCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 13.0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
