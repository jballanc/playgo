#########
# Setup #
#########

# Constants for building LuaJIT
#
# Build results will go in the "./build" directory along with everything else.
# However, the LuaJIT build process expects a full prefix path for binaries,
# libraries, etc. So, we create a fake "/usr/local" heirarchy in the build
# directory where everything will go.
LJDESTDIR = $(CURDIR)/build
LJPREFIX = $(LJDESTDIR)/usr/local
LJSTATIC = $(LJPREFIX)/lib/libluajit-5.1.a
LJBIN = $(LJPREFIX)/bin/luajit

# Standard C Constants
#
ifeq ($(strip $(shell uname)), Darwin)
  # On OS X, we compile the main.c shim that ties everything together, as well
  # as all of the vendored dependencies, using Clang. We need ensure that the
  # correct values of page-zero size and base image address offset for LuaJIT
  # are set.  Finally the "PLATFORM" constant is set to macosx for use later
  # during LPeg compilation.
  CC = clang
  CFLAGS = -pagezero_size 10000 -image_base 100000000 -Ibuild/usr/local/include
  PLATFORM = macosx
else
  # On Linux, we'll use the system default C compiler (pretty much always gcc)
  # for main.c and the vendored dependencies. The only additional configuration
  # required is to explicitly list the libraries that LuaJIT depends on, so that
  # we can statically link it with the finished binary.
  CFLAGS = -Ibuild/usr/local/include
  PLATFORM = linux
  LJ_OPTS = -lm -ldl -lc
endif
# Finally, the only external dependencies for the entire project are libcurl and
# libexpat.
LDFLAGS = -lexpat -lcurl

# Helper Functions
#
# Here we define two helper functions that we'll use later on in the Makefile.
# The first will convert a path string like "src/foo/bar/baz.lua" into
# "build/foo.bar.baz.lua" (actually, the suffix will be whatever is specified as
# the first argument when this function is called). This function is needed for
# the special trick used later to compile nested modules with LuaJIT.
slashtodots = $(addprefix build/,\
	      $(addsuffix $1,\
	      $(subst /,.,$(patsubst src/%.lua,%,$2))))
# This function is a recursive version of the standard Make "wildcard" function.
# By calling itself recursively, this function makes it possible to search a
# directory as well as all subdirectories, something not supported by Make's
# built-in wildcard function. Credit for this technique goes to StackOverflow
# user "Ben": http://stackoverflow.com/questions/3774568
rwildcard = $(wildcard $1$2) \
	    $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))

# Build Constants
#
# This collection of constants specifies a variety of components used in
# actually building the project. The MAIN source file is the C shim that ties
# the whole thing together (and, as such, represents the final build-step).
MAIN = src/main.c
# The LUA_SRC collection holds the list of all the Lua source files in the
# project that need to be compiled by LuaJIT...
LUA_SRC = $(call rwildcard,src/,*.lua)
# ...while the LUA_OBJS collection is the list of the compiled object files that
# will actually be linked in the final build step.
LUA_OBJS = $(call slashtodots,.o,$(LUA_SRC))
# These are the re-targeted object files that will actually be linked in the
# final executable:
OBJS = build/lxp.o build/lua-curl.o build/lpeg.o
# Finally, we use a recursive search to gather all the test files for the test
# target:
TESTS = $(call rwildcard,test/,*.lua)


###########
# Targets #
###########

# The default target. This builds the self-contained executable by compiling the
# main C file and linking it with both the Lua object files generated by LuaJIT
# and the re-targeted object files from the vendored projects.
playgo: $(MAIN) $(LPEG) $(LUA_OBJS) $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) $(MAIN) $(LUA_OBJS) $(OBJS) $(LJSTATIC) $(LJ_OPTS) -o $@

# This is a trick that accomplishes two things: 1. it allows us to have targets
# that simply rename Lua files from "src/foo/bar/baz.lua" to
# "build/foo.bar.baz.lua" and 2. it will only re-run the renaming task when the
# original "src/foo/bar/baz.lua" file is updated. The way this works is that we
# generate a separate file containing targets for every Lua file to be renamed,
# and then we include that file in this Makefile (thereby including all those
# targets). Each individual rename target is as simple as:
#
#     build/foo.bar.baz.lua: src/foo/bar/baz.lua
#         cp $< $@
#
# As for why this renaming step is required, when LuaJIT creates object-files
# from Lua source files, it generates the module name from the basename of the
# file. That is, normally in Lua if you have "require('foo.bar.baz')", this will
# look for "foo/bar/baz.lua". However, because we are linking object files,
# instead of shipping around a nested directory structure, we instead tell
# LuaJIT to compile "foo.bar.baz.lua" to "foo.bar.baz.o", which then works just
# the same with "require('foo.bar.baz')". In this way, we can develop playgo
# uncompiled using usual Lua require rules, or compiled with LuaJIT, and we
# don't need to change any code.
build/luadeps.mk: | build
	$(foreach f,$(LUA_SRC),\
	  $(shell echo \
	  "$(call slashtodots,.lua,$(f)): $(f)\n\tcp $$< \$$@" >> build/luadeps.mk))

include build/luadeps.mk

# The final part of this trick is a catch-all target for any Lua object files
# that don't already have a target defined in the "build/luadeps.mk" include
# file. This would be the case if a new Lua file was created and then Make was
# run from a non-clean state (i.e. running "make" without first running "make
# clean"). In such a situation, we need to clear out the outdated include file,
# rebuild it, and then re-run the Lua file build step.
build/%.lua: build/luadeps.mk
	rm -f $(CURDIR)/build/luadeps.mk
	$(MAKE) build/luadeps.mk
	$(MAKE) $@


# The acutal target for generating object files from Lua source using LuaJIT.
# This target depends on both the Lua files from the renaming target above and
# the vendored version of LuaJIT compiled below.
%.o: %.lua $(LJBIN) | build
	LUA_PATH=";;$(LJPREFIX)/share/luajit-2.0.2/?.lua" $(LJBIN) -b $< $@

# The vendored Lua libraries. These three targets all follow the same basic
# structure. First, we run make in the base directory of the vendored code.
# Then, we gather the resulting object files using "ld -r" to re-target them to
# a single object file in our "build" directory. This gives us...
# ...lxp (for XML/HTML parsing):
build/lxp.o: $(LJBIN) | build
	$(MAKE) -C vendor/lua-expat
	ld -r vendor/lua-expat/src/*.o -o ./build/lxp.o

# ...lua-curl (for making HTTP requests):
build/lua-curl.o: $(LJBIN) | build
	cmake -DUSE_LUAJIT=ON -Bvendor/lua-curl/ -Hvendor/lua-curl/
	$(MAKE) -C vendor/lua-curl
	ld -r vendor/lua-curl/CMakeFiles/cURL.dir/src/*.o -o ./build/lua-curl.o

# ...and LPeg (for parsing SGF files). Note that we rely on having set the
# "PLATFORM" variable ahead of time, since LPeg's build does not do
# autodetection on its own.
build/lpeg.o: $(LJBIN) | build
	LUADIR=$(LJPREFIX)/include/luajit-2.0/ $(MAKE) -C vendor/LPeg $(PLATFORM)
	ld -r vendor/LPeg/*.o -o $(CURDIR)/build/lpeg.o
	mv vendor/LPeg/lpeg.so $(CURDIR)/build/
	cp vendor/LPeg/re.lua $(CURDIR)/build/

# In order to remove any dependance on a local install of LuaJIT, we build our
# own vendored version and install it in a faux directory structure under
# "build":
$(LJBIN) $(LJSTATIC): | build
	DESTDIR=$(CURDIR)/build $(MAKE) -C vendor/LuaJIT install

# This target simply creates the "build" directory if it doesn't already exist.
# Note that all the other targets that place files in the "build" directory
# depend on this target in an "order-only" fashion (e.g. the "build" target is
# included after a "|" character, indicating that the target only requires that
# the "build" target be run first and not that the target needs to be re-run if
# "build" is updated).
build:
	mkdir -p $@

# This simply tells make to run the "clean" and "test" targets every time:
.PHONY: clean test

# The test target simply uses luaunit and runs with LuaJIT, both vendored:
test: $(LJBIN) $(OBJS)
	@ $(foreach t,$(TESTS),\
	  LUA_PATH=";;./src/?.lua;./test/?.lua;./vendor/luaunit/?.lua" \
	  LUA_CPATH=";;./build/?.so"\
	  $(LJBIN) $(t))

# Cleaning is as simple as running the "clean" target in each vendored project
# directory, then destroying the "build" directory:
clean:
	$(MAKE) clean -C vendor/lua-expat
	$(MAKE) clean -C vendor/lua-curl
	$(MAKE) clean -C vendor/lpeg
	$(MAKE) clean -C vendor/LuaJIT
	rm -rf build playgo

# vim:nolist:ts=4:tw=80
