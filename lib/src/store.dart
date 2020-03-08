import 'dart:math';

import 'package:crdt/src/clock.dart';

import 'package:crdt/src/crdt.dart';

abstract class Store<K, V> {
  HybridLogicalClock get latestLogicalTime;

  Future<Map<K, Record<V>>> getMap([int logicalTime = 0]);

  Future<Record<V>> get(K key);

  Future<void> put(K key, Record<V> value);

  Future<void> putAll(Map<K, Record<V>> values);

  Future<void> clear();
}

class MapStore<K, V> implements Store<K, V> {
  final Map<K, Record<V>> _map;

  @override
  HybridLogicalClock get latestLogicalTime => HybridLogicalClock(_map.isEmpty
      ? 0
      : _map.values
          .map((record) => record.hybridLogicalClock.logicalTime)
          .reduce(max));

  MapStore([Map<K, Record<V>> map]) : _map = map ?? <K, Record<V>>{};

  @override
  Future<Map<K, Record<V>>> getMap([int logicalTime = 0]) async =>
      Map<K, Record<V>>.from(_map)
        ..removeWhere((_, record) =>
            record.hybridLogicalClock.logicalTime <= logicalTime);

  @override
  Future<Record<V>> get(K key) async => _map[key];

  @override
  Future<void> put(K key, Record<V> value) async => _map[key] = value;

  @override
  Future<void> putAll(Map<K, Record<V>> values) async => _map.addAll(values);

  @override
  Future<void> clear() async => _map.clear();
}
