---
name: feed
description: >-
  RSS/Atom 피드를 수집하고 프로젝트 dependency와 대조하여 관련 보안/기술 뉴스를 리포팅.
  Use when checking security advisories, supply chain news, CVE alerts, or technology updates relevant to current project.
  /feed (전체), /feed security, /feed backend, /feed frontend.
  Do NOT use for general web search (use WebSearch instead).
argument-hint: "[security|backend|frontend|all]"
user-invocable: true
allowed-tools: Bash(ruby:*)
---

## Overview

프로젝트에서 사용 중인 dependency(Maven, npm, Docker, GitHub Actions, CLI tools)를 자동 추출하고, RSS/Atom 보안 피드에서 관련 항목만 필터링하여 리포팅한다. last-run 타임스탬프 기반으로 이전 실행 이후의 새 항목만 수집한다.

## Instructions

상세 워크플로우와 분석 기준은 INSTRUCTIONS.md를 참조한다.

## Examples

### `/feed`
전체 카테고리 피드를 수집하고, 프로젝트 dependency와 대조하여 3단계로 분류한다.
→ Directly Relevant (dependency 매칭) / Worth Noting (카테고리 관련) / Feed Health

### `/feed security`
security 카테고리 피드만 수집. CVE, supply chain 공격, 취약점 advisory를 우선 플래그한다.
→ 매칭된 dependency가 있으면 구체적인 다음 행동을 포함하여 리포팅.

### `/feed backend`
backend 카테고리 피드를 수집. Spring, Java 생태계 관련 뉴스를 필터링한다.

## Technical Details

| 컴포넌트 | 경로 |
|----------|------|
| 피드 설정 | `~/dots/prompts/skills/feed/feeds.yaml` |
| RSS 파서 | `~/dots/prompts/skills/feed/scripts/fetch-feeds.py` |
| Dependency 추출 | `~/dots/prompts/skills/feed/scripts/extract-deps.py` |
| Last-run 캐시 | `~/.cache/feed/last-run` |

- Python 3 stdlib only (외부 패키지 불필요)
- 첫 실행 시 72시간 lookback 적용
- 피드당 최대 20항목, summary 500자 제한
