---
name: 연습
description: 프로젝트의 학습 파일을 src/에서 직접 빈칸 처리하고 사용자가 작성 후 채점까지 진행한다. 백업/복구로 원본 안전.
---

# 연습 — 원본 구멍 뚫기 방식 코딩 연습 사이클

두 가지 모드로 동작한다:
- `/연습` : src/의 학습 대상 파일에 빈칸 뚫기 (33/67/100%) 또는 **장인 모드** (5-파일 묶음 통째 빈 파일)
- `/연습 채점` : 사용자가 작성한 코드 채점 + src/ 원본 복구

빈칸 형식은 **항상 fill-in-the-blank (`_____`)**. 퍼센티지로 빈칸 양만 조절.
장인 모드는 토큰 빈칸이 아니라 파일 자체를 빈 상태로 두는 별개 모드 — 구조부터 사용자가 직접 작성.

---

## 핵심 워크플로우 (이전 격리 모델과 다름)

기존 방식(`practice/<회차>/`에 빈칸 파일 격리)은 5-파일 묶음에서 외부 import(JWT, Security 등) 미해결로 빨간줄 폭탄. 새 방식:

1. **학습 대상 파일을 `.practice-backup/<session-id>/`에 그대로 복사** (원본 경로 미러)
2. **src/의 같은 파일들을 빈칸 버전으로 덮어쓰기** — 사용자는 src/ 실제 위치에서 IDE 풀 기능 받아 작업
3. **`practice/<회차>/.state`** 에 백업 위치 + 학습 대상 파일 목록 기록 (학습 중 상태 마커)
4. **`/연습 채점`** 시: 사용자 코드를 `practice/<회차>/`에 답안 보존 + 채점 + src/ 원본 복구

= **src/ 가 일시적으로 빈칸 상태**. 학습 끝나면 git diff 0으로 원상복귀.

---

## 빈칸 비율과 자리 정의

**핵심 원칙**: 퍼센티지는 **빈칸 양**의 비율임. 카테고리 누적 ❌, 토큰 풀 × 비율 ✅.

### 1. 빈칸 가능 토큰 풀

선택 기능 메소드 안의 모든 토큰 중, 다음만 **빈칸 X (절대 안 비움)**:

- **구조 키워드**: `try`, `catch`, `if`, `else`, `for`, `while`, `do`
- **구두점/연산자**: `{`, `}`, `(`, `)`, `;`, `=`, `,`, `.`, `:`
- **패키지/import 구문** 전체
- **클래스 선언 + 클래스 레벨 어노테이션** (`@RestController`, `@RequestMapping("/...")` 등 — 선택 기능 메소드 범위 밖)
- **필드 선언부** (`@Autowired private GuestBookService guestBookService;`)

그 외 모든 토큰 = **빈칸 가능 자리** (= "빈칸 풀").

빈칸 풀에 들어가는 자리 예시:
- 메소드 레벨 어노테이션 + 파라미터: `@GetMapping`, `"/list"`
- 메소드 시그니처 리턴 타입: `DataVO`
- 변수 선언 타입: `DataVO`, `List<GuestBookVO>`, `Exception`
- 생성자 호출: `new`, 클래스명
- 메소드 호출: 호출명 자체
- getter/setter
- 메소드 호출 인자 (값, 문자열, Boolean)
- 조건 연산자: `==`, `||`, `&&`
- 값 토큰: `null`, `Boolean.TRUE/FALSE`, 숫자, 문자열
- 흐름 키워드: `return`, `throw`, `break`, `continue`

### 2. 비율 적용 방식

선택 기능 메소드의 빈칸 풀 토큰 수가 N개라면:

| 비율 | 빈칸 개수 | 빈칸 X 추가 자리 |
|---|---|---|
| **33%** | ≈ N × 0.33 | 변수명, 컨트롤러 메소드명, `public` 접근제어자, 시그니처 리턴타입 일부 살림 |
| **67%** | ≈ N × 0.67 | 변수명, 컨트롤러 메소드명, `public` 접근제어자 살림 |
| **100%** | N개 전부 | 위 자리들도 다 빈칸 |

같은 토큰 여러 번 등장해도 100%에선 전부 비움.

### 3. 33% / 67% 선별 우선순위 (P1 → P8)

비율 채울 때 위에서부터 비움:

1. **Service/Mapper 메소드 호출명** (5-파일 묶음 핵심)
2. **getter/setter 첫 등장**
3. **표준 라이브러리 메소드 호출** (`isEmpty`, `getMessage`, `equals` 등)
4. **어노테이션 파라미터** (`"/list"`, `MembersVO.class` 등)
5. **같은 토큰 중복 등장** (setter 2번째 이후 등)
6. **문자열 리터럴** (사용자 메시지)
7. **변수 타입, 생성자(`new`), 시그니처 리턴 타입**
8. **조건 연산자(`==`/`||`/`&&`), 값 토큰(`null`/`Boolean.*`/숫자), 흐름 키워드(`return`/`throw`)**

100%는 P1~P8 전부 + 변수명/컨트롤러 메소드명/`public`까지.

### 4. 카테고리 ① — 메소드명 빈칸 범위 (5-파일 묶음 핵심)

- ✅ 메소드 호출 위치 (예: `guestBookService.guestBookList()`)
- ✅ 서비스/매퍼 **인터페이스** 시그니처의 메소드명
- ✅ `@Override` 메소드 시그니처의 메소드명 (ServiceImpl)
- ✅ XML `<select id="...">` 등 매퍼 쿼리 id 속성값
- ❌ **컨트롤러 클래스의 메소드명**은 33%/67%에선 빈칸 X (자유 작명이라 채점 모호). 100%에서만 빈칸.

> 의도: Controller가 부른 메소드명이 ↔ Service 시그니처 ↔ 임플 `@Override` ↔ Mapper 시그니처 ↔ XML `id` 가 **전부 정확히 같아야 동작**한다는 일관성을 5번 채우면서 자연스럽게 익힘.

---

## 사전 가드 — 학습 중 중복 호출 거절

`/연습` 호출 시 가장 먼저 확인:

1. `practice/*/.state` 파일이 하나라도 있는지 검사
2. 있으면 → **거절**:
   ```
   이미 진행 중인 학습이 있음: practice/<회차폴더>/
   먼저 /연습 채점으로 끝내거나, 포기하려면 practice/<회차폴더>/.state 삭제 후 .practice-backup/<id>/에서 수동 복구.
   ```
3. 없으면 정상 진행

= **한 번에 한 회차만 진행** (src/가 빈칸 상태인 동안 다른 회차 동시 진행 금지)

---

## 모드 A: `/연습` — src/에 구멍 뚫기

### 1. 연습 파일 파악

UI 선택지 쓰지 말 것. 텍스트 목록 출력하고 채팅 응답 기다림.
프로젝트 `src/` 동적 탐색해서 목록 구성. 컨트롤러 옆에 `← 5-파일 묶음` 표시.

출력 형식 예시:
```
연습할 파일 번호를 입력해줘 (예: 1 또는 5 67)

[JWT / Security 공통]
1. JwtUtil
2. JwtRequestFilter
3. JwtConfig
4. SecurityConfig
5. DataVO

[Members]
6. MembersController       ← 5-파일 묶음 (컨트롤러-서비스-서비스임플-매퍼-매퍼xml)
7. MembersVO
8. RefreshTokenVO

[GuestBook]
9. GuestBookController     ← 5-파일 묶음
10. GuestBookVO
```

> 5-파일 묶음에 속하는 Service/ServiceImpl/Mapper/mapper.xml은 목록에 따로 표시하지 않음 (컨트롤러 선택 시 자동 포함).

### 2. 분기

- **선택이 컨트롤러면** → 2-A. 5-파일 묶음 모드
- **그 외 단일 파일이면** → 2-B. 단일 파일 모드

---

### 2-A. 5-파일 묶음 모드

#### a. PROGRESS 확인

`practice/PROGRESS.md` 읽음. 없으면 자동 생성 (구조는 아래 "PROGRESS.md 구조" 참고). 기능 목록은 `src/` 컨트롤러를 분석해서 동적으로 채움.

#### b. 기능 + 퍼센티지 선택

해당 컨트롤러 도메인 매트릭스 출력. UI 선택지 X.

```
컨트롤러 선택. 5-파일 묶음 모드.

[Members] 진척도:
| # | 기능 | 33% | 67% | 100% |
|---|---|---|---|---|
| 1 | 로그인 | ⬜ | ⬜ | ⬜ |
| 2 | 토큰 재발급 | ⬜ | ⬜ | ⬜ |
| 3 | 마이페이지 | ⬜ | ⬜ | ⬜ |
| 🔒 | 로그아웃 (강사 미구현) | | | |

진행할 기능과 퍼센티지 입력:
  - 단일: "1 33", "2 67", "3 100"
  - 다중 (한 회차에 여러 기능 동시 학습): "1,2 67" 또는 "1 2 67" (쉼표 또는 공백 구분)
  - 장인 (5-파일 묶음 통째 빈 파일): "장인" — 모든 구현 기능을 한꺼번에, 빈 .java/.xml에서 처음부터 작성 (2-A-장인 섹션 참고)
```

- 잠금(🔒) 기능은 선택 못 함. 강사 코드에 해당 메소드가 없으면 자동 잠금.
- 이미 ✅인 셀도 다시 풀 수 있음 (반복 학습 허용).
- **다중 기능**: 같은 컨트롤러 안의 여러 기능을 동시에 빈칸 처리. 빈칸 양 늘어나지만 5-파일 묶음 파일 셋은 동일하니까 백업/복구는 똑같이 동작.
- **장인 모드**: 100% 상위. 토큰 빈칸 대신 5-파일 묶음을 통째로 빈 파일로 만들어 구조부터 직접 작성. 별도 워크플로우 — 2-A-장인 섹션에서 다룸.

#### c. 회차 폴더 + 백업 생성

회차 폴더명:
```
단일 기능:  practice/YYYY-MM-DD_<도메인>-<기능slug>_<%>/
다중 기능:  practice/YYYY-MM-DD_<도메인>-<기능1>+<기능2>_<%>/
```
예: `practice/2026-05-16_guestbook-list+insert_67/`

같은 회차 폴더 이미 있으면 `_2`, `_3` 자동 추가.

**학습 대상 파일 목록 결정** (5-파일 묶음 기준):
- `src/main/java/com/study/myproject01/<도메인>/controller/<도메인>Controller.java`
- `src/main/java/com/study/myproject01/<도메인>/service/<도메인>Service.java`
- `src/main/java/com/study/myproject01/<도메인>/service/<도메인>ServiceImpl.java`
- `src/main/java/com/study/myproject01/<도메인>/mapper/<도메인>Mapper.java`
- `src/main/resources/mapper/<도메인>-mapper.xml`

**백업 폴더 생성**:
```
.practice-backup/<session-id>/
  └── (src/ 트리 미러로 학습 대상 파일들을 그대로 복사)
```
`<session-id>` = `YYYY-MM-DD_<도메인>-<기능slug>_<%>` (회차 폴더명과 동일하게 — _2, _3 suffix 포함)

각 학습 대상 파일을 백업 위치에 그대로 복사 (디렉토리 구조 유지).

#### d. src/ 파일들 빈칸 버전으로 덮어쓰기

각 파일을 "빈칸 비율과 자리 정의" 룰대로 처리해서 **src/의 실제 위치에 덮어쓰기**:

| 파일 | 처리 방식 |
|---|---|
| 컨트롤러 | 선택 기능의 메소드만 빈칸. 다른 기능 메소드는 원본 그대로. |
| 서비스 인터페이스 | **선택 기능의 시그니처(메소드명+리턴타입+파라미터 타입) 빈칸**. 다른 기능은 그대로. |
| 서비스 임플 | 선택 기능 메소드만 빈칸. 다른 기능 구현은 그대로. |
| 매퍼 인터페이스 | 서비스 인터페이스와 동일. |
| 매퍼 XML | 선택 기능 SQL만 빈칸. 다른 쿼리는 그대로. |

> **이전 룰 폐기**: "서비스/매퍼 인터페이스는 시그니처 그대로 박음(빈칸 없음)"은 카테고리 ①의 "5곳 일관성" 의도와 모순. 의도(5곳) 우선이 맞음. 인터페이스 2곳도 빈칸.

#### e. `.state` 파일 생성

`practice/<회차>/.state` 작성 (JSON 형식). `features`는 항상 배열:

```json
{
  "mode": "5-file",
  "session_id": "2026-05-16_guestbook-list+insert_67",
  "domain": "guestbook",
  "features": [
    { "slug": "list",   "label": "방명록 리스트" },
    { "slug": "insert", "label": "방명록 등록" }
  ],
  "percent": 67,
  "started_at": "2026-05-16T22:30:00",
  "backup_dir": ".practice-backup/2026-05-16_guestbook-list+insert_67",
  "target_files": [
    "src/main/java/com/study/myproject01/guestbook/controller/GuestBookController.java",
    "src/main/java/com/study/myproject01/guestbook/service/GuestBookService.java",
    "src/main/java/com/study/myproject01/guestbook/service/GuestBookServiceImpl.java",
    "src/main/java/com/study/myproject01/guestbook/mapper/GuestBookMapper.java",
    "src/main/resources/mapper/guestbook-mapper.xml"
  ]
}
```

단일 기능이어도 `features` 배열에 1개 원소로 기록.

#### f. README.md 생성

`practice/<회차>/README.md`:
- 회차 정보 (기능, 퍼센티지, 시작 시각)
- **학습 대상 파일 경로 5개 명시** (사용자가 IntelliJ에서 어디 열어서 작업할지)
- 빈칸 카테고리 매핑 (어떤 카테고리가 빈칸인지)
- "IntelliJ에서 위 5개 파일 열고 `_____` 채우기. 끝나면 `/연습 채점`."

#### g. PROGRESS.md 갱신

해당 셀을 ⌛(진행 중)로 변경. `마지막 갱신` 날짜 오늘로.

---

### 2-A-장인. 장인 모드 (5-파일 묶음 통째)

100% 모드의 상위. 토큰 빈칸 박지 않음. **5-파일 묶음 전체를 빈 파일로 덮어쓰기** — 사용자가 import부터, 클래스 선언부터, 어노테이션 위치부터, 메소드 시그니처부터, SQL부터 전부 직접 작성. 강사 코드 대신 README의 **스펙(URL/요청/응답/SQL 동작)** 만 보고 5-파일 묶음을 처음부터 짜는 모드.

#### a. 입력

5-파일 묶음 매트릭스 출력 후 기능+퍼센티지 자리에 `장인` 입력. 부분 기능 선택 불가 — **컨트롤러의 모든 구현된 기능을 한꺼번에 작업**. 잠금(🔒) 기능은 자동 제외.

#### b. 회차 폴더

```
practice/YYYY-MM-DD_<도메인>-장인/
```
예: `practice/2026-05-17_guestbook-장인/`. 같은 이름 폴더 있으면 `_2`, `_3` 추가.

#### c. 백업

5-파일 묶음 일반 모드와 동일. `.practice-backup/<session-id>/` 에 5개 파일 그대로 복사.

#### d. src/ 빈 파일로 덮어쓰기

각 학습 대상 파일을 다음 내용으로 덮어쓰기:

**Controller / Service / ServiceImpl / Mapper (.java)**:
```java
package com.study.myproject01.<도메인>.<하위>;

// 장인 모드: 본인이 처음부터 작성
```

**Mapper XML**:
```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper
        PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"
        "https://mybatis.org/dtd/mybatis-3-mapper.dtd">

<mapper namespace="com.study.myproject01.<도메인>.mapper.<도메인>Mapper">

</mapper>
```

= 패키지 선언 / 네임스페이스만 있고 나머지 0줄.

#### e. `.state` 파일

```json
{
  "mode": "5-file-craftsman",
  "session_id": "2026-05-17_guestbook-장인",
  "domain": "guestbook",
  "started_at": "2026-05-17T22:30:00",
  "backup_dir": ".practice-backup/2026-05-17_guestbook-장인",
  "target_files": [
    "src/main/java/com/study/myproject01/guestbook/controller/GuestBookController.java",
    "src/main/java/com/study/myproject01/guestbook/service/GuestBookService.java",
    "src/main/java/com/study/myproject01/guestbook/service/GuestBookServiceImpl.java",
    "src/main/java/com/study/myproject01/guestbook/mapper/GuestBookMapper.java",
    "src/main/resources/mapper/guestbook-mapper.xml"
  ],
  "spec": {
    "features": [
      {
        "label": "방명록 리스트",
        "url": "GET /guestbook/list",
        "request": "없음",
        "response": "DataVO { success, message, data: List<GuestBookVO> }",
        "sql_intent": "g_active=0 인 행 전체 SELECT"
      }
    ]
  }
}
```

`spec.features` 는 강사 백업 코드 분석해서 자동 채움 — URL(`@GetMapping/@PostMapping`), 시그니처, SQL 동작을 추출.

#### f. README.md — 스펙 명세

코드 0줄. URL/요청/응답/SQL 동작만 박음.

```markdown
# YYYY-MM-DD <도메인> 장인 모드

## 모드
**장인 모드** — 5-파일 묶음 통째 빈 파일에서 시작. 토큰 빈칸 없음. 본인이 import부터 SQL까지 처음부터 작성.

## 학습 대상 파일 (전부 빈 상태, 패키지 선언만 박힘)
1. src/.../controller/<도메인>Controller.java
2. src/.../service/<도메인>Service.java
3. src/.../service/<도메인>ServiceImpl.java
4. src/.../mapper/<도메인>Mapper.java
5. src/main/resources/mapper/<도메인>-mapper.xml

## 스펙 (참고용 — 구현은 본인이)

### 기능 1: 방명록 리스트
- URL: GET /guestbook/list
- 요청: 없음
- 응답: DataVO { success, message, data: List<GuestBookVO> }
- SQL: g_active=0 인 행 전체 SELECT

### 기능 2: 방명록 등록
(반복)

## 진행 방법
1. IntelliJ에서 5개 파일 열고 통째 작성
2. import, 어노테이션, 클래스 선언, 메소드 시그니처, SQL 모두 본인이
3. 빌드 통과 확인: `./gradlew build`
4. 끝나면 `/연습 채점`

## 채점 방식 (토큰 비교 X)
- 컴파일 통과 (`./gradlew build`)
- 강사 스펙 ↔ 시그니처/URL/SQL 매칭
- 5-파일 일관성 (메소드명 5곳)
- SCORE_<N>.md 에 기능 단위 체크리스트로 결과 기록
```

#### g. PROGRESS.md 영향

장인 모드는 33/67/100 매트릭스 셀 갱신 **안 함**. PROGRESS.md 끝에 별도 섹션 "장인 회차 기록" 자동 추가/갱신 (구조는 PROGRESS.md 구조 섹션 참고).

---

### 2-B. 단일 파일 모드

#### a. 퍼센티지 선택

```
난이도 입력 (33, 67, 100 중 하나):
33  — 빈칸 풀의 약 1/3 (P1~P4 핵심 위주)
67  — 빈칸 풀의 약 2/3 (P1~P7)
100 — 빈칸 풀 전부 (변수명/접근제어자까지)
```

#### b. 회차 폴더 + 백업 생성

회차 폴더명:
```
practice/YYYY-MM-DD_<파일명slug>_<%>/
```
- `파일명slug`: 파일명 케밥케이스 (예: `jwt-util`, `security-config`, `members-vo`)
- 같은 회차 폴더 이미 있으면 `_2`, `_3` 자동 추가.

학습 대상은 1개 파일. 그 파일을 `.practice-backup/<session-id>/`에 백업 (src/ 트리 미러).

#### c. src/ 파일 빈칸 버전으로 덮어쓰기

"빈칸 비율과 자리 정의" 룰대로 처리해서 src/ 실제 위치에 덮어쓰기.

#### d. `.state` 파일 생성

```json
{
  "mode": "single",
  "session_id": "2026-05-16_jwt-util_67",
  "file_slug": "jwt-util",
  "percent": 67,
  "started_at": "2026-05-16T22:30:00",
  "backup_dir": ".practice-backup/2026-05-16_jwt-util_67",
  "target_files": [
    "src/main/java/com/study/myproject01/common/jwt/JwtUtil.java"
  ]
}
```

#### e. README.md 생성

파일명, 퍼센티지, 학습 대상 경로, 안내.

> 단일 파일 모드는 PROGRESS.md 갱신 안 함.

---

## 모드 B: `/연습 채점` — 채점 + 원본 복구

### 1. 진행 중 회차 찾기

`practice/*/.state` 파일을 찾음.
- 0개 → 거절: "진행 중인 학습 없음. 먼저 /연습으로 시작해줘."
- 1개 → 그 회차로 진행
- 2개 이상 → 거절 + 목록 출력. 사용자에게 폴더명 지정 요청 (`/연습 채점 <회차폴더명>`)

### 2. .state 읽기

`backup_dir`, `target_files`, `session_id`, `mode`, `percent` 등 추출.

### 3. 채점

각 `target_files` 파일에 대해:
- **사용자 작성본**: `src/` 의 현재 파일 (사용자가 빈칸 채워놓은 상태)
- **원본 정답**: `.practice-backup/<session-id>/` 의 같은 경로 파일
- **빈칸 위치**: 원본 vs 빈칸 파일 비교는 필요 없음 — **사용자 작성본 vs 원본 정답** 토큰 비교

자리별 O/X 판정 (기준은 아래 "채점 기준" 표).

### 4. 사용자 작성본 → `practice/<회차>/`에 보존

각 `target_files`의 사용자 작성본을 회차 폴더 안에 동일 경로 구조로 복사:
```
practice/2026-05-16_members-login_67/
├── README.md
├── SCORE_1.md
├── .state                                                   ← 채점 후 삭제될 것
├── src/main/java/com/study/myproject01/members/controller/MembersController.java
├── src/main/java/com/study/myproject01/members/service/MembersService.java
├── src/main/java/com/study/myproject01/members/service/MembersServiceImpl.java
├── src/main/java/com/study/myproject01/members/mapper/MembersMapper.java
└── src/main/resources/mapper/members-mapper.xml
```
= **사용자 답안 영구 보존**.

### 5. SCORE_<N>.md 작성

학습형 SCORE.md. **파일 단위로 묶음**. 개념 묶음·잘한 점·다음에 할 것 섹션 **금지**.

**파일명 규칙**: `SCORE_<N>.md` (N=1부터 시작, 같은 회차 폴더에서 재채점할 때마다 +1).
- 첫 채점 → `SCORE_1.md`
- 두 번째 채점 → `SCORE_2.md` (이전 보존 — 진척 비교용)
- 회차 폴더별로 독립 카운터

```markdown
# 채점 결과 #<N> — YYYY-MM-DD <도메인> <기능> <%>

(이전 채점이 있으면 1줄: `> 이전 채점: SCORE_<N-1>.md (X/Y, Z%)`)

## 점수
**X / Y (Z%)**

| 파일 | 점수 |
| ... | ... |

---

## <파일명1> (X/Y)

### L<라인>: `<오답>` → `<정답>`
- **왜 틀렸나**: 컴파일러·런타임 관점에서 근본 원인 (1~3줄)
- **외우는 법**: 다음번에 안 틀리게 하는 패턴/연상법 (1~2줄)

(반복)

---

## <파일명2> (X/Y)
(반복)
```

#### 작성 룰

- **파일 단위 묶음 고정**: Controller → Service → ServiceImpl → Mapper → XML 순. 5-파일 묶음이면 5개 섹션, 단일 파일이면 1개 섹션
- **각 오답마다 정답 박을 것**. 빈칸 자리의 정답 토큰만
- **맞은 빈칸은 SCORE.md에 안 적음**. 틀린 것만 나열
- **잘한 점 / 다음에 할 것 / 개념별 묶음 섹션 박지 말 것**
- **왜 틀렸나·외우는 법은 매 오답마다 1~3줄로 짧게**. 똑같은 이유로 여러 군데 틀렸으면 첫 번째에만 자세히 쓰고 다음부터는 "같은 이유" 한 줄
- 미작성(`_____` 그대로) 빈칸도 오답. 정답 박고 "미작성" 이유 한 줄

### 6. src/ 원본 복구

`.practice-backup/<session-id>/` 의 파일들을 src/ 의 같은 경로로 복사 (덮어쓰기) → src/ 가 학습 전 강사 코드 상태로 복귀.

### 7. 정리

- `.practice-backup/<session-id>/` 폴더 삭제
- `practice/<회차>/.state` 파일 삭제
- `practice/<회차>/`는 그대로 (README + SCORE_*.md + 답안 보존)

### 8. PROGRESS.md 갱신 (5-파일 묶음일 경우)

`.state`의 `features` 배열 각 기능에 대해 **기능별로 채점 → PROGRESS 셀 갱신**:
- 만점 → ✅
- 부분 점수 → ⌛ 유지
- 0점 → ⬜ 회귀

다중 기능이면 각 행의 해당 % 셀을 각각 갱신.

단일 파일 모드는 PROGRESS.md 안 건드림.

### SCORE.md 다중 기능 처리

SCORE.md는 **파일 단위** 묶음 유지하되, 다중 기능이면 점수 표에 기능별 합계도 표시:
```markdown
| 기능 | 점수 |
| 방명록 리스트 | X/Y |
| 방명록 등록 | X/Y |

| 파일 | 점수 |
| GuestBookController.java | X/Y |
...
```
오답 섹션은 파일 단위로만. 기능별 분리하지 않음 (같은 파일에 두 기능 메소드가 들어있어도 한 섹션에 다 나열).

### 9. 채팅 응답

채팅엔 다음만:
1. 총점 (한 줄)
2. `[SCORE.md](path) 참고` 안내
3. "src/ 원본 복구 완료. git diff 0 확인 가능." 한 줄

오답 나열·요약 채팅에 박지 말 것.

---

## 장인 모드 채점 (mode == `5-file-craftsman`)

`.state` 의 `mode` 가 `5-file-craftsman` 이면 위의 일반 채점(3~5, 8단계)을 우회하고 다음 절차로 진행. 토큰 자리 비교 안 함 — 자리 자체가 없음.

### a. 빌드 검사

`./gradlew build` 실행. 결과 캡처.
- 통과: PASS
- 실패: FAIL — 컴파일 에러 메시지를 SCORE.md 메모에 3줄 이내로 인용

### b. 기능별 매칭

`.state` 의 `spec.features` 각 기능마다 사용자 작성본을 4가지 축으로 검사:

| 체크 | 기준 |
|---|---|
| URL 매핑 | 컨트롤러에 해당 `@GetMapping/@PostMapping` 있는지 |
| 시그니처 | 메소드 리턴 타입·파라미터가 스펙과 의미 단위 일치 |
| 5-파일 일관성 | Controller 호출명 ↔ Service ↔ Impl ↔ Mapper ↔ XML id 동일 |
| SQL 의미 | 강사 의도(`sql_intent`)와 사용자 SQL이 의미적으로 같은지 (테이블·컬럼·조건) |

기능당 4점. 일반 모드의 토큰 자리별 점수와는 다른 척도.

### c. 사용자 작성본 보존

일반 모드와 동일 — `practice/<회차>/src/...` 트리에 사용자 코드 복사.

### d. SCORE_<N>.md (장인 모드 형식)

```markdown
# 장인 모드 채점 #N — YYYY-MM-DD <도메인>

## 빌드
[O/X] `./gradlew build` 통과
(실패 시 에러 메시지 인용 — 3줄 이내)

## 기능 1: <기능명>
- [O/X] URL 매핑 (<URL>)
- [O/X] 시그니처
- [O/X] 5-파일 일관성
- [O/X] SQL 의미 (<sql_intent>)
- 메모: <발견된 이슈 / 개선점, 1~3줄>

(기능 반복)

## 종합
- 빌드: O/X
- 기능 통과율: X/Y (각 기능 4점 만점 합계)
- 평가: 2~3줄 코멘트 (강점·약점)
```

### e. src/ 원본 복구

일반 모드와 동일 — 백업에서 src/로 복사.

### f. PROGRESS.md 갱신 — 장인 회차 기록 섹션

매트릭스 셀은 안 건드림. PROGRESS.md 끝에 "장인 회차 기록" 섹션 있는지 확인, 없으면 추가, 있으면 새 행 append (구조는 아래 PROGRESS.md 구조 섹션 참고).

### g. 정리 + 채팅 응답

일반 모드와 동일. `.practice-backup/` 삭제, `.state` 삭제, 회차 폴더 보존. 채팅엔 빌드 결과 + 기능 통과율 + SCORE 링크 + 복구 안내만.

---

## 채점 기준

빈칸 위치(원본 정답 vs 사용자 작성본)별 O/X:

| 자리 유형 | 채점 기준 |
|---|---|
| **5-파일 묶음 메소드명** | **사용자가 5곳에서 일관되게 사용했으면 O**. 강사 코드와 다른 이름이어도 동작하면 인정 |
| getter/setter, 필드 접근 | 완전 일치 (Lombok 자동 생성이라 변경 불가) |
| 어노테이션 이름·파라미터 | 완전 일치 |
| SQL 식별자 (테이블·컬럼) | 완전 일치 (대소문자 무시) |
| 문자열 리터럴 | 의미 비슷하면 O |
| 변수 타입, 시그니처 리턴 타입, 생성자 | 완전 일치 |
| 조건 연산자, 값 토큰, 흐름 키워드 | 의미 동일하면 O (예: `Boolean.FALSE` ↔ `false` 허용) |
| 변수명, 컨트롤러 메소드명 (100%만) | 사용자가 일관되게 사용했으면 O |

**원칙**: "동작 가능하면 O". 강사 코드와 비교는 스타일 차이일 뿐 오답 아님.

점수: `맞은 빈칸 / 전체 빈칸`

---

## PROGRESS.md 구조

위치: `practice/PROGRESS.md` (회차 폴더 밖, 마스터 진척도)

PROGRESS.md가 없으면 `/연습` 첫 실행 시 자동 생성. 기능 목록은 `src/`의 컨트롤러를 분석해서 동적으로 채움.

```markdown
# 5-파일 묶음 연습 진척도

마지막 갱신: YYYY-MM-DD

## GuestBook (`/guestbook`)
| # | 기능 | 33% | 67% | 100% |
|---|---|---|---|---|
| 1 | 방명록 리스트 | ⬜ | ⬜ | ⬜ |
| 2 | 방명록 등록 | ⬜ | ⬜ | ⬜ |
| 🔒 | 방명록 상세 (강사 미구현) | | | |

## Members (`/members`)
| # | 기능 | 33% | 67% | 100% |
|---|---|---|---|---|
| 1 | 로그인 | ⬜ | ⬜ | ⬜ |
| 2 | 토큰 재발급 | ⬜ | ⬜ | ⬜ |
| 3 | 마이페이지 | ⬜ | ⬜ | ⬜ |
| 🔒 | 로그아웃 (강사 미구현) | | | |

## 표기
- ⬜ 미진행
- ⌛ 진행 중 (빈칸 생성 후 채점 전)
- ✅ 만점 완료
- 🔒 잠김 (강사 미구현)

## 잠금 해제 방법
강사가 새 기능을 강의/구현한 후, 위 표에서 해당 행의 🔒를 #(다음 번호)로 바꾸고 셀을 ⬜로 추가.

## 장인 회차 기록 (5-파일 묶음 통째 작성)
*장인 모드 채점 후 자동 추가/갱신. 매트릭스와 별개 트랙.*

| 날짜 | 도메인 | 빌드 | 기능 통과 | 메모 |
|---|---|---|---|---|
| 2026-05-17 | GuestBook | O | 2/2 | 4점 만점 |
```

### 학습 곡선 기준 기본 순서 (PROGRESS 자동 생성 시 적용)

**GuestBook** (JWT 무관 → 진입용):
1. 리스트 조회 (단순 SELECT)
2. 등록 (INSERT + `@RequestBody`)
3. 상세 — 강사 미구현이면 🔒

**Members** (JWT 필요):
1. 로그인 (BCrypt + JwtUtil + 2테이블)
2. 토큰 재발급 (로그인 패턴 재활용)
3. 마이페이지 (SecurityContext)
4. 로그아웃 — 강사 미구현이면 🔒

---

## .gitignore 추가 사항

이 스킬은 다음 항목이 `.gitignore`에 있다고 가정한다 (없으면 추가):
```
.practice-backup/
practice/*/.state
```

이유:
- `.practice-backup/`: 학습 중 임시 백업. commit 대상 아님.
- `practice/*/.state`: 학습 중 상태 마커. 휘발성.

회차 폴더 자체와 README, SCORE_*.md, 답안 파일들은 git에 commit해서 보존.

---

## 다른 스킬들과의 충돌 방지

`practice/*/.state`가 존재하는 동안 다음 스킬은 거절해야 함:
- `/강사싱크` — src/가 빈칸 상태라 머지 꼬임
- `/푸쉬` — 빈칸 상태가 git에 들어감

각 스킬에서 사전 체크 후 거절 메시지 출력. 사용자에게 `/연습 채점` 먼저 안내.
