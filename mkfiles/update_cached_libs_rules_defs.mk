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
CHISELSCRIPTS_LIB_DIR_A := $(shell cygpath -w $(CHISELSCRIPTS_LIB_DIR) | sed -e 's%\\%/%g')
else
CHISELSCRIPTS_LIB_DIR_A := $(CHISELSCRIPTS_LIB_DIR)
endif

ifneq (true,$(VERBOSE))
Q=@
endif

JAVA=java

SBT := $(JAVA) -jar $(CHISELSCRIPTS_LIB_DIR_A)/sbt-launch.jar

ifeq (Msys,$(uname_o))
IVY2_CACHE=/c/users/$(USER)/.ivy2/cache
PS=;
else
IVY2_CACHE=$(HOME)/.ivy2/cache
PS=:
endif

else # Rules

# all : $(CHISELSCRIPTS_DEPS)

$(CHISELSCRIPTS_DEPS) : $(CS_LIB)/chisel3.jar

$(CS_LIB)/firrtl.jar : $(FIRRTL_SRC)
	$(Q)if test ! -d `dirname $@`; then mkdir -p `dirname $@`; fi
	$(Q)rm -rf $(CS_LIB)/firrtl
	$(Q)cp -r $(CHISELSCRIPTS_LIB_DIR)/firrtl $(CS_LIB)
	$(Q)rm -rf $(CS_LIB)/firrtl/.git $(CS_LIB)/firrtl/.gitignore
#	$(Q)cd $(CS_LIB)/firrtl ; sed -i -e 's/2.11.11/2.12.3/g' build.sbt
	$(Q)cd $(CS_LIB)/firrtl ; $(SBT) packageBin
	$(Q)cp $(CS_LIB)/firrtl/target/scala-*/firrtl_*.jar $(CS_LIB)/firrtl.jar
	$(Q)paths=`sed -e 's/$(PS)/ /g' $(CS_LIB)/firrtl/target/streams/compile/compileIncremental/*/streams/export`; \
		for p in $$paths; do \
			echo "FIRRTL path=$$p"; \
			if test -f $$p; then \
				is_jar=`echo $$p | sed -e 's/.*\.jar/true/g'`; \
                is_ivy=`echo $$p | sed -e 's/.*ivy2.*/true/g'`; \
				echo "is_jar=$${is_jar} is_ivy=$${is_ivy}"; \
				if test "x$${is_jar}" = "xtrue" && test "x$${is_ivy}" = "xtrue"; then \
					new_name=`basename $$p | sed -e 's/-[0-9][0-9\.]*\.jar/.jar/g' -e 's/_[0-9][0-9\.]*\.jar/.jar/g'`; \
					echo "new_name=$$new_name"; \
					cp $$p $(CS_LIB)/$$new_name; \
				fi \
			fi \
		done
	$(Q)rm -rf $(CS_LIB)/firtl
	
$(CS_LIB)/chisel3.jar : $(CS_LIB)/firrtl.jar $(CHISEL3_SRC)
	$(Q)if test ! -d `dirname $@`; then mkdir -p `dirname $@`; fi
	$(Q)rm -rf $(CS_LIB)/chisel3
	$(Q)cp -r $(CHISELSCRIPTS_LIB_DIR)/chisel3 $(CS_LIB)
	$(Q)rm -rf $(CS_LIB)/chisel3/.git $(CS_LIB)/chisel3/.gitignore
	$(Q)cp -r $(CS_LIB)/firrtl/target $(CS_LIB)/chisel3
#	$(Q)cd $(CS_LIB)/chisel3 ; sed -i -e 's/2.11.11/2.12.3/g' build.sbt
	$(Q)cd $(CS_LIB)/chisel3 ; mkdir lib ; cp $(CS_LIB)/firrtl.jar lib
	$(Q)cd $(CS_LIB)/chisel3 ; $(SBT) packageBin
	$(Q)cp $(CS_LIB)/chisel3/target/scala-*/chisel3_*.jar $(CS_LIB)/chisel3.jar
	$(Q)paths=`sed -e 's/$(PS)/ /g' $(CS_LIB)/chisel3/target/streams/compile/compileIncremental/*/streams/export`; \
		for p in $$paths; do \
			p=`echo $$p | sed -e 's/-Xplugin://g'`; \
			echo "CHISEL path=$$p"; \
			if test -f $$p; then \
				is_jar=`echo $$p | sed -e 's/.*\.jar/true/g'`; \
                is_ivy=`echo $$p | sed -e 's/.*ivy2.*/true/g'`; \
				echo "is_jar=$${is_jar} is_ivy=$${is_ivy}"; \
				if test "x$${is_jar}" = "xtrue" && test "x$${is_ivy}" = "xtrue"; then \
					new_name=`basename $$p | sed -e 's/[-_][0-9][0-9\.]*\.jar/.jar/g' -e 's/_[0-9][0-9\.]*\.jar/.jar/g'`; \
					echo "new_name=$$new_name"; \
					cp $$p $(CS_LIB)/$$new_name; \
				fi \
			fi \
		done
#resolution-cache/reports/edu.berkeley.cs-chisel3_2.11-plugin.xml
	$(Q)if test -d $(CS_LIB)/chisel3/target/resolution-cache; then \
          sc_jar=`grep 'scala-compiler' \
		    $(CS_LIB)/chisel3/target/resolution-cache/reports/edu.berkeley.cs-chisel3_*-plugin.xml \
    		| grep 'jar' | grep -v 'https' | sed -e 's/.*\(scala-compiler.*.jar\).*/\1/g'`; \
        elif test -d $(CS_LIB)/chisel3/target/scala-*; then \
          sc_jar=`grep 'scala-compiler' \
		    $(CS_LIB)/chisel3/target/scala-*/resolution-cache/reports/edu.berkeley.cs-chisel3_*-plugin.xml \
    		| grep 'jar' | grep -v 'https' | sed -e 's/.*\(scala-compiler.*.jar\).*/\1/g'`; \
        else \
		  echo "Error: unknown chisel3 target directory structure"; exit 1; \
        fi ; \
		echo "sc_jar=$$sc_jar"; \
		new_name=`basename $$sc_jar | sed -e 's/[-_][0-9][0-9\.]*\.jar/.jar/g' -e 's/_[0-9][0-9\.]*\.jar/.jar/g'`; \
		cp $(IVY2_CACHE)/org.scala-lang/scala-compiler/jars/$$sc_jar $(CS_LIB)/$$new_name
	$(Q)rm -rf $(CS_LIB)/chisel3


endif

