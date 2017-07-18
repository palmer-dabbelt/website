AUTHOR_NAME = "Palmer Dabbelt"
AUTHOR_EMAIL = "palmer@dabbelt.com"
LOCALE = "en_US.utf-8"

BLOGC ?= $(shell which blogc 2> /dev/null)
INSTALL ?= $(shell which rsync 2> /dev/null)
WGET ?= $(shell which wget 2> /dev/null)
PDFLATEX ?= $(shell which pdflatex 2> /dev/null)
OUTPUT_DIR ?= build
BASE_DOMAIN ?= http://www.dabbelt.com/~palmer/
BUILD ?= build

PAGES = $(subst pages/,,$(subst .md,,$(shell find pages/ -iname "*.md")))
ASSETS = $(shell find assets -type f)
KEEP = $(shell find keep -type f)

# A generic target to build everything in my website.  This target
# must come first!
all: \
	$(addsuffix .html,$(addprefix $(BUILD)/,$(PAGES))) \
	$(addprefix $(BUILD)/,$(ASSETS)) \
	$(addprefix $(BUILD)/,$(KEEP)) \
	$(BUILD)/index.html \
	$(BUILD)/resume.pdf \
	$(BUILD)/palmer-dabbelt.gpg

# Ensure I actually have the required program, if I don't then install thems
ifeq ($(BLOGC),)
BLOGC := tools/bin/blogc
endif

BLOGC_VERSION ?= 0.12.0
BLOGC_URL ?= https://github.com/blogc/blogc/releases/download/v$(BLOGC_VERSION)/blogc-$(BLOGC_VERSION).tar.gz
tools/bin/blogc: tools/src/blogc/build/blogc
	mkdir -p $(dir $@)
	cp -f $< $@
tools/src/blogc/build/blogc: tools/src/blogc/build/Makefile
	$(MAKE) -C $(dir $@)
tools/src/blogc/build/Makefile: tools/src/blogc/stamp
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
	cd $(dir $@) && ../configure
tools/src/blogc/stamp: tools/src/blogc-$(BLOGC_VERSION).tar.gz
	mkdir -p $(dir $@)
	tar -xzC $(dir $@) -f $< --strip-components=1
	touch $@
tools/src/blogc-$(BLOGC_VERSION).tar.gz:
	mkdir -p $(dir $@)
	$(WGET) $(BLOGC_URL) -O $@

# Builds HTML pages using blogc
$(BUILD)/%.html: pages/%.md templates/*.html $(BLOGC)
	mkdir -p $(dir $@)
	$(BLOGC) -o $@ -t templates/$(lastword $(subst /, ,$(dir $<))).html $<

# Builds PDF pages using pdflatex, or just fetches them if that's not
# installed.  Since these don't change a whole lot this should be OK...
ifeq ($(PDFLATEX),)
$(BUILD)/%.pdf:
	mkdir -p $(dir $@)
	$(WGET) http://www.dabbelt.com/~palmer/$(subst $(BUILD),,$@) -O $@
else
$(BUILD)/%.pdf: pages/%.tex $(PDFLATEX)
	mkdir -p .latex_cache
	cp $< .latex_cache
	cd .latex_cache; $(PDFLATEX) -interaction=batchmode $(notdir $<) >& /dev/null
	cp .latex_cache/$(notdir $@) $@
endif

# Generates my GPG key
$(BUILD)/palmer-dabbelt.gpg:
	gpg -a --export palmer@dabbelt.com > $@

# Assets are copied directly from the repository
$(BUILD)/assets/%: assets/%
	mkdir -p $(dir $@)
	cp $< $@

$(BUILD)/keep/%: keep/%
	mkdir -p $(dir $@)
	cp $< $@

# I want people to go to the about page by default, and the easiest
# way for me to do that is to simply install it twice.
$(BUILD)/index.html: $(BUILD)/about.html
	mkdir -p $(dir $@)
	cp --reflink=auto $< $@

# Removes everything that's been built
.PHONY: clean
clean:
	rm -rf build .latex_cache
.PHONY: distclean
distclean:
	$(MAKE) clean
	rm -rf tools

# Installs the currenty copy of the website on all the servers that I
# store it on.
.PHONY: install install-dabbelt install-cal
install: install-dabbelt install-cal

install-dabbelt: all
	rsync -av --delete build/ palmer@www.dabbelt.com:public_html/

install-cal: all
	rsync -av --delete build/ palmer.dabbelt@a5.millennium.berkeley.edu:public_html/

# Shows the website in your browser of choice
.PHONY: view
view: all
	$(BROWSER) $(BUILD)/index.html
