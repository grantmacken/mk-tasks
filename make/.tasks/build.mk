
define buildHelp
=========================================================
LAST TAG: $(lastTag)
RELEASE STRATEGY: $(releaseStrategy)
NEXT TAG: $(nextTag)
XAR: $(XAR)

BUILD : create a release xar
   < repack package files
    [ build  ] ->
 -> [ deploy ] xar zip created

==========================================================


endef

build-help: export buildHelp:=$(buildHelp)
build-help:
	echo "$${buildHelp}"

build: 
	@echo '##[ $@ ]##'
	@echo 'recreate package files and put into build folder'
	@$(MAKE) --silent package
	@echo 'building $(XAR) and put into deploy folder ' 
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


.PHONY: build-help build build-clean build-restore

$(XAR): config
	@echo "##[ $@ ]##"
	@mkdir -p $(dir $@)
	@echo "XAR FILE $@"
	@cd $(B); zip -r ../$@ .

