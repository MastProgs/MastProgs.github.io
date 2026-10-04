// 크기 제한 캐시(가장 오래 안 쓴 항목부터 버림). 가공한 프레임 이미지를 무한히 쌓지 않기 위해 쓴다.
export function createLruCache(limit) {
  if (!(limit > 0)) throw new Error("limit must be positive");
  const map = new Map();
  return {
    get(key) {
      if (!map.has(key)) return undefined;
      const value = map.get(key);
      map.delete(key);
      map.set(key, value);
      return value;
    },
    set(key, value) {
      if (map.has(key)) map.delete(key);
      map.set(key, value);
      while (map.size > limit) map.delete(map.keys().next().value);
    },
    clear: () => map.clear(),
    get size() {
      return map.size;
    },
  };
}
