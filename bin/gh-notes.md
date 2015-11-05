#gh-notes

## 3 stages

1. creating a branch off master to work on an issue.
2. creating pull request and merging back into master
3. creating a release and deployable release asset

a social github work flow
-------------------------

Some notes of what I am aiming for.

1. each feature *branch* is based on an *issue* raised in github. An issue that
can developed into a branch is identified by its label (feature or bug ) and
associated with a simple *milestone* release strategy

    - `gh new-issue-md`  a markdown file with a simple task list
    - `gh create-issue`  from `ISSUE.md` file create a github issue
    - `gh create-branch-from-issue`  from the new github issue create a branch off
  master. The issue will have an associate milestone release-strategy and a
  label.

2. each issue has a public *task list* ( the feature branch being worked on)
    - github issue url - what I am working on
    - github issues url- what everbody is working on

  TODO! cron task to fetch issue events and comments from github

3. a watched issue task list ( ISSUES.md )
    - `gh commit-issue-task` on completion of task (task ticked) when saved the
      task generates the git commit message
    - `gh sync-issue` local ISSUES.md is synced to github issue so others can
      see progress made
    - all tasks ticked should mean issue resolved.

TODO! not yet happy with 3

Don't push until ready for a pull request
    - `git commit -am ''` combined changes into commit
    - `git rebase -i @{u

 notes: if I am the only person working on the branch there is no need to
 `git pull --rebase` otherwise ...

4. pull request: when issue resolved create a pull request. The pull request
   uses the github issue number, so the task list gets pulled into the pull
   request
    - `gh create-pull-request`
    - `gh info-pr-merge-state`

5. satisfy merge criteria prior to merge
    1. reviewed: a human has looked at this and added an approve comment
    with the (pr-comments url) we can
    - `gh create-pr-shipit-comment`
    - `gh create-pr-compare-url-comment`
    2. status: a machine has looked at this and passed any integration *tests*
    (pr-status ) Tests are run in travis
    not sure what to do here yet but ... linters etc.
        -local tests then generate a
        `gh create-pr-default-success-status`
    3.  pull - commit - push fix any bugs based on comments and tests

6. use github api to create a merge into master
    - `gh merge-pull-request`
    - `gh merged-pull-request`
        1. merge message based on ISSUE.md
        2. checkout master - pull --rebase
        3. delete associated local branch and remote tracked branch`

7. update semver
