define repoXML
<meta xmlns="http://exist-db.org/xquery/repo">
  <description>$(DESCRIPTION)</description>
  <author>$(AUTHOR)</author>
  <website>$(WEBSITE)</website>
  <status>alpha</status>
  <license>GNU-LGPL</license>
  <copyright>true</copyright>
  <type>application</type>
  <target>$(GIT_REPO_NAME)</target>
  <prepare>modules/pre-install.xq</prepare>
  <permissions user="$(OWNER)" group="$(OWNER)" mode="0775"/>
</meta>
endef

define expathPkgXML
<package xmlns="http://expath.org/ns/pkg"
  name="$(GIT_REPO_NAME)"
  abbrev="$(ABBREV)"
  spec="1.0"
  version="$(VERSION)">
  <title>$(GIT_REPO_NAME)</title>
</package>
endef

define collectionXconf
<?xml version="1.0" encoding="UTF-8"?>
<collection xmlns="http://exist-db.org/collection-config/1.0">
    <index xmlns:xs="http://www.w3.org/2001/XMLSchema">
        <fulltext default="none" attributes="false"/>
    </index>
</collection>
endef

pack1: export repoXML:=$(repoXML)
pack1:
	@echo "$${repoXML}" | tidy -q -xml -utf8 -e  --show-warnings no
	@echo "$${repoXML}" | tidy -q -xml -utf8 -i --indent-spaces 1 --output-file $(B)/repo.xml

pack2: export expathPkgXML:=$(expathPkgXML)
pack2:
	@echo "$${expathPkgXML}" | tidy -q -xml -utf8 -e
	@echo "$${expathPkgXML}" | tidy -q -xml -utf8 -i --indent-spaces 1 --output-file $(B)/expath-pkg.xml

pack3: export collectionXconf:=$(collectionXconf)
pack3:
	@echo "$${collectionXconf}" | tidy -q -xml -utf8 -e  --show-warnings no
	echo "$${collectionXconf}" > $(B)/collection.xconf

package:
	@$(MAKE) --silent pack1
	@$(MAKE) --silent pack2
	@$(MAKE) --silent pack3
