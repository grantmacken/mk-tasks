#Web Project Tasks

Make tasks and shell scripts for 
working with web projects under git control

This project provides helper tools for working with 
multiple website projects, that uses a web server setup consisting of 
 - OpenResty  in front of 
 - eXist  ( a XML data store in a jetty container )


```
cd  -p ~\projects\$( git config --get user.name )
git clone git@github.com:grantmacken/mk-tasks.git
cd mk-tasks
make help
```
# website projects

1. Establish a projects directories structure

```
echo "$( git config --get user.name )"
mk  -p ~\projects\$( git config --get user.name )
```

2. Set up website domain named directories

Assume we are in a ~/projects/{GIT_USER} dir
Our web projects will be in website domain named directories, like so

`~/projects/{GIT_USER}/{DOMAIN}`

~/projects/grantmacken/gmack.nz
~/projects/grantmacken/zie.nz

3. Define your web projects in the config located at the root of the project

`WEB_PROJECTS=gmack.nz zie.nz example.com`

# set up mk-tasks

make will use stow to
1. symlink to bin dir one level up
2. symlink properties files to one level up
3. symlink node package.json file to one level up
4. symlink project Makefile and make includes into `.tasks`dir into each web project.

What does this do?

bin:           a common  web projects bin dir populated with helper scripts
node_modules:  a common web projects node_module dir 
common.properties:  constants that can be included by Make or sourced by Bash scripts
project.properties: property values evaluated in a git repo context

Each project in the WEB_PROJECTS list will have it own
- symlinked Makefile in the projects root dir
- symlinked .tasks dir in the projects root dir

The tasks are now available by invoking Make in root of a web-project

```
cd  ~\projects\$( git config --get user.name )/gmack.nz
make help

```


##node notes:

when calling node from a web project dir, node will move up the dir tree looking for node_modules dir

##stow notes.

This project depends on Stow.
Stow can be installed through  apt-get, the  ubuntu repo is out of date so use Perls package manager `cpan` instead
`cpan install Stow`

## Whats Here

1. 





