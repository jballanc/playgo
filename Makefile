LUAJIT_LIB=luajit-51
LUAJIT_BIN=luajit

CC=clang
CFLAGS=-pagezero_size 10000 -image_base 100000000 -l$(LUAJIT_LIB) -Ibuild
LDFLAGS=-lexpat -lcurl

BC = main.h
LUA_SRC = $(wildcard src/*.lua)
OBJS = $(LUA_SRC:.lua=.o)

playgo: lxp lua-curl $(OBJS) $(BC)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(wildcard build/*.o) main.c

%.o: %.lua | build
	$(LUAJIT_BIN) -b $(@:.o=.lua) build/$(notdir $@)

%.h: %.lua | build
	$(LUAJIT_BIN) -b $(@:.h=.lua) build/$(notdir $@)

lxp: | build
	$(MAKE) -C vendor/lua-expat
	cp vendor/lua-expat/src/*.o ./build/

lua-curl: | build
	cmake -DUSE_LUAJIT=ON -Bvendor/lua-curl/ -Hvendor/lua-curl/
	$(MAKE) -C vendor/lua-curl
	cp vendor/lua-curl/CMakeFiles/cURL.dir/src/*.o ./build/

.PHONY: clean
clean:
	$(MAKE) clean -C vendor/lua-expat
	$(MAKE) clean -C vendor/lua-curl
	rm -rf build playgo

build:
	mkdir -p $@

