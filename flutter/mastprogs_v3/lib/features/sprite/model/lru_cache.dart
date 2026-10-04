// 크기 제한 캐시(가장 오래 안 쓴 항목부터 버림, React src/pixel/cache.js 이식). 가공한 프레임 이미지를 무한히 쌓지 않기 위해 쓴다.
// onEvict 는 버려지는 값을 정리할 때(예: dart:ui Image.dispose) 쓴다.
import 'dart:collection';

class LruCache<K, V> {
  LruCache(int limit, {this.onEvict}) : _limit = limit {
    if (limit <= 0) throw ArgumentError.value(limit, 'limit', 'limit must be positive');
  }

  int _limit;
  int get limit => _limit;
  final void Function(V value)? onEvict;
  final LinkedHashMap<K, V> _map = LinkedHashMap<K, V>();

  /// 한도를 바꾼다. 줄이면 가장 오래 안 쓴 항목부터 즉시 버린다(onEvict 호출).
  void resize(int limit) {
    if (limit <= 0) throw ArgumentError.value(limit, 'limit', 'limit must be positive');
    _limit = limit;
    _trim();
  }

  void _trim() {
    while (_map.length > _limit) {
      final oldest = _map.keys.first;
      final evicted = _map.remove(oldest) as V;
      onEvict?.call(evicted);
    }
  }

  V? get(K key) {
    if (!_map.containsKey(key)) return null;
    final value = _map.remove(key) as V;
    _map[key] = value;
    return value;
  }

  void set(K key, V value) {
    final previous = _map.remove(key);
    if (previous != null && !identical(previous, value)) onEvict?.call(previous);
    _map[key] = value;
    _trim();
  }

  void clear() {
    final values = _map.values.toList();
    _map.clear();
    if (onEvict != null) values.forEach(onEvict!);
  }

  int get size => _map.length;
}
