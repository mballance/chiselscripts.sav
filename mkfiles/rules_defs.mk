
CHISELSCRIPTS_MKFILES_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
CHISELSCRIPTS_DIR := $(shell cd $(CHISELSCRIPTS_MKFILES_DIR)/.. ; pwd)
CHISELSCRIPTS_BINDIR := $(CHISELSCRIPTS_DIR)/bin
CHISEL := $(CHISELSCRIPTS_BINDIR)/chisel.pl
CHISELC := $(CHISELSCRIPTS_BINDIR)/chisel.pl compile
CHISELG := $(CHISELSCRIPTS_BINDIR)/chisel.pl generate

ifneq (1,$(RULES))

else # Rules

endif

