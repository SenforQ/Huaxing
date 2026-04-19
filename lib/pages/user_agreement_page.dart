import 'package:flutter/material.dart';

import '../widgets/legal_web_view_page.dart';

/// 用户协议网页（合规链接由产品提供）。
const String kUserAgreementUrl =
    'https://www.privacypolicies.com/live/88fb5181-4336-48c8-896e-07793a7976b5';

class UserAgreementPage extends StatelessWidget {
  const UserAgreementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalWebViewPage(
      title: '用户协议',
      url: kUserAgreementUrl,
    );
  }
}
