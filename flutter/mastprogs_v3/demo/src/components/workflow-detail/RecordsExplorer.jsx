import { FileTextIcon, FolderIcon } from "@phosphor-icons/react";
import { DETAIL_COPY } from "../../content/workflowDetail.js";

const CHANGE_TEXT = { new: "새 파일", updated: "갱신" };

// 경로 목록을 폴더 머리글 + 파일 행으로 펼친다. 폴더는 처음 나올 때 한 번만 넣는다.
function toRows(files) {
  const rows = [];
  const seen = new Set();
  for (const file of files) {
    const parts = file.path.split("/");
    for (let depth = 1; depth < parts.length; depth += 1) {
      const dir = parts.slice(0, depth).join("/");
      if (!seen.has(dir)) {
        seen.add(dir);
        rows.push({ type: "dir", key: `dir:${dir}`, name: parts[depth - 1], depth: depth - 1 });
      }
    }
    rows.push({ type: "file", key: file.path, name: parts.at(-1), depth: parts.length - 1, file });
  }
  return rows;
}

// AI-NOTE: 기록은 cursor 에서 매번 파생된다(records.js). 처음으로 누르면 목록이 비고 선택도 풀린다.
// 선택하지 않았으면 마지막 단계가 만든 파일을 따라가고, 파일을 누르면 그 파일에 고정된다.
export function RecordsExplorer({ records, changes, selectedPath, onSelect, onFollow }) {
  const { files, root, latestPath } = records;
  const pinned = selectedPath !== null && files.some((file) => file.path === selectedPath);
  const activePath = pinned ? selectedPath : latestPath;
  const active = files.find((file) => file.path === activePath) ?? null;
  const rows = toRows(files);

  return (
    <section className="wfd-records" aria-labelledby="wfd-records-title">
      <div className="wfd-records__head">
        <h2 id="wfd-records-title" className="wfd-block__title">{DETAIL_COPY.recordsHeading}</h2>
        <p className="wfd-records__lead">{DETAIL_COPY.recordsLead}</p>
        <p className="wfd-records__root">
          <FolderIcon size={16} aria-hidden="true" />
          <code>{root}/</code>
          <span className="wfd-records__count">파일 {files.length}개</span>
        </p>
      </div>

      {files.length === 0 ? (
        <p className="wfd-records__empty">{DETAIL_COPY.recordsEmpty}</p>
      ) : (
        <div className="wfd-records__body">
          <ul className="wfd-tree" aria-label="기록 파일">
            {rows.map((row) =>
              row.type === "dir" ? (
                <li key={row.key} className="wfd-tree__dir" style={{ "--depth": row.depth }} aria-hidden="true">
                  <FolderIcon size={15} />
                  {row.name}/
                </li>
              ) : (
                <li key={row.key} style={{ "--depth": row.depth }}>
                  <button
                    type="button"
                    className={`wfd-tree__file${row.file.path === activePath ? " is-selected" : ""}`}
                    aria-pressed={row.file.path === activePath}
                    onClick={() => onSelect(row.file.path)}
                  >
                    <FileTextIcon size={15} aria-hidden="true" />
                    <span className="wfd-tree__name">
                      {row.name}
                      <span className="sr-only"> ({row.file.path})</span>
                    </span>
                    {changes.has(row.file.path) && (
                      <span className={`wfd-tree__change wfd-tree__change--${changes.get(row.file.path)}`}>{CHANGE_TEXT[changes.get(row.file.path)]}</span>
                    )}
                  </button>
                </li>
              ),
            )}
          </ul>

          <div className="wfd-viewer">
            <div className="wfd-viewer__bar">
              <code className="wfd-viewer__path">{active?.path}</code>
              {pinned && (
                <button type="button" className="wfd-viewer__follow" onClick={onFollow}>
                  {DETAIL_COPY.recordsFollow}
                </button>
              )}
            </div>
            <pre className="wfd-viewer__content" tabIndex={0} aria-label={`${active?.path ?? ""} 내용`}>
              {active && active.content.length > 0 ? active.content : "(비어 있음)"}
            </pre>
          </div>
        </div>
      )}
    </section>
  );
}
