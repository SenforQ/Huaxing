import 'package:flutter/material.dart';

import '../widgets/legal_web_view_page.dart';

/// 隐私政策网页（合规链接由产品提供）。
const String kPrivacyPolicyUrl =
    'https://www.privacypolicies.com/live/baf5d6e8-e6bf-44ac-a3c6-b93fd3f5e443';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalWebViewPage(
      title: '隐私政策',
      url: kPrivacyPolicyUrl,
    );
  }
}
