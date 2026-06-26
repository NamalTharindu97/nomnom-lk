class PaginatedResponse<T> {
  final List<T> data;
  final int page;
  final int perPage;
  final int total;
  final int totalPages;

  const PaginatedResponse({
    required this.data,
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final pagination = json['pagination'] as Map<String, dynamic>?;
    final dataList = (json['data'] as List?)
            ?.map((e) => fromItem(e as Map<String, dynamic>))
            .toList() ??
        [];

    return PaginatedResponse(
      data: dataList,
      page: pagination?['page'] as int? ?? 1,
      perPage: pagination?['per_page'] as int? ?? 20,
      total: pagination?['total'] as int? ?? 0,
      totalPages: pagination?['total_pages'] as int? ?? 1,
    );
  }
}
