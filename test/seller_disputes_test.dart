import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secondlife_app_seller/features/reports/domain/user_report_model.dart';
import 'package:secondlife_app_seller/features/reports/presentation/report_providers.dart';
import 'package:secondlife_app_seller/features/reports/presentation/screens/seller_disputes_screen.dart';

void main() {
  test('Seller report model preserves response fields', () {
    final report = SellerUserReportModel.fromJson({
      'id': 'report-1',
      'orderId': 'order-1',
      'reasonCode': 'ITEM_NOT_RECEIVED',
      'description': 'Mô tả tình huống',
      'status': 'IN_REVIEW',
      'evidenceUrls': [
        '/api/v1/reports/evidence/12345678-1234-1234-1234-123456789012',
      ],
      'responsibleParty': 'CARRIER',
      'resolutionAction': 'NONE',
      'createdAt': '2026-11-17T08:00:00Z',
    });

    expect(report.id, 'report-1');
    expect(report.orderId, 'order-1');
    expect(report.status, 'IN_REVIEW');
    expect(report.evidenceUrls, hasLength(1));
    expect(report.responsibleParty, 'CARRIER');
  });

  testWidgets('Seller disputes adapts its empty state across viewports', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const viewports = <Size>[
      Size(360, 800),
      Size(390, 844),
      Size(600, 900),
      Size(768, 1024),
      Size(1024, 768),
      Size(1366, 768),
      Size(1440, 900),
      Size(1920, 1080),
    ];
    for (final viewport in viewports) {
      tester.view.physicalSize = viewport;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sellerUserReportsProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(home: SellerDisputesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Khiếu nại của tôi'), findsOneWidget);
      expect(find.text('Bạn chưa có khiếu nại nào.'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(tester.takeException(), isNull, reason: 'Viewport $viewport');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });
}
