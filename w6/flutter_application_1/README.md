# Thực hành 2 — Xử lý mạng và gọi API

Đề gốc: `reference/bai_tap.jpg`.

- Gọi HTTP GET đúng endpoint: https://mock.apidog.com/m1/890655-872447-default/v2/product
- Đọc dữ liệu thật: `id` (UUID), `name`, `price`, `imgURL`, `des`.
- Hiển thị ảnh, tên, giá và mô tả theo bố cục Product detail trong đề.
- Có trạng thái tải, lỗi mạng, thử lại, kéo để tải lại và xử lý ảnh lỗi.
- Đã khai báo quyền Internet cho Android, kể cả bản release.

API hiện trả một object sản phẩm và có thể trả dữ liệu khác ảnh giày minh họa trong đề. Ứng dụng hiển thị dữ liệu API, không thay bằng dữ liệu viết cứng. Bộ đọc cũng hỗ trợ danh sách và dữ liệu bọc trong `data`.

Chạy: `flutter pub get`, sau đó `flutter run`.
Kiểm tra: `flutter analyze` và `flutter test`.
