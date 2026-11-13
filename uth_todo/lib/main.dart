import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'constants/app_colors.dart';
import 'firebase_options.dart';
import 'screens/start_screen.dart';
import 'services/task_store.dart';
import 'services/firestore_task_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const UTHTodoApp());
}

class UTHTodoApp extends StatefulWidget {
  const UTHTodoApp({super.key});

  @override
  State<UTHTodoApp> createState() => _UTHTodoAppState();
}

class _UTHTodoAppState extends State<UTHTodoApp> {
  late Future<TaskStore> _store = _loadStore();
  TaskStore? _loaded;
  StreamSubscription<User?>? _authSubscription;
  String? _activeUid;

  Future<TaskStore> _loadStore() async {
    final store = await TaskStore.load();
    if (!mounted) {
      store.dispose();
      throw StateError('Ứng dụng đã đóng.');
    }
    _loaded = store;
    final auth = FirebaseAuth.instance;
    _activeUid = auth.currentUser?.uid;
    if (_activeUid != null) {
      store.bindRepository(FirestoreTaskRepository(uid: _activeUid!));
    }
    _authSubscription = auth.authStateChanges().listen((user) {
      final uid = user?.uid;
      if (uid == _activeUid) return;
      _activeUid = uid;
      store.bindRepository(
        uid == null ? null : FirestoreTaskRepository(uid: uid),
      );
    }, onError: (Object error) => store.reportSyncError(error));
    unawaited(store.initializeMockApi());
    return store;
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    _loaded?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<TaskStore>(
    future: _store,
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: snapshot.hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Không thể đọc công việc đã lưu.'),
                        TextButton(
                          onPressed: () =>
                              setState(() => _store = _loadStore()),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        );
      }
      _loaded = snapshot.data!;
      return TaskScope(
        store: snapshot.data!,
        child: MaterialApp(
          locale: const Locale('vi'),
          supportedLocales: const [Locale('vi'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          title: 'UTH Todo',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.mainBlue)
                .copyWith(
                  primary: AppColors.mainBlue,
                  secondary: AppColors.mainBlue,
                ),
            scaffoldBackgroundColor: AppColors.mainWhite,
            fontFamily: 'Roboto',
            useMaterial3: false,
          ),
          home: const StartScreen(),
        ),
      );
    },
  );
}
