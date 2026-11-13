Đã bổ sung [Mock API bài tập](mock-api.md) để nhập dữ liệu mẫu một lần. Firestore vẫn lưu các thay đổi riêng của tài khoản; dữ liệu khách không được tự chuyển lên.

# Nối Firestore vào UTH Todo

Ứng dụng dùng Firebase Authentication để lấy UID, sau đó TaskStore nghe collection `users/{uid}/tasks`. Các màn hình tiếp tục đọc TaskScope/TaskStore như trước.

## Luồng dữ liệu

- Chưa đăng nhập: đọc/ghi công việc khách bằng shared_preferences tại khóa uth.tasks.v1.
- Đã đăng nhập: đọc snapshot và ghi công việc bằng FirestoreTaskRepository của UID đó.
- Đổi tài khoản/đăng xuất: hủy listener cũ, xóa dữ liệu tài khoản cũ khỏi UI, đóng form/chi tiết của phiên cũ và chọn nguồn tương ứng.
- Công việc khách vẫn được giữ riêng trên thiết bị; không tự động chuyển lên bất kỳ tài khoản nào.
- Đọc lỗi: hiển thị thông báo và nút Thử lại. Ghi lỗi: giữ luồng UI hiện tại và báo lỗi, không báo lưu thành công.
- Khi ghi Firestore, UI chờ Future ghi hoàn tất trước khi báo thành công. Firestore có thể phát snapshot cục bộ trước khi server xác nhận. UX ghi offline hoàn chỉnh chưa được triển khai; khi mất mạng, thao tác lưu có thể tiếp tục chờ kết nối.

## Dữ liệu Console cần có

Đúng project trong firebase_options.dart và google-services.json; collection `users/{UID của tài khoản đăng nhập}/tasks/{taskId}`.

Các trường task:

| Trường | Kiểu |
| --- | --- |
| title | string |
| note | string |
| group | study hoặc life |
| priority | low, medium hoặc high |
| due | timestamp |
| done | boolean |
| reminder | boolean |
| subtasks | array các map id/title/done; có thể rỗng |

Code tự ghi thêm remindAt và updatedAt. remindAt chỉ là dữ liệu; chưa lên lịch thông báo hệ thống hoặc FCM.

Hai nhóm UI vẫn dùng enum TaskGroup hiện có. Collection categories có thể lưu cấu hình, nhưng bước này chưa đọc nhãn danh mục động từ collection đó.

## File liên quan

- lib/services/firestore_task_repository.dart: chuyển Task/Timestamp, đọc stream, thêm/sửa/xóa theo UID.
- lib/services/task_store.dart: chọn nguồn khách/tài khoản, giữ listener, loading/error/retry và ngăn kết quả ghi của phiên cũ ảnh hưởng phiên mới.
- lib/main.dart: theo dõi authStateChanges và gắn repository theo UID, hủy listener khi đóng app.
- lib/screens/task_shell.dart: thông báo tải/lỗi, thử lại, đóng route của phiên cũ và cập nhật mô tả lưu trữ trong Cài đặt.
- lib/widgets/task_widgets.dart và lib/screens/add_task_screen.dart: thông báo lỗi Firestore rõ hơn khi thao tác.
- lib/screens/background_screen.dart: phân biệt đang tải/lỗi đọc với công việc đã bị xóa.
- test/firestore_task_store_test.dart: dùng repository giả lập để kiểm tra tách tài khoản, cập nhật stream, lỗi, thử lại và thao tác ghi đang chờ. Không truy cập Firebase thật.

## Kiểm thử thật khi sẵn sàng chạy app

1. Đăng nhập Google đúng tài khoản có UID đã tạo dữ liệu trên Console.
2. Vào Danh sách: công việc mẫu từ Firestore phải xuất hiện. Trang chủ chỉ liệt kê công việc có hạn hôm nay.
3. Thêm công việc; sau khi lưu, kiểm tra document mới trong users/{uid}/tasks.
4. Sửa tên/ngày/nhóm, tích hoàn thành và sửa việc nhỏ; đối chiếu các trường trên Console.
5. Sửa document trên Console và kiểm tra UI nhận cập nhật; xóa một công việc để kiểm tra biến mất cả hai phía.
6. Đăng xuất: về danh sách khách, không còn công việc tài khoản. Đăng nhập tài khoản B để kiểm tra không nhìn thấy công việc A.
7. Nếu permission-denied: kiểm tra Rules request.auth.uid == uid, tài khoản và UID trong đường dẫn. Nếu lỗi định dạng: kiểm tra due là timestamp và đủ trường trong bảng.

Chưa xác minh đọc/ghi Firebase thật trong workspace này. Không chạy flutter run hoặc build app trong lần tích hợp này.

## Kiểm tra code sau tích hợp

- flutter analyze: No issues found.
- flutter test: 27 tests passed (18 test hiện có + 9 test tích hợp store/Firestore giả lập).
- Không chạy app, không build và không ghi dữ liệu lên Firebase Console trong lần sửa này. Các test trên chưa xác minh Firebase Authentication, Rules hoặc dữ liệu của project thật.

