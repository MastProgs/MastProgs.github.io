import { IDENTITY } from "../content/site.js";

// AI-NOTE: 사용자 명시 요청으로 데모 안내 문구·직함을 뺐다. 푸터에는 이름만 둔다.
export function SiteFooter() {
  return (
    <footer className="site-footer">
      <p className="site-footer__name">{IDENTITY.name}</p>
    </footer>
  );
}
