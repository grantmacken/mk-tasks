# mk-tasks

my Make tasks for working with projects

make build

1. copies mk-includes into your ~/bin dir
2. copy Makefile into web-projects dir
3. copy properties files to one level up
3. node: copy package.json file to one level up
  note: when calling node from a web project dir node will move up the dir tree looking
  for node_modules dir
