import 'package:flutter_test/flutter_test.dart';

import 'package:huaxing/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const HuaxingApp());
    await tester.pump();
    expect(find.text('花杏摄影'), findsOneWidget);
  });
}
