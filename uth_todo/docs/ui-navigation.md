Luồng Cài đặt → Tài khoản đã đổi sang [Hồ sơ theo login.png](account-screen.md).

Phần lưu trữ đã được cập nhật: tài khoản đăng nhập dùng Firestore, khách dùng dữ liệu cục bộ. Xem [hướng dẫn Firestore](firestore.md). Các mô tả chỉ lưu cục bộ bên dưới là ghi chép của giai đoạn UI ban đầu.

# UI và Navigation — UTH Todo

## Bốn màn hình

- **Trang chủ** (`home_screen.dart`): avatar tài khoản, ngày hiện tại, tiến độ hôm nay, hai nhóm và công việc hôm nay. Tiến độ/số lượng tính từ dữ liệu thật; không tự tạo công việc giả khi chạy lần đầu.
- **Danh sách** (`task_list_screen.dart`): tìm theo tên, lọc Tất cả/Học tập/Cuộc sống, tách Cần làm/Đã xong, đánh dấu hoàn thành, mở chi tiết.
- **Thêm mới/Sửa** (`add_task_screen.dart`): tên bắt buộc, ghi chú, nhóm, chọn ngày/giờ, nhắc trước 15 phút và mức ưu tiên. Hủy không lưu. Sửa giữ nguyên trạng thái hoàn thành và việc nhỏ.
- **Background/Chi tiết** (`background_screen.dart`): dựng bằng widget theo Background.jpg, là một route riêng. Nội dung cuộn dọc tự nhiên, không ép hoặc kéo giãn ảnh. Có sửa công việc, thêm/sửa/xóa/tích việc nhỏ, tiến độ việc nhỏ, hoàn thành/chưa hoàn thành và xác nhận trước khi xóa công việc.

Màu nền #F5F5F7, thẻ trắng, màu chính #2F5BEA, bo góc và bố cục được đối chiếu đủ 4 ảnh. Phần nền đen, nhãn Section và khung điện thoại trong ảnh tham khảo không phải nội dung ứng dụng.

## Navigation

```text
Splash hiện có → Onboarding 1 → 2 → 3 → Bắt đầu ngay → TaskShell (Trang chủ)
                                                         ├─ Danh sách
                                                         ├─ + → Thêm mới → Lưu → Danh sách
                                                         ├─ Công việc → Background/Chi tiết → Sửa → Lưu → Chi tiết
                                                         ├─ Chuông/Thông báo → Danh sách nhắc nhở trong app
                                                         └─ Avatar/Cài đặt → Tài khoản → Google Login hiện có
```

- Giữ nguyên các màn Onboarding và nút Tiếp tục/Bỏ qua; chỉ đổi đích cuối sang Trang chủ theo yêu cầu mới.
- Khi hoàn thành Onboarding, xóa các route giới thiệu khỏi stack để Back không mở lại chúng.
- `TaskShell` giữ một thanh điều hướng dùng chung. Trang chủ/Danh sách giữ trạng thái trong IndexedStack.
- Back Android từ tab Danh sách về Trang chủ. Form/Chi tiết dùng Navigator.push/pop để trở về màn trước.
- Lưu từ nút + về Danh sách và bỏ bộ lọc để công việc mới nhìn thấy được. Sửa từ Chi tiết thì trở lại Chi tiết.
- Avatar khách dùng icon người dùng. Đã đăng nhập thì dùng ảnh Firebase, hoặc chữ cái đầu tên (Minh Anh → MA), không cố định MA cho mọi người.
- AuthGate chỉ được chỉnh đích điều hướng sau xác thực; không sửa thuật toán Firebase/Google trong auth_service.dart.

## Dữ liệu được chia sẻ như thế nào?

- `models/task.dart`: Task, Subtask, nhóm và ưu tiên; copyWith tạo bản mới, nên dữ liệu nhập dở không thay đổi danh sách.
- `services/task_store.dart`: một ChangeNotifier giữ danh sách và thực hiện thêm/sửa/xóa/toggle. TaskScope đặt phía trên MaterialApp để mọi route dùng cùng một store.
- Thêm `shared_preferences` để lưu danh sách JSON trên thiết bị, đọc lại khi mở app. Chỉ cập nhật UI sau khi lưu thành công; lỗi đọc/ghi có thông báo, không báo thành công giả.
- Thêm `flutter_localizations` từ Flutter SDK để lịch/bộ chọn giờ hiển thị tiếng Việt.
- `widgets/task_widgets.dart`: tái sử dụng card, badge nhóm, nút hoàn thành, nút chính và định dạng ngày/giờ.

Dữ liệu hiện là cục bộ cho thiết bị, dùng chung giữa chế độ khách và tài khoản trên thiết bị đó; chưa chia theo UID, chưa đồng bộ Firebase. Tùy chọn Nhắc tôi được lưu và hiển thị ở mục Thông báo trong app; chưa lên lịch thông báo hệ thống khi đóng app. Lặp lại giữ giá trị Không theo thiết kế; chưa triển khai công việc định kỳ.

## File tạo và sửa

Tạo: `lib/models/task.dart`, `lib/services/task_store.dart`, `lib/widgets/task_widgets.dart`, `lib/screens/home_screen.dart`, `task_list_screen.dart`, `add_task_screen.dart`, `background_screen.dart`, `task_shell.dart`, `test/task_flow_test.dart`, tài liệu này.

Sửa: `lib/main.dart` (nạp dữ liệu + TaskScope + tiếng Việt + khôi phục điểm vào Splash), `lib/screens/onboarding_step_three_screen.dart` (đi Trang chủ), `lib/screens/auth_gate.dart` (trở lại Home sau đăng nhập), `pubspec.yaml`, `pubspec.lock`, `test/widget_test.dart` (luồng Onboarding mới).

## Chạy thử thủ công

```powershell
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run -d <device-id>
```

1. Đi đủ 3 bước Onboarding, nhấn Bắt đầu ngay. Kiểm tra Trang chủ và Back không trở lại Onboarding.
2. Nhấn +, thử lưu tên rỗng, rồi nhập tên/ghi chú; thay nhóm/ngày/giờ/ưu tiên, bật/tắt Nhắc tôi và lưu. Công việc xuất hiện ở Danh sách.
3. Tìm kiếm/lọc nhóm; mở chi tiết; sửa và kiểm tra danh sách cập nhật.
4. Thêm/sửa/xóa/tích việc nhỏ; kiểm tra tỷ lệ; thêm nội dung dài và cuộn tới cuối màn Background.
5. Hoàn thành/chưa hoàn thành; kiểm tra tiến độ hôm nay và số việc còn lại. Công việc ngày khác không tính vào tiến độ hôm nay.
6. Xóa công việc: thử Hủy rồi xác nhận Xóa. Đóng/mở lại ứng dụng để kiểm tra dữ liệu còn đúng.
7. Mở avatar khi có tài khoản Google thật, kiểm tra ảnh/tên, đăng xuất/đăng nhập và không xuất hiện hai thanh điều hướng.
8. Kiểm tra bàn phím, system Back, vùng an toàn và font tiếng Việt trên Android thật.

Bộ widget tests kiểm tra ba kích thước 320×568, 390×844, 768×1024, chữ lớn 150%, bàn phím giả lập, lưu dữ liệu và các thao tác nêu trên. Chúng không thay thế thử nghiệm thiết bị/Google Login thật.

## Kết quả kiểm tra

- flutter pub get: thành công.
- flutter analyze: No issues found.
- flutter test: 18 tests passed (gồm các test Auth hiện có, Navigation, dữ liệu và UI mới).
- Đã phát hiện/sửa lỗi tràn ngang tiêu đề Danh sách với chữ 150% trên màn 320px; chỉnh căn phải ngày/giờ và tránh tạo thêm TaskShell sau Google Login; xóa tìm kiếm cũ sau khi thêm mới để công việc vừa lưu luôn xuất hiện.
- flutter build web --no-wasm-dry-run: thành công.
- Lệnh build Android trước đó đã hoàn tất trước khi nhận được yêu cầu dừng. Không chạy thêm lệnh build app theo yêu cầu mới của người dùng.
- Không có Android kết nối trong flutter devices; chưa kiểm thử tương tác trên thiết bị thật.



