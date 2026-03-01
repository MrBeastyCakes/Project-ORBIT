import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/app.dart';

void main() {
  testWidgets('OrbitApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: OrbitApp()),
    );
    // App renders without crashing.
    expect(find.byType(OrbitApp), findsOneWidget);
  });
}
