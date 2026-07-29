// アプリの開始地点
// 主に以下を行う
// flutterを初期化
// Firebaseを初期化
// Riverpodを有効化
// アプリ本体を起動

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/Widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: VilleeApp()));
}
