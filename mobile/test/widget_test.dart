import 'package:flutter_test/flutter_test.dart';

import 'package:joe_talk_mobile/main.dart';

void main() {
  testWidgets('loads conversation home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const JoeTalkApp());
    await tester.pump();

    expect(find.text('語音導師對話'), findsOneWidget);
    expect(find.text('開始'), findsOneWidget);
  });
}
