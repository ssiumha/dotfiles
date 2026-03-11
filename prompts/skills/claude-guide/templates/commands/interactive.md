# {Command Name}

{1-2문장 설명}

$ARGUMENTS: {초기 컨텍스트 (선택)}

## Workflow

1. **컨텍스트 수집**
   - $ARGUMENTS가 있으면 파싱
   - 없으면 AskUserQuestion으로 수집

2. **질문 단계**
   AskUserQuestion으로 확인:
   - [1] {옵션 1}
   - [2] {옵션 2}
   - [3] {옵션 3}

3. **실행**
   - 사용자 선택에 따라 분기
   - {작업 수행}

4. **결과 보고**
   - 수행 결과 요약
   - 다음 단계 안내 (있다면)
