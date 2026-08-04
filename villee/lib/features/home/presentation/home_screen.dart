import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/providers/auth_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(firebaseAuthProvider);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Villee')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(auth.currentUser?.email ?? ''),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: authState.isLoading
                  ? null
                  : () {
                      ref.read(authControllerProvider.notifier).signOut();
                    },
              child: const Text('ログアウト'),
            ),
          ],
        ),
      ),
    );
  }
}
