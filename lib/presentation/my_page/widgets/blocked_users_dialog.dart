import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/repository/saved_sake_sync_repository.dart';

class BlockedUsersDialog extends StatefulWidget {
  const BlockedUsersDialog({super.key});
  @override
  State<BlockedUsersDialog> createState() => _BlockedUsersDialogState();
}

class _BlockedUsersDialogState extends State<BlockedUsersDialog> {
  List<Map<String, dynamic>>? _users;
  String? _error;
  String? _pending;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final users = await context
          .read<SavedSakeSyncRepository>()
          .blockedUsers();
      if (mounted)
        setState(() {
          _users = users;
          _error = null;
        });
    } catch (_) {
      if (mounted) setState(() => _error = '一覧を取得できませんでした。');
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('ブロックしたユーザー'),
    content: SizedBox(
      width: double.maxFinite,
      child: _error != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!),
                TextButton(onPressed: _load, child: const Text('再試行')),
              ],
            )
          : _users == null
          ? const Center(heightFactor: 2, child: CircularProgressIndicator())
          : _users!.isEmpty
          ? const Text('ブロックしたユーザーはいません。')
          : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView(
                shrinkWrap: true,
                children: _users!
                    .map(
                      (user) => ListTile(
                        title: Text(user['username'] as String? ?? 'ユーザー'),
                        trailing: TextButton(
                          onPressed: _pending != null
                              ? null
                              : () async {
                                  setState(
                                    () => _pending = user['id'] as String,
                                  );
                                  try {
                                    await context
                                        .read<SavedSakeSyncRepository>()
                                        .unblockUser(user['id'] as String);
                                    if (mounted)
                                      setState(() => _users!.remove(user));
                                  } catch (_) {
                                    if (mounted)
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            '解除できませんでした。もう一度お試しください。',
                                          ),
                                        ),
                                      );
                                  } finally {
                                    if (mounted)
                                      setState(() => _pending = null);
                                  }
                                },
                          child: Text(_pending == user['id'] ? '解除中…' : '解除'),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('閉じる'),
      ),
    ],
  );
}
