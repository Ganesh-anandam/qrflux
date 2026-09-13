import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_file_transfer/core/constants/app_constants.dart';
import 'package:smart_file_transfer/main.dart';

void main() {
  testWidgets('App renders QR Transfer title and action buttons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: QrTransferApp()));
    await tester.pumpAndSettle();

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('Send Files'), findsOneWidget);
    expect(find.text('Receive Files'), findsOneWidget);
  });
}
