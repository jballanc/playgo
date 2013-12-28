LUAJIT_LIB=luajit-51
LUAJIT_BIN=luajit

CC=clang
CFLAGS=-pagezero_size 10000 -image_base 100000000 -l$(LUAJIT_LIB) -Ibuild
LDFLAGS=-lexpat -lcurl

slashtodots = $(addprefix build/,$(addsuffix $1,$(subst /,.,$(patsubst src/%.lua,%,$2))))
rwildcard = $(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))

BC = build/main.h
LUA_SRC = $(call rwildcard,src/,*.lua)
LUA_OBJS = $(call slashtodots,.o,$(LUA_SRC))
OBJS = build/lxp.o build/lua-curl.o
TESTS = $(call rwildcard,test/,*.lua)

playgo: $(OBJS) $(LUA_OBJS) $(BC)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(wildcard build/*.o) main.c

build/luadeps.mk: | build
	$(foreach f,$(LUA_SRC),$(shell echo "$(call slashtodots,.lua,$(f)): $(f)\n\tcp $$< \$$@" >> build/luadeps.mk))

include build/luadeps.mk

%.o: %.lua | build
	$(LUAJIT_BIN) -b $< $@

build/main.h: main.lua | build
	$(LUAJIT_BIN) -b $< build/$(notdir $@)

build/lxp.o: | build
	$(MAKE) -C vendor/lua-expat
	ld -r vendor/lua-expat/src/*.o -o ./build/lxp.o

build/lua-curl.o: | build
	cmake -DUSE_LUAJIT=ON -Bvendor/lua-curl/ -Hvendor/lua-curl/
	$(MAKE) -C vendor/lua-curl
	ld -r vendor/lua-curl/CMakeFiles/cURL.dir/src/*.o -o ./build/lua-curl.o

build:
	mkdir -p $@

.PHONY: clean test

test:
	@ $(foreach t,$(TESTS),LUA_PATH=";;./src/?.lua;./test/?.lua;./vendor/luaunit/?.lua" $(LUAJIT_BIN) $(t))

clean:
	$(MAKE) clean -C vendor/lua-expat
	$(MAKE) clean -C vendor/lua-curl
	rm -rf build playgo

