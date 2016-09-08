#==========================================================
# CONTENT
#  content is the working directory for entries written in markdown
#  contentType ( pages |  posts )
#  postTypes   ( articles | notes )
#
#  {project}/content{contentType}
#  pages =  entries in a named collection hierachy
#  {project}/content/pages/{collectionName}
#  posts =  entries in a date stamped archive
#  {project}/content/posts/{postType}
#
# markdown is stored on server using the following template URI https://tools.ietf.org/html/rfc6570
#  /db/data/{project}/posts/{postType}/{year}-{month}-{day}-{name}
#  /db/data/{project}/pages/{collection}/{name}
# interaction with data is via restxq
# http://exquery.github.io/exquery/exquery-restxq-specification/restxq-1.0-specification.html
#
#
#############################################################
SRC_ARTICLES := $(wildcard content/posts/articles/*.md)

ARTICLES  := $(patsubst content/%.md,$(L)/content/%.json,$(SRC_ARTICLES))

# $(info $(SRC_ARTICLES))
# $(info $(ARTICLES))

content: $(ARTICLES)

watch-content:
	@watch -q $(MAKE) content

.PHONY:   watch-content

# @xq store-built-resource \
# '$(join data/,$(NAME))' \
# '$(abspath  $(subst /$(subst $(NAME)/content/,,$(<)),,$(<)))' \
# '$(<)' \
# '$(call getMimeType,$(suffix $(notdir $(<))))' \
# 'content/$*'
# in eXist and log response

$(L)/content/%.log: content/%.md
	@echo "## $@ ##"
	@mkdir -p $(@D)
	@echo "SRC: $<"
	@echo "eXist content collection_uri: $(join apps/,$(NAME))"
	@echo "directory in file system: $(subst $(<),,$(abspath  $(<)))"
	@echo "eXist store pattern: : $(<) "
	@echo "mime-type: $(call getMimeType,$(suffix $(notdir $(<))))"
	@mkdir -p $(L)/$*
	@xq store-built-resource \
 '$(join apps/,$(NAME))' \
 '$(subst $(<),,$(abspath  $(<)))' \
 '$(<)' \
 '$(call getMimeType,$(suffix $(notdir $(<))))' \
 'content/$*'
	@echo '-----------------------------------------------------------------'

$(L)/content/%.json: $(L)/content/%.log
	@echo "## $@ ##"
	@echo "SRC: $<"
	@echo "input log: $<"
	@echo "input log last item: $(shell tail -n 1 $<)"
	@echo "output log: $@"
	@echo "suffix: $(suffix $(shell tail -n 1 $<)) "
	@curl -s --ipv4  http://localhost:35729/changed?files=$(shell tail -n 1 $<) > $@
	@echo "output last livereload item: $(shell tail -n 1 $@  | jq -r  '.files[0]')"
	@echo '-----------------------------------------------------------------'
