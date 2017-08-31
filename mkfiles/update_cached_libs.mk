
CHISELSCRIPTS_MKFILES_DIR := $(shell cd $(dir $(lastword $(MAKEFILE_LIST))); pwd)
CHISELSCRIPTS_LIB_DIR := $(shell cd $(CHISELSCRIPTS_MKFILES_DIR)/../lib; pwd)
CS_LIB := $(CHISELSCRIPTS_LIB_DIR)/cache

include $(CHISELSCRIPTS_MKFILES_DIR)/update_cached_libs_rules_defs.mk

RULES := 1

all : $(CS_LIB)/chisel3.jar
	echo "CHISELSCRIPTS_MKFILES_DIR=$(CHISELSCRIPTS_MKFILES_DIR)"
	

include $(CHISELSCRIPTS_MKFILES_DIR)/update_cached_libs_rules_defs.mk
