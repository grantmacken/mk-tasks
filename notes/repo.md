<!--

-->

#GitHub Repo tasks

1. on master
 - create issue task list file
 - create *issue*  -> receive *issue number*
 - create *branch* based on issue number
2. on branch
 - work on issue
 - update semver 
 - patch issue when issue task list altered 
 - commit any completed tasks
3. pull request
    - establish prior pull-request criteria met
    - create *pull-request* based on issue number  
    - establish merge ready state criteria met
        - comments: at least one person commented LGTM 
        - review-comments: TODO
        - status of tests
            - Establish remote Travis CI tests passed
            - Do local tests passed and generate gh status
        - combined statuses ok
    - merge
        - merge pull-request
        - delete local and remote branch -> back on master
4. [deploy](#DEPLOY)
    - create release - release tag 
    - upload release asset to github 
    - deploy
        - local deploment
        - remote deployment
 



# DEPLOY <a id="DEPLOY"/>

 note: not every merged pull-request needs to be released


