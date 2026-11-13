import 'package:flutter/material.dart';
import '../models/library_model.dart';

// ============================================================================
// BÀI TẬP 2: GIAO DIỆN QUẢN LÝ THƯ VIỆN (LIBRARY SCREEN)
// Minh họa trực tiếp 4 đặc trưng OOP & Đóng gói Giáo viên, Đóng gói Sách
// ============================================================================

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  // --------------------------------------------------------------------------
  // [1. MINH HỌA TÍNH ĐÓNG GÓI - KHỞI TẠO ĐỐI TƯỢNG ĐÃ ĐƯỢC ĐÓNG GÓI]
  // - Đối tượng '_student' (Sinh viên): Dữ liệu bên trong đã được bảo vệ kín đáo.
  // - Đối tượng '_teacher' (Giáo viên): Thể hiện ĐÓNG GÓI GIÁO VIÊN (mã, tên, khoa/bộ môn).
  // --------------------------------------------------------------------------
  final Student _student = Student('SV01', 'Nguyen Van A');
  final Teacher _teacher = Teacher('GV01', 'TS. Trần Văn B', 'Khoa Công Nghệ Thông Tin');

  // [2. MINH HỌA TÍNH ĐÓNG GÓI SÁCH - KHỞI TẠO DANH SÁCH ĐỐI TƯỢNG BOOK]
  // Các thuộc tính mã sách, tựa sách, tác giả, trạng thái mượn đều được đóng gói nội bộ
  final List<Book> _books = [
    Book('B01', 'Lập trình Flutter cơ bản', true),
    Book('B02', 'Lập trình Hướng đối tượng OOP', true),
    Book('B03', 'Cấu trúc dữ liệu và giải thuật', false),
  ];

  // Trạng thái lựa chọn vai trò người mượn: true = Sinh viên, false = Giáo viên
  bool _isStudent = true;

  // Controller quản lý nhập liệu Họ và tên
  late final TextEditingController _nameController;

  // [3. MINH HỌA TÍNH TRỪU TƯỢNG & TÍNH ĐA HÌNH TRONG CODE]
  // Khai báo Getter 'currentBorrower' kiểu lớp cha 'Person'.
  // Nhờ Tính Kế Thừa và Trừu Tượng, 'currentBorrower' có thể đại diện linh hoạt
  // cho cả 'Student' lẫn 'Teacher' mà không cần viết lại mã nguồn.
  Person get currentBorrower => _isStudent ? _student : _teacher;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: currentBorrower.name);

    // [TÍNH ĐÓNG GÓI]: Thêm các cuốn sách có isBorrowed == true vào danh sách mượn ban đầu
    for (final book in _books) {
      if (book.isBorrowed) {
        // Gọi phương thức nghiệp vụ đã được đóng gói an toàn
        _student.addBookToBorrow(book);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Chuyển đổi qua lại giữa Sinh viên và Giáo viên
  void _toggleBorrowerRole(bool selectStudent) {
    setState(() {
      _isStudent = selectStudent;
      // [TÍNH ĐÓNG GÓI - Getter]: Lấy tên người mượn an toàn qua Getter 'name'
      _nameController.text = currentBorrower.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hệ thống Quản lý Thư viện'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------------------
            // BỘ CHỌN VAI TRÒ: MINH HỌA ĐA HÌNH & KẾ THỪA (SINH VIÊN VÀ GIÁO VIÊN)
            // ----------------------------------------------------------------
            const Text(
              'Chọn đối tượng mượn sách (OOP Demo):',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Sinh viên (Student)'),
                    selected: _isStudent,
                    selectedColor: Colors.blue[100],
                    onSelected: (selected) {
                      if (selected) _toggleBorrowerRole(true);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Giáo viên (Teacher)'),
                    selected: !_isStudent,
                    selectedColor: Colors.green[100],
                    onSelected: (selected) {
                      if (selected) _toggleBorrowerRole(false);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ----------------------------------------------------------------
            // THÔNG TIN NGƯỜI MƯỢN (ĐÓNG GÓI GIÁO VIÊN / SINH VIÊN)
            // ----------------------------------------------------------------
            Text(
              _isStudent ? 'Sinh viên' : 'Giáo viên (${_teacher.department})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      hintText: _isStudent ? 'Nhập tên sinh viên' : 'Nhập tên giáo viên',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // [TÍNH ĐÓNG GÓI - Setter]:
                      // Cập nhật tên thông qua Setter 'name = ...' có kiểm tra tính hợp lệ
                      currentBorrower.name = _nameController.text;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          // [TÍNH ĐÓNG GÓI - Getter]: Đọc tên qua Getter 'currentBorrower.name'
                          'Đã cập nhật: ${currentBorrower.name}',
                        ),
                      ),
                    );
                  },
                  child: const Text('Thay đổi'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ----------------------------------------------------------------
            // DANH SÁCH SÁCH: MINH HỌA TÍNH ĐÓNG GÓI SÁCH (CLASS BOOK)
            // ----------------------------------------------------------------
            const Text(
              'Danh sách sách',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _books.length,
                itemBuilder: (context, index) {
                  // Lấy đối tượng Book thứ index
                  final book = _books[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CheckboxListTile(
                      // [ĐÓNG GÓI SÁCH - Getter]: Đọc tên tựa sách an toàn qua Getter 'title'
                      title: Text(book.title),
                      // [ĐÓNG GÓI SÁCH - Getter]: Đọc trạng thái mượn qua Getter 'isBorrowed'
                      value: book.isBorrowed,
                      activeColor: Colors.red[700],
                      onChanged: (bool? value) {
                        setState(() {
                          // [ĐÓNG GÓI SÁCH - Setter]:
                          // Cập nhật trạng thái mượn an toàn qua Setter 'book.isBorrowed = value'
                          book.isBorrowed = value ?? false;

                          if (book.isBorrowed) {
                            // [TÍNH ĐÓNG GÓI - Gọi hàm nghiệp vụ thêm sách]:
                            // Người mượn (Giáo viên/Sinh viên) thêm sách vào danh sách quản lý nội bộ
                            currentBorrower.addBookToBorrow(book);
                          } else {
                            // [TÍNH ĐÓNG GÓI - Gọi hàm nghiệp vụ trả sách]:
                            // Bỏ sách ra khỏi danh sách mượn
                            currentBorrower.removeBook(book);
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            // ----------------------------------------------------------------
            // NÚT THAO TÁC: MINH HỌA TÍNH ĐA HÌNH (POLYMORPHISM)
            // ----------------------------------------------------------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Thông tin hệ thống (OOP Output)'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // [ĐẶC TRƯNG 4: TÍNH ĐA HÌNH (POLYMORPHISM) TRONG THỰC TẾ]:
                          // Gọi phương thức 'currentBorrower.getInfo()'.
                          // Dù con trỏ thuộc kiểu cha 'Person', nhưng tại runtime hệ thống
                          // tự động nhận diện và gọi đúng hàm getInfo() của 'Student'
                          // hoặc 'Teacher' mà không cần if-else kiểm tra kiểu!
                          Text(
                            currentBorrower.getInfo(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          // [TÍNH ĐÓNG GÓI - Getter]:
                          // Đọc số lượng sách đã mượn qua Getter 'borrowBooks.length'
                          Text('Số lượng sách đang chọn: ${currentBorrower.borrowBooks.length}'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Đóng'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Thêm', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
