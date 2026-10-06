// 브라우저 HostPlatform(dart:js_interop + package:web). 앱 로직이나 React/JS 런타임을 넣지 않고 아래 브라우저 기능만 쓴다.
// AI-NOTE: 개인정보 보장의 유일한 예외(사용자 요청): 고른 테마만 localStorage 의 한 키에 "dark" | "light" 문자열로 남긴다.
// 저장소 접근(게터 포함)은 막혀 있을 수 있으므로 모두 try/catch 로 감싸고 실패하면 저장소 없음으로 다룬다(기본 dark).
// 새 탭은 noopener, noreferrer 로만 연다. 색 선택은 숨긴 <input type="color"> 하나를 다시 써서 브라우저 기본 창을 띄운다.
// AI-NOTE: 접근성 트리의 링크는 엔진이 실제 <a href>(Semantics.linkUrl)로 그린다. 그 링크를 누르면 브라우저 기본 이동(전체 새로고침·
// 같은 탭 외부 이동)과 엔진의 tap 전달이 함께 일어난다. 규칙은 link_click_rule.dart: 보통 클릭은 기본 이동만 막아 앱이 한 번 이동,
// Ctrl/Cmd/Shift/Alt·보조 버튼은 브라우저 기본(새 탭 등)을 두고 click·pointerdown/up 의 전파를 캡처 단계에서 막아 앱 이동을 막는다.
// 키보드 Enter 는 Flutter 가 처리한 keydown 을 엔진이 이미 preventDefault 하므로 기본 이동이 생기지 않는다.
import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import '../core/constants.dart';
import 'host_platform.dart';
import 'link_click_rule.dart';

HostPlatform createPlatform() => WebHostPlatform();

class WebHostPlatform implements HostPlatform {
  WebHostPlatform() {
    _reducedQuery = _safe(() => web.window.matchMedia('(prefers-reduced-motion: reduce)'));
    _storageListener = ((web.Event event) {
      final storage = event as web.StorageEvent;
      if (storage.key == themeStorageKey) _themeChanges.add(storage.newValue);
    }).toJS;
    _visibilityListener = ((web.Event _) => _visibility.add(documentHidden)).toJS;
    _motionListener = ((web.Event _) => _motion.add(prefersReducedMotion)).toJS;
    LinkClickAction decide(web.MouseEvent event) {
      final target = event.target;
      final onLink = target != null && target.isA<web.Element>() && (target as web.Element).closest('flt-semantics-host a[href]') != null;
      return semanticLinkClickAction(
        onSemanticLink: onLink,
        button: event.button,
        ctrl: event.ctrlKey,
        meta: event.metaKey,
        shift: event.shiftKey,
        alt: event.altKey,
      );
    }

    _linkClickListener = ((web.MouseEvent event) {
      switch (decide(event)) {
        case LinkClickAction.preventDefault:
          event.preventDefault();
        case LinkClickAction.stopPropagation:
          event.stopPropagation();
        case LinkClickAction.ignore:
          break;
      }
    }).toJS;
    _linkPointerDownListener = ((web.PointerEvent event) {
      if (decide(event) != LinkClickAction.stopPropagation) return;
      _nativePointers.add(event.pointerId);
      event.stopPropagation();
    }).toJS;
    _linkPointerEndListener = ((web.PointerEvent event) {
      if (_nativePointers.remove(event.pointerId)) event.stopPropagation();
    }).toJS;
    web.document.addEventListener('pointerdown', _linkPointerDownListener, true.toJS);
    web.document.addEventListener('pointerup', _linkPointerEndListener, true.toJS);
    web.document.addEventListener('pointercancel', _linkPointerEndListener, true.toJS);
    web.window.addEventListener('storage', _storageListener);
    web.document.addEventListener('visibilitychange', _visibilityListener);
    web.document.addEventListener('click', _linkClickListener, true.toJS);
    _reducedQuery?.addEventListener('change', _motionListener);
  }

  final StreamController<String?> _themeChanges = StreamController<String?>.broadcast();
  final StreamController<bool> _visibility = StreamController<bool>.broadcast();
  final StreamController<bool> _motion = StreamController<bool>.broadcast();
  web.MediaQueryList? _reducedQuery;
  late final JSFunction _storageListener;
  late final JSFunction _visibilityListener;
  late final JSFunction _motionListener;
  late final JSFunction _linkClickListener;
  late final JSFunction _linkPointerDownListener;
  late final JSFunction _linkPointerEndListener;

  /// 브라우저 기본 동작에 맡긴(수정 키·보조 버튼) 접근성 링크 위 포인터. up/cancel 까지 엔진에 보내지 않는다.
  final Set<int> _nativePointers = <int>{};
  web.HTMLInputElement? _colorInput;
  void Function(String hex)? _colorHandler;

  static T? _safe<T>(T Function() read) {
    try {
      return read();
    } catch (error) {
      if (kDebugMode) debugPrint('[portfolio] browser API unavailable: $error');
      return null;
    }
  }

  web.Storage? get _storage => _safe(() => web.window.localStorage);

  @override
  String? readTheme() => _safe<String?>(() => _storage?.getItem(themeStorageKey));

  @override
  bool writeTheme(String value) {
    final storage = _storage;
    if (storage == null) return false;
    return _safe(() {
          storage.setItem(themeStorageKey, value);
          return true;
        }) ??
        false;
  }

  @override
  Stream<String?> get themeChanges => _themeChanges.stream;

  @override
  bool get documentHidden => _safe(() => web.document.hidden) ?? false;

  @override
  Stream<bool> get visibilityChanges => _visibility.stream;

  @override
  bool get prefersReducedMotion => _reducedQuery?.matches ?? false;

  @override
  Stream<bool> get reducedMotionChanges => _motion.stream;

  @override
  void openNewTab(String url) {
    _safe(() => web.window.open(url, '_blank', 'noopener,noreferrer'));
  }

  @override
  void downloadFile(String path, String filename) {
    // AI-NOTE: 임시 앵커는 사용자 클릭 핸들러 안에서 동기적으로 누른다. iOS Safari가 download를
    // 무시하면 PDF 뷰어로 열리며, 그곳의 공유/저장 기능으로 파일을 받을 수 있다.
    _safe(() {
      final link = web.HTMLAnchorElement()
        ..href = path
        ..download = filename;
      web.document.body?.append(link);
      link.click();
      link.remove();
    });
  }

  @override
  bool pickColor({required String initial, required void Function(String hex) onInput}) {
    final input = _colorInput ??= _createColorInput();
    if (input == null) return false;
    _colorHandler = onInput;
    input.value = initial;
    final opened = _safe(() {
      try {
        input.showPicker();
      } catch (_) {
        input.click();
      }
      return true;
    });
    return opened ?? false;
  }

  web.HTMLInputElement? _createColorInput() => _safe(() {
    final input = web.HTMLInputElement()
      ..type = 'color'
      ..tabIndex = -1
      ..setAttribute('aria-hidden', 'true');
    final style = input.style;
    style.position = 'fixed';
    style.left = '50%';
    style.top = '50%';
    style.width = '1px';
    style.height = '1px';
    style.opacity = '0';
    style.pointerEvents = 'none';
    input.addEventListener('input', ((web.Event _) => _colorHandler?.call(input.value)).toJS);
    web.document.body?.append(input);
    return input;
  });

  @override
  void dispose() {
    web.window.removeEventListener('storage', _storageListener);
    web.document.removeEventListener('visibilitychange', _visibilityListener);
    web.document.removeEventListener('click', _linkClickListener, true.toJS);
    web.document.removeEventListener('pointerdown', _linkPointerDownListener, true.toJS);
    web.document.removeEventListener('pointerup', _linkPointerEndListener, true.toJS);
    web.document.removeEventListener('pointercancel', _linkPointerEndListener, true.toJS);
    _reducedQuery?.removeEventListener('change', _motionListener);
    _colorInput?.remove();
    _themeChanges.close();
    _visibility.close();
    _motion.close();
  }
}
