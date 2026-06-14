import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_app/services/notifications.dart';

/// Tests the pure "what's new since last time" logic that decides which inbox
/// rows raise a notification. The plugin/I/O wrapper around it ([pollAndNotify])
/// is validated on-device; this covers the dedup/high-water-mark rules.
void main() {
  ({int id, bool seen}) row(int id, {bool seen = false}) =>
      (id: id, seen: seen);

  test('first run only baselines — nothing is new', () {
    final (toNotify, hwm) =
        NotificationService.selectNew([row(5), row(4)], null);
    expect(toNotify, isEmpty);
    expect(hwm, '5', reason: 'watermark jumps to the largest existing id');
  });

  test('an unseen id past the watermark is new, exactly once', () {
    // Baseline established at 5.
    var (toNotify, hwm) = NotificationService.selectNew([row(5)], '5');
    expect(toNotify, isEmpty);

    // A newer unseen item arrives.
    (toNotify, hwm) = NotificationService.selectNew([row(7), row(5)], hwm);
    expect(toNotify, [7]);
    expect(hwm, '7');

    // Polling again with the same data must not re-notify.
    (toNotify, hwm) = NotificationService.selectNew([row(7), row(5)], hwm);
    expect(toNotify, isEmpty);
  });

  test('a newer item that was already seen in-app does not notify', () {
    final (toNotify, hwm) =
        NotificationService.selectNew([row(9, seen: true), row(3)], '3');
    expect(toNotify, isEmpty, reason: 'id 9 is newer but already seen');
    expect(hwm, '9', reason: 'watermark still advances past seen items');
  });

  test('multiple new unseen items all notify', () {
    final (toNotify, hwm) =
        NotificationService.selectNew([row(8), row(7), row(6)], '5');
    expect(toNotify..sort(), [6, 7, 8]);
    expect(hwm, '8');
  });

  test('an empty feed leaves the watermark untouched', () {
    final (toNotify, hwm) = NotificationService.selectNew([], '12');
    expect(toNotify, isEmpty);
    expect(hwm, '12');
  });
}
