// 개발 서버에서만 출력하는 로거. 배포 빌드에서는 import.meta.env.DEV 가 false 라 아무것도 출력하지 않는다.
const isDev = Boolean(import.meta.env?.DEV);

export function debugWarn(message, detail) {
  if (isDev) console.warn(`[demo] ${message}`, detail ?? "");
}

export function debugError(message, detail) {
  if (isDev) console.error(`[demo] ${message}`, detail ?? "");
}
