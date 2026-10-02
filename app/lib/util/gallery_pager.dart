import 'dart:collection';

/// Paginates media without allowing an old album response or concurrent scroll
/// requests to append duplicate or unrelated items.
class GalleryPager<T> {
  final int pageSize;
  final void Function()? onChanged;
  final List<T> _items = [];
  Future<List<T>> Function(int page)? _loader;
  Future<void>? _inFlight;
  int _generation = 0;
  int _page = 0;
  bool _disposed = false;
  bool isLoading = false;
  bool hasMore = false;
  Object? error;

  GalleryPager({required this.pageSize, this.onChanged});

  List<T> get items => UnmodifiableListView(_items);

  Future<void> reset(Future<List<T>> Function(int page) loader) {
    if (_disposed) return Future.value();
    _generation++;
    _loader = loader;
    _items.clear();
    _page = 0;
    _inFlight = null;
    isLoading = false;
    hasMore = true;
    error = null;
    return loadNext();
  }

  Future<void> loadNext() {
    if (_disposed || !hasMore || _loader == null) return Future.value();
    return _inFlight ??= _load(_loader!, _generation);
  }

  Future<void> _load(Future<List<T>> Function(int page) loader, int generation) async {
    isLoading = true;
    error = null;
    onChanged?.call();
    try {
      final page = await Future<List<T>>.sync(() => loader(_page));
      if (_generation != generation) return;
      _items.addAll(page);
      _page++;
      hasMore = page.length >= pageSize;
    } catch (e) {
      if (_generation == generation) error = e;
    } finally {
      if (_generation == generation) {
        _inFlight = null;
        isLoading = false;
        onChanged?.call();
      }
    }
  }

  void dispose() {
    _disposed = true;
    _generation++;
    _items.clear();
  }
}
