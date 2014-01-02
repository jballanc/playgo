# PlayGo!

A simple, curses-based interface for reviewing Go games in SGF format, playing
turns on the Dragon Go Server, and more!


## How to Play

The `playgo` tool is available as a stand-alone binary download...

...or will be when I get a bit further. For now, this project is mostly about
experimenting with LuaJIT's build system, curses, SGF parsing, and other fun
programming topics.


# Development

PlayGo is built with Lua using the excellent LuaJIT runtime. Aside from
excellent performance and a built-in library for bit-wise operations, LuaJIT
also has the advantage of being able to compile Lua code to self-contained
executables. Aside from LuaJIT, this project is also using lcurses for drawing
the game screen in terminal, Lua-Curl for interactions with the Dragon Go
Server, and LPeg for parsing SGF files.


## Build System


