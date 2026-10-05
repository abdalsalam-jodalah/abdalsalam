// test/sync/support/sync_row_factory.dart — builds stored-row maps with explicit timestamps for sync tests.

Map<String, dynamic> syncRow(
  String id, {
  required String updatedAt,
  String? deletedAt,
  String? title,
  Map<String, dynamic> extra = const <String, dynamic>{},
}) {
  return <String, dynamic>{
    'id': id,
    'title': title ?? 'row-$id',
    'createdAt': '2026-01-01T00:00:00.000',
    'updatedAt': updatedAt,
    'deletedAt': deletedAt,
    ...extra,
  };
}
