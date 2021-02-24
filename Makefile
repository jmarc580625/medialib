SOURCE_TEST_DIR = test

#-------------------------------------------------------------------------------
SOURCE_BIN_DIR = src/sh
BUILD_BIN_DIR = bin
INSTALL_BIN_DIR = $$HOME/bin
SOURCE_BIN_FILES := $(shell find $(SOURCE_BIN_DIR) -type f -name '*.sh')
TARGET_BUILD_BIN_FILES := $(subst $(SOURCE_BIN_DIR),$(BUILD_BIN_DIR),$(patsubst %.sh,%,$(SOURCE_BIN_FILES)))
TARGET_INSTALL_BIN_FILES := $(subst $(BUILD_BIN_DIR),$(INSTALL_BIN_DIR),$(TARGET_BUILD_BIN_FILES))

$(BUILD_BIN_DIR)/% : $(SOURCE_BIN_DIR)/%.sh
	cp $< $@
	chmod +x $@

$(INSTALL_BIN_DIR)/% : $(BUILD_BIN_DIR)/%
	cp $< $@

#-------------------------------------------------------------------------------
SOURCE_LIB_DIR = src/lib
BUILD_LIB_DIR = lib
INSTALL_LIB_DIR = $$HOME/lib
SOURCE_LIB_FILES := $(shell find $(SOURCE_LIB_DIR) -type f -name '*.sh')
TARGET_BUILD_LIB_FILES := $(subst $(SOURCE_LIB_DIR),$(BUILD_LIB_DIR),$(patsubst %.sh,%,$(SOURCE_LIB_FILES)))
TARGET_INSTALL_LIB_FILES := $(subst $(BUILD_LIB_DIR),$(INSTALL_LIB_DIR),$(TARGET_BUILD_LIB_FILES))

$(BUILD_LIB_DIR)/% : $(SOURCE_LIB_DIR)/%.sh
	cp $< $@

$(INSTALL_LIB_DIR)/% : $(BUILD_LIB_DIR)/%
	cp $< $@

#-------------------------------------------------------------------------------

$(BUILD_BIN_DIR) $(BUILD_LIB_DIR) $(INSTALL_LIB_DIR) $(INSTALL_BIN_DIR) :
	mkdir -p $@

#-------------------------------------------------------------------------------

.PHONY: uninstall install install_dirs clean test all build_lib build_bin
build_bin : $(BUILD_BIN_DIR) $(TARGET_BUILD_BIN_FILES)
build_lib : $(BUILD_LIB_DIR) $(TARGET_BUILD_LIB_FILES)
all : build_lib build_bin
test : all
clean :
	rm -rf $(BUILD_BIN_DIR)
	rm -rf $(BUILD_LIB_DIR)
install : all $(INSTALL_LIB_DIR) $(TARGET_INSTALL_LIB_FILES) $(INSTALL_BIN_DIR) $(TARGET_INSTALL_BIN_FILES)
uninstall :
	rm -f $(TARGET_INSTALL_BIN_FILES) $(TARGET_INSTALL_LIB_FILES)
