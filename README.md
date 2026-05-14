# claude-skills

Claude Code 글로벌 skill 모음. 새 컴퓨터에서 셋업하면 모든 프로젝트에서 `/강사싱크`, `/시작`, `/노션메모`, `/노션정리`, `/푸쉬`, `/연습`, `/힌트` 사용 가능.

---

## 새 컴퓨터 셋업 (한 번만)

### 방법 ① — 더블클릭 (가장 쉬움)

1. 이 레포를 적당한 위치에 클론
   - GitHub Desktop, VS Code의 "Clone Repository", 또는 명령어로:
     ```
     git clone https://github.com/jungwonil11-jpg/claude-skills
     ```
2. 파일 탐색기로 클론된 `claude-skills` 폴더 열기
3. 안에 있는 **`setup.bat`** 파일을 **더블클릭**
4. 검정 창이 뜨면서 `Done: skills copied to ...` 메시지 출력
5. `Press any key to continue . . .` 나오면 아무 키나 눌러서 닫기

### 방법 ② — CMD 명령어로

1. **시작 메뉴 → "cmd" 검색 → 명령 프롬프트** 실행
2. 다음 3줄을 순서대로 입력:
   ```cmd
   git clone https://github.com/jungwonil11-jpg/claude-skills
   cd claude-skills
   setup.bat
   ```

### ⚠️ 마지막 한 가지 — Claude Code 재시작 필수

setup.bat을 돌렸다고 바로 슬래시 커맨드가 뜨지 않음.
**Claude Code를 종료했다가 다시 실행해야** `/푸쉬`, `/노션메모` 등이 자동완성에 나타남.

이미 켜져 있다면:
- `/exit` 입력 또는 창 닫기 → 다시 `claude` 실행
- VS Code 등 IDE 내 Claude Code 패널이면 패널 닫고 다시 열기

### 레포 업데이트 후

이 레포에 새 skill이 추가되면, 본인 PC에서:
1. `claude-skills` 폴더에서 `git pull` (또는 GitHub Desktop에서 Pull)
2. `setup.bat` 다시 더블클릭
3. Claude Code 재시작

---

## Skill 목록

| Skill | 설명 |
|--------|------|
| `/강사싱크` | 수업 끝난 직후 실행. 강사 코드를 main에 미러링하고 study에 머지. |
| `/시작` | 다른 컴퓨터에서 자습 시작 전 실행. study 브랜치를 최신 상태로 동기화. |
| `/노션메모` | 직전 대화에서 설명한 내용을 노션 학습 노트에 추가. |
| `/노션정리` | 프로젝트 전체를 파악해 노션을 동기화. 처음 실행 시 CLAUDE.md에 정리 방식 자동 기록. |
| `/푸쉬` | 현재 브랜치를 origin에 push. fetch → 충돌 분석 → 사용자 결정 → push. |
| `/연습` | 프로젝트 파일의 빈칸 골격을 `practice/YYYY-MM-DD/` 폴더에 생성 → IDE에서 작성 → `/연습 채점`으로 채점. |
| `/힌트` | `/연습` 풀다가 막혔을 때 호출. 개념부터 정답까지 섹션별로 설명해줌. |

---

## 특정 프로젝트에서 skill 끄기

수업용 skill(`/강사싱크`, `/시작`)이 일반 프로젝트 메뉴에 뜨는 게 싫으면, 그 프로젝트에 `.claude/settings.local.json` 추가:

```json
{
  "skillOverrides": {
    "강사싱크": "off",
    "시작": "off"
  }
}
```

`.local.json` 은 보통 gitignore 되므로 팀원에게는 안 보이고 본인 PC에만 적용됨.

---

## 새 수업 프로젝트 시작할 때

**1. 프로젝트 repo의 `CLAUDE.md`에 강사 정보 추가**

```markdown
## 강사 정보
- upstream: https://github.com/강사계정/강사repo
```

**2. `/강사싱크` 실행** → CLAUDE.md에서 URL을 읽어 upstream 자동 등록

---

## /노션정리 사용할 때

처음 실행하면 Claude가 프로젝트 구조를 보고 정리 방식을 판단해 `CLAUDE.md`에 자동 기록함.

```markdown
## 노션 정리 방식
- 노션 상위 페이지: 🐍 Python 강의
- 하위 페이지 구성: day별
- 정리 기준: 코드 파일 기준
```

이후 실행부터는 `CLAUDE.md`를 읽어 그 방식대로 노션 동기화.
수정이 필요하면 `CLAUDE.md`의 해당 섹션을 직접 편집하면 됨.

---

## 팀 프로젝트에서 /푸쉬 사용할 때

프로젝트 `CLAUDE.md`에 아래 두 줄 추가:

```markdown
## 브랜치 정보
- my-branch: 내브랜치명
- integration-branch: dev
```

`/푸쉬` 실행 시 CLAUDE.md에서 자동으로 읽어옴.

---

## /연습 + /힌트 사용법

AI 도움 없이 배운 코드를 직접 처음부터 작성해보는 연습 사이클.

### 연습 시작

```
/연습
```

1. `src/` 를 탐색해 지금까지 배운 파일을 카테고리별 번호 목록으로 출력
2. 번호 입력으로 연습할 파일 선택 (복수 선택 가능, 예: `1,3` 또는 `1-3`)
3. 난이도 선택
   - `0` 왕초보 — 실제 코드 거의 그대로, 핵심 토큰만 `_____` 빈칸 (fill-in-the-blank)
   - `1` 쉬움 — TODO 힌트에 메서드명까지 알려줌
   - `2` 보통 — 로직 흐름 설명만
   - `3` 어려움 — 메서드 시그니처만, 힌트 없음
4. 프로젝트 루트 `practice/YYYY-MM-DD/` 폴더에 원본 확장자 그대로 빈칸 파일 생성
   - 예: `practice/2026-05-13/JwtUtil.java`, `practice/2026-05-13/members-mapper.xml`
   - `README.md` 도 같이 생성됨
5. IDE에서 폴더 열고 `_____` 빈칸 채우기

### 막혔을 때 — /힌트

빈칸 풀다가 모르겠으면:

```
/힌트              # 최근 연습 폴더 자동 탐지
/힌트 JwtUtil      # 특정 파일 지정 (확장자 생략 OK)
```

- 도메인 개념부터 → 섹션별 빈칸 코드 → 의도 설명 → 정답 코드 순으로 풀어줌
- 사용자가 이미 채운 건 무시하고 원본 기준으로 설명 (평가는 `/연습 채점`의 영역)

### 채점

빈칸 다 채우면:

```
/연습 채점
```

- `practice/YYYY-MM-DD/` 의 가장 최근 폴더 자동 탐지
- 빈칸별 O/X + 점수 + 힌트를 `SCORE.md` 에 기록
- 정답 코드 전체는 바로 주지 않고 힌트만 제공 — 재도전 유도

### 왜 노션이 아니라 로컬 파일?

이전엔 노션에 빈칸 페이지를 생성했는데, Cloudflare 차단 + 노션 코드 블록 직접 편집 불편 등 비효율적이라 로컬 파일 방식으로 확정함. IDE에서 syntax highlighting 받으면서 빈칸 채우는 게 학습/채점 모두에 적합.

---

## 브랜치 전략 (수업 프로젝트)

| 브랜치 | 역할 |
|--------|------|
| `main` | 강사 코드 미러. 직접 작업 금지. |
| `study` | 자습·실습·주석 작업 공간. |

- `.claude/`, `CLAUDE.md`, `CLAUDE.local.md` 는 `study` 에만 존재 (`main` commit 금지)
- `study` 브랜치에서 `.claude/` 파일 수정 시 `git add -f .claude/` 필요
