import { useId } from "react";
import { PIXEL_COPY, SOURCE_SET_ID } from "../../../content/pixelStudio.js";

const SHARE_ROWS = 8;
const pct = (value) => `${Math.round(value * 1000) / 10}%`;

// AI-NOTE: 기존 1행(포인트 색 프리셋·직접 고르기·추가 외곽선) 아래에 붙는 2행. 1행을 대신하지 않는다.
// 원본 내장 팔레트 10종 전체를 고르고 "팔레트 적용 비율"(0..100%)로 세트 색까지 얼마나 옮길지 정한다.
// 세트 색 견본(현재 프레임에 실제로 쓰인 색 표시)과 현재 출력의 색 점유율로 비율의 뜻을 바로 보여 준다.
// AI-NOTE: (사용자 최신 요청) 목록 맨 앞에 '원본 색상' 선택지(SOURCE_SET_ID)를 둔다. 포인트 색·외곽선 결과 다음의 세트 매핑을 건너뛰는 뜻이며
// 1행의 '원본'(포인트 색 프리셋)과 다르다. 이때 set 은 null 이고 비율 슬라이더는 비활성(값은 보존), 견본은 현재 출력 색을 보여 준다.
export function PaletteSetRow({ sets, mode, set, ratio, shares, onSelect, onRatio }) {
  const ratioId = useId();
  const hintId = useId();
  const isSource = mode === "source";
  const used = new Set(shares.entries.map((entry) => entry.hex));
  const usedCount = set ? set.colors.filter((hex) => used.has(hex)).length : 0;
  const top = shares.entries.slice(0, SHARE_ROWS);

  return (
    <div className="pixel-controls__group pixel-sets" role="group" aria-label={PIXEL_COPY.setGroup}>
      <p className="pixel-controls__label" aria-hidden="true">{PIXEL_COPY.setGroup}</p>
      <div className="pixel-sets__list">
        <button
          type="button"
          className={`pixel-set pixel-set--source${isSource ? " is-current" : ""}`}
          aria-pressed={isSource}
          onClick={() => onSelect(SOURCE_SET_ID)}
        >
          <span className="pixel-set__name">{PIXEL_COPY.sourceSet}</span>
          <span className="pixel-set__count">{PIXEL_COPY.sourceSetMeta}</span>
          <span className="pixel-set__strip pixel-set__strip--source" aria-hidden="true" />
        </button>
        {sets.map((item) => (
          <button
            key={item.id}
            type="button"
            className={`pixel-set${!isSource && item.id === set.id ? " is-current" : ""}`}
            aria-pressed={!isSource && item.id === set.id}
            onClick={() => onSelect(item.id)}
          >
            <span className="pixel-set__name">{item.name}</span>
            <span className="pixel-set__count">
              {item.colors.length}
              {PIXEL_COPY.colorsUnit}
            </span>
            <span className="pixel-set__strip" aria-hidden="true">
              {item.colors.map((hex) => (
                <span key={hex} style={{ background: hex }} />
              ))}
            </span>
          </button>
        ))}
      </div>

      <div className={`pixel-ratio${isSource ? " is-disabled" : ""}`}>
        <label htmlFor={ratioId} className="pixel-ratio__label">
          {PIXEL_COPY.ratio}
        </label>
        <input
          id={ratioId}
          className="pixel-range"
          type="range"
          min="0"
          max="100"
          step="1"
          value={ratio}
          disabled={isSource}
          aria-describedby={isSource ? hintId : undefined}
          aria-valuetext={isSource ? PIXEL_COPY.sourceSetMeta : `${set.name} ${ratio}%`}
          onChange={(event) => onRatio(event.target.value)}
        />
        <output htmlFor={ratioId} className="pixel-ratio__value">
          {isSource ? "—" : `${ratio}%`}
        </output>
      </div>
      <p id={hintId} className="pixel-controls__hint">
        {isSource ? `${PIXEL_COPY.sourceSetHint} ${PIXEL_COPY.ratioDisabled}` : `${PIXEL_COPY.ratioHint} ${PIXEL_COPY.setHint}`}
      </p>

      <div className="pixel-sets__detail">
        <div>
          {isSource ? (
            <>
              <p className="pixel-sets__caption">
                {PIXEL_COPY.sourceSet} · {PIXEL_COPY.sourceColors} {shares.entries.length}
                {PIXEL_COPY.colorsUnit}
              </p>
              <ul className="pixel-sets__swatches" aria-label={`${PIXEL_COPY.sourceSet} ${PIXEL_COPY.sourceColors}`}>
                {shares.entries.map((entry) => (
                  <li key={entry.hex} className="is-used" style={{ background: entry.hex }} title={entry.hex}>
                    <span className="sr-only">{entry.hex}</span>
                  </li>
                ))}
              </ul>
            </>
          ) : (
            <>
              <p className="pixel-sets__caption">
                {PIXEL_COPY.setColors} {set.colors.length} · {PIXEL_COPY.setUsed} {usedCount}
              </p>
              <ul className="pixel-sets__swatches" aria-label={`${set.name} ${PIXEL_COPY.setColors}`}>
                {set.colors.map((hex) => (
                  <li key={hex} className={used.has(hex) ? "is-used" : undefined} style={{ background: hex }} title={hex}>
                    <span className="sr-only">
                      {hex}
                      {used.has(hex) ? ` · ${PIXEL_COPY.setUsed}` : ""}
                    </span>
                  </li>
                ))}
              </ul>
            </>
          )}
        </div>

        <div>
          <p className="pixel-sets__caption">
            {PIXEL_COPY.sharesTitle}({shares.entries.length}
            {PIXEL_COPY.colorsUnit})
            {!isSource && (
              <>
                {" "}
                · {PIXEL_COPY.inSetShare} <strong>{pct(shares.inSetShare)}</strong>
              </>
            )}
          </p>
          <div className="pixel-shares__bar" aria-hidden="true">
            {shares.entries.map((entry) => (
              <span key={entry.hex} style={{ background: entry.hex, flexGrow: entry.count }} />
            ))}
          </div>
          <ol className="pixel-shares__list">
            {top.map((entry) => (
              <li key={entry.hex} className={entry.inSet ? "is-in-set" : undefined}>
                <span className="pixel-shares__chip" style={{ background: entry.hex }} aria-hidden="true" />
                <span className="pixel-shares__hex">{entry.hex}</span>
                <span className="pixel-shares__pct">{pct(entry.share)}</span>
              </li>
            ))}
          </ol>
        </div>
      </div>
    </div>
  );
}
