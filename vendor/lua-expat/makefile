# This is a heavily modified Makefile based on the original for lxp:

T= lxp
V= 1.2.0

# LuaJIT includes directory
LUA_INC= /usr/local/include/luajit-2.0
# Expat includes directory
EXPAT_INC= /usr/include

# Compilation parameters
CWARNS = -Wall -pedantic \
        -Waggregate-return \
        -Wcast-align \
        -Wmissing-prototypes \
        -Wstrict-prototypes \
        -Wnested-externs \
        -Wpointer-arith \
        -Wshadow \
        -Wwrite-strings

CFLAGS = $(CWARNS) -ansi -O2 -I$(LUA_INC) \
   -I$(COMPAT_DIR) -I$(EXPAT_INC)
CC = clang

OBJS= src/lxplib.o
objs: $(OBJS)

clean:
	rm -f $(OBJS)
