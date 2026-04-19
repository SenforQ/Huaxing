import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../theme/huaxing_theme.dart';
import '../utils/profile_storage.dart';
import '../widgets/glass_ui.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  PackageInfo? _packageInfo;
  ProfileEditState? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pkg = await PackageInfo.fromPlatform();
    final profile = await ProfileStorage.load();
    if (!mounted) return;
    setState(() {
      _packageInfo = pkg;
      _profile = profile;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundBlack,
      appBar: AppBar(
        title: const Text('关于我们'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAccentYellow))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: GlassPanel(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                borderRadius: 22,
                blurSigma: 20,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/applogo.png',
                        width: 108,
                        height: 108,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) {
                          return Container(
                            width: 108,
                            height: 108,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.apps_rounded,
                              size: 56,
                              color: kAccentYellow.withOpacity(0.8),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      _profile?.nickname ?? ProfileStorage.defaultNickname,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _versionLabel(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.58),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _versionLabel() {
    final p = _packageInfo;
    if (p == null) return '';
    return '版本 ${p.version}（${p.buildNumber}）';
  }
}
