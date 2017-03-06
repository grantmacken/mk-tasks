define imageHelp
===============================================================================
IMAGES : working with images
 - gif, png, jpeg 

Place in resources/images/{size} folder 
where size is what you are aiming for on the web

    < src images
     [ optimise ] use smartResize 
     [ build ]    images in  build.images dir
     [ upload ]   store into eXist dev server
     [ reload ]   TODO!  trigger live reload
     [ check ]     with prove run functional tests
=============================================================================

 Tools Used 

- ImageMagick : http://imagemagick.org/

[smart resize](https://www.smashingmagazine.com/2015/06/efficient-image-resizing-with-imagemagick/)
   
 Notes: path always relative to root

`make images`
`make watch-images`
`make images-help`

 1. images 
 2. watch-styles  ...  watch the directory
  'make images' will now be triggered by changes in dir
endef

images-help: export imageHelp:=$(imageHelp)
images-help:
	echo "$${imageHelp}"

SOURCE_IMAGES := $(shell find resources/images -name '*.png')
BUILD_IMAGES  := $(patsubst %,$(B)/%,$(SOURCE_IMAGES))
UPLOAD_IMAGE_LOGS  := $(patsubst %.png,$(L)/%.log,$(SOURCE_IMAGES))
# $(patsubst %.svg,$(L)/%.log,$(SOURCE_ICONS)) 
#############################################################
# https://www.imagemagick.org/script/escape.php

images: $(L)/upImages.log

smartResize = $(shell  mogrify \
 -path $3 \
 -filter Triangle \
 -define filter:support=2 \
 -thumbnail $2 \
 -unsharp 0.25x0.08+8.3+0.045 \
 -dither None \
 -posterize 136 \
 -quality 82 \
 -define jpeg:fancy-upsampling=off \
 -define png:compression-filter=5 \
 -define png:compression-level=9 \
 -define png:compression-strategy=1 \
 -define png:exclude-chunk=all \
 -interlace none \
 -colorspace sRGB \
 $1)

# $(call smartResize,$<,,)

# @$(call smartResize,$<,$(shell basename $(dir $<)),$@)

watch-images:
	@watch -q $(MAKE) images

.PHONY:  watch-images

$(B)/resources/images/%.png: resources/images/%.png
	@echo "## $@ ##"
	@[ -d @D ] || mkdir -p $(@D)
	@echo "SRC: [ $< ]"
	@echo "Orginal Width: [ $$(identify -format '%w' $<) ]"
	@echo "Aim For Width: [ $(shell basename $(dir $<)) ]"
	@mogrify -path $(dir $@) \
 -filter Triangle \
 -define filter:support=2 \
 -thumbnail $(shell basename $(dir $<)) \
 -unsharp 0.25x0.08+8.3+0.045 \
 -dither None \
 -posterize 136 \
 -quality 82 \
 -define jpeg:fancy-upsampling=off \
 -define png:compression-filter=5 \
 -define png:compression-level=9 \
 -define png:compression-strategy=1 \
 -define png:exclude-chunk=all \
 -interlace none \
 -colorspace sRGB  $<
	@echo "Orginal size: [ $$(identify -format '%b' $<) ]"
	@echo " Build  size: [ $$(identify -format '%b' $@) ]"

$(L)/resources/images/%.log: $(B)/resources/images/%.png
	@echo "## $@ ##"
	@mkdir -p $(@D)
	@echo 'Upload $(basename $@) to eXist'
	@xQstore $< > $@
	@echo "Uploaded eXist path: [ $$(cat $@) ]"


$(B)/resources/images/%.jpeg: resources/images/%.jpeg
	@echo "## $@ ##"g
	@[ -d @D ] || mkdir -p $(@D)
	@echo "SRC: [ $< ]"
	@echo "STEM: [ $* ]"

$(B)/resources/images/%.gif: resources/images/%.gif
	@echo "## $@ ##"
	@[ -d @D ] || mkdir -p $(@D)
	@echo "SRC: [ $< ]"
	@echo "STEM: [ $* ]"

$(L)/upImages.log: $(UPLOAD_IMAGE_LOGS) 
	@$(MAKE) --silent $(UPLOAD_IMAGE_LOGS) 
	@echo '' > $@ 
	@for log in $(UPLOAD_IMAGE_LOGS); do \
 cat $$log >> $@ ; \
 done
	@echo "$$( sort $@ | uniq )" > $@
	@sleep 1 && clear
	@echo '----------------------------'
	@echo '|  Uploaded Images In eXist  |'
	@echo '----------------------------'
	@cat $@
	@echo '----------------------------'
	@sleep 1
	@echo '----------------------------'
	@echo '| Run Test With Prove       |'
	@echo '----------------------------'
	@touch $(UPLOAD_IMAGE_LOGS) 
	@prove -v t/images.t

# @sleep 1
# @echo '-----------------------------'
# @echo '| Dump View With W3M browser |'
# @echo '-----------------------------'
# @w3m -dump $(WEBSITE)/images/mail
# @echo '-----------------------------'

images-clean:
	@rm $(L)/upImages.log

images-touch:
	@touch $(SOURCE_IMAGES)
