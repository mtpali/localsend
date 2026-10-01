import 'package:photo_manager/photo_manager.dart';

/// A non-null filter is essential on Android's legacy MediaStore path:
/// photo_manager otherwise supplies `LIMIT … OFFSET …` as the whole sort order,
/// resulting in invalid `ORDER BY LIMIT …` SQL on Android 7–9 and legacy 10.
/// Empty orders in a classical filter select the plugin's stable `_id DESC`
/// order. Do not filter out media with missing dimensions or unusual timestamps.
FilterOptionGroup galleryQueryOptions() => FilterOptionGroup(
  imageOption: const FilterOption(sizeConstraint: SizeConstraint(ignoreSize: true)),
  videoOption: const FilterOption(sizeConstraint: SizeConstraint(ignoreSize: true)),
  createTimeCond: DateTimeCond.def().copyWith(ignore: true),
);
