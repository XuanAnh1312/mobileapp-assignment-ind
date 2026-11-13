# Hồ sơ tài khoản — theo reference/login.png

Ảnh hiện tại là màn Hồ sơ. Cài đặt → Tài khoản mở AccountScreen thay cho bottom sheet tài khoản cũ. Avatar Trang chủ mở cùng màn hình.

## Navigation và thao tác

- Từ Cài đặt: mở Hồ sơ; nút Cài đặt hoặc system Back trở về sheet Cài đặt.
- Từ avatar Trang chủ: mở Hồ sơ; quay lại về Trang chủ.
- Chưa đăng nhập: hiển thị Khách, không giả tên/email/Google liên kết. Nút đăng nhập, Sửa hoặc camera mở LoginScreen có sẵn.
- Trong Login: Quay lại về Hồ sơ; Dùng thử không cần tài khoản về Trang chủ, không mở lại sheet Cài đặt. Google Login giữ AuthService hiện tại và về Trang chủ sau thành công.
- Đã đăng nhập: tên, email, avatar và trạng thái Google lấy từ Firebase Auth. MA chỉ xuất hiện nếu chữ cái đầu tên phù hợp, không cố định cho mọi tài khoản.
- Sửa mở form tên hiển thị, kiểm tra rỗng/độ dài và lưu bằng updateDisplayName. Profile và avatar/tên trên Home nhận userChanges.
- Camera mở bộ chọn ảnh, nhận JPG/PNG tối đa 5 MB, upload Storage tại users/{uid}/avatars rồi cập nhật photoURL trong Firebase Auth. Nếu lỗi, không thay ảnh bằng kết quả giả. Tính năng này cần bucket/Rules Storage được cấu hình; chưa thử upload thật trong lần sửa này.
- Đồng bộ dữ liệu đọc trực tiếp Firestore server. Vừa xong chỉ xuất hiện sau lần xác nhận thành công (đọc server hoặc ghi hoàn tất), không dùng một nhãn cố định.
- Quyền riêng tư mở một route nội dung thật và có thể quay về Hồ sơ.
- Đăng xuất dùng AuthService hiện có, trở về Trang chủ khách và không mở lại Cài đặt. Việc chuyển dữ liệu tài khoản/khách giữ logic TaskStore đã có.

## Thống kê

- Việc đã xong: đếm task.done.
- Chuỗi liên tiếp: các ngày có completedAt được ghi nhận, kết thúc hôm nay hoặc hôm qua.
- Đúng hạn: số việc có completedAt <= due chia cho số việc hoàn thành có completedAt.
- Dữ liệu cũ/API không có completedAt không bị đoán thời gian hoàn thành từ hạn chót. Nếu chưa đủ dữ liệu, hiển thị —.
- Tuần này: tổng và số việc đã xong có hạn từ thứ Hai tới hết Chủ nhật; biểu đồ thể hiện lượng công việc theo ngày. Không hardcode số 128/12/86 hay chiều cao cột theo ảnh.

Task bổ sung completedAt tùy chọn; dữ liệu cũ vẫn đọc được. Toggle hoàn thành ghi thời gian hiện tại; đánh dấu chưa xong xóa thời gian này. Khi sửa tên/ghi chú công việc vẫn giữ thời điểm hoàn thành. Trên Firestore completedAt được lưu dạng timestamp, cục bộ lưu ISO string.

Tên/email/ảnh trong UI lấy từ Firebase Auth; trường displayName/photoURL thủ công trong document users cũ không phải nguồn hiển thị của màn này.

## File

Tạo:
- lib/screens/account_screen.dart: UI Hồ sơ, form sửa tên, nội dung quyền riêng tư.
- lib/services/account_service.dart: đọc userChanges, cập nhật tên/ảnh và tái sử dụng signOut.
- lib/models/account_profile.dart, task_statistics.dart: thông tin hiển thị và tính thống kê.
- test/account_screen_test.dart: Navigation, thao tác, dữ liệu và responsive.

Sửa:
- lib/screens/task_shell.dart: route Hồ sơ và quay về đúng màn trước.
- lib/screens/login_screen.dart: callback quay về chế độ khách.
- lib/models/task.dart: completedAt tùy chọn, tương thích dữ liệu cũ.
- lib/services/task_store.dart: ghi thời điểm hoàn thành và đồng bộ server có xác nhận.
- lib/services/firestore_task_repository.dart: chuyển completedAt/Timestamp và đọc server.
- test/firestore_task_store_test.dart: kiểm tra đồng bộ thành công/lỗi, không báo thành công giả.

## Kiểm tra

flutter analyze: No issues found.
flutter test: 55 tests passed, gồm 44 test hiện có, 10 test Hồ sơ/thống kê và 1 test đồng bộ server.

Đã kiểm tra 320×568, 390×844, 768×1024 với chữ 150%; cuộn tới nút cuối không overflow. Đã render widget để đối chiếu trực quan với ảnh. Không khôi phục Widget Preview, không chạy flutter run, không build app và không sửa cấu hình Firebase Console.

Chưa kiểm thử đăng nhập/đăng xuất thật, cập nhật Firebase Auth, upload Storage hay đồng bộ Firestore trên thiết bị thật. Các thao tác backend được kiểm tra bằng fake service/repository trong test.
