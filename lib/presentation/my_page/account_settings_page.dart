import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../common/widgets/primary_app_bar.dart';

import '../../domain/notifier/auth/auth_notifier.dart'
    show AuthNotifier, AuthState;
import '../../domain/notifier/my_page/my_page_notifier.dart';
import '../../common/utils/custom_image_picker.dart';

enum AccountSettingsResult { loggedOut, usernameUpdated, accountDeleted }

enum _AccountSettingsAction { save, logout, delete }

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  static const double _avatarPreviewSize = 96;
  late final TextEditingController _usernameController;
  late final TextEditingController _deletePasswordController;
  bool _hasInitialized = false;
  bool _isProcessing = false;
  bool _isAvatarUpdating = false;
  String? _errorMessage;
  String? _deleteErrorMessage;
  String? _avatarErrorMessage;
  File? _pendingAvatarFile;
  _AccountSettingsAction? _activeAction;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _deletePasswordController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitialized) {
      return;
    }
    final myPageNotifier = context.read<MyPageNotifier>();
    final authState = context.read<AuthState>();
    final initialName = myPageNotifier.state.userName?.trim().isNotEmpty == true
        ? myPageNotifier.state.userName!.trim()
        : (authState.user?.displayName?.trim().isNotEmpty == true
            ? authState.user!.displayName!.trim()
            : (authState.user?.email ?? ''));
    _usernameController.text = initialName;
    _hasInitialized = true;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _deletePasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    final newName = _usernameController.text.trim();
    if (newName.isEmpty) {
      setState(() {
        _errorMessage = 'ニックネームを入力してください。';
      });
      return;
    }
    if (newName.characters.length > 10) {
      setState(() {
        _errorMessage = 'ニックネームは10文字以内で入力してください。';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _deleteErrorMessage = null;
      _activeAction = _AccountSettingsAction.save;
    });

    final notifier = context.read<MyPageNotifier>();
    final success = await notifier.updateUsername(newName);

    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessing = false;
      _activeAction = null;
    });

    if (success) {
      Navigator.of(context).pop(AccountSettingsResult.usernameUpdated);
    } else {
      setState(() {
        _errorMessage = 'ニックネームの更新に失敗しました。時間をおいて再度お試しください。';
      });
    }
  }

  Future<void> _handleLogout() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _deleteErrorMessage = null;
      _activeAction = _AccountSettingsAction.logout;
    });

    final authNotifier = context.read<AuthNotifier>();
    authNotifier.clearMessages();
    await authNotifier.signOut();

    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessing = false;
      _activeAction = null;
    });

    final authState = context.read<AuthState>();
    if (authState.errorMessage != null) {
      setState(() {
        _errorMessage = authState.errorMessage;
      });
      return;
    }

    Navigator.of(context).pop(AccountSettingsResult.loggedOut);
  }

  Future<void> _handleDeleteAccount() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _deleteErrorMessage = null;
    });

    final password = await _promptDeleteConfirmation();
    if (password == null) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _deleteErrorMessage = null;
      _activeAction = _AccountSettingsAction.delete;
    });

    final authNotifier = context.read<AuthNotifier>();
    final result = await authNotifier.deleteAccount(password);

    if (!mounted) {
      return;
    }

    if (result.isSuccess) {
      setState(() {
        _isProcessing = false;
        _activeAction = null;
      });
      if (mounted) {
        Navigator.of(context).pop(AccountSettingsResult.accountDeleted);
      }
      return;
    }

    setState(() {
      _isProcessing = false;
      _activeAction = null;
      _deleteErrorMessage = result.message;
    });
  }

  Future<String?> _promptDeleteConfirmation() async {
    _deletePasswordController.clear();
    String? validationMessage;
    bool obscureText = true;

    return showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1D3567),
              title: const Text(
                'アカウント削除の確認',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'アカウントを削除すると、保存酒・お気に入り・嗜好設定などのデータはすべて削除されます。',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '確認のため、パスワードを入力してください。',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _deletePasswordController,
                      obscureText: obscureText,
                      autofocus: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        hintText: 'パスワード',
                        hintStyle: const TextStyle(color: Colors.white54),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              obscureText = !obscureText;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (validationMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          validationMessage!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(null);
                  },
                  child: const Text(
                    'キャンセル',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final password = _deletePasswordController.text.trim();
                    if (password.isEmpty) {
                      setState(() {
                        validationMessage = 'パスワードを入力してください。';
                      });
                      return;
                    }
                    if (password.length < 6) {
                      setState(() {
                        validationMessage = 'パスワードは6文字以上で入力してください。';
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(password);
                  },
                  child: const Text(
                    '削除する',
                    style: TextStyle(color: Color(0xFFFF8A65)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleChangeAvatar() async {
    FocusScope.of(context).unfocus();
    final source = await _showImageSourceSheet();
    if (source == null) {
      return;
    }

    final file = await CustomImagePicker.pickImage(source: source);
    if (file == null) {
      return;
    }

    setState(() {
      _pendingAvatarFile = file;
      _isAvatarUpdating = true;
      _avatarErrorMessage = null;
    });

    final notifier = context.read<MyPageNotifier>();
    final success = await notifier.updateUserPhoto(file);

    if (!mounted) {
      return;
    }

    setState(() {
      _isAvatarUpdating = false;
      _pendingAvatarFile = null;
      if (!success) {
        _avatarErrorMessage = 'アイコンの更新に失敗しました。時間をおいて再度お試しください。';
      }
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('アイコンを更新しました。')),
      );
    }
  }

  Future<ImageSource?> _showImageSourceSheet() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF14264A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white70),
                title: const Text(
                  'フォトライブラリから選択',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.white70),
                title: const Text(
                  'カメラで撮影',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarPreview(String? iconUrl) {
    Widget placeholder() {
      return Container(
        width: _avatarPreviewSize,
        height: _avatarPreviewSize,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.person,
          color: Colors.white70,
          size: 40,
        ),
      );
    }

    if (_pendingAvatarFile != null) {
      return SizedBox(
        width: _avatarPreviewSize,
        height: _avatarPreviewSize,
        child: ClipOval(
          child: Image.file(
            _pendingAvatarFile!,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final trimmed = iconUrl?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return SizedBox(
        width: _avatarPreviewSize,
        height: _avatarPreviewSize,
        child: ClipOval(
          child: Image.network(
            trimmed,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => placeholder(),
          ),
        ),
      );
    }

    return placeholder();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final email = authState.user?.email ?? '未設定';
    final myPageState = context.watch<MyPageState>();
    final iconUrl = myPageState.userIconUrl;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1D3567), Color(0xFF0A1428)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const PrimaryAppBar(
          title: 'アカウント設定',
          titleFontSize: 18,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildAvatarPreview(iconUrl),
                          if (_isAvatarUpdating)
                            Container(
                              width: _avatarPreviewSize,
                              height: _avatarPreviewSize,
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white70),
                              ),
                            ),
                        ],
                      ),
                      if (_avatarErrorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _avatarErrorMessage!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed:
                            _isAvatarUpdating ? null : _handleChangeAvatar,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        icon: Icon(
                          _isAvatarUpdating
                              ? Icons.hourglass_top
                              : Icons.image_outlined,
                          color: Colors.white70,
                        ),
                        label: Text(
                          _isAvatarUpdating ? '更新中...' : 'アイコンを変更',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ニックネーム',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _usernameController,
                        enabled: !_isProcessing,
                        maxLength: 10,
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          hintText: '例）日本酒好き太郎',
                          hintStyle: const TextStyle(color: Colors.white38),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: Color(0xFFFFD54F)),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD54F),
                            foregroundColor: const Color(0xFF1D3567),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isProcessing
                              ? _activeAction == _AccountSettingsAction.save
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Color(0xFF1D3567),
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'ニックネームを保存',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    )
                              : const Text(
                                  'ニックネームを保存',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.mail_outline,
                              color: Color(0xFFFFD54F)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'メールアドレス',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '※ 現在アプリ内でメールアドレスの変更はできません。',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing ? null : _handleLogout,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.4),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: _activeAction == _AccountSettingsAction.logout
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Color(0xFFFF8A65),
                                    ),
                                  ),
                                )
                              : const Icon(Icons.logout,
                                  color: Color(0xFFFF8A65)),
                          label: Text(
                            _activeAction == _AccountSettingsAction.logout
                                ? 'ログアウト中...'
                                : 'ログアウト',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.delete_forever, color: Color(0xFFFF8A65)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'アカウント削除',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'アカウントを削除すると、保存酒・お気に入り・嗜好設定などのデータはすべて削除されます。削除後は元に戻せません。',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      if (_deleteErrorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _deleteErrorMessage!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed:
                              _isProcessing ? null : _handleDeleteAccount,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF8A65),
                            side: BorderSide(
                              color: const Color(0xFFFF8A65).withOpacity(0.6),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _activeAction == _AccountSettingsAction.delete
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Color(0xFFFF8A65),
                                    ),
                                  ),
                                )
                              : const Text(
                                  'アカウントを削除する',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
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
    );
  }
}
