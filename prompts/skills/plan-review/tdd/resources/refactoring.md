# 리팩토링 패턴

**핵심 원칙**: 동작 변경 없이 구조만 개선

## Extract Method (메서드 추출)

**목적**: 긴 메서드를 작은 메서드로 분할

**시나리오**: 메서드가 너무 길거나 여러 일을 함

**방법**:
```python
# Before
def process_order(order):
    # 할인 계산
    discount = 0
    if order.customer.is_premium:
        discount = order.total * 0.1

    # 세금 계산
    tax = (order.total - discount) * 0.08

    # 최종 금액
    final = order.total - discount + tax
    return final

# After - Extract Method
def process_order(order):
    discount = calculate_discount(order)
    tax = calculate_tax(order, discount)
    return calculate_final_amount(order, discount, tax)

def calculate_discount(order):
    if order.customer.is_premium:
        return order.total * 0.1
    return 0

def calculate_tax(order, discount):
    return (order.total - discount) * 0.08

def calculate_final_amount(order, discount, tax):
    return order.total - discount + tax
```

## Rename (이름 변경)

**목적**: 의도를 명확히 표현

**시나리오**: 변수/함수 이름이 불명확

**방법**:
```python
# Before
def calc(a, b):
    return a * b * 0.08

# After
def calculate_sales_tax(price, quantity):
    return price * quantity * 0.08
```

## Inline Method (메서드 인라인)

**목적**: 불필요한 간접 참조 제거

**시나리오**: 메서드 본문이 이름만큼 명확할 때

**방법**:
```python
# Before
def is_adult(person):
    return is_over_18(person)

def is_over_18(person):
    return person.age >= 18

# After
def is_adult(person):
    return person.age >= 18
```

## Extract Variable (변수 추출)

**목적**: 복잡한 표현식을 이름 있는 변수로

**방법**:
```python
# Before
if (order.quantity > 10 and order.customer.is_premium
    and order.total > 1000):
    apply_bulk_discount(order)

# After
is_bulk_order = order.quantity > 10
is_premium_customer = order.customer.is_premium
is_high_value = order.total > 1000

if is_bulk_order and is_premium_customer and is_high_value:
    apply_bulk_discount(order)
```

## Remove Duplication (중복 제거)

**목적**: DRY 원칙 (Don't Repeat Yourself)

**방법**:
```python
# Before
def login_user(username, password):
    if not username:
        log_error("Username is empty")
        return False
    if not password:
        log_error("Password is empty")
        return False
    # ...

# After
def login_user(username, password):
    if not validate_required(username, "Username"):
        return False
    if not validate_required(password, "Password"):
        return False
    # ...

def validate_required(value, field_name):
    if not value:
        log_error(f"{field_name} is empty")
        return False
    return True
```
