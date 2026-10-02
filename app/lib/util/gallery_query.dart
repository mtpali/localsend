import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

/// A non-null filter is essential on Android's legacy MediaStore path:
/// photo_manager otherwise supplies `LIMIT … OFFSET …` as the whole sort order,
/// resulting in invalid `ORDER BY LIMIT …` SQL on Android 7–9 and legacy 10.
/// An explicit Android ID order also avoids the classical filter's implicit
/// 24-hour video limit and rejection of videos whose duration is still unknown.
/// An empty custom condition preserves RequestType.common's image/video filter
/// without imposing date, dimensions, or duration constraints.
PMFilter galleryQueryOptions() {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return CustomFilter.sql(where: '', orderBy: [OrderByItem.desc(CustomColumns.android.id)]);
  }
  return FilterOptionGroup(
    imageOption: const FilterOption(sizeConstraint: SizeConstraint(ignoreSize: true)),
    videoOption: const FilterOption(sizeConstraint: SizeConstraint(ignoreSize: true)),
    createTimeCond: DateTimeCond.def().copyWith(ignore: true),
  );
}
