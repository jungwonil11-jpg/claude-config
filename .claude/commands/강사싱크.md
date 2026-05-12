# 강사싱크 — 수업 끝난 직후 실행

강사 코드를 main에 미러링하고, study에 머지한다.

## 실행 순서

### 1. study 브랜치 확인
현재 브랜치가 study가 아니면 `git checkout study` 실행.

### 2. study 변경사항 처리
`git status`로 변경사항 확인.
- 변경사항 있으면: commit할지 stash할지 사용자에게 물어볼 것.
  - commit 선택 시: `git add -A && git commit -m "wip: 싱크 전 저장"`
  - stash 선택 시: `git stash push --include-untracked -m "강사싱크 전 임시저장"`
- 변경사항 없으면 생략.

### 3. main으로 이동
```
git checkout main
```

### 4. upstream 확인 및 fetch
`git remote get-url upstream` 으로 upstream URL 확인.
- upstream이 없으면: CLAUDE.md에서 `upstream:` 으로 시작하는 줄을 찾아 URL을 읽어온 뒤 자동 등록:
  ```
  git remote add upstream <CLAUDE.md에서 읽은 URL>
  ```
  CLAUDE.md에도 없으면 사용자에게 직접 URL을 물어볼 것.
- fetch 실행:
  ```
  git fetch upstream
  ```

### 5. upstream/main 파일 덮어쓰기
```
git ls-tree -r upstream/main --name-only | xargs git checkout upstream/main --
```

### 6. main에 commit
변경사항 있으면:
```
git add -A && git commit -m "sync: 강사 코드 (YYYY-MM-DD)"
```
(YYYY-MM-DD는 오늘 날짜로 치환)
변경사항 없으면 commit 생략.

### 7. origin/main push
```
git push origin main
```

### 8. study로 복귀
```
git checkout study
```

### 9. main을 study에 머지
```
git merge main
```
충돌 발생 시:
- 강사가 수정한 코드 내용은 upstream 버전을 살림
- 내 주석 및 실습 코드는 study 버전을 유지
- `.claude/`, `CLAUDE.md`, `CLAUDE.local.md`는 **반드시 study 버전 유지**
- 해결 후 `git add -A && git merge --continue`

### 10. stash 복원 (2단계에서 stash했을 경우)
```
git stash pop
```

### 11. study push
```
git push origin study
```

### 12. 완료 요약
다음 항목을 출력:
- 변경된 파일 목록
- 충돌 발생 여부 및 해결 방법
- 현재 브랜치 (`git branch --show-current`)
