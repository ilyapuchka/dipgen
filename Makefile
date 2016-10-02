TEMPORARY_FOLDER?=/tmp/DipGen.dst
PREFIX?=/usr/local
BUILD_TOOL?=xcodebuild

XCODEFLAGS=-project 'DipGen.xcodeproj' \
	-scheme 'dipgen' \
	DSTROOT=$(TEMPORARY_FOLDER) \
	OTHER_LDFLAGS=-Wl,-headerpad_max_install_names

BUILT_BUNDLE=$(TEMPORARY_FOLDER)/Applications/dipgen.app
DIPGEN_FRAMEWORK_BUNDLE=$(BUILT_BUNDLE)/Contents/Frameworks/DipGenFramework.framework
DIPGEN_EXECUTABLE=$(BUILT_BUNDLE)/Contents/MacOS/dipgen

FRAMEWORKS_FOLDER=$(PREFIX)/Frameworks
BINARIES_FOLDER=$(PREFIX)/bin

OUTPUT_PACKAGE=DipGen.pkg

VERSION_STRING=$(shell agvtool what-marketing-version -terse1)
COMPONENTS_PLIST=dipgen/Supporting Files/Components.plist

.PHONY: all bootstrap clean install package test uninstall

all: bootstrap
	$(BUILD_TOOL) $(XCODEFLAGS) build

bootstrap:
	script/bootstrap

test: clean bootstrap
	$(BUILD_TOOL) $(XCODEFLAGS) test

clean:
	rm -f "$(OUTPUT_PACKAGE)"
	rm -rf "$(TEMPORARY_FOLDER)"
	$(BUILD_TOOL) $(XCODEFLAGS) -configuration Debug clean
	$(BUILD_TOOL) $(XCODEFLAGS) -configuration Release clean
	#$(BUILD_TOOL) $(XCODEFLAGS) -configuration Test clean

install: package
	sudo installer -pkg DipGen.pkg -target /

uninstall:
	rm -rf "$(FRAMEWORKS_FOLDER)/DipGenFramework.framework"
	rm -f "$(BINARIES_FOLDER)/dipgen"

installables: clean bootstrap
	$(BUILD_TOOL) $(XCODEFLAGS) install

	mkdir -p "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)" "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)"
	mv -f "$(DIPGEN_FRAMEWORK_BUNDLE)" "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)/DipGenFramework.framework"
	mv -f "$(DIPGEN_EXECUTABLE)" "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)/dipgen"
	rm -rf "$(BUILT_BUNDLE)"

prefix_install: installables
	mkdir -p "$(FRAMEWORKS_FOLDER)" "$(BINARIES_FOLDER)"
	cp -Rf "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)/DipGenFramework.framework" "$(FRAMEWORKS_FOLDER)/"
	cp -f "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)/dipgen" "$(BINARIES_FOLDER)/"

package: installables
	pkgbuild \
		--component-plist "$(COMPONENTS_PLIST)" \
		--identifier "me.puchka.dipgen" \
		--install-location "/" \
		--root "$(TEMPORARY_FOLDER)" \
		--version "$(VERSION_STRING)" \
		"$(OUTPUT_PACKAGE)"

archive:
	carthage build --no-skip-current --platform mac
	carthage archive DipGenFramework SourceKittenFramework Yaml SWXMLHash Xcode

release: package archive
