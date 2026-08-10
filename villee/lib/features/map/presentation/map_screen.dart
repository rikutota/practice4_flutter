import 'package:flutter/material.dart';

/// マップ機能を実装するための仮画面。
///
/// flutter_mapや位置情報処理は後のフェーズで追加する。
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('マップ')),
      body: const Center(child: Text('マップ画面')),
    );
  }
}
