/// Orders network startup and recovery without discarding refreshes received
/// while sockets are being opened or rebound.
class NetworkRecovery {
  final Future<void> Function() _initialize;
  final Future<void> Function() _recover;
  Future<void>? _initializing;
  Future<void>? _refreshing;
  bool _initialized = false;
  bool _startAllowed = false;
  bool _pending = false;

  NetworkRecovery({required Future<void> Function() initialize, required Future<void> Function() recover})
    : _initialize = initialize,
      _recover = recover;

  Future<void> initialize() {
    _startAllowed = true;
    if (_initializing != null) return _initializing!;
    if (_initialized) return Future.value();
    return _initializing = _start().whenComplete(() => _initializing = null);
  }

  Future<void> _start() async {
    await _initialize();
    _initialized = true;
    if (_pending) await _refresh();
  }

  Future<void> refresh() {
    _pending = true;
    // Startup is authorized only after the permission flow has finished.
    if (!_startAllowed) return Future.value();
    if (!_initialized) return _initializing ?? initialize();
    return _refresh();
  }

  Future<void> _refresh() => _refreshing ??= _drain().whenComplete(() => _refreshing = null);

  Future<void> _drain() async {
    while (_pending) {
      _pending = false;
      await _recover();
    }
  }
}
