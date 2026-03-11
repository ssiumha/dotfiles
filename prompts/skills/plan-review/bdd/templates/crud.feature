# CRUD Feature Template
# 리소스명, 필드명을 프로젝트에 맞게 수정하세요

Feature: {리소스} 관리
  {리소스}를 생성, 조회, 수정, 삭제할 수 있다

  Background:
    Given 인증된 사용자가 있다

  # CREATE
  Scenario: {리소스} 생성
    Given {리소스} 생성 페이지에 있다
    When 필수 정보를 입력한다
    And 저장 버튼을 누른다
    Then {리소스}가 생성된다
    And 상세 페이지로 이동한다

  Scenario: 필수 정보 누락 시 생성 실패
    Given {리소스} 생성 페이지에 있다
    When 필수 정보 없이 저장한다
    Then 오류 메시지가 표시된다

  # READ
  Scenario: {리소스} 목록 조회
    Given {리소스}가 존재한다
    When 목록 페이지에 접근한다
    Then {리소스} 목록이 표시된다

  Scenario: {리소스} 상세 조회
    Given {리소스}가 존재한다
    When 해당 {리소스}를 선택한다
    Then 상세 정보가 표시된다

  # UPDATE
  Scenario: {리소스} 수정
    Given {리소스}가 존재한다
    When 정보를 수정한다
    And 저장 버튼을 누른다
    Then 변경 사항이 저장된다

  # DELETE
  Scenario: {리소스} 삭제
    Given {리소스}가 존재한다
    When 삭제 버튼을 누른다
    And 삭제를 확인한다
    Then {리소스}가 삭제된다

  Scenario: 삭제 취소
    Given {리소스}가 존재한다
    When 삭제 버튼을 누른다
    And 삭제를 취소한다
    Then {리소스}가 유지된다
