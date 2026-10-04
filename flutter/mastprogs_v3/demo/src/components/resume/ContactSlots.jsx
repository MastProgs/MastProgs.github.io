import { EnvelopeSimpleIcon, LinkSimpleIcon, PhoneIcon } from "@phosphor-icons/react";
import { CONTACT, contactHref, contactValue } from "../../content/resume.js";

const FIELD_ICON = {
  email: EnvelopeSimpleIcon,
  phone: PhoneIcon,
  profile: LinkSimpleIcon,
};

// AI-NOTE: 연락처 칸. 값이 비어 있으면 점선 칸에 "준비 중" 을 보여 준다. 채워진 값은 일반 텍스트로만 표시하고
// mailto/tel 링크를 만들지 않는다. 유일한 예외는 사용자가 준 포트폴리오 주소(contactHref 가 PORTFOLIO_URL 을 돌려줄 때)로,
// 새 탭(target="_blank", rel="noopener noreferrer") 링크가 된다. 소개 상단(#contact)에 항상 보이며,
// 헤더·고정 바에는 "연락" 링크가 없다. ContactDialog 도 이 컴포넌트를 쓰지만 현재 페이지에서는 렌더링하지 않는다.
export function ContactSlots({ headingId, showHeading = true, className = "" }) {
  const allEmpty = CONTACT.fields.every((field) => contactValue(field) === null);
  return (
    <div className={`contact-slots ${className}`.trim()}>
      {showHeading && (
        <h3 id={headingId} className="contact-slots__heading">{CONTACT.heading}</h3>
      )}
      <dl className="contact-slots__list" aria-labelledby={showHeading ? headingId : undefined}>
        {CONTACT.fields.map((field) => {
          const value = contactValue(field);
          const href = contactHref(field);
          const Icon = FIELD_ICON[field.id] ?? LinkSimpleIcon;
          return (
            <div key={field.id} className={`contact-slot${value === null ? " is-empty" : ""}`}>
              <dt className="contact-slot__label">
                <Icon size={18} aria-hidden="true" />
                {field.label}
              </dt>
              <dd className="contact-slot__value">
                {href !== null ? (
                  <a className="contact-slot__link" href={href} target="_blank" rel="noopener noreferrer">
                    {value}
                  </a>
                ) : (
                  value ?? <span className="contact-slot__empty">{CONTACT.emptyValue}</span>
                )}
              </dd>
            </div>
          );
        })}
      </dl>
      {allEmpty && <p className="contact-slots__note">{CONTACT.emptyNote}</p>}
    </div>
  );
}
