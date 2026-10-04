import { useEffect, useRef, useState } from "react";
import { announcementFor } from "../workflow/announce.js";

// 상태 변화에서 필요한 알림만 골라 하나의 polite 라이브 영역에 전달한다.
export function useAnnouncement(state) {
  const previous = useRef(state);
  const [message, setMessage] = useState("");

  useEffect(() => {
    const text = announcementFor(previous.current, state);
    previous.current = state;
    if (text) setMessage(text);
  }, [state]);

  return message;
}
