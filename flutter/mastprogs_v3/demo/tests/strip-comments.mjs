import { parse } from "@babel/parser";

// 소스 배치 검사용: 파서가 찾은 실제 주석 범위만 공백으로 바꿔 코드·문자열·JSX 내용과 줄 위치를 그대로 둔다.
export const stripComments = (source) => {
  const { comments } = parse(source, { sourceType: "module", plugins: ["jsx"] });
  let code = source;
  for (const { start, end } of comments) code = code.slice(0, start) + " ".repeat(end - start) + code.slice(end);
  return code;
};
