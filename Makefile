SHELL=/bin/bash -e -E
.PHONY=all debug profile

# common.mk contains the configuration for this build setup
COMMONMK = git_blasr_common.mk
ifneq ($(shell ls $(COMMONMK) 2>/dev/null || echo -n notfound), notfound)
include $(COMMONMK)
endif

GIT_BLASR_LIBPATH = libcpp
PB_BLASR_LIBPATH = ../../lib/cpp

# Determine where is PBINCROOT, either from github or PacBio SMRTAnalysis package.
PBINCROOT ?= $(shell cd $(GIT_BLASR_LIBPATH) 2>/dev/null && pwd || echo -n notfound)
ifeq ($(PBINCROOT), notfound)
	PBINCROOT = $(shell cd $(PB_BLASR_LIBPATH) 2>/dev/null && pwd || echo -n notfound)
	ifeq ($(PBINCROOT), notfound)
		$(error please check your blasr lib exists.)
	endif
endif


#HDFINC ?= ../../../../assembly/seymour/dist/common/include
#HDFLIB ?= ../../../../assembly/seymour/dist/common/lib
HDFINC ?= /home/UNIXHOME/yli/yliWorkspace/software/assembly/seymour/dist/common/include
HDFLIB ?= /home/UNIXHOME/yli/yliWorkspace/software/assembly/seymour/dist/common/lib

INCDIRS = -I$(PBINCROOT)/alignment \
		  -I$(PBINCROOT)/pbdata \
		  -I$(PBINCROOT)/hdf \
		  -I$(HDFINC) 

LIBDIRS = -L$(PBINCROOT)/alignment \
		  -L$(PBINCROOT)/pbdata \
		  -L$(PBINCROOT)/hdf \
		  -L$(HDFINC) \
		  -L$(HDFLIB)

CXXFLAGS := -std=c++0x -Wall -Wuninitialized -Wno-div-by-zero \
			-pedantic -c -fmessage-length=0 -MMD -MP -w -fpermissive

SRCS := $(wildcard *.cpp)
OBJS := $(SRCS:.cpp=.o)
DEPS := $(SRCS:.cpp=.d)
LIBS := -lblasr -lpbdata -lpbihdf -lhdf5_cpp -lhdf5 -lz -lpthread -lrt -ldl
# -lhdf5, -lhdf5_cpp, -lz required for HDF5
# -lpthread for multi-threading
# -lrt for clock_gettime
# -ldl for dlopen dlclose 


all : OPTIMIZE = -O3
debug : OPTIMIZE = -g -ggdb -fno-inline
profile : OPTIMIZE = -Os -pg 

all: mk_lib_all mk_tools_all
debug: mk_lib_debug mk_tools_debug
profile: mk_lib_profile mk_tools_profile

mk_lib_all:
	cd $(PBINCROOT); make all

mk_tools_all:
	cd tools; make all

mk_lib_debug:
	cd $(PBINCROOT); make debug

mk_tools_debug:
	cd tools; make all

mk_lib_profile:
	cd $(PBINCROOT); make profile

mk_tools_profile:
	cd tools; make profile

exe = blasr

all debug profile: $(exe)

blasr: Blasr.o
	cd $(PBINCROOT); make all > /dev/null
	$(CXX) $(LIBDIRS) $(OPTIMIZE) $(G_OPTIMIZE) -static -o $@ $^ $(LIBS) $(G_LIBS)

Blasr.o: Blasr.cpp
	$(CXX) $(CXXFLAGS) $(OPTIMIZE) $(G_OPTIMIZE) $(INCDIRS) -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.o) $(@:%.o=%.d)" -o $@ $<

.INTERMEDIATE: $(OBJS)

cramtests:
	cram --shell=/bin/bash ctest/*.t

clean: 
	rm -f blasr
	rm -f $(OBJS) $(DEPS)
	cd $(PBINCROOT); make clean
	cd tools; make clean

clean_blasr:
	rm -f blasr
	rm -f $(OBJS) $(DEPS)

curdir = $(shell pwd)

submodules = tools $(PBINCROOT)

p4togit: $(submodules)
	for submodule in $(submodules); do \
		cd $$submodule; git p4 sync; git p4 rebase; git push -u origin master; cd $(curdir);\
	done 
	for submodule in $(submodules); do \
		git add $$submodule; \
	done
	git commit -m "Push latest $(submodules) from p4 to github"
	git push -u origin master

# To help users sync all submodules from github to local.
pullfromgit:
	git pull -u origin master
	git submodule update --init --recursive

-include $(DEPS)


