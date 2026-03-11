# {Command Name}

$ARGUMENTS를 체크리스트 파일로 사용하여 {작업}을 병렬 처리합니다.

## Checklist Format

```yaml
items:
  - id: 1
    input: "{입력값}"
    done: false
  - id: 2
    input: "{입력값}"
    done: false
```

## Workflow

1. **체크리스트 로드**
   - $ARGUMENTS 파일 Read
   - `done: false`인 항목 필터링

2. **병렬 처리**
   - {agent-name} agent를 Task tool로 병렬 호출
   - 최대 {N}개씩 배치 실행
   - 각 agent에 개별 항목 전달

3. **상태 업데이트**
   - 완료된 항목 `done: true`로 수정
   - 체크리스트 파일 저장

4. **반복**
   - 미완료 항목이 남아있으면 2번으로
   - 모두 완료되면 결과 보고

## Error Handling

- agent 실패 시: 해당 항목 `error: "{메시지}"` 추가
- 3회 실패: 사용자에게 보고 후 다음 항목으로
