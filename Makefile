LJDESTDIR=$(CURDIR)/build
LJPREFIX=$(LJDESTDIR)/usr/local
LJSTATIC=$(LJPREFIX)/lib/libluajit-5.1.a
LJBIN=$(LJPREFIX)/bin/luajit

CC=clang
CFLAGS=-pagezero_size 10000 -image_base 100000000 -Ibuild/usr/local/include
LDFLAGS=-lexpat -lcurl

slashtodots = $(addprefix build/,$(addsuffix $1,$(subst /,.,$(patsubst src/%.lua,%,$2))))
rwildcard = $(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))

MAIN = src/main.c
LUA_SRC = $(call rwildcard,src/,*.lua)
LUA_OBJS = $(call slashtodots,.o,$(LUA_SRC))
OBJS = build/lxp.o build/lua-curl.o
TESTS = $(call rwildcard,test/,*.lua)

playgo: $(MAIN) $(LUA_OBJS) $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(LJSTATIC) $(wildcard build/*.o) $(MAIN)

build/luadeps.mk: | build
	$(foreach f,$(LUA_SRC),$(shell echo "$(call slashtodots,.lua,$(f)): $(f)\n\tcp $$< \$$@" >> build/luadeps.mk))

include build/luadeps.mk

%.o: %.lua $(LJBIN) | build
	LUA_PATH=";;$(LJPREFIX)/share/luajit-2.0.2/?.lua" $(LJBIN) -b $< $@

build/lxp.o: | build
	$(MAKE) -C vendor/lua-expat
	ld -r vendor/lua-expat/src/*.o -o ./build/lxp.o

build/lua-curl.o: | build
	cmake -DUSE_LUAJIT=ON -Bvendor/lua-curl/ -Hvendor/lua-curl/
	$(MAKE) -C vendor/lua-curl
	ld -r vendor/lua-curl/CMakeFiles/cURL.dir/src/*.o -o ./build/lua-curl.o

$(LJBIN) $(LJSTATIC): | build
	DESTDIR=$(CURDIR)/build $(MAKE) -C vendor/LuaJIT install

build:
	mkdir -p $@

.PHONY: clean test

test:
	@ $(foreach t,$(TESTS),LUA_PATH=";;./src/?.lua;./test/?.lua;./vendor/luaunit/?.lua" $(LJBIN) $(t))

clean:
	$(MAKE) clean -C vendor/lua-expat
	$(MAKE) clean -C vendor/lua-curl
	$(MAKE) clean -C vendor/LuaJIT
	rm -rf build playgo

