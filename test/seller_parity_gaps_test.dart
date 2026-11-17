import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:secondlife_app_seller/core/network/api_client.dart';
import 'package:secondlife_app_seller/features/auth/presentation/password_recovery_screen.dart';
import 'package:secondlife_app_seller/features/listings/data/post_repository.dart';
import 'package:secondlife_app_seller/features/listings/presentation/create_listing_providers.dart';
import 'package:secondlife_app_seller/features/listings/presentation/screens/edit_listing_draft_screen.dart';

class FakePostRepository extends PostRepository {
  FakePostRepository() : super(client: ApiClient());
  final List<String> calls = [];
  Map<String, dynamic>? updatedDraft;

  @override
  Future<Map<String, dynamic>> getMyPostDetail(String postId) async => {
    'id': postId,
    'status': 'DRAFT',
    'title': 'Máy lọc không khí',
    'description': 'Mô tả draft',
    'itemCondition': 'USED_GOOD',
    'price': 1200000,
    'shippingWeight': 3000,
    'shippingLength': 40,
    'shippingWidth': 30,
    'shippingHeight': 50,
    'imageUrls': <String>[],
  };

  @override
  Future<void> updateDraft({
    required String postId,
    required Map<String, dynamic> data,
  }) async {
    calls.add('updateDraft');
    updatedDraft = data;
  }

  @override
  Future<Map<String, dynamic>> acceptDescription({
    required String postId,
    String? description,
  }) async {
    calls.add('acceptDescription');
    return {'id': postId, 'description': description};
  }
}

void main() {
  testWidgets('Seller password recovery presents all reset fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: PasswordRecoveryScreen())),
    );

    expect(find.text('Địa chỉ Email tài khoản *'), findsOneWidget);
    expect(find.text('Mã xác thực OTP (6 chữ số) *'), findsOneWidget);
    expect(find.text('Mật khẩu mới *'), findsOneWidget);
    expect(find.text('Nhập lại mật khẩu mới *'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Seller draft editor lays out at the target viewports', (
    tester,
  ) async {
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
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final viewport in viewports) {
      tester.view.physicalSize = viewport;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            postRepositoryProvider.overrideWithValue(FakePostRepository()),
          ],
          child: const MaterialApp(
            home: EditListingDraftScreen(postId: 'post-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tiêu đề *'), findsOneWidget);
      expect(find.text('Mô tả *'), findsOneWidget);
      expect(find.text('Giá bán (VND) *'), findsOneWidget);
      expect(find.text('Lưu thay đổi'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Viewport $viewport');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Seller draft continues only after save and description accept', (
    tester,
  ) async {
    final repository = FakePostRepository();
    final router = GoRouter(
      initialLocation: '/create-listing/post-1/edit',
      routes: [
        GoRoute(
          path: '/create-listing/:productId/edit',
          builder: (context, state) => EditListingDraftScreen(
            postId: state.pathParameters['productId']!,
          ),
        ),
        GoRoute(
          path: '/create-listing',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('listing wizard'))),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [postRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(EditListingDraftScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView).last, const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(find.text('Lưu thay đổi'), findsOneWidget);
    expect(find.text('Tiếp tục đăng bài'), findsOneWidget);
    await tester.ensureVisible(find.text('Tiếp tục đăng bài'));
    await tester.tap(find.text('Tiếp tục đăng bài'));
    await tester.pumpAndSettle();

    expect(repository.calls, ['updateDraft', 'acceptDescription']);
    expect(repository.updatedDraft?['title'], 'Máy lọc không khí');
    expect(repository.updatedDraft?['shippingLength'], 40);
    expect(find.text('listing wizard'), findsOneWidget);
  });
}
