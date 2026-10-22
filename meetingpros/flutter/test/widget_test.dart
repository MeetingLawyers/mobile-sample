import 'package:flutter_test/flutter_test.dart';
import 'package:meetingpros_sample/main.dart';

void main() {
  testWidgets('shows the missing credentials hint without a .env', (tester) async {
    await tester.pumpWidget(const SampleApp());
    await tester.pump();

    expect(find.textContaining('missingCredentials'), findsOneWidget);
  });
}
