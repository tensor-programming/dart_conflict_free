import 'dart:math';

const _microsMask = 0xFFFFFFFFFFFF0000;
const _counterMask = 0xFFFF;
const _maxCounter = _counterMask;
const _maxDrift = 60000000;

class HybridLogicalClock implements Comparable<HybridLogicalClock> {
  final int logicalTime;

  int get micros => logicalTime & _microsMask;

  int get counter => logicalTime & _counterMask;

  HybridLogicalClock([int micros, int counter = 0])
      : logicalTime =
            ((micros ?? DateTime.now().microsecondsSinceEpoch) & _microsMask) +
                counter,
        assert(counter < _maxCounter);

  HybridLogicalClock.fromLogicalTime(this.logicalTime);

  factory HybridLogicalClock.parse(String timestamp) {
    var lastDash = timestamp.lastIndexOf('-');
    var micros =
        DateTime.parse(timestamp.substring(0, lastDash)).microsecondsSinceEpoch;
    var counter = int.parse(timestamp.substring(lastDash + 1), radix: 16);

    return HybridLogicalClock(micros, counter);
  }

  factory HybridLogicalClock.send(HybridLogicalClock timestamp, [int micros]) {
    micros = (micros ?? DateTime.now().microsecondsSinceEpoch) & _microsMask;

    var oldMicros = timestamp.micros;
    var oldCounter = timestamp.counter;

    var newMicros = max(oldMicros, micros);
    var newCounter = oldMicros == newMicros ? oldCounter + 1 : 0;

    if (newMicros - micros > _maxDrift) {
      throw ClockDriftException(newMicros, micros);
    }
    if (newCounter > _maxCounter) {
      throw OverflowException(newCounter);
    }

    return HybridLogicalClock(newMicros, newCounter);
  }

  factory HybridLogicalClock.recv(
      HybridLogicalClock local, HybridLogicalClock remote,
      [int micros]) {
    micros = (micros ?? DateTime.now().microsecondsSinceEpoch) & _microsMask;

    var remoteMicros = remote.micros;
    var remoteCounter = remote.counter;

    var localMicros = local.micros;
    var localCounter = local.counter;

    var newMicros = max(max(localMicros, micros), remoteMicros);
    var newCounter = newMicros == localMicros && newMicros == remoteMicros
        ? max(localCounter, remoteCounter) + 1
        : newMicros == localMicros
            ? localCounter + 1
            : newMicros == remoteMicros ? remoteCounter + 1 : 0;
    if (newMicros - micros > _maxDrift) {
      throw ClockDriftException(newMicros, micros);
    }
    if (newCounter > _maxCounter) {
      throw OverflowException(newCounter);
    }

    return HybridLogicalClock(newMicros, newCounter);
  }

  String toJson() => toString();

  @override
  String toString() =>
      '${DateTime.fromMillisecondsSinceEpoch((micros / 1000).ceil(), isUtc: true).toIso8601String()}'
      '-'
      '${counter.toRadixString(16).toUpperCase().padLeft(4, '0')}';

  @override
  int get hashCode => toString().hashCode;

  @override
  bool operator ==(other) =>
      other is HybridLogicalClock && logicalTime == other.logicalTime;

  bool operator <(other) =>
      other is HybridLogicalClock && logicalTime < other.logicalTime;

  bool operator <=(other) =>
      other is HybridLogicalClock && logicalTime <= other.logicalTime;

  bool operator >(other) =>
      other is HybridLogicalClock && logicalTime > other.logicalTime;

  bool operator >=(other) =>
      other is HybridLogicalClock && logicalTime >= other.logicalTime;

  @override
  int compareTo(HybridLogicalClock other) {
    return logicalTime.compareTo(other.logicalTime);
  }
}

class ClockDriftException implements Exception {
  final int drift;

  ClockDriftException(int microsTs, int microsWall)
      : drift = microsTs - microsWall;

  @override
  String toString() => 'Clock drift of $drift ms exceeds maximum ($_maxDrift).';
}

class OverflowException implements Exception {
  final int counter;

  OverflowException(this.counter);

  @override
  String toString() => 'Timestamp counter overflow: $counter.';
}
