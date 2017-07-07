#****************************************************************************
#* Chiselscripts rules_defs.mk
#****************************************************************************

CHISELSCRIPTS_MKFILES_DIR := $(shell cd $(dir $(lastword $(MAKEFILE_LIST))); pwd)
CHISELSCRIPTS_LIB_DIR := $(CHISELSCRIPTS_MKFILES_DIR)/../lib

ifneq (1,$(RULES))

CS_CWD := $(shell pwd)

ifeq (,$(CS_LIB))
CS_LIB := $(CS_CWD)/.cslib
endif

CHISELSCRIPTS_DEPS := $(CS_LIB)/chiselscripts.d
FIRRTL_SRC := $(shell find $(CHISELSCRIPTS_LIB_DIR)/firrtl/src -type f)
CHISEL3_SRC := $(shell find $(CHISELSCRIPTS_LIB_DIR)/chisel3/src -type f)
# MOULTING_YAML_SRC := $(shell find $(CHISELSCRIPTS_LI

uname_o := $(shell uname -o)

ifeq (Cygwin,$(uname_o))
CHISELSCRIPTS_LIB_DIR_A := $(CHISELSCRIPTS_LIB_DIR)
else
CHISELSCRIPTS_LIB_DIR_A := $(CHISELSCRIPTS_LIB_DIR)
endif

ifneq (true,$(VERBOSE))
Q=@
endif

JAVA=java

SBT := $(JAVA) -jar $(CHISELSCRIPTS_LIB_DIR_A)/sbt-launch.jar
IVY2_CACHE=$(HOME)/.ivy2/cache

else # Rules

# all : $(CHISELSCRIPTS_DEPS)

$(CHISELSCRIPTS_DEPS) : $(CS_LIB)/chisel3.jar

$(CS_LIB)/firrtl.jar : $(FIRRTL_SRC)
	$(Q)if test ! -d `dirname $@`; then mkdir -p `dirname $@`; fi
	$(Q)rm -rf $(CS_LIB)/firrtl
	$(Q)cp -r $(CHISELSCRIPTS_LIB_DIR)/firrtl $(CS_LIB)
	$(Q)rm -rf $(CS_LIB)/firrtl/.git $(CS_LIB)/firrtl/.gitignore
	$(Q)cd $(CS_LIB)/firrtl ; $(SBT) packageBin
	$(Q)cp $(CS_LIB)/firrtl/target/scala-*/firrtl_*.jar $(CS_LIB)/firrtl.jar
	$(Q)paths=`sed -e 's/:/ /g' $(CS_LIB)/firrtl/target/streams/compile/dependencyClasspath/*/streams/export`; \
		for p in $$paths; do \
			if test -f $$p; then cp $$p $(CS_LIB); fi \
		done
	$(Q)rm -rf $(CS_LIB)/fir/cyrtl
	
$(CS_LIB)/chisel3.jar : $(CHISEL3_SRC)
	$(Q)if test ! -d `dirname $@`; then mkdir -p `dirname $@`; fi
	$(Q)rm -rf $(CS_LIB)/chisel3
	$(Q)cp -r $(CHISELSCRIPTS_LIB_DIR)/chisel3 $(CS_LIB)
	$(Q)rm -rf $(CS_LIB)/chisel3/.git $(CS_LIB)/chisel3/.gitignore
	$(Q)cd $(CS_LIB)/chisel3 ; $(SBT) packageBin
	$(Q)cp $(CS_LIB)/chisel3/target/scala-*/chisel3_*.jar $(CS_LIB)/chisel3.jar
	$(Q)paths=`sed -e 's/:/ /g' $(CS_LIB)/chisel3/target/streams/compile/dependencyClasspath/*/streams/export`; \
		for p in $$paths; do \
			if test -f $$p; then cp $$p $(CS_LIB); fi \
		done
	$(Q)sc_jar=`grep 'scala-compiler' \
		$(CS_LIB)/chisel3/target/resolution-cache/reports/edu.berkeley.cs-chisel3_*-plugin.xml \
		| grep 'jar' | grep -v 'https' | sed -e 's/.*\(scala-compiler.*.jar\).*/\1/g'`; \
		cp $(IVY2_CACHE)/org.scala-lang/scala-compiler/jars/$$sc_jar $(CS_LIB)
	$(Q)rm -rf $(CS_LIB)/chisel3

$(CS_LIB)/moultingyaml.jar : $(MOULTING_YAML_SRC)
	$(Q)if test ! -d `dirname $@`; then mkdir -p `dirname $@`; fi
	$(Q)rm -rf $(CS_LIB)/moultingyaml
	$(Q)cp -r $(CHISELSCRIPTS_LIB_DIR)/moultingyaml $(CS_LIB)
	$(Q)rm -rf $(CS_LIB)/moultingyaml/.git $(CS_LIB)/moultingyaml/.gitignore
	$(Q)cd $(CS_LIB)/moultingyaml ; $(SBT) packageBin
	$(Q)cp $(CS_LIB)/moultingyaml/target/scala-*/moultingyaml_*.jar $(CS_LIB)/moultingyaml.jar
#	$(Q)rm -rf $(CS_LIB)/chisel3

endif

