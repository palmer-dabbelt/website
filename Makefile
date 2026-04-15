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
	$(BUILD)/blog.html \
	$(BUILD)/resume.pdf

# Ensure I actually have the required program, if I don't then install thems
ifeq ($(BLOGC),)
BLOGC := tools/bin/blogc
endif

tools/bin/blogc: tools/src/blogc/build/blogc
	@mkdir -p $(dir $@)
	$(MAKE) -C $(dir $<) install
	touch -c $@
tools/src/blogc/build/blogc: tools/src/blogc/build/Makefile
	$(MAKE) -C $(dir $<)
	touch -c $@
tools/src/blogc/build/Makefile:
	@rm -rf $(dir $@)
	@mkdir -p $(dir $@)
	cmake -B $(dir $@) -S $(dir $<) -DCMAKE_INSTALL_PREFIX=$(abspath tools/bin)
	touch -c $@

# Builds HTML pages using blogc
$(BUILD)/%.html: pages/%.md $(wildcard templates/*.html) $(BLOGC)
	mkdir -p $(dir $@)
	$(BLOGC) -o $@ -t templates/$(lastword $(subst /, ,$(dir $<))).html $<

$(BUILD)/blog/%.html: $(BUILD)/blog/%.md $(wildcard templates/*.html) $(BLOGC)
	mkdir -p $(dir $@)
	$(BLOGC) -o $@ -t templates/$(lastword $(subst /, ,$(dir $<))).html $(sort $<)

$(BUILD)/blog/%.md: pages/blog/%.md $(BLOGC)
	mkdir -p $(dir $@)
	echo "DATE: $$(date -d "$$(basename "$<" .md | cut -d- -f1)" "+%B %e, %Y")" > $@
	echo "BASENAME: $$(basename "$<" .md)" >> $@
	cat "$^" | sed 's/^#/##/g' >> "$@"

# Builds PDF pages using pdflatex, or just fetches them if that's not
# installed.  Since these don't change a whole lot this should be OK...
ifeq ($(PDFLATEX),)
$(BUILD)/%.pdf:
	@mkdir -p $(dir $@)
	$(WGET) http://www.dabbelt.com/~palmer/$(subst $(BUILD),,$@) -O $@
else
$(BUILD)/%.pdf: pages/%.tex $(PDFLATEX)
	@mkdir -p .latex_cache
	cp $< .latex_cache
	cd .latex_cache; $(PDFLATEX) -interaction=batchmode $(notdir $<) >& /dev/null
	cp .latex_cache/$(notdir $@) $@
endif

# Signs essentially anything.
$(BUILD)/%.gpg: $(BUILD)/%
	@rm -f $@

# Generates my GPG key
#$(BUILD)/palmer-dabbelt.gpg: $(wildcard $HOME/.gnupg/*)
#	gpg -a --export palmer@dabbelt.com > $@

# Assets are copied directly from the repository
$(BUILD)/assets/%: assets/%
	@mkdir -p $(dir $@)
	cp $< $@

$(BUILD)/keep/%: keep/%
	@mkdir -p $(dir $@)
	cp $< $@

# I want people to go to the about page by default, and the easiest
# way for me to do that is to simply install it twice.
$(BUILD)/index.html: $(BUILD)/about.html
	@mkdir -p $(dir $@)
	cp $< $@

# I'm going to start a blog!
$(BUILD)/blog.html: \
		$(patsubst pages/%,$(BUILD)/%,$(wildcard pages/blog/*.md)) \
		$(wildcard templates/*.html) \
		$(BLOGC)
	$(BLOGC) -o $@ -t templates/multiblog.html $(sort $(filter %.md,$^))

# Removes everything that's been built
.PHONY: clean
clean:
	rm -rf build .latex_cache tools/src/blogc/build/
.PHONY: distclean
distclean:
	$(MAKE) clean
	rm -rf tools

# Installs the currenty copy of the website on all the servers that I
# store it on.
.PHONY: install install-dabbelt install-cal
install: install-nfshost

install-nfshost: all
	rsync -av --delete build/ palmer_dabbelt@ssh.nyc1.nearlyfreespeech.net:~palmer/

# Shows the website in your browser of choice
.PHONY: view
view: all
	$(BROWSER) $(BUILD)/index.html
