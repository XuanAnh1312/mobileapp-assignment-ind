import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/account_profile.dart';
import '../models/task_statistics.dart';
import '../services/account_service.dart';
import '../services/task_store.dart';
import '../widgets/task_widgets.dart';
import 'login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, this.backLabel = 'Cài đặt', this.service});
  final String backLabel;
  final AccountService? service;
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final AccountService _service = widget.service ?? AccountService();
  late final Stream<AccountProfile> _profiles = _service.changes;
  bool _busy = false;

  Future<void> _login() async {
    final guest = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (loginContext) => LoginScreen(
          onContinueAsGuest: () => Navigator.pop(loginContext, true),
        ),
      ),
    );
    if (guest == true && mounted) Navigator.pop(context, false);
  }

  Future<void> _edit(AccountProfile profile) async {
    if (!profile.signedIn) {
      _login();
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _EditProfileScreen(service: _service, profile: profile),
      ),
    );
  }

  Future<void> _avatar(AccountProfile profile) async {
    if (!profile.signedIn) {
      _login();
      return;
    }
    setState(() => _busy = true);
    try {
      await _service.changeAvatar();
    } catch (error) {
      _message(AccountService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _sync(AccountProfile profile) async {
    if (!profile.signedIn) {
      _login();
      return;
    }
    final store = TaskScope.of(context);
    setState(() => _busy = true);
    try {
      await store.syncNow();
      _message('Đã đồng bộ dữ liệu.');
    } catch (error) {
      _message(TaskStore.errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _busy = true);
    try {
      await _service.signOut();
      if (mounted) Navigator.pop(context, false);
    } catch (error) {
      _message(AccountService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<AccountProfile>(
    stream: _profiles,
    initialData: _service.current,
    builder: (context, snapshot) {
      final profile = snapshot.data ?? const AccountProfile();
      final store = TaskScope.of(context);
      final stats = TaskStatistics(store.tasks);
      final lastSync = store.lastSyncedAt;
      final syncLabel =
          _busy || store.loading || store.saving || store.apiLoading
          ? 'Đang xử lý…'
          : !profile.signedIn
          ? 'Chưa đăng nhập'
          : store.syncError != null
          ? 'Thử lại'
          : lastSync == null
          ? 'Chưa xác nhận'
          : DateTime.now().difference(lastSync).inMinutes < 1
          ? 'Vừa xong'
          : taskTime(lastSync);
      return Scaffold(
        backgroundColor: taskBackground,
        appBar: AppBar(
          backgroundColor: taskBackground,
          elevation: 0,
          centerTitle: true,
          leadingWidth: 120,
          leading: TextButton.icon(
            onPressed: _busy ? null : () => Navigator.maybePop(context),
            icon: const Icon(Icons.chevron_left, size: 20),
            label: Text(widget.backLabel, style: const TextStyle(fontSize: 13)),
          ),
          title: const Text(
            'Hồ sơ',
            style: TextStyle(
              color: AppColors.mainBlack,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: _busy ? null : () => _edit(profile),
              child: const Text('Sửa'),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 30).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: SizedBox(
                          width: 88,
                          height: 88,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 4,
                                top: 0,
                                child: CircleAvatar(
                                  radius: 38,
                                  backgroundColor: const Color(0xFFE7ECFF),
                                  child: profile.photoUrl != null
                                      ? ClipOval(
                                          child: Image.network(
                                            profile.photoUrl!,
                                            width: 76,
                                            height: 76,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                _Initials(profile: profile),
                                          ),
                                        )
                                      : _Initials(profile: profile),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 3,
                                child: Semantics(
                                  button: true,
                                  label: 'Đổi ảnh đại diện',
                                  child: InkWell(
                                    onTap: _busy
                                        ? null
                                        : () => _avatar(profile),
                                    borderRadius: BorderRadius.circular(22),
                                    child: Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: AppColors.mainBlue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: taskBackground,
                                          width: 2,
                                        ),
                                      ),
                                      child: _busy
                                          ? const SizedBox(
                                              width: 15,
                                              height: 15,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.camera_alt_outlined,
                                              color: Colors.white,
                                              size: 15,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        profile.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        profile.email ??
                            'Đăng nhập để lưu công việc theo tài khoản',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: taskMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: profile.googleLinked
                                ? const Color(0xFFDDF7ED)
                                : const Color(0xFFE8E8EE),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            profile.googleLinked
                                ? '✓ Đã liên kết tài khoản Google'
                                : 'Chưa liên kết tài khoản Google',
                            style: TextStyle(
                              fontSize: 10,
                              color: profile.googleLinked
                                  ? const Color(0xFF16815E)
                                  : taskMuted,
                            ),
                          ),
                        ),
                      ),
                      if (snapshot.hasError)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Chưa tải được thông tin tài khoản.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 20),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _Stat(
                                value: '${stats.completed}',
                                label: 'Việc đã xong',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Tooltip(
                                message: 'Chuỗi tính theo thời điểm hoàn thành đã ghi nhận. Dữ liệu cũ có thể chưa đủ thông tin.',
                                child: _Stat(
                                  value: stats.streak == null
                                      ? '—'
                                      : '${stats.streak} ngày',
                                  label: 'Chuỗi liên tiếp',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Stat(
                                value: stats.onTimePercent == null
                                    ? '—'
                                    : '${stats.onTimePercent}%',
                                label: 'Đúng hạn',
                                tooltip: 'Tỷ lệ đúng hạn chỉ tính những việc có ghi nhận thời gian hoàn thành.',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _WeekChart(stats: stats),
                      const SizedBox(height: 16),
                      TaskPanel(
                        child: Column(
                          children: [
                            _AccountRow(
                              icon: Icons.sync,
                              title: 'Đồng bộ dữ liệu',
                              value: syncLabel,
                              onTap: _busy ? null : () => _sync(profile),
                            ),
                            const Divider(height: 1, color: taskBackground),
                            _AccountRow(
                              icon: Icons.lock_outline,
                              title: 'Quyền riêng tư',
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: taskMuted,
                                size: 19,
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const _PrivacyScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 44),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: _busy
                              ? null
                              : profile.signedIn
                              ? _logout
                              : _login,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: profile.signedIn
                                ? const Color(0xFFE44739)
                                : AppColors.mainBlue,
                            minimumSize: const Size(0, 54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          icon: Icon(
                            profile.signedIn ? Icons.logout : Icons.login,
                            size: 19,
                          ),
                          label: Text(
                            profile.signedIn
                                ? 'Đăng xuất'
                                : 'Đăng nhập bằng Google',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _Initials extends StatelessWidget {
  const _Initials({required this.profile});
  final AccountProfile profile;
  @override
  Widget build(BuildContext context) => profile.signedIn
      ? Text(
          profile.initials,
          style: const TextStyle(
            color: Color(0xFF2450DA),
            fontSize: 27,
            fontWeight: FontWeight.w700,
          ),
        )
      : const Icon(Icons.person_outline, color: AppColors.mainBlue, size: 34);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.tooltip});
  final String value;
  final String label;
  final String? tooltip;
  @override
  Widget build(BuildContext context) {
    final panel = TaskPanel(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 10, color: taskMuted)),
        ],
      ),
    );
    return tooltip == null ? panel : Tooltip(message: tooltip!, child: panel);
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.stats});
  final TaskStatistics stats;
  @override
  Widget build(BuildContext context) {
    final maxCount = stats.days.fold<int>(
      1,
      (max, value) => value > max ? value : max,
    );
    return TaskPanel(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tuần này',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${stats.completedThisWeek}/${stats.totalThisWeek} việc',
                style: const TextStyle(color: taskMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 94,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final selected = index + 1 == DateTime.now().weekday;
                return Expanded(
                  child: Semantics(
                    label:
                        '${index == 6 ? 'Chủ nhật' : 'Thứ ${index + 2}'}: ${stats.days[index]} công việc',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: stats.days[index] == 0
                                ? 9
                                : 14 + stats.days[index] / maxCount * 54,
                            decoration: BoxDecoration(
                              color: stats.days[index] == 0
                                  ? const Color(0xFFE5E5EB)
                                  : selected
                                  ? AppColors.mainBlue
                                  : const Color(0xFFB7C6FF),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          const SizedBox(height: 7),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              index == 6 ? 'CN' : 'T${index + 2}',
                              style: TextStyle(
                                fontSize: 10,
                                color: selected
                                    ? AppColors.mainBlue
                                    : taskMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final String? value;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
      child: Row(
        children: [
          Icon(icon, color: taskMuted, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 13))),
          const SizedBox(width: 8),
          if (value != null)
            Flexible(
              fit: FlexFit.tight,
              child: Text(
                value!,
                textAlign: TextAlign.right,
                style: const TextStyle(color: taskMuted, fontSize: 11),
              ),
            ),
          ?trailing,
        ],
      ),
    ),
  );
}

class _EditProfileScreen extends StatefulWidget {
  const _EditProfileScreen({required this.service, required this.profile});
  final AccountService service;
  final AccountProfile profile;
  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.name);
  bool _saving = false;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.service.updateName(_name.text);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AccountService.errorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: taskBackground,
    appBar: AppBar(
      backgroundColor: taskBackground,
      elevation: 0,
      foregroundColor: AppColors.mainBlack,
      title: const Text('Sửa hồ sơ'),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            children: [
              TaskPanel(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  key: const Key('profile-name'),
                  controller: _name,
                  enabled: !_saving,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Tên hiển thị'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Vui lòng nhập tên hiển thị.'
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              if (widget.profile.email != null)
                Text(
                  widget.profile.email!,
                  style: const TextStyle(color: taskMuted),
                ),
              const SizedBox(height: 24),
              PrimaryTaskButton(
                label: _saving ? 'Đang lưu…' : 'Lưu thay đổi',
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PrivacyScreen extends StatelessWidget {
  const _PrivacyScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: taskBackground,
    appBar: AppBar(
      backgroundColor: taskBackground,
      elevation: 0,
      foregroundColor: AppColors.mainBlack,
      title: const Text('Quyền riêng tư'),
    ),
    body: const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dữ liệu của bạn',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 20),
          Text(
            '• Tài khoản Google được dùng để xác thực và hiển thị tên, email, ảnh đại diện.\n\n'
            '• Khi đăng nhập, công việc được lưu theo tài khoản. Khi dùng khách, công việc được lưu trên thiết bị.\n\n'
            '• Nếu bạn đổi ảnh đại diện, ảnh được tải lên bộ nhớ của ứng dụng.\n\n'
            '• Đăng xuất không xóa công việc của tài khoản. Bạn có thể xóa từng công việc trong màn hình Chi tiết.\n\n'
            '• Dữ liệu mẫu bài tập được nhập riêng và không tự chuyển công việc cá nhân của khách lên tài khoản.',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    ),
  );
}
