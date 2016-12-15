#Web Project Tasks

Make tasks and shell scripts for working with web projects

Assume we are in a ~/projects/{REPO_OWNER} dir
Our web projects will be in domain named directories, like so
`~/projects/grantmacken/gmack.nz`

cd into  project dir  `~/projects/grantmacken`  

clone this project and cd into it

make build

will use stow to
1. symlink to bin dir one level up
2. symlink properties files to one level up
3. symlink node package.json file to one level up
4. symlink project Makefile  `.tasks`dir into each web project.


##node notes:

when calling node from a web project dir, node will move up the dir tree looking for node_modules dir

##stow notes.

This project depends on Stow.
Stow can be installed through  apt-get, the  ubuntu repo is out of date so use Perls package manager `cpan` instead
`cpan install Stow`

## Whats Here


