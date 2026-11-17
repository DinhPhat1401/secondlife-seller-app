import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/user_report_model.dart';

class SellerUserReportRepository {
  const SellerUserReportRepository(this._client);

  final ApiClient _client;

  Future<List<SellerUserReportModel>> getMine({
    int page = 0,
    int size = 50,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.userReports,
      queryParameters: {'page': page, 'size': size},
    );
    final payload = response.data;
    final rawItems = payload?['items'] ?? payload?['content'];
    if (rawItems is! List) return const [];
    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(SellerUserReportModel.fromJson)
        .toList(growable: false);
  }

  Future<List<int>> readEvidence(String evidenceUrl) async {
    final match = RegExp(
      r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
    ).firstMatch(evidenceUrl);
    if (match == null)
      throw const FormatException('Đường dẫn bằng chứng không hợp lệ.');
    final response = await _client.dio.get<List<int>>(
      '/api/v1/reports/evidence/${match.group(0)}',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? const <int>[];
  }
}
