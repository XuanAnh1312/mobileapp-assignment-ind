# Mock API bài tập — UTH Todo

## API đã kiểm tra

`GET https://share.tryapps.store/mock/teach/tasks`

Header: `Authorization: Bearer <MOCK_API_TOKEN do admin cấp>`.

Kiểm tra thực tế ngày 10/11/2026: GET trả HTTP 200, 6 công việc, nội dung tiếng Việt và việc nhỏ. OPTIONS cho phép Authorization/Content-Type từ trình duyệt. GET chi tiết /tasks/2 cũng trả dữ liệu.

Đã thử ghi bằng bản ghi thử riêng rồi gọi DELETE dọn ngay; không sửa các ID mẫu 1–6. POST trả 201 với nội dung mẫu cố định (ID 7), nhưng GET lại ID đó trả 404; PATCH ID thử trả bản mẫu ID 2. PUT trả 405, allowed GET/PATCH/DELETE. Sau dọn, GET danh sách vẫn có 6 bản ghi gốc. Vì vậy code không dựa vào các phản hồi ghi này để khẳng định dữ liệu đã được lưu trên server.

## Luồng tích hợp

```text
Mock API GET + Bearer token
→ chuyển JSON thành Task
→ nhập dữ liệu mẫu một lần
→ TaskStore dùng chung
→ Trang chủ / Danh sách / Chi tiết / form sửa
```

- Chưa đăng nhập: mẫu API được nhập vào dữ liệu cục bộ. Thêm/sửa/xóa sau đó lưu bằng shared_preferences.
- Đã đăng nhập: mẫu API được nhập vào users/{uid}/tasks. Thêm/sửa/xóa sau đó lưu bằng Firestore thật, theo Rules của tài khoản.
- Không upload công việc cá nhân của khách vào tài khoản. Khi tài khoản mới cần mẫu, app tải lại trực tiếp từ API.
- Marker cục bộ uth.mockTeach.imported.v1 và marker Firestore users/{uid}.mockTeachImportedV1 ngăn nhập trùng hoặc khôi phục các việc đã xóa. Firestore nhập tasks và marker trong cùng transaction, không ghi đè document đã tồn tại.
- Kéo xuống ở Trang chủ/Danh sách để gọi GET lại; thao tác này không ghi đè các chỉnh sửa hoặc khôi phục việc mẫu đã xóa.
- Lỗi token, HTTP, timeout hoặc JSON có thông báo và nút Thử lại API; không xóa dữ liệu hiện có vì lỗi HTTP.
- API dùng ngày tháng 10/2026. App giữ nguyên ngày, không giả làm hôm nay. Trang chủ có Việc quá hạn cho các việc cũ chưa hoàn thành. Danh sách hiển thị cả việc đã xong và chưa xong.
- Chức năng CRUD hiện không gửi POST/PATCH/DELETE lên Mock API: các endpoint ghi được kiểm tra chưa chứng minh khả năng lưu lâu dài. Nếu thầy yêu cầu CRUD bằng HTTP thay vì GET dữ liệu mẫu, cần hợp đồng endpoint ghi có lưu dữ liệu hoặc thống nhất mô hình mô phỏng với thầy.

## Ánh xạ trường

| API | Model / Firestore |
| --- | --- |
| id số, ví dụ 2 | id mock_2, tránh trùng công việc tự tạo |
| category | group: study/life |
| date và time | DateTime due; khi ghi Firestore dùng Timestamp |
| remind | reminder |
| subtasks không có id | cấp ID ổn định theo task + vị trí khi nhập lần đầu |
| title, note, priority, done | giữ nội dung và trạng thái thật |

## Cấu hình token

Token đã được đặt trong config/mock_api.local.json ở workspace hiện tại; file này bị loại khỏi Git. File được khai báo trong assets để F5 với cấu hình hiện có dùng được, không bắt buộc nhập tham số khi chạy.

Khi clone project sang máy khác, sao chép config/mock_api.example.json thành config/mock_api.local.json rồi điền token admin cấp. Có thể ghi đè bằng --dart-define=MOCK_API_TOKEN=<token> nếu cần. Đây là token của API bài tập, không phải Firebase UID hay Google ID token. Không ghi token vào log, ảnh báo cáo hoặc source được commit. Token trong client vẫn có thể được trích xuất từ app; chỉ dùng credential đúng phạm vi bài tập.

## File

- lib/services/mock_task_api.dart: HTTP GET, Bearer header, timeout, UTF-8, kiểm tra JSON, chuyển model.
- lib/services/task_store.dart: nạp API, nhập một lần, lỗi/thử lại, giữ riêng nguồn khách và tài khoản.
- lib/services/firestore_task_repository.dart: transaction nhập mẫu và marker theo UID.
- lib/main.dart: khởi tạo cấu hình API khi app khởi động, giữ Auth và Firestore đã có.
- lib/screens/home_screen.dart: dùng dữ liệu API qua store, kéo tải lại và hiển thị quá hạn.
- lib/screens/task_list_screen.dart: dùng store chung và kéo tải lại.
- lib/screens/task_shell.dart: trạng thái tải/lỗi API và thông tin nguồn dữ liệu.
- pubspec.yaml/pubspec.lock: http và asset cấu hình; .gitignore: loại token cục bộ khỏi Git.
- test/mock_task_api_test.dart, test/mock_task_import_test.dart: kiểm thử header, kiểu dữ liệu, lỗi, nhập một lần và luồng UI.

## Kiểm tra thủ công khi được phép chạy app

1. Mở app với mạng và token hợp lệ: API mẫu được nạp tự động, không cần đăng nhập để xem chế độ khách.
2. Danh sách hiển thị các mẫu; Trang chủ có số lượng theo nhóm và Việc quá hạn nếu ngày mẫu trước hôm nay.
3. Mở một việc, đọc ghi chú/việc nhỏ, sửa/hoàn thành/xóa. Kéo tải lại và mở lại app: chỉnh sửa còn, việc đã xóa không bị phục hồi.
4. Đăng nhập: mẫu thuộc UID riêng trên Firestore; thử sửa document ở Console để kiểm tra stream. Guest tasks không được chuyển lên.
5. Đổi token sai để kiểm tra 401/403; bật lại token đúng và khởi động lại app. Tắt mạng để kiểm tra lỗi tải mà dữ liệu cũ không biến mất.

Không chạy flutter run hay build app trong lần sửa này. Đã gọi API thật qua HTTP để xác minh hợp đồng; UI được kiểm tra bằng widget tests, chưa kiểm thử trên thiết bị thật. Chưa ghi dữ liệu lên Firebase thật trong quá trình làm.

## Kết quả kiểm tra sau triển khai

- flutter pub get: thành công; http 1.6.0 được đưa thành dependency trực tiếp.
- flutter analyze: No issues found.
- flutter test: 44 tests passed, gồm kiểm tra Bearer header, UTF-8, ánh xạ ngày/giờ, 401/403/500/timeout, dữ liệu sai, lưu qua lần mở lại, không nhập trùng, tách khách/tài khoản và điều hướng UI với dữ liệu API.
- git diff --check: không có lỗi khoảng trắng; config/mock_api.local.json đã được git check-ignore xác nhận.
- GET endpoint thật đã xác minh HTTP 200. Firestore và UI trên thiết bị thật vẫn cần kiểm thử khi được phép chạy ứng dụng.
