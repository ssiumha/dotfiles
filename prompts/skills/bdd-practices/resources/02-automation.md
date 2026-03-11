# BDD Automation Guide

.feature 파일을 자동화 테스트로 연결하는 가이드입니다.

## 프레임워크 선택

| 언어 | 프레임워크 | 특징 |
|------|-----------|------|
| Python | pytest-bdd | pytest 생태계 통합 |
| Python | behave | 독립적, Django 친화 |
| JavaScript | cucumber-js | Node.js 표준 |

## Python (pytest-bdd)

### 설치

```bash
pip install pytest-bdd
```

### Step Definitions

```python
# steps/login_steps.py
from pytest_bdd import given, when, then, scenario, parsers

@scenario('../features/login.feature', '유효한 자격증명으로 로그인')
def test_valid_login():
    pass

@given('로그인 페이지에 있다')
def login_page(browser):
    browser.get('/login')

@when(parsers.parse('이메일 "{email}"을 입력한다'))
def enter_email(browser, email):
    browser.find_element('#email').send_keys(email)

@when(parsers.parse('비밀번호 "{password}"를 입력한다'))
def enter_password(browser, password):
    browser.find_element('#password').send_keys(password)

@when('로그인 버튼을 클릭한다')
def click_login(browser):
    browser.find_element('#login-btn').click()

@then('대시보드로 이동한다')
def verify_dashboard(browser):
    assert '/dashboard' in browser.current_url
```

### 실행

```bash
pytest tests/steps/ -v
```

## Python (behave)

### 설치

```bash
pip install behave
```

### Step Definitions

```python
# features/steps/login_steps.py
from behave import given, when, then

@given('로그인 페이지에 있다')
def step_login_page(context):
    context.browser.get('/login')

@when('유효한 자격증명을 입력한다')
def step_enter_credentials(context):
    context.browser.find_element('#email').send_keys('test@example.com')
    context.browser.find_element('#password').send_keys('password')

@then('대시보드로 이동한다')
def step_verify_dashboard(context):
    assert '/dashboard' in context.browser.current_url
```

### 실행

```bash
behave features/
```

## JavaScript (cucumber-js)

### 설치

```bash
npm install @cucumber/cucumber
```

### Step Definitions

```javascript
// features/steps/login.steps.js
const { Given, When, Then } = require('@cucumber/cucumber');
const assert = require('assert');

Given('로그인 페이지에 있다', async function() {
  await this.page.goto('/login');
});

When('유효한 자격증명을 입력한다', async function() {
  await this.page.fill('#email', 'test@example.com');
  await this.page.fill('#password', 'password');
});

When('로그인 버튼을 클릭한다', async function() {
  await this.page.click('#login-btn');
});

Then('대시보드로 이동한다', async function() {
  const url = this.page.url();
  assert(url.includes('/dashboard'));
});
```

### 실행

```bash
npx cucumber-js features/
```

## RED → GREEN → REFACTOR

### Phase 1: RED
```bash
# 테스트 실행 → 실패
pytest tests/steps/login_steps.py -v
# FAILED - 아직 구현 없음
```

### Phase 2: GREEN
```python
# 최소 구현으로 테스트 통과
def login(email, password):
    return True  # Fake it
```

### Phase 3: REFACTOR
- Step definitions 중복 제거
- 공통 fixture 추출
- 복잡한 로직은 tdd로

## 파일 구조

```
project/
├── features/
│   ├── login.feature
│   ├── checkout.feature
│   └── steps/           # behave
│       └── login_steps.py
├── tests/
│   └── steps/           # pytest-bdd
│       └── login_steps.py
└── src/
    └── auth/
        └── login.py
```

## Tips

1. **Step definition 재사용**: 여러 시나리오에서 같은 step 공유
2. **Fixture 활용**: 공통 설정은 conftest.py에 정의
3. **태그로 필터링**: `pytest -m smoke`로 스모크 테스트만 실행
4. **tdd 연계**: 복잡한 비즈니스 로직은 별도 유닛 테스트로
