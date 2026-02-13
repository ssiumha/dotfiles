# Java Import Patterns

ast-grep 및 grep 패턴으로 Java 파일의 import문을 추출합니다.

## ast-grep Patterns

### 일반 import

```bash
ast-grep --pattern 'import $PACKAGE;' --json <file>
```

### Static import

```bash
ast-grep --pattern 'import static $PACKAGE;' --json <file>
```

## grep Fallback Patterns

ast-grep 미설치 시 아래 정규식 사용:

```bash
# 일반 + static import
grep -oP "^import\s+(static\s+)?([a-zA-Z_][\w.]*\*?);" <file>
```

**캡처 그룹 2**가 전체 패키지 경로 (e.g., `com.example.service.UserService`).

## 패키지 → 파일 매핑

### 매핑 규칙

Java의 패키지명은 디렉토리 구조에 대응:

```
import com.example.service.UserService;
→ com/example/service/UserService.java
```

변환: `.` → `/`, 끝에 `.java` 추가.

### 소스 루트 탐색

프로젝트 내 소스 루트를 자동 감지:

```
우선순위:
1. src/main/java/          (Maven/Gradle 표준)
2. src/                     (단순 프로젝트)
3. app/src/main/java/      (Android)
4. <module>/src/main/java/ (멀티모듈)
```

**감지 방법**: `build.gradle`, `pom.xml`, 또는 `*.java` 파일의 `package` 선언으로 역추적.

### 와일드카드 import

```java
import com.example.service.*;  // 패키지 전체
```

해당 디렉토리 내 모든 `.java` 파일을 의존성으로 추가 (팬아웃 과다 주의).
옵션: 와일드카드는 패키지 노드 하나로 축약 가능.

## 내부/외부 판단

### 내부 (Internal)

프로젝트 소스 루트 내에서 실제 파일을 찾을 수 있는 import:

```java
// 프로젝트 base package: com.example
import com.example.model.User;     // → 내부 (파일 존재)
import com.example.util.DateUtils; // → 내부 (파일 존재)
```

**판별 방법**:
1. 패키지 경로를 파일 경로로 변환
2. 소스 루트에서 해당 파일 존재 여부 확인
3. 존재하면 내부, 아니면 외부

### 외부 (External)

프로젝트 소스 내 파일이 없는 import:

```java
import org.springframework.stereotype.Service;  // → 외부
import java.util.List;                           // → 외부 (JDK)
import lombok.Data;                              // → 외부
```

외부 import는 `{ id: "ext:org.springframework", group: "external", external: true }` 형태로 그룹화.

### 그룹화 규칙

외부 패키지는 상위 2-3 세그먼트로 그룹화하여 노드 수 제한:

```
org.springframework.stereotype.Service → ext:org.springframework
org.springframework.web.bind.annotation.GetMapping → ext:org.springframework
java.util.List → ext:java.util
java.io.File → ext:java.io
com.google.common.collect.ImmutableList → ext:com.google.common
```

## 제외 패턴

기본적으로 의존성 추출에서 제외하거나 별도 처리:

```
- java.lang.* → 항상 제외 (암묵적 import)
- 같은 패키지 내 클래스 → import 없이 사용 가능, 별도 처리
```
