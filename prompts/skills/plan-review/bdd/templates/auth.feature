# Auth Feature Template
# 인증 방식에 맞게 수정하세요 (이메일/소셜/2FA 등)

Feature: 사용자 인증
  사용자가 로그인하고 로그아웃할 수 있다

  # 로그인 - Happy Path
  Scenario: 유효한 자격증명으로 로그인
    Given 등록된 사용자가 있다
    And 로그인 페이지에 있다
    When 올바른 자격증명으로 로그인한다
    Then 로그인에 성공한다
    And 대시보드로 이동한다

  # 로그인 - 예외 케이스
  Scenario: 잘못된 비밀번호로 로그인 시도
    Given 등록된 사용자가 있다
    And 로그인 페이지에 있다
    When 잘못된 비밀번호로 로그인한다
    Then 로그인에 실패한다
    And 오류 메시지가 표시된다

  Scenario: 존재하지 않는 사용자로 로그인 시도
    Given 로그인 페이지에 있다
    When 존재하지 않는 계정으로 로그인한다
    Then 로그인에 실패한다
    And 오류 메시지가 표시된다

  # 로그아웃
  Scenario: 로그아웃
    Given 로그인된 상태다
    When 로그아웃한다
    Then 로그인 페이지로 이동한다
    And 인증이 해제된다

  # 회원가입
  Scenario: 신규 사용자 가입
    Given 회원가입 페이지에 있다
    When 유효한 정보로 가입한다
    Then 가입에 성공한다
    And 환영 메시지가 표시된다

  Scenario: 중복 이메일로 가입 시도
    Given 등록된 사용자가 있다
    And 회원가입 페이지에 있다
    When 동일한 이메일로 가입한다
    Then 가입에 실패한다
    And 중복 오류가 표시된다

  # 비밀번호 찾기
  Scenario: 비밀번호 재설정 요청
    Given 등록된 사용자가 있다
    And 비밀번호 찾기 페이지에 있다
    When 이메일을 입력하고 요청한다
    Then 재설정 링크가 발송된다
