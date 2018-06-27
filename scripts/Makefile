
CHISELSCRIPTS_SCRIPTS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
CHISELSCRIPTS_DIR := $(abspath $(CHISELSCRIPTS_SCRIPTS_DIR)/..)
BUILD_DIR := $(CHISELSCRIPTS_DIR)/build
PACKAGES_DIR := $(CHISELSCRIPTS_DIR)/packages
LIB_DIR := $(CHISELSCRIPTS_DIR)/lib
FIRRTL_VERSION=1.1.1
FIRRTL_URL=https://github.com/freechipsproject/firrtl/archive/v$(FIRRTL_VERSION).tar.gz
FIRRTL_DIR=firrtl-$(FIRRTL_VERSION)
FIRRTL_TGZ=$(BUILD_DIR)/$(FIRRTL_DIR).tar.gz
CHISEL3_VERSION=3.1.1
CHISEL3_URL=https://github.com/freechipsproject/chisel3/archive/v$(CHISEL3_VERSION).tar.gz
CHISEL3_DIR=chisel3-$(CHISEL3_VERSION)
CHISEL3_TGZ=$(BUILD_DIR)/$(CHISEL3_DIR).tar.gz
IVY2_CACHE=$(HOME)/.ivy2/cache
PS=:

# Bring in the version
include $(CHISELSCRIPTS_DIR)/etc/ivpm.info

JAVA=java
SBT := $(JAVA) -jar $(CHISELSCRIPTS_SCRIPTS_DIR)/sbt-launch.jar

build : \
	$(LIB_DIR)/scala.jar \
	$(LIB_DIR)/support.jar \
	$(LIB_DIR)/firrtl.jar \
	$(LIB_DIR)/chisel3.jar 

release : build
	$(Q)rm -rf $(BUILD_DIR)/release
	$(Q)mkdir -p $(BUILD_DIR)/release
	$(Q)cp -r \
          $(CHISELSCRIPTS_DIR)/etc \
          $(CHISELSCRIPTS_DIR)/bin \
          $(CHISELSCRIPTS_DIR)/lib \
          $(CHISELSCRIPTS_DIR)/mkfiles \
          $(BUILD_DIR)/release
	$(Q)cd $(BUILD_DIR)/release ; \
		tar czf $(BUILD_DIR)/chiselscripts-$(version).tar.gz *
	$(Q)rm -rf $(BUILD_DIR)/release

$(LIB_DIR)/support.jar : $(LIB_DIR)/chisel3.jar $(LIB_DIR)/firrtl.jar
	$(Q)rm -rf $(BUILD_DIR)/support
	$(Q)mkdir -p $(BUILD_DIR)/support
	$(Q)cd $(BUILD_DIR)/support; \
          for jar in $(BUILD_DIR)/support_libs/*.jar; do \
            unzip -o $$jar; \
          done
	$(Q)cd $(BUILD_DIR)/support ; zip -r $(LIB_DIR)/support.jar *
	$(Q)rm -rf $(BUILD_DIR)/support

$(LIB_DIR)/scala.jar : $(LIB_DIR)/chisel3.jar $(LIB_DIR)/firrtl.jar
	$(Q)rm -rf $(BUILD_DIR)/scala
	$(Q)mkdir -p $(BUILD_DIR)/scala
	$(Q)cd $(BUILD_DIR)/scala; \
          for jar in $(BUILD_DIR)/scala_libs/*.jar; do \
            unzip -o $$jar; \
          done
	$(Q)cd $(BUILD_DIR)/scala ; zip -r $(LIB_DIR)/scala.jar *
	$(Q)rm -rf $(BUILD_DIR)/scala

$(BUILD_DIR)/chisel3.unpack : $(CHISEL3_TGZ)
	$(Q)if test ! -d `dirname $@`; then mkdir -p `dirname $@`; fi
	$(Q)cd $(BUILD_DIR) ; tar xvzf $(CHISEL3_TGZ)
	$(Q)touch $@

$(CHISEL3_TGZ) :
	$(Q)if test ! -d `dirname $@`; then mkdir -p `dirname $@`; fi
	$(Q)wget -O $@ $(CHISEL3_URL)	

$(LIB_DIR)/chisel3.jar : $(BUILD_DIR)/chisel3.unpack
#	$(Q)mkdir -p $(BUILD_DIR)/$(CHISEL3_DIR)/lib
#	$(Q)cp $(LIB_DIR)/firrtl.jar $(BUILD_DIR)/$(CHISEL3_DIR)/lib
	$(Q)mkdir -p $(BUILD_DIR)/support_libs
	$(Q)mkdir -p $(BUILD_DIR)/scala_libs
	$(Q)cd $(BUILD_DIR)/$(CHISEL3_DIR) ; $(SBT) packageBin
	$(Q)cp $(BUILD_DIR)/$(CHISEL3_DIR)/target/scala-*/chisel3*.jar \
		$(LIB_DIR)/chisel3.jar
	$(Q)paths=`sed -e 's/$(PS)/ /g' $(BUILD_DIR)/$(CHISEL3_DIR)/target/streams/compile/compileIncremental/*/streams/export`; \
		for p in $$paths; do \
			p=`echo $$p | sed -e 's/-Xplugin://g'`; \
			echo "CHISEL path=$$p"; \
			if test -f $$p; then \
				is_jar=`echo $$p | sed -e 's/.*\.jar/true/g'`; \
                is_ivy=`echo $$p | sed -e 's/.*ivy2.*/true/g'`; \
				echo "is_jar=$${is_jar} is_ivy=$${is_ivy}"; \
				if test "x$${is_jar}" = "xtrue" && test "x$${is_ivy}" = "xtrue"; then \
					new_name=`basename $$p | sed -e 's/[-_][0-9][0-9\.]*\.jar/.jar/g' -e 's/_[0-9][0-9\.]*\.jar/.jar/g'`; \
                                        is_scala=`echo $$new_name | sed -e 's/^scala-.*/true/g'`; \
                                        if test "x$${is_scala}" = "xtrue"; then \
					  cp $$p $(BUILD_DIR)/scala_libs/$$new_name ; \
                                        else \
					  cp $$p $(BUILD_DIR)/support_libs/$$new_name ; \
                                        fi \
				fi \
			fi \
		done
	$(Q)if test -d $(BUILD_DIR)/$(CHISEL3_DIR)/target/resolution-cache; then \
          sc_jar=`grep 'scala-compiler' \
		    $(BUILD_DIR)/$(CHISEL3_DIR)/target/resolution-cache/reports/*-chisel3*-scala-tool.xml \
    		| grep 'jar' | grep -v 'https' | sed -e 's/.*\(scala-compiler.*.jar\).*/\1/g'`; \
        elif test -d $(BUILD_DIR)/$(CHISEL3_DIR)/target/scala-*; then \
          sc_jar=`grep 'scala-compiler' \
		    $(BUILD_DIR)/$(CHISEL3_DIR)/target/scala-*/resolution-cache/reports/*-chisel3*-plugin.xml \
    		| grep 'jar' | grep -v 'https' | sed -e 's/.*\(scala-compiler.*.jar\).*/\1/g'`; \
        else \
		  echo "Error: unknown chisel3 target directory structure"; exit 1; \
        fi ; \
		echo "sc_jar=$$sc_jar"; \
		new_name=`basename $$sc_jar | sed -e 's/[-_][0-9][0-9\.]*\.jar/.jar/g' -e 's/_[0-9][0-9\.]*\.jar/.jar/g'`; \
		cp $(IVY2_CACHE)/org.scala-lang/scala-compiler/jars/$$sc_jar $(BUILD_DIR)/scala_libs/$$new_name

$(BUILD_DIR)/firrtl.unpack : $(FIRRTL_TGZ)
	$(Q)if test ! -d `dirname $@`; then mkdir -p `dirname $@`; fi
	$(Q)rm -rf $(BUILD_DIR)/$(FIRRTL_DIR)
	$(Q)cd $(BUILD_DIR) ; tar xvzf $(FIRRTL_TGZ)
	$(Q)touch $@

$(FIRRTL_TGZ) :
	$(Q)if test ! -d `dirname $@`; then mkdir -p `dirname $@`; fi
	$(Q)wget -O $@ $(FIRRTL_URL)

$(LIB_DIR)/firrtl.jar : $(BUILD_DIR)/firrtl.unpack
	$(Q)cd $(BUILD_DIR)/$(FIRRTL_DIR) ; $(SBT) packageBin
	$(Q)mkdir -p $(BUILD_DIR)/support_libs
	$(Q)mkdir -p $(BUILD_DIR)/scala_libs
	$(Q)cp $(BUILD_DIR)/$(FIRRTL_DIR)/target/scala-*/firrtl_*.jar \
          $(LIB_DIR)/firrtl.jar
	$(Q)paths=`sed -e 's/$(PS)/ /g' $(BUILD_DIR)/$(FIRRTL_DIR)/target/streams/compile/compileIncremental/*/streams/export`; \
	for p in $$paths; do \
          if test -f $$p; then \
            is_jar=`echo $$p | sed -e 's/.*\.jar/true/g'`; \
            is_ivy=`echo $$p | sed -e 's/.*ivy2.*/true/g'`; \
            if test "x$${is_jar}" = "xtrue" && test "x$${is_ivy}" = "xtrue"; then \
              new_name=`basename $$p | sed -e 's/[-_][0-9][0-9\.]*\.jar/.jar/g' -e 's/_[0-9][0-9\.]*\.jar/.jar/g'`; \
              is_scala=`echo $$new_name | sed -e 's/^scala-.*/true/g'`; \
              if test "x$${is_scala}" = "xtrue"; then \
                cp $$p $(BUILD_DIR)/scala_libs/$$new_name; \
              else \
                cp $$p $(BUILD_DIR)/support_libs/$$new_name; \
              fi \
            fi \
          fi \
        done

