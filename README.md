# mk-tasks

my Make tasks for working with projects

make build

uses stow to
1. symlink to bin dir one level up
2. symlink properties files to one level up
3. symlink node package.json file to one level up
  note: when calling node from a web project dir node will move up the dir tree looking
  for node_modules dir

