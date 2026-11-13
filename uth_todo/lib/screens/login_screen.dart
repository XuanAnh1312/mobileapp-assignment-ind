import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import '../widgets/auth_action_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, this.onContinueAsGuest});
  final VoidCallback? onContinueAsGuest;

  void _showPolicy(BuildContext context, String title) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nội dung đang được cập nhật. Vui lòng quay lại sau.',
                style: TextStyle(color: AppColors.mutedText, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.mainWhite,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        tooltip: 'Quay lại',
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                        icon: const Icon(Icons.chevron_left_rounded, size: 28),
                      ),
                      SizedBox(height: constraints.maxHeight < 650 ? 36 : 72),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.mainBlue,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x332F5BEA),
                              blurRadius: 22,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'reference/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Chào mừng đến với\nUTH Todo',
                        style: TextStyle(
                          fontSize: 30,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainBlack,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Đăng nhập để lưu công việc và đồng bộ trên mọi thiết bị của bạn.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 26),
                      const _Benefit(
                        icon: Icons.sync_rounded,
                        label: 'Tự động sao lưu, không lo mất dữ liệu',
                      ),
                      const SizedBox(height: 12),
                      const _Benefit(
                        icon: Icons.devices_rounded,
                        label: 'Đồng bộ trên điện thoại và máy tính',
                      ),
                      SizedBox(height: constraints.maxHeight < 650 ? 44 : 76),
                      AuthActionButton(
                        label: 'Tiếp tục với Google',
                        action: () => AuthService.instance.signInWithGoogle(),
                        leading: const Text(
                          'G',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4285F4),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Row(
                          children: [
                            Expanded(child: Divider(color: Color(0xFFE7E8EF))),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                'hoặc',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.mutedText,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Color(0xFFE7E8EF))),
                          ],
                        ),
                      ),
                      Center(
                        child: TextButton(
                          onPressed:
                              onContinueAsGuest ??
                              () =>
                                  Navigator.of(context)
                                      .popUntil((route) => route.isFirst),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.mainBlue,
                            minimumSize: const Size(48, 48),
                          ),
                          child: const Text(
                            'Dùng thử không cần tài khoản',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Center(
                        child: Text(
                          'Khi tiếp tục, bạn đồng ý với',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _PolicyLink(
                              label: 'Điều khoản sử dụng',
                              onPressed: () =>
                                  _showPolicy(context, 'Điều khoản sử dụng'),
                            ),
                            const Text(
                              'và',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedText,
                              ),
                            ),
                            _PolicyLink(
                              label: 'Chính sách quyền riêng tư',
                              onPressed: () => _showPolicy(
                                context,
                                'Chính sách quyền riêng tư',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: AppColors.mainBlue),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: AppColors.mainBlack,
          ),
        ),
      ),
    ],
  );
}

class _PolicyLink extends StatelessWidget {
  const _PolicyLink({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: AppColors.mutedText,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      minimumSize: const Size(48, 48),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        decoration: TextDecoration.underline,
      ),
    ),
  );
}
