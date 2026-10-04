import { RobotIcon, UserIcon, UserFocusIcon } from "@phosphor-icons/react";
import { ACTOR_LABEL, DETAIL_COPY } from "../../content/workflowDetail.js";

const DECISION_TAG = { scope: "범위 결정", permission: "권한 결정" };

const NO_FRAME = new Set();

// 사람과 Master AI 의 대화. 사람의 답 중 범위·권한 결정만 표시를 붙인다(단계마다 승인하는 구조가 아님).
// 메시지마다 data-frame-id="msg:<이벤트 id>" 를 달고, 방금 도착한 메시지에 is-frame 을 붙인다.
export function ConversationPanel({ messages, frame = NO_FRAME }) {
  return (
    <section className="wfd-chat" aria-labelledby="wfd-chat-title">
      <h2 id="wfd-chat-title" className="wfd-block__title">{DETAIL_COPY.conversationHeading}</h2>
      {messages.length === 0 ? (
        <p className="wfd-chat__empty">{DETAIL_COPY.conversationEmpty}</p>
      ) : (
        <ol className="wfd-chat__list">
          {messages.map((message) => {
            const Icon = message.actor === "human" ? UserIcon : RobotIcon;
            const tag = DECISION_TAG[message.decision];
            return (
              <li
                key={message.id}
                data-frame-id={`msg:${message.id}`}
                className={`wfd-msg wfd-msg--${message.actor}${frame.has(`msg:${message.id}`) ? " is-frame" : ""}`}
              >
                <span className="wfd-msg__avatar" aria-hidden="true">
                  <Icon size={18} />
                </span>
                <div className="wfd-msg__body">
                  <p className="wfd-msg__meta">
                    <span className="wfd-msg__who">{ACTOR_LABEL[message.actor]}</span>
                    <span className="wfd-msg__time">{message.time}</span>
                    {tag && (
                      <span className="wfd-msg__tag">
                        <UserFocusIcon size={14} aria-hidden="true" />
                        {tag}
                      </span>
                    )}
                  </p>
                  <p className="wfd-msg__text">{message.text}</p>
                </div>
              </li>
            );
          })}
        </ol>
      )}
      <p className="wfd-chat__note">
        <UserFocusIcon size={16} aria-hidden="true" />
        {DETAIL_COPY.humanNote}
      </p>
    </section>
  );
}
