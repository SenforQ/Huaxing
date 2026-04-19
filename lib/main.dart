import 'package:flutter/material.dart';

import 'pages/community_shell.dart';
import 'state/feed_mute_controller.dart';
import 'theme/huaxing_theme.dart';

void main() {
  runApp(const HuaxingApp());
}

class HuaxingApp extends StatefulWidget {
  const HuaxingApp({super.key});

  @override
  State<HuaxingApp> createState() => _HuaxingAppState();
}

class _HuaxingAppState extends State<HuaxingApp> {
  late final FeedMuteController _feedMute;

  @override
  void initState() {
    super.initState();
    _feedMute = FeedMuteController();
    _feedMute.reloadFromStorage();
  }

  @override
  void dispose() {
    _feedMute.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: false,
      title: '花杏',
      theme: buildHuaxingTheme(),
      builder: (BuildContext context, Widget? child) {
        return FeedMuteScope(
          notifier: _feedMute,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const CommunityShell(),
    );
  }
}
