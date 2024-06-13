#-------------------------------------------------------------------------------
# include calcuted dependencies
#-------------------------------------------------------------------------------

include depends
depends : Makefile

#-------------------------------------------------------------------------------
# rules for shell libraries
#-------------------------------------------------------------------------------
# where the shell libraries are developped
SOURCE_LIB_DIR = src/lib
# where the shell libraries are installed for test
BUILD_LIB_DIR = lib
# where the shell libraries are installed for use
INSTALL_LIB_DIR = $$HOME/lib
# find all shell libraries
SH_SOURCE_LIB_FILES := $(shell find $(SOURCE_LIB_DIR) -type f -name '*.sh')
AWK_SOURCE_LIB_FILES := $(shell find $(SOURCE_LIB_DIR) -type f -name '*.awk')
FMT_SOURCE_LIB_FILES := $(shell find $(SOURCE_LIB_DIR) -type f -name '*.fmt')
# name all shell libraries to be installed for test
SH_TARGET_BUILD_LIB_FILES := $(subst $(SOURCE_LIB_DIR)/,$(BUILD_LIB_DIR)/,$(patsubst %.sh,%,$(SH_SOURCE_LIB_FILES)))
AWK_TARGET_BUILD_LIB_FILES := $(subst $(SOURCE_LIB_DIR)/,$(BUILD_LIB_DIR)/,$(patsubst %.awk,%,$(AWK_SOURCE_LIB_FILES)))
FMT_TARGET_BUILD_LIB_FILES := $(subst $(SOURCE_LIB_DIR)/,$(BUILD_LIB_DIR)/,$(patsubst %.fmt,%,$(FMT_SOURCE_LIB_FILES)))
TARGET_BUILD_LIB_FILES := $(SH_TARGET_BUILD_LIB_FILES) $(AWK_TARGET_BUILD_LIB_FILES) $(FMT_TARGET_BUILD_LIB_FILES)
# name all shell libraries to be installed for use
SH_TARGET_INSTALL_LIB_FILES := $(subst $(BUILD_LIB_DIR)/,$(INSTALL_LIB_DIR)/,$(SH_TARGET_BUILD_LIB_FILES))
AWK_TARGET_INSTALL_LIB_FILES := $(subst $(BUILD_LIB_DIR)/,$(INSTALL_LIB_DIR)/,$(AWK_TARGET_BUILD_LIB_FILES))
FMT_TARGET_INSTALL_LIB_FILES := $(subst $(BUILD_LIB_DIR)/,$(INSTALL_LIB_DIR)/,$(FMT_TARGET_BUILD_LIB_FILES))
TARGET_INSTALL_LIB_FILES := $(SH_TARGET_INSTALL_LIB_FILES) $(AWK_TARGET_INSTALL_LIB_FILES) $(FMT_TARGET_INSTALL_LIB_FILES)
# rule to install shell libraries for test
$(BUILD_LIB_DIR)/% : $(SOURCE_LIB_DIR)/%.sh
	cp -f $< $@
	chmod -w $@
$(BUILD_LIB_DIR)/% : $(SOURCE_LIB_DIR)/%.awk
	cp -f $< $@
	chmod -w $@
$(BUILD_LIB_DIR)/% : $(SOURCE_LIB_DIR)/%.fmt
	cp -f $< $@
	chmod -w $@
# rule to install shell libraries for use
$(INSTALL_LIB_DIR)/% : $(BUILD_LIB_DIR)/%
	cp -f $< $@

#-------------------------------------------------------------------------------
# rules for shell scripts
#-------------------------------------------------------------------------------
# where the shell scripts are developped
SOURCE_BIN_DIR = src/sh
# where the shell scripts are installed for test
BUILD_BIN_DIR = bin
# where the shell scripts are installed for use
INSTALL_BIN_DIR = $$HOME/bin
# find all shell scripts
SOURCE_BIN_FILES := $(shell find $(SOURCE_BIN_DIR) -type f -name '*.sh')
# name all shell scripts to be installed for test
TARGET_BUILD_BIN_FILES := $(subst $(SOURCE_BIN_DIR)/,$(BUILD_BIN_DIR)/,$(patsubst %.sh,%,$(SOURCE_BIN_FILES)))
# name all shell scripts to be installed for use
TARGET_INSTALL_BIN_FILES := $(subst $(BUILD_BIN_DIR)/,$(INSTALL_BIN_DIR)/,$(TARGET_BUILD_BIN_FILES))
# rule to install shell scripts for test
$(BUILD_BIN_DIR)/% : $(SOURCE_BIN_DIR)/%.sh
	cp -f $< $@
	chmod +x-w $@
# rule to install shell scripts for use
$(INSTALL_BIN_DIR)/% : $(BUILD_BIN_DIR)/%
	cp -f $< $@

#-------------------------------------------------------------------------------
# rules for test scripts resources
#-------------------------------------------------------------------------------
# where the test resources are
RESOURCE_TEST_DIR = $(shell pwd)/res/test
# resource files creation
RESOURCE_FILES :=  accessNone.txt accessReadOnly.txt accessReadWrite.txt accessWriteOnly.txt
RESOURCE_DIRS := aDirectory
TARGET_RESOURCE_FILES := $(patsubst %,$(RESOURCE_TEST_DIR)/%,$(RESOURCE_FILES))
TARGET_RESOURCE_DIRS := $(patsubst %,$(RESOURCE_TEST_DIR)/%,$(RESOURCE_DIRS))
create_res : $(TARGET_RESOURCE_FILES) $(TARGET_RESOURCE_DIRS)
$(RESOURCE_TEST_DIR)/aDirectory:
	mkdir -p $@
$(RESOURCE_TEST_DIR)/accessNone.txt:
	touch $@
	chmod -r-w-x $@
$(RESOURCE_TEST_DIR)/accessReadOnly.txt:  
	touch $@
	chmod -r+w-x $@
$(RESOURCE_TEST_DIR)/accessReadWrite.txt:
	touch $@
	chmod +r+w-x $@
$(RESOURCE_TEST_DIR)/accessWriteOnly.txt:
	touch $@
	chmod -r+w-x $@
clean_res : $(TARGET_RESOURCE_FILES) $(TARGET_RESOURCE_DIRS)
	rm -rf $^

#-------------------------------------------------------------------------------
# rules for test scripts
#-------------------------------------------------------------------------------
# where the test scripts are developped
SOURCE_TEST_DIR = src/test
# where the test result are stored
RESULT_TEST_DIR = $(SOURCE_TEST_DIR)/result
# find all test scripts
SOURCE_TEST_FILES := $(shell find $(SOURCE_TEST_DIR) -type f -name '*.sh' | sort)
# name all test scripts to be produced
TEST_RESULT_FILES := $(subst $(SOURCE_TEST_DIR)/,$(RESULT_TEST_DIR)/,$(patsubst %.sh,%.log,$(SOURCE_TEST_FILES)))
# update the PATH to prioritize shell scripts under test against installed ones
export PATH := $(BUILD_BIN_DIR):$(PATH)
# rule to run the test scripts
$(RESULT_TEST_DIR)/%.log : $(SOURCE_TEST_DIR)/%.sh
	mv --backup=t $@ $@.bak 2>/dev/null | true
	bash $< -a $(TEST_OPTION) > $$$$.log 2>&1 && mv $$$$.log $@ || mv $$$$.log --backup=t $@.bad
#rule to pass environment variables to test drivers
$(RESULT_TEST_DIR)/%.log : export RESOURCE_TEST_DIR := $(RESOURCE_TEST_DIR)

#-------------------------------------------------------------------------------
# take care of target directories where files are created by make
#-------------------------------------------------------------------------------

$(BUILD_BIN_DIR) $(BUILD_LIB_DIR) $(RESULT_TEST_DIR) $(INSTALL_LIB_DIR) $(INSTALL_BIN_DIR) :
	mkdir -p $@

#-------------------------------------------------------------------------------
# the make file rules
#-------------------------------------------------------------------------------
.PHONY: build_bin build_lib all test clean install uninstall
.DEFAULT_GOAL := all
build_bin : $(BUILD_BIN_DIR) $(TARGET_BUILD_BIN_FILES)
build_lib : $(BUILD_LIB_DIR) $(TARGET_BUILD_LIB_FILES)
all : build_lib build_bin
test : all create_res $(RESULT_TEST_DIR) $(TEST_RESULT_FILES) 
clean_dir : $(BUILD_BIN_DIR) $(BUILD_LIB_DIR) $(RESULT_TEST_DIR)
	rm -rf $^
clean : clean_dir clean_res
	rm -f depends
install : all $(INSTALL_LIB_DIR) $(TARGET_INSTALL_LIB_FILES) $(INSTALL_BIN_DIR) $(TARGET_INSTALL_BIN_FILES)
uninstall :
	rm -f $(TARGET_INSTALL_BIN_FILES) $(TARGET_INSTALL_LIB_FILES)
depends :
	rm -f depends
	echo "#-------------------------------------------------------------------------------" >> depends ; \
	echo "# dependencies between shell libraries" >> depends ; \
	echo "#-------------------------------------------------------------------------------" >> depends ; \
	for f in $(SOURCE_LIB_FILES) ; do \
		d=$$(egrep "^\[" $$f | \
			grep "source " | \
			sed -e "s@.*/@@" -e 's@^@$(BUILD_LIB_DIR)/@'	| \
			tr '\n' ' '); \
		echo $(BUILD_LIB_DIR)/$$(basename $${f%.*}) : $$d >> depends ; \
	done ; \
	echo "#-------------------------------------------------------------------------------" >> depends ; \
	echo "# dependencies between shell scripts and shell libraries" >> depends ; \
	echo "#-------------------------------------------------------------------------------" >> depends ; \
	for f in $(SOURCE_BIN_FILES) ; do \
		d=$$(egrep "^\[" $$f | \
			grep "source " | \
			sed -e "s@.*/@@" -e 's@^@$(BUILD_LIB_DIR)/@'	| \
			tr '\n' ' '); \
		echo $(BUILD_BIN_DIR)/$$(basename $${f%.*}) : $$d >> depends ; \
	done
	echo "#-------------------------------------------------------------------------------" >> depends ; \
	echo "# dependencies between test scripts and shell libraries" >> depends ; \
	echo "#-------------------------------------------------------------------------------" >> depends ; \
	for f in $(SOURCE_TEST_FILES) ; do \
		d=$$(egrep "^\[" $$f | \
			grep "source " | \
			sed -e "s@.*/@@" -e 's@^@$(BUILD_LIB_DIR)/@'	| \
			tr '\n' ' '); \
		echo $(RESULT_TEST_DIR)/$$(basename $${f%.*}).log : $$d >> depends ; \
	done

