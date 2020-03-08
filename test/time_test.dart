import 'package:crdt/crdt.dart';
import 'package:test/test.dart';

var testHybridLogicalClock = HybridLogicalClock(1579633503119000, 42);

void main() {
  group('Comparison', () {
    test('Equality', () {
      var hybridLogicalClock = HybridLogicalClock(1579633503119000, 42);
      expect(testHybridLogicalClock, hybridLogicalClock);
    });

    test('Equality with different nodes', () {
      var hybridLogicalClock = HybridLogicalClock(1579633503119000, 42);
      expect(testHybridLogicalClock, hybridLogicalClock);
    });

    test('Less than millis', () {
      var hybridLogicalClock = HybridLogicalClock(1579733503119000, 42);
      expect(testHybridLogicalClock < hybridLogicalClock, isTrue);
    });

    test('Less than counter', () {
      var hybridLogicalClock = HybridLogicalClock(1579633503119000, 43);
      expect(testHybridLogicalClock < hybridLogicalClock, isTrue);
    });

    test('Fail less than if equals', () {
      var hybridLogicalClock = HybridLogicalClock(1579633503119000, 42);
      expect(testHybridLogicalClock < hybridLogicalClock, isFalse);
    });

    test('Fail less than if millis and counter disagree', () {
      var hybridLogicalClock = HybridLogicalClock(1579533503119000, 43);
      expect(testHybridLogicalClock < hybridLogicalClock, isFalse);
    });
  });

  group('Logical time representation', () {
    test('HybridLogicalClock as logical time', () {
      expect(testHybridLogicalClock.logicalTime, 1579633503109162);
    });

    test('HybridLogicalClock from logical time', () {
      expect(HybridLogicalClock.fromLogicalTime(1579633503109162),
          testHybridLogicalClock);
    });
  });

  group('String operations', () {
    test('hybridLogicalClock to string', () {
      expect(
          testHybridLogicalClock.toString(), '2020-01-21T19:05:03.110Z-002A');
    });

    test('Parse hybridLogicalClock', () {
      expect(HybridLogicalClock.parse('2020-01-21T19:05:03.119Z-002A'),
          testHybridLogicalClock);
    });
  });

  group('Send', () {
    test('Send before', () {
      var hybridLogicalClock =
          HybridLogicalClock.send(testHybridLogicalClock, 1579633503110000);
      expect(hybridLogicalClock, isNot(testHybridLogicalClock));
      expect(hybridLogicalClock.toString(), '2020-01-21T19:05:03.110Z-002B');
    });

    test('Send simultaneous', () {
      var hybridLogicalClock =
          HybridLogicalClock.send(testHybridLogicalClock, 1579633503119000);
      expect(hybridLogicalClock, isNot(testHybridLogicalClock));
      expect(hybridLogicalClock.toString(), '2020-01-21T19:05:03.110Z-002B');
    });

    test('Send later', () {
      var hybridLogicalClock =
          HybridLogicalClock.send(testHybridLogicalClock, 1579733503119000);
      expect(hybridLogicalClock, HybridLogicalClock(1579733503119000));
    });
  });

  group('Receive', () {
    test('Receive before', () {
      var remoteHlc = HybridLogicalClock(1579633503110000);
      var hybridLogicalClock = HybridLogicalClock.recv(
          testHybridLogicalClock, remoteHlc, 1579633503119000);
      expect(hybridLogicalClock, isNot(equals(testHybridLogicalClock)));
    });

    test('Receive simultaneous', () {
      var remoteHlc = HybridLogicalClock(1579633503119000);
      var hybridLogicalClock = HybridLogicalClock.recv(
          testHybridLogicalClock, remoteHlc, 1579633503119000);
      expect(hybridLogicalClock, isNot(testHybridLogicalClock));
    });

    test('Receive after', () {
      var remoteHlc = HybridLogicalClock(1579633503119000);
      var hybridLogicalClock = HybridLogicalClock.recv(
          testHybridLogicalClock, remoteHlc, 1579633503129000);
      expect(hybridLogicalClock, isNot(testHybridLogicalClock));
    });
  });
}
