# git

## Don't ask

- `git status`, `git diff`, `git log`, `git show`, `git blame`
- `git branch --list`, `git fetch`
- `git add`, `git rm`, `git mv`
- `git switch`, `git switch -c`, `git checkout <branch>`, `git checkout -b`
- `git stash`, `git stash push`
- `git reset --soft`
- `git commit`
- `git worktree add`
- `gh pr view`, `gh pr list`, `gh pr diff`, `gh issue view`, `gh issue list`
- `gh issue create`, `gh issue comment`, `gh issue close`, `gh issue edit`

## Ask

- `git push`
- `git pull`, `git merge`, `git rebase`
- `git cherry-pick`, `git revert`
- `git reset`, `git reset --mixed`
- `git restore <file>`
- `git stash pop`
- `git tag`
- `git worktree remove`
- `gh pr create`, `gh pr merge`, `gh pr comment`, `gh pr edit`

## Never do

- `git push --force`, `git push --force-with-lease`
- `git push --delete`
- `git reset --hard`, `git clean -fdx`
- `git checkout -- .`, `git restore .`
- `git branch -D`
- `git stash drop`, `git stash clear`
- `git commit --no-verify`
- `git remote add`, `git remote set-url`
- `git config --global`
- `gh issue delete`
