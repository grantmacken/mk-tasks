
print-enviroment:
	@printenv

help:
	@echo 'BIN_DIR ': $(abspath ../bin)
	@echo 'SAXON ': $(SAXON)
	@echo 'REPO_SLUG': $(REPO_SLUG)
	@echo 'OWNER': $(OWNER)
	@echo 'REPO': $(REPO)
	@echo 'DESCRIPTION: $(DESCRIPTION)'
	@echo 'ABBREV: $(ABBREV)'
	@echo 'WEBSITE: $(WEBSITE)'
	@echo 'API_REPO: $(API_REPO)'
	@echo 'CURRENT_BRANCH: $(CURRENT_BRANCH)'
	@echo 'VERSION: $(VERSION)'
ifneq ($(TRAVIS_TAG),)
	@echo 'TRAVIS_TAG: $(TRAVIS_TAG)'
endif
ifdef PARSED_ISSUE_NUMBER
	@echo 'PARSED_ISSUE_LABEL: $(PARSED_ISSUE_LABEL)'
	@echo 'PARSED_ISSUE_NUMBER: $(PARSED_ISSUE_NUMBER)'
	@echo 'PARSED_ISSUE_TITLE: $(PARSED_ISSUE_TITLE)'
endif
	@echo XAR $(XAR)
	@echo TINY-LR_UP $(TINY-LR_UP)

.PHONY: generate-certificate view-certificate

generate-certificate:
	@echo "$(NAME)"
	@echo "$(ABBREV)"
	@echo "$(EXIST_HOME)/tools/jetty/etc"
	@ls "$(EXIST_HOME)/tools/jetty/etc"
	@keytool -genkeypair \
   -keystore $(EXIST_HOME)/tools/jetty/etc/keystore \
  -dname "CN=$(NAME), OU=eXist-db Application Server, O=eXist-db, L=Awhitu, ST=Auckland, C=NZ" \
  -keypass secret \
  -storepass secret \
  -keyalg RSA \
  -keysize 2048 \
  -alias $(ABBREV) \
  -ext SAN=DNS:$(NAME) \
  -validity 9999

view-certificate:
	keytool -list -v \
 -alias $(ABBREV) \
 -storepass secret \
  -keystore $(EXIST_HOME)/tools/jetty/etc/keystore \
