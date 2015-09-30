AUTHOR_NAME = "Palmer Dabbelt"
AUTHOR_EMAIL = "palmer@dabbelt.com"
LOCALE = "en_US.utf-8"

BLOGC ?= $(shell which blogc)
INSTALL ?= $(shell which rsync)
OUTPUT_DIR ?= build
BASE_DOMAIN ?= http://www.dabbelt.com/~palmer/
BUILD ?= build

PAGES = $(subst pages/,,$(subst .md,,$(shell find pages/ -iname "*.md")))
ASSETS = $(shell find assets -type f)

# A generic target to build everything in my website.  This target
# must come first!
all: \
	$(addsuffix .html,$(addprefix $(BUILD)/,$(PAGES))) \
	$(addprefix $(BUILD)/,$(ASSETS)) \
	$(BUILD)/index.html \
	$(BUILD)/research_log.html \
	$(BUILD)/resume.pdf

# Builds HTML pages using blogc
$(BUILD)/%.html: pages/%.md templates/*.html
	mkdir -p $(dir $@)
	$(BLOGC) -o $@ -t templates/$(lastword $(subst /, ,$(dir $<))).html $<

# This is a front page for my research log, which contains a list of
# all of them.
$(BUILD)/research_log.html: pages/rlog/*.md templates/research_log.html
	mkdir -p $(dir $@)
	find pages/rlog/*.md | sort --reverse | xargs $(BLOGC) -o $@ -t templates/research_log.html -l

# Builds PDF pages using pdflatex
$(BUILD)/%.pdf: pages/%.tex
	mkdir -p .latex_cache
	cp $^ .latex_cache
	cd .latex_cache; pdflatex -interaction=batchmode $(notdir $^) >& /dev/null
	cp .latex_cache/$(notdir $@) $@

# Assets are copied directly from the repository
$(BUILD)/assets/%: assets/%
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

# Installs the currenty copy of the website on all the servers that I
# store it on.
.PHONY: install install-dabbelt install-cal
install: install-dabbelt install-cal

install-dabbelt: all
	rsync -av --delete build/ palmer@www.dabbelt.com:public_html/

install-cal: all
	rsync -av --delete build/ palmer.dabbelt@a5.millennium.berkeley.edu:public_html/
