define deployHelp
=========================================================
DEPLOY : create a deployment release xar

    < src build
     [ deploy ]   release xar created
     [ upload ]   deployment to dev server.
     [ check ]    with prove run functional tests
==========================================================

`make deploy`
`make watch-deploy`
`make deploy-help`

 1. deploy 
 2. watch-deploy  ...  watch the directory
  'make deploy' will now be triggered by changes in dir
endef


deploy-help: export deployHelp:=$(deployHelp)
deploy-help:
	echo "$${deployHelp}"

build-xar: 
	@$(MAKE) --silent $(XAR)

build-xar-clean: 
	@[ -e  $(XAR) ] && rm $(XAR) || echo 'no xar to remove'

build-clean:
	@$(MAKE) --silent build-xar-clean
	@rm -r $(B)/*

build-restore:
	@$(MAKE) --silent build-clean
	@$(MAKE) --silent templates-touch
	@$(MAKE) --silent $(BUILD_TEMPLATES)
	@$(MAKE) --silent modules-touch
	@$(MAKE) --silent $(BUILD_XQM) $(BUILD_XQ)
	@$(MAKE) --silent icons-touch
	@$(MAKE) --silent $(BUILD_ZIPPED_ICONS)
	@$(MAKE) --silent images-touch
	@$(MAKE) --silent $(BUILD_IMAGES)
	@$(MAKE) --silent styles-touch
	@$(MAKE) --silent $(BUILD_STYLES)
	@$(MAKE) --silent scripts-touch
	@$(MAKE) --silent $(BUILD_SCRIPTS)
	@$(MAKE) --silent pack

$(XAR): config
	@echo "##[ $@ ]##"
	@mkdir -p $(dir $@)
	@echo "XAR FILE $@"
	@cd $(B); zip -r ../$@ .

# @cd $(B); zip -r ../$@ . -x 'data/archive/*' 'data/pages/*'
