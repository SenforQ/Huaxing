import 'package:flutter/material.dart';

import '../widgets/glass_ui.dart';
import 'explore_tab.dart';
import 'inbox_tab.dart';
import 'lens_tab.dart';
import 'profile_tab.dart';
import 'tab_one_page.dart';

class CommunityShell extends StatefulWidget {
  const CommunityShell({super.key});

  @override
  State<CommunityShell> createState() => _CommunityShellState();
}

class _CommunityShellState extends State<CommunityShell> {
  static const int _kInboxTabIndex = 3;

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: GradientShellBackground(
        child: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _index,
            children: [
              const TabOnePage(),
              const LensTab(),
              const ExploreTab(),
              InboxTab(isActive: _index == _kInboxTabIndex),
              const ProfileTab(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _index,
        onChanged: (int index) => setState(() => _index = index),
      ),
    );
  }
}
