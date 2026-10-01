import 'dart:async';
import 'package:localsend_app/util/network_recovery.dart';
import 'package:test/test.dart';

void main() {
  test('Resume events before permission completion defer network startup', () async {
    final events = <String>[];
    final recovery = NetworkRecovery(initialize: () async => events.add('start'), recover: () async => events.add('recover'));
    await recovery.refresh();
    expect(events, isEmpty);
    await recovery.initialize();
    expect(events, ['start', 'recover']);
  });

  test('Cold share and resume wait for startup and coalesce their refreshes', () async {
    final start = Completer<void>();
    final events = <String>[];
    final recovery = NetworkRecovery(
      initialize: () async {
        events.add('start');
        await start.future;
      },
      recover: () async => events.add('recover'),
    );
    final first = recovery.initialize();
    final second = recovery.initialize();
    final share = recovery.refresh();
    final resume = recovery.refresh();
    expect(events, ['start']);
    start.complete();
    await Future.wait([first, second, share, resume]);
    expect(events, ['start', 'recover']);
  });

  test('Network changes during recovery request one subsequent rebind', () async {
    final firstRebind = Completer<void>();
    var active = 0;
    var maximumActive = 0;
    var count = 0;
    final recovery = NetworkRecovery(
      initialize: () async {},
      recover: () async {
        active++;
        if (active > maximumActive) maximumActive = active;
        count++;
        if (count == 1) await firstRebind.future;
        active--;
      },
    );
    await recovery.initialize();
    final first = recovery.refresh();
    final requests = List.generate(8, (_) => recovery.refresh());
    firstRebind.complete();
    await Future.wait([first, ...requests]);
    expect(count, 2);
    expect(maximumActive, 1);
  });

  test('Failed startup can be retried without reopening the application', () async {
    var count = 0;
    var recovered = false;
    final recovery = NetworkRecovery(
      initialize: () async {
        if (++count == 1) throw StateError('Network unavailable');
      },
      recover: () async => recovered = true,
    );
    await expectLater(recovery.initialize(), throwsStateError);
    await recovery.refresh();
    expect(count, 2);
    expect(recovered, isTrue);
  });
}
