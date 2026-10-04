import { CheckCircleIcon, CircleDashedIcon, CircleNotchIcon } from "@phosphor-icons/react";
import { DETAIL_COPY, DIRECT_WORK } from "../../content/workflowDetail.js";

const isFrame = (frame, id) => (frame.has(id) ? " is-frame" : "");

// AI-NOTE: 직접 처리 흐름(요청 → Master AI 직접 처리 → 응답). WORK SPEC·Seed·레인·검수·QA 가 없다는 점이 보이도록
// 세 칸만 그린다. 노드 id 는 direct:<단계> 이며 방금 바뀐 칸에 is-frame 이 붙는다(frames.js).
export function DirectPanel({ nodes, frame }) {
  return (
    <section className="wfd-direct" aria-labelledby="wfd-direct-title">
      <h2 id="wfd-direct-title" className="wfd-block__title">{DETAIL_COPY.directHeading}</h2>
      <ol className="wfd-direct__flow">
        {nodes.map((node) => {
          const Icon = node.status === "done" ? CheckCircleIcon : node.isActive ? CircleNotchIcon : CircleDashedIcon;
          const id = `direct:${node.step}`;
          return (
            <li
              key={node.id}
              data-frame-id={id}
              className={`wfd-direct__node wfd-direct__node--${node.status}${node.isActive ? " is-active" : ""}${isFrame(frame, id)}`}
              aria-current={node.isActive ? "step" : undefined}
            >
              <Icon size={18} weight={node.status === "done" ? "fill" : "bold"} aria-hidden="true" />
              <span className="wfd-direct__label">{node.label}</span>
              {node.id === "direct" && <code>{DIRECT_WORK.owns}</code>}
            </li>
          );
        })}
      </ol>
    </section>
  );
}
