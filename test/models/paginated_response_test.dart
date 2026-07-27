import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom_lk/models/paginated_response.dart';

void main() {
  group('PaginatedResponse', () {
    test('fromJson parses response', () {
      final json = {
        'data': [
          {'id': '1', 'name': 'Item 1'},
          {'id': '2', 'name': 'Item 2'},
        ],
        'pagination': {
          'page': 1,
          'per_page': 10,
          'total': 25,
          'total_pages': 3,
        },
      };
      final response = PaginatedResponse.fromJson(json, (item) => item['name'] as String);
      expect(response.data, ['Item 1', 'Item 2']);
      expect(response.page, 1);
      expect(response.perPage, 10);
      expect(response.total, 25);
      expect(response.totalPages, 3);
    });

    test('hasMore when more pages', () {
      const response = PaginatedResponse(
        data: ['a'],
        page: 1,
        perPage: 10,
        total: 25,
        totalPages: 3,
      );
      expect(response.hasMore, isTrue);
    });

    test('hasMore when last page', () {
      const response = PaginatedResponse(
        data: ['a', 'b'],
        page: 3,
        perPage: 10,
        total: 25,
        totalPages: 3,
      );
      expect(response.hasMore, isFalse);
    });
  });
}
