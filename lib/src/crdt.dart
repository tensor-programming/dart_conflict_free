import 'dart:convert';

import 'package:crdt/src/clock.dart';
import 'package:crdt/src/store.dart';

typedef KeyDecoder<K> = K Function(String key);
typedef ValueDecoder<V> = V Function(dynamic value);

class Crdt<K, V> {
  final Store<K, V> _store;

  HybridLogicalClock _canonicalTime;

  Crdt([Store<K, V> store]) : _store = store ?? MapStore() {
    _canonicalTime = _store.latestLogicalTime;
  }

  Future<Map<K, Record<V>>> getMap([int logicalTime = 0]) =>
      _store.getMap(logicalTime);

  Future<Record<V>> get(K key) => _store.get(key);

  Future<void> put(K key, V value) async {
    _canonicalTime = HybridLogicalClock.send(_canonicalTime);
    await _store.put(key, Record<V>(_canonicalTime, value));
  }

  Future<void> putAll(Map<K, V> records) async {
    _canonicalTime = HybridLogicalClock.send(_canonicalTime);
    await _store.putAll(records.map<K, Record<V>>(
        (key, value) => MapEntry(key, Record(_canonicalTime, value))));
  }

  Future<void> delete(K key) async => put(key, null);

  Future<void> clear() async => _store.clear();

  Future<void> merge(Map<K, Record<V>> remoteRecords) async {
    var localMap = await _store.getMap();
    var updatedRecords = <K, Record<V>>{};

    remoteRecords.forEach((key, remoteRecord) {
      var localRecord = localMap[key];

      if (localRecord == null) {
        updatedRecords[key] =
            Record<V>(remoteRecord.hybridLogicalClock, remoteRecord.value);
      } else if (localRecord.hybridLogicalClock <
          remoteRecord.hybridLogicalClock) {
        _canonicalTime = HybridLogicalClock.recv(
            _canonicalTime, remoteRecord.hybridLogicalClock);
        updatedRecords[key] = Record<V>(_canonicalTime, remoteRecord.value);
      }
    });

    await _store.putAll(updatedRecords);
  }

  @override
  String toString() => _store.toString();

  Future<List<V>> get values async => (await getMap())
      .values
      .where((record) => !record.isDeleted)
      .map((record) => record.value)
      .toList();
}

class Record<V> {
  final HybridLogicalClock hybridLogicalClock;
  final V value;

  bool get isDeleted => value == null;

  Record(this.hybridLogicalClock, this.value);

  Record.fromJson(Map<String, dynamic> map, [ValueDecoder<V> decoder])
      : hybridLogicalClock =
            HybridLogicalClock.parse(map['hybridLogicalClock']),
        value = decoder == null || map['value'] == null
            ? map['value']
            : decoder(map['value']);

  Map<String, dynamic> toJson() =>
      {'hybridLogicalClock': hybridLogicalClock.toJson(), 'value': value};

  @override
  bool operator ==(other) =>
      other is Record<V> &&
      hybridLogicalClock == other.hybridLogicalClock &&
      value == other.value;

  @override
  String toString() => toJson().toString();
}

String crdtMap2Json(Map map) => jsonEncode(
    map.map((key, value) => MapEntry(key.toString(), value.toJson())));

Map<K, Record<V>> json2CrdtMap<K, V>(String json,
        {KeyDecoder<K> keyDecoder, ValueDecoder<V> valueDecoder}) =>
    (jsonDecode(json) as Map<String, dynamic>).map(
      (key, value) => MapEntry(
        keyDecoder == null ? key : keyDecoder(key),
        Record.fromJson(value, valueDecoder),
      ),
    );
