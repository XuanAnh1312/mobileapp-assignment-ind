Màn hình và luồng Navigation đã được cập nhật tiếp: xem [UI và Navigation](ui-navigation.md). Sau đăng nhập hiện trở về Trang chủ; các mô tả màn hình UID bên dưới là ghi chép của lần tích hợp Auth trước.

# Google Login — UTH Todo (Android)

## Kết quả kiểm tra cấu hình

- Flutter 3.47.9, Dart 3.13.7; mã Google dùng API google_sign_in 7.2.0.
- Firebase.initializeApp được gọi trước runApp, dùng DefaultFirebaseOptions.currentPlatform.
- firebase_options.dart và google-services.json cùng project uth-todo-xa1312 và Android app ID.
- applicationId/namespace: com.example.uth_todo. Google Services Gradle plugin và quyền INTERNET đã có.
- Lỗi cấu hình xác định được: google-services.json có oauth_client rỗng. Không có Web OAuth client để plugin lấy serverClientId; Firebase initialization thành công không có nghĩa Google Login đã được cấu hình.
- Chưa truy cập Firebase Console nên chưa xác minh provider Google hay SHA đã được thêm.

## Phạm vi sửa

- lib/screens/login_screen.dart: dùng logo reference/logo.png, bố cục theo phần Login của reference/login.png; chỉ hiển thị Google. Dùng thử và nội dung chính sách vẫn là phần giữ chỗ cũ.
- lib/screens/auth_gate.dart: chưa đăng nhập thì mở Login trực tiếp, có xử lý lỗi đọc phiên. Đăng nhập xong vẫn dùng màn hình xác nhận/UID có sẵn; đăng xuất quay lại Login.
- lib/services/auth_service.dart: giữ luồng initialize → chọn tài khoản → lấy ID token → Firebase signInWithCredential; cho phép thử lại initialization thất bại, xóa lựa chọn Google cũ trước lần đăng nhập chủ động, thông báo rõ lỗi OAuth/ID token. Web dùng Firebase popup thay cho API authenticate chỉ dành cho native.
- lib/widgets/auth_action_button.dart: thêm biểu tượng tùy chọn, chặn gọi trùng khi đang chờ; giữ loading, SnackBar và pop về route gốc sau thành công.
- pubspec.yaml: ràng buộc ba package Auth/Core/Google theo phiên bản đã cài thay vì any, không nâng major.
- test/auth_ui_test.dart: thêm kiểm tra màn hình chỉ có Google, lỗi cấu hình, hủy đăng nhập và chặn nhấn liên tục.

Không triển khai thêm phương thức đăng nhập. Code provider khác vốn có vẫn giữ nguyên nhưng không còn nút truy cập từ Login. Splash/Onboarding và các route giữa chúng được giữ trong mã nguồn. Luồng mở app hiện đi thẳng Login theo yêu cầu. Trong lib/screens chưa có màn hình quản lý công việc/Home; không tự tạo mới hoặc coi màn hình UID là Home hoàn chỉnh.

## Cấu hình Firebase Console cần thực hiện

1. Mở project uth-todo-xa1312 → Authentication → Sign-in method → Google → Enable, chọn email hỗ trợ và Save.
2. Project settings → Your apps → Android com.example.uth_todo → thêm SHA-1 và SHA-256 của chứng chỉ dùng ký APK. Lấy dấu vân tay bằng:

```powershell
cd android
.\gradlew.bat signingReport
cd ..
```

Nếu chỉ cần đọc chứng chỉ debug mặc định và có keytool trong PATH:

```powershell
keytool -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android
```

3. Tải lại google-services.json của đúng Android app, thay android/app/google-services.json. Kiểm tra oauth_client có Web client với client_type: 3. Không tự điền client ID giả, API key hay appId vào serverClientId. firebase_options.dart hiện khớp project nên không cần sửa khi chỉ thêm OAuth client/SHA.
4. Nếu vẫn lỗi cấu hình, kiểm tra Google Cloud Console → Google Auth Platform/Credentials cùng project: Web client và Android client khớp package + SHA-1; kiểm tra consent screen/audience/test users nếu ứng dụng bị giới hạn truy cập.
5. Với bản release/Play Store, thêm fingerprint đúng chứng chỉ release/Play App Signing. Cấu hình release hiện vẫn dùng debug signing, chưa phải cấu hình phát hành chính thức.

## Chạy thử

```powershell
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run -d <android-device-id>
```

Dùng máy thật có Google Play services hoặc emulator có Google Play, có mạng và có tài khoản Google. Sau khi thay file JSON phải dừng và chạy lại ứng dụng; hot reload không cập nhật cấu hình native. Nếu cần, chạy flutter clean rồi flutter pub get trước khi chạy lại.

- Chưa có phiên: mở app thấy Login; nhấn Tiếp tục với Google, chọn tài khoản.
- Chọn thành công: màn hình xác nhận hiển thị tài khoản, Firebase UID và provider google.com. Kiểm tra cùng UID/email tại Firebase Console → Authentication → Users.
- Đóng rồi mở lại: Firebase giữ phiên và vào màn hình xác nhận.
- Đăng xuất: quay về Login; đăng nhập lại để kiểm tra chọn tài khoản khác.
- Hủy chọn tài khoản hoặc mất mạng: không vào màn hình xác nhận, thông báo lỗi và nút có thể thử lại.

Widget tests chỉ xác minh giao diện/loading/lỗi, không chứng minh OAuth thật hoạt động. Chỉ được kết luận Google Login thành công sau khi thực hiện luồng thật và kiểm tra Firebase Users.

Tài liệu chính thức:
- https://pub.dev/packages/google_sign_in_android
- https://firebase.google.com/docs/auth/flutter/federated-auth

## Kết quả kiểm tra trong lần sửa này

- flutter pub get: thành công.
- flutter analyze: No issues found.
- flutter test: 8 tests passed, gồm kiểm tra điều hướng Onboarding tới Login. File test/widget_test.dart cũ rỗng được bổ sung test điều hướng để toàn bộ test suite chạy được.
- flutter devices: không có thiết bị Android kết nối. Chưa kiểm thử chọn tài khoản Google và xác thực Firebase thật.
- flutter build apk --debug: đã thử, Gradle không trả kết quả sau nhiều phút; dừng lệnh. Chưa xác nhận APK mới build thành công. APK có sẵn trong build/ có thời gian cũ, không dùng làm bằng chứng cho lần sửa này.

