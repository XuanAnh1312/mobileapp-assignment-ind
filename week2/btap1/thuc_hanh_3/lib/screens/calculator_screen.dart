import 'package:flutter/material.dart';
import '../models/calculator_model.dart'; // Import model vào để dùng

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final TextEditingController _num1Controller = TextEditingController();
  final TextEditingController _num2Controller = TextEditingController();

  double? _result;
  String _selectedOperator = '';

  void _onCalculate(String operator) {
    setState(() {
      _selectedOperator = operator;
      double num1 = double.tryParse(_num1Controller.text) ?? 0;
      double num2 = double.tryParse(_num2Controller.text) ?? 0;

      // Gọi logic từ CalculatorModel thay vì viết trực tiếp ở đây
      _result = CalculatorModel.calculate(num1, num2, operator);
    });
  }

  @override
  void dispose() {
    _num1Controller.dispose();
    _num2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Number'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Thực hành 03',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _num1Controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Nhập số thứ nhất',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOperatorButton('+', Colors.red),
                _buildOperatorButton('-', Colors.amber),
                _buildOperatorButton('*', Colors.deepPurple),
                _buildOperatorButton('/', Colors.black),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _num2Controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Nhập số thứ hai',
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Kết quả: ${_result != null ? _result.toString() : ""}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorButton(String operator, Color color) {
    bool isSelected = _selectedOperator == operator;
    return GestureDetector(
      onTap: () => _onCalculate(operator),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.blue, width: 3) : null,
        ),
        child: Center(
          child: Text(
            operator,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
