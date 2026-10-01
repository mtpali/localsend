import 'dart:async';

import 'package:localsend_app/util/gallery_pager.dart';
import 'package:test/test.dart';

void main() {
  test('Switching albums discards the old pending page', () async {
    final oldPage = Completer<List<String>>();
    final pager = GalleryPager<String>(pageSize: 2);
    final oldLoad = pager.reset((_) => oldPage.future);
    await pager.reset((_) async => ['new album']);
    oldPage.complete(['old album']);
    await oldLoad;
    expect(pager.items, ['new album']);
    expect(pager.isLoading, isFalse);
  });

  test('Overlapping scroll requests fetch the next page only once', () async {
    final nextPage = Completer<List<int>>();
    final pages = <int>[];
    final pager = GalleryPager<int>(pageSize: 2);
    await pager.reset((page) {
      pages.add(page);
      return page == 0 ? Future.value([1, 2]) : nextPage.future;
    });
    final loads = List.generate(8, (_) => pager.loadNext());
    nextPage.complete([3]);
    await Future.wait(loads);
    await pager.loadNext();
    expect(pages, [0, 1]);
    expect(pager.items, [1, 2, 3]);
    expect(pager.hasMore, isFalse);
  });

  test('A failed page can be retried without skipping any media', () async {
    var attempts = 0;
    final pages = <int>[];
    final pager = GalleryPager<int>(pageSize: 2);
    await pager.reset((page) {
      pages.add(page);
      if (attempts++ == 0) throw StateError('MediaStore unavailable');
      return Future.value([1]);
    });
    expect(pager.error, isA<StateError>());
    await pager.loadNext();
    expect(pages, [0, 0]);
    expect(pager.items, [1]);
    expect(pager.error, isNull);
  });

  test('Closing the gallery prevents a pending response from retaining images', () async {
    final page = Completer<List<int>>();
    var notifications = 0;
    final pager = GalleryPager<int>(pageSize: 2, onChanged: () => notifications++);
    final load = pager.reset((_) => page.future);
    pager.dispose();
    page.complete([1, 2]);
    await load;
    expect(pager.items, isEmpty);
    expect(notifications, 1);
  });
}
