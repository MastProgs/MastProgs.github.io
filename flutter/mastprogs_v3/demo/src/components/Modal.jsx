import { useEffect, useLayoutEffect, useRef } from "react";
import { XIcon } from "@phosphor-icons/react";
import { debugError, debugWarn } from "../lib/debug.js";
import { inertOutside, trapTabKey } from "../lib/modalFallback.js";

const LOCK_CLASS = "is-scroll-locked";
const FALLBACK_CLASS = "modal--fallback";

// AI-NOTE: 네이티브 <dialog>.showModal() 로 배경을 inert 처리하고 포커스를 가둔다. Esc(cancel)는 기본 동작을 막고
// 상위 상태를 통해 닫아 전환 효과와 상태가 어긋나지 않게 한다. close 이벤트에서 본문 스크롤 잠금을 풀고 연 버튼으로 포커스를 돌려준다.
// showModal 이 실패하는 환경에서는 open 속성으로 대체하며, 이 경우 배경 inert 는 보장되지 않는다.
// AI-NOTE: (갱신) showModal 이 없거나 실패하면 대체 모드로 열고, 배경 형제 요소를 직접 inert 처리하며 Tab 을 가두고 Esc 를 직접 처리한다.
// 대체 모드에서는 close 이벤트가 없을 수 있으므로 닫기 마무리(finishClose)를 직접 호출한다.
export function Modal({ open, onClose, labelledBy, className = "", closeLabel = "닫기", children }) {
  const dialogRef = useRef(null);
  const closeRef = useRef(null);
  const returnFocusRef = useRef(null);
  const restoreFallbackRef = useRef(null);
  const onCloseRef = useRef(onClose);
  onCloseRef.current = onClose;
  const openRef = useRef(open);
  openRef.current = open;

  const finishCloseRef = useRef(() => {});
  finishCloseRef.current = () => {
    const dialog = dialogRef.current;
    document.body.classList.remove(LOCK_CLASS);
    if (restoreFallbackRef.current) {
      restoreFallbackRef.current();
      restoreFallbackRef.current = null;
      dialog?.classList.remove(FALLBACK_CLASS);
    }
    const target = returnFocusRef.current;
    returnFocusRef.current = null;
    if (target && target.isConnected && typeof target.focus === "function") target.focus({ preventScroll: true });
    // AI-NOTE: 브라우저가 cancel 이벤트 없이 대화상자를 닫는 경우(반복 Esc 등)에도 상위 상태를 닫힘으로 맞춘다.
    if (openRef.current) onCloseRef.current();
  };

  useLayoutEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;
    const isOpen = dialog.open || dialog.hasAttribute("open");
    if (open && !isOpen) {
      returnFocusRef.current = document.activeElement;
      let native = false;
      if (typeof dialog.showModal === "function") {
        try {
          dialog.showModal();
          native = true;
        } catch (error) {
          debugError("dialog showModal failed, using fallback modal", error);
        }
      } else {
        debugWarn("dialog showModal unavailable, using fallback modal");
      }
      if (!native) {
        dialog.setAttribute("open", "");
        dialog.classList.add(FALLBACK_CLASS);
        restoreFallbackRef.current = inertOutside(dialog);
      }
      document.body.classList.add(LOCK_CLASS);
      closeRef.current?.focus();
    } else if (!open && isOpen) {
      if (restoreFallbackRef.current || typeof dialog.close !== "function") {
        dialog.removeAttribute("open");
        finishCloseRef.current();
      } else {
        dialog.close();
      }
    }
  }, [open]);

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return undefined;
    const handleClose = () => finishCloseRef.current();
    dialog.addEventListener("close", handleClose);
    return () => {
      dialog.removeEventListener("close", handleClose);
      document.body.classList.remove(LOCK_CLASS);
      if (restoreFallbackRef.current) {
        restoreFallbackRef.current();
        restoreFallbackRef.current = null;
      }
    };
  }, []);

  const handleCancel = (event) => {
    event.preventDefault();
    onCloseRef.current();
  };

  const handleKeyDown = (event) => {
    if (!restoreFallbackRef.current) return;
    if (event.key === "Escape") {
      event.preventDefault();
      onCloseRef.current();
      return;
    }
    trapTabKey(event, event.currentTarget);
  };

  const handleBackdrop = (event) => {
    if (event.target === event.currentTarget) onCloseRef.current();
  };

  return (
    <dialog
      ref={dialogRef}
      className={`modal ${className}`.trim()}
      aria-labelledby={labelledBy}
      aria-modal={open ? "true" : undefined}
      onCancel={handleCancel}
      onKeyDown={handleKeyDown}
      onClick={handleBackdrop}
    >
      <div className="modal__surface">
        <button ref={closeRef} type="button" className="modal__close" onClick={() => onCloseRef.current()} aria-label={closeLabel}>
          <XIcon size={20} weight="bold" aria-hidden="true" />
        </button>
        {children}
      </div>
    </dialog>
  );
}
