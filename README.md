# dotfiles

Claude Code 글로벌 커맨드 모음. 새 컴퓨터에서 셋업하면 모든 프로젝트에서 `/강사싱크`, `/시작`, `/노션추`, `/푸쉬` 사용 가능.

---

## 새 컴퓨터 셋업 (한 번만)

```powershell
git clone https://github.com/jungwonil11-jpg/dotfiles
cd dotfiles
.\setup.ps1
```

---

## 커맨드 목록

| 커맨드 | 설명 |
|--------|------|
| `/강사싱크` | 수업 끝난 직후 실행. 강사 코드를 main에 미러링하고 study에 머지. |
| `/시작` | 다른 컴퓨터에서 자습 시작 전 실행. study 브랜치를 최신 상태로 동기화. |
| `/노션추` | 직전 대화에서 설명한 내용을 노션 학습 노트에 추가. |
| `/푸쉬` | 현재 브랜치를 origin에 push. fetch → 충돌 분석 → 사용자 결정 → push. |

---

## 새 수업 프로젝트 시작할 때

**1. 프로젝트 repo의 `CLAUDE.md`에 강사 정보 추가**

```markdown
## 강사 정보
- upstream: https://github.com/강사계정/강사repo
```

**2. `/강사싱크` 실행** → CLAUDE.md에서 URL을 읽어 upstream 자동 등록

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

## 브랜치 전략 (수업 프로젝트)

| 브랜치 | 역할 |
|--------|------|
| `main` | 강사 코드 미러. 직접 작업 금지. |
| `study` | 자습·실습·주석 작업 공간. |

- `.claude/`, `CLAUDE.md`, `CLAUDE.local.md` 는 `study` 에만 존재 (`main` commit 금지)
- `study` 브랜치에서 `.claude/` 파일 수정 시 `git add -f .claude/` 필요
