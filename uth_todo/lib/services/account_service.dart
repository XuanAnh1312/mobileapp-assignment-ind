import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/account_profile.dart';
import 'auth_service.dart';

class AccountService {
  FirebaseAuth? get _auth =>
      Firebase.apps.isEmpty ? null : FirebaseAuth.instance;
  AccountProfile get current => _profile(_auth?.currentUser);
  Stream<AccountProfile> get changes =>
      _auth?.userChanges().map(_profile) ??
      Stream.value(const AccountProfile());

  AccountProfile _profile(User? user) => user == null
      ? const AccountProfile()
      : AccountProfile(
          uid: user.uid,
          name: user.displayName?.trim().isNotEmpty == true
              ? user.displayName!
              : 'Người dùng UTH',
          email: user.email,
          photoUrl: user.photoURL,
          googleLinked: user.providerData.any(
            (provider) => provider.providerId == 'google.com',
          ),
        );

  User _requireUser() {
    final user = _auth?.currentUser;
    if (user == null) throw StateError('Vui lòng đăng nhập Google trước.');
    return user;
  }

  Future<void> updateName(String name) async {
    final value = name.trim();
    if (value.isEmpty || value.length > 80) {
      throw StateError('Tên phải từ 1 đến 80 ký tự.');
    }
    await _requireUser().updateDisplayName(value);
  }

  Future<void> changeAvatar() async {
    final user = _requireUser();
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (image == null) return;
    if (_auth?.currentUser?.uid != user.uid) {
      throw StateError('Tài khoản đã thay đổi.');
    }
    final extension = image.name.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png'].contains(extension)) {
      throw StateError('Vui lòng chọn ảnh JPG hoặc PNG.');
    }
    final bytes = await image.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      throw StateError('Ảnh đại diện không được lớn hơn 5 MB.');
    }
    final ref = FirebaseStorage.instance.ref(
      'users/${user.uid}/avatars/${DateTime.now().microsecondsSinceEpoch}.$extension',
    );
    await ref.putData(
      bytes,
      SettableMetadata(
        contentType: extension == 'png' ? 'image/png' : 'image/jpeg',
      ),
    );
    try {
      final url = await ref.getDownloadURL();
      if (_auth?.currentUser?.uid != user.uid) {
        throw StateError('Tài khoản đã thay đổi.');
      }
      await user.updatePhotoURL(url);
    } catch (_) {
      try {
        await ref.delete();
      } catch (_) {
        /* Best-effort cleanup of this upload. */
      }
      rethrow;
    }
  }

  Future<void> signOut() => AuthService.instance.signOut();

  static String errorMessage(Object error) {
    if (error is StateError) return error.message.toString();
    if (error is FirebaseException && error.plugin == 'firebase_storage') {
      return 'Chưa tải được ảnh đại diện. Kiểm tra kết nối, quyền Storage và cấu hình bucket Firebase.';
    }
    return AuthService.errorMessage(error);
  }
}
