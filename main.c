#include <stdlib.h>
#include <stdio.h>
#include <luajit-2.0/lua.h>
#include <luajit-2.0/lualib.h>
#include <luajit-2.0/lauxlib.h>
#include "main.h"

#define CHECK_LOADED(i) if(i) {\
                          fprintf(stderr, "Problem loading playgo: %s\n",\
                                  lua_tostring(L, -1));\
                          exit(i);\
                        }

extern int luaopen_lxp(lua_State *);
extern int luaopen_cURL(lua_State *);

int
main(int argc, char *argv[]) {
  int status, result;
  lua_State *L;

  L = luaL_newstate();
  luaL_openlibs(L);
  luaopen_lxp(L);
  luaopen_cURL(L);

  CHECK_LOADED(luaL_loadbuffer(L, luaJIT_BC_main, luaJIT_BC_main_SIZE, "main"));
  CHECK_LOADED(lua_pcall(L, 0, LUA_MULTRET, 0));

  lua_getglobal(L, "main");
  CHECK_LOADED(lua_pcall(L, 0, 0, 0));

  return 0;
}
