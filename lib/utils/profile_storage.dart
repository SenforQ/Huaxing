import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileEditState {
  const ProfileEditState({
    required this.nickname,
    required this.signature,
    required this.avatarRelativePath,
  });

  final String nickname;
  final String signature;
  final String? avatarRelativePath;
}

class ProfileStorage {
  ProfileStorage._();

  static const String keyNickname = 'profile_nickname';
  static const String keySignature = 'profile_signature';
  static const String keyAvatarRelative = 'profile_avatar_relative_path';

  static const String defaultNickname = '花杏';

  static const String avatarRelativeFolder = 'profile';
  static const String avatarFileName = 'user_avatar.jpg';

  static String get standardAvatarRelativePath =>
      '$avatarRelativeFolder/$avatarFileName';

  static Future<Directory> documentsDirectory() async {
    return getApplicationDocumentsDirectory();
  }

  static Future<File> fileFromRelative(String relativePath) async {
    final doc = await documentsDirectory();
    return File(p.join(doc.path, relativePath));
  }

  static Future<bool> relativeFileExists(String? relativePath) async {
    if (relativePath == null || relativePath.isEmpty) return false;
    final f = await fileFromRelative(relativePath);
    return f.existsSync();
  }

  static Future<ProfileEditState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawNick = prefs.getString(keyNickname);
    final rawSig = prefs.getString(keySignature);
    final rawAvatar = prefs.getString(keyAvatarRelative);

    final nickname =
        (rawNick != null && rawNick.trim().isNotEmpty) ? rawNick.trim() : defaultNickname;
    final signature = rawSig ?? '';

    String? avatarRel = rawAvatar;
    if (avatarRel != null &&
        avatarRel.isNotEmpty &&
        !await relativeFileExists(avatarRel)) {
      avatarRel = null;
    }

    return ProfileEditState(
      nickname: nickname,
      signature: signature,
      avatarRelativePath: avatarRel,
    );
  }

  static Future<void> save({
    required String nickname,
    required String signature,
    required String? avatarRelativePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyNickname, nickname.trim());
    await prefs.setString(keySignature, signature.trim());
    final rel = avatarRelativePath?.trim();
    if (rel != null && rel.isNotEmpty) {
      await prefs.setString(keyAvatarRelative, rel);
    } else {
      await prefs.remove(keyAvatarRelative);
    }
  }

  static Future<String> savePickedAvatarToSandbox(File pickedFile) async {
    final doc = await documentsDirectory();
    final relativePath = standardAvatarRelativePath;
    final dest = File(p.join(doc.path, relativePath));
    await dest.parent.create(recursive: true);
    await pickedFile.copy(dest.path);
    return relativePath;
  }
}
