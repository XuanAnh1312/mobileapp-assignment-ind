// ============================================================================
// BÀI TẬP 2: QUẢN LÝ THƯ VIỆN (UTH) - MINH HỌA 4 ĐẶC TRƯNG HƯỚNG ĐỐI TƯỢNG (OOP)
// ============================================================================
// 1. TÍNH TRỪU TƯỢNG (Abstraction)
// 2. TÍNH KẾ THỪA (Inheritance)
// 3. TÍNH ĐÓNG GÓI (Encapsulation) - Chỉ rõ ở Đóng Gói Giáo Viên & Đóng Gói Sách
// 4. TÍNH ĐA HÌNH (Polymorphism)
// ============================================================================

// ignore_for_file: unnecessary_getters_setters

// ----------------------------------------------------------------------------
// [ĐẶC TRƯNG 1: TÍNH TRỪU TƯỢNG - ABSTRACTION]
// - Sử dụng 'abstract class' để tạo ra một "bản thiết kế chung" (blueprint/interface)
//   cho tất cả các thực thể trong hệ thống thư viện.
// - Ẩn giấu chi tiết cài đặt bên trong; chỉ công bố các phương thức trừu tượng
//   (không có phần thân hàm `{}`) bắt buộc mọi lớp con phải tự triển khai.
// ----------------------------------------------------------------------------
abstract class LibraryEntity {
  // Phương thức trừu tượng: Lấy mã nhận diện thực thể (ID)
  String getId();

  // Phương thức trừu tượng: Lấy thông tin tóm tắt của thực thể
  String getInfo();
}

// ----------------------------------------------------------------------------
// [ĐẶC TRƯNG 2: TÍNH KẾ THỪA (INHERITANCE) & NỀN TẢNG ĐÓNG GÓI CỦA PERSON]
// - Class 'Person' triển khai 'LibraryEntity', làm lớp cha cho mọi con người
//   (Sinh viên, Giáo viên,...).
// - TÍNH ĐÓNG GÓI (Encapsulation):
//   + Sử dụng tiền tố '_' để bảo vệ các thuộc tính nhạy cảm (_id, _name, _borrowBooks).
//   + Bên ngoài chỉ có thể đọc hoặc cập nhật thông qua Getter và Setter có kiểm soát.
// ----------------------------------------------------------------------------
class Person implements LibraryEntity {
  // [Tính đóng gói - Thuộc tính Private]: Che giấu ID (chỉ đọc) và Tên
  final String _id;
  String _name;

  // [Tính đóng gói - Danh sách sách mượn]: Được bảo vệ nội bộ, tránh bên ngoài gán đè danh sách
  final List<Book> _borrowBooks = [];

  // Constructor khởi tạo thông tin Person
  Person(this._id, this._name);

  // [Tính đóng gói - Getter]: Cung cấp quyền đọc ID an toàn ra bên ngoài
  @override
  String getId() => _id;

  // [Tính đóng gói - Getter]: Cung cấp quyền đọc Họ tên
  String get name => _name;

  // [Tính đóng gói - Setter]: Cho phép cập nhật Họ tên với kiểm tra ràng buộc không rỗng
  set name(String newName) {
    if (newName.trim().isNotEmpty) {
      _name = newName.trim();
    }
  }

  // [Tính đóng gói - Getter]: Cho phép truy xuất danh sách sách mượn
  List<Book> get borrowBooks => _borrowBooks;

  // [Tính đóng gói - Phương thức nghiệp vụ]: Kiểm soát logic thêm sách vào danh sách mượn
  void addBookToBorrow(Book book) {
    if (!_borrowBooks.contains(book)) {
      _borrowBooks.add(book);
    }
  }

  // [Tính đóng gói - Phương thức nghiệp vụ]: Kiểm soát logic trả lại sách
  void removeBook(Book book) {
    _borrowBooks.remove(book);
  }

  // [ĐẶC TRƯNG 4: TÍNH ĐA HÌNH - POLYMORPHISM]: Phương thức getInfo() cơ bản
  @override
  String getInfo() {
    return 'ID: $_id, Họ và tên: $_name';
  }
}

// ----------------------------------------------------------------------------
// [ĐẶC TRƯNG 3 (PHẦN 1): TÍNH ĐÓNG GÓI GIÁO VIÊN - TEACHER ENCAPSULATION]
// - TÍNH KẾ THỪA: Teacher dùng từ khóa 'extends' để kế thừa lớp Person
//   -> Thừa hưởng toàn bộ _id, _name, danh sách _borrowBooks, addBookToBorrow, removeBook.
// - TÍNH ĐÓNG GÓI GIÁO VIÊN:
//   + Thuộc tính riêng '_department' (Khoa/Bộ môn) được đặt là PRIVATE ('_')
//     nhằm thực hiện che giấu dữ liệu (Data Hiding), không cho truy cập tự do bên ngoài.
//   + Cung cấp Getter 'department' để đọc dữ liệu an toàn.
//   + Cung cấp Setter 'set department' kiểm tra tính hợp lệ trước khi cho phép gán.
// - TÍNH ĐA HÌNH: Ghi đè (@override) phương thức getInfo() để hiển thị thông tin đặc thù của Giáo viên.
// ----------------------------------------------------------------------------
class Teacher extends Person {
  // [Đóng gói Giáo viên - Thuộc tính Private]: Che giấu thông tin Khoa/Bộ môn
  String _department;

  // Constructor: Dùng super() để chuyển _id và _name lên lớp cha Person khởi tạo
  Teacher(super.id, super.name, this._department);

  // [Đóng gói Giáo viên - Getter]: Cho phép đọc tên Khoa/Bộ môn
  String get department => _department;

  // [Đóng gói Giáo viên - Setter]: Kiểm soát việc cập nhật Khoa/Bộ môn (không nhận chuỗi rỗng)
  set department(String value) {
    if (value.trim().isNotEmpty) {
      _department = value.trim();
    }
  }

  // [ĐẶC TRƯNG 4: TÍNH ĐA HÌNH - POLYMORPHISM]
  // Ghi đè phương thức getInfo() của Person để trả về chuỗi thông tin dành riêng cho Giáo viên
  @override
  String getInfo() {
    return 'Giáo viên: $name (Mã: ${getId()}) - Khoa: $_department - Đã mượn: ${borrowBooks.length} cuốn sách';
  }
}

// ----------------------------------------------------------------------------
// [LỚP SINH VIÊN - CLASS STUDENT]
// - TÍNH KẾ THỪA (Inheritance): 'Student extends Person' kế thừa toàn bộ thuộc tính và hàm từ Person.
// - TÍNH ĐA HÌNH (Polymorphism): Ghi đè (@override) getInfo() để thể hiện thông tin riêng biệt của Sinh viên.
// ----------------------------------------------------------------------------
class Student extends Person {
  // Constructor: Tái sử dụng constructor của lớp cha Person qua super
  Student(super.id, super.name);

  // [ĐẶC TRƯNG 4: TÍNH ĐA HÌNH - POLYMORPHISM]
  // Ghi đè getInfo() để hiển thị thông tin đặc thù dành cho Sinh viên
  @override
  String getInfo() {
    return 'Sinh viên: $name (Mã: ${getId()}) - Đã mượn: ${borrowBooks.length} cuốn sách';
  }
}

// ----------------------------------------------------------------------------
// [ĐẶC TRƯNG 3 (PHẦN 2): TÍNH ĐÓNG GÓI SÁCH - BOOK ENCAPSULATION]
// - TÍNH TRỪU TƯỢNG & ĐA HÌNH: Book triển khai 'implements LibraryEntity'.
// - TÍNH ĐÓNG GÓI SÁCH:
//   + Mọi thuộc tính quan trọng: '_bookId', '_title', '_author', '_isBorrowed'
//     đều có tiền tố '_' để thành PRIVATE (Data Hiding).
//   + Mã sách '_bookId' là 'final' (Read-only), bên ngoài chỉ có thể đọc qua Getter,
//     không thể bị ghi đè sau khi khởi tạo, đảm bảo tính toàn vẹn dữ liệu.
//   + Tựa sách '_title' được bảo vệ: đọc qua 'get title', sửa qua 'set title' có kiểm tra rỗng.
//   + Trạng thái mượn '_isBorrowed' được đọc qua 'get isBorrowed' và cập nhật qua
//     'set isBorrowed(bool value)', kiểm soát việc sách đang rảnh hay đã cho mượn.
// ----------------------------------------------------------------------------
class Book implements LibraryEntity {
  // [Đóng gói Sách - Thuộc tính Private]: Che giấu dữ liệu bên trong của cuốn sách
  final String _bookId;  // Mã sách: Private và chỉ đọc (Read-only)
  String _title;         // Tên tựa sách: Private
  final String _author;  // Tác giả: Private
  bool _isBorrowed;      // Trạng thái mượn: Private (true: đang mượn, false: còn trong kho)

  // Constructor: Khởi tạo đối tượng sách với các tham số bắt buộc
  Book(this._bookId, this._title, this._isBorrowed, [this._author = 'NXB Giáo Dục']);

  // [Đóng gói Sách - Getter]: Đọc mã sách an toàn
  String get bookId => _bookId;

  // [Đóng gói Sách - Getter]: Đọc tựa đề sách
  String get title => _title;

  // [Đóng gói Sách - Getter]: Đọc tên tác giả
  String get author => _author;

  // [Đóng gói Sách - Getter]: Đọc trạng thái mượn sách
  bool get isBorrowed => _isBorrowed;

  // [Đóng gói Sách - Setter]: Kiểm soát việc cập nhật trạng thái mượn của sách
  set isBorrowed(bool value) {
    _isBorrowed = value;
  }

  // [Đóng gói Sách - Setter]: Kiểm soát việc đổi tên sách, ngăn chuỗi rỗng
  set title(String value) {
    if (value.trim().isNotEmpty) {
      _title = value.trim();
    }
  }

  // [Triển khai Tính trừu tượng LibraryEntity]: Cung cấp mã định danh của sách
  @override
  String getId() => _bookId;

  // [ĐẶC TRƯNG 4: TÍNH ĐA HÌNH - POLYMORPHISM]
  // Ghi đè phương thức getInfo() để thể hiện thông tin riêng biệt của cuốn Sách
  @override
  String getInfo() {
    return 'Sách: $_title (Mã: $_bookId) - Tác giả: $_author - Trạng thái: ${_isBorrowed ? "Đang được mượn" : "Còn trong kho"}';
  }
}
