let
  commands =
    verdict:
    map (command: {
      inherit verdict command;
    });
in
commands "dont-ask" [
  "git status"
  "git diff"
  "git log"
  "git show"
  "git blame"
  "git branch --list"
  "git fetch"
  "git add"
  "git rm"
  "git mv"
  "git switch"
  "git switch -c"
  "git checkout -b"
  "git stash"
  "git stash push"
  "git reset --soft"
  "git commit"
  "git worktree add"
  "gh pr view"
  "gh pr list"
  "gh pr diff"
  "gh issue view"
  "gh issue list"
  "gh issue create"
  "gh issue comment"
  "gh issue close"
  "gh issue edit"
]
++ [
  {
    verdict = "dont-ask";
    prose = "Switching to an existing branch with `git checkout <branch>`, when the argument names a branch and not a file or path.";
  }
]
++ commands "ask" [
  "git push"
  "git pull"
  "git merge"
  "git rebase"
  "git cherry-pick"
  "git revert"
  "git reset"
  "git reset --mixed"
  "git restore"
  "git stash pop"
  "git tag"
  "git worktree remove"
  "gh pr create"
  "gh pr merge"
  "gh pr comment"
  "gh pr edit"
]
++ commands "never-do" [
  "git push --force"
  "git push --force-with-lease"
  "git push --delete"
  "git reset --hard"
  "git clean -fdx"
  "git checkout -- ."
  "git restore ."
  "git branch -D"
  "git stash drop"
  "git stash clear"
  "git commit --no-verify"
  "git remote add"
  "git remote set-url"
  "git config --global"
  "gh issue delete"
]
