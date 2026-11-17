import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/user_report_repository.dart';
import '../domain/user_report_model.dart';

final sellerUserReportRepositoryProvider = Provider<SellerUserReportRepository>(
  (ref) {
    return SellerUserReportRepository(ref.watch(apiClientProvider));
  },
);

final sellerUserReportsProvider = FutureProvider<List<SellerUserReportModel>>((
  ref,
) async {
  return ref.watch(sellerUserReportRepositoryProvider).getMine();
});
