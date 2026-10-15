import 'package:flutter_test/flutter_test.dart';

import 'package:community_assist/main.dart';

void main() {
  testWidgets('CommunityAssist app loads with Firebase connected screen',
      (WidgetTester tester) async {
    // Build our app.
    await tester.pumpWidget(const CommunityAssistApp());

    // Verify the app bar title appears.
    expect(find.text('CommunityAssist'), findsOneWidget);

    // Verify the Firebase-connected placeholder text appears.
    expect(find.text('Firebase Connected'), findsOneWidget);
  });
}