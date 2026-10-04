import { ArrowClockwiseIcon, CircleDashedIcon, EyeIcon, GitForkIcon, UserCircleIcon } from "@phosphor-icons/react";
import { SEED_COPY } from "../../content/workflowDetail.js";

const SEEDS = [
  { id: "author-seed", label: SEED_COPY.authorSeed, children: ["plan-author", "dev-author"] },
  { id: "reviewer-seed", label: SEED_COPY.reviewerSeed, children: ["plan-reviewer", "dev-reviewer"] },
];

function childText(child) {
  if (child.runs === 0) return "fork 대기";
  if (child.runs === 1) return "fork됨";
  return `같은 child resume · ${child.runs}회 실행`;
}

// AI-NOTE: 레인 하나의 Seed 세션 계보. Seed(읽기 전용) 아래로 Planning/Development sibling 두 개가 갈라진다.
// child 가 처음 실행되면 fork 선이 이어지고(is-forked), 재작업은 같은 child 를 resume 하므로 Seed 는 다시 나타나지 않는다.
// QA·Wiki 는 계보 밖 독립 세션으로(QA 재시도는 같은 레인 QA 세션 resume) 따로 표시한다. 속도·캐시·비용 수치는 만들지 않는다.
export function SeedLineage({ lineage, laneKey }) {
  const byId = Object.fromEntries(lineage.children.map((child) => [child.id, child]));
  return (
    <div className={`wfd-seed${lineage.seedReady ? " is-ready" : ""}`} aria-label={`레인 ${laneKey} ${SEED_COPY.heading}`} role="group">
      {SEEDS.map((seed) => (
        <div key={seed.id} className="wfd-seed__family">
          <p className="wfd-seed__parent">
            <EyeIcon size={15} aria-hidden="true" />
            <span className="wfd-seed__name">{seed.label}</span>
            <span className="wfd-seed__tag">{lineage.seedReady ? "읽기 전용 · 준비됨" : "대기"}</span>
          </p>
          <ul className="wfd-seed__children">
            {seed.children.map((id) => {
              const child = byId[id];
              const Icon = child.runs === 0 ? CircleDashedIcon : child.runs > 1 ? ArrowClockwiseIcon : GitForkIcon;
              return (
                <li key={id} className={`wfd-seed__child${child.runs > 0 ? " is-forked" : ""}${child.runs > 1 ? " is-resumed" : ""}`}>
                  <Icon size={14} weight="bold" aria-hidden="true" />
                  <span className="wfd-seed__name">{SEED_COPY.children[id]}</span>
                  <span className="wfd-seed__tag">{childText(child)}</span>
                </li>
              );
            })}
          </ul>
        </div>
      ))}
      <p className="wfd-seed__independent">
        <UserCircleIcon size={15} aria-hidden="true" />
        {SEED_COPY.independent}
        {lineage.qaRuns > 0 ? ` · QA ${lineage.qaRuns}회 실행(같은 QA 세션)` : ""}
      </p>
    </div>
  );
}
