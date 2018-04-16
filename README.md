# PlayGo!

[![Project Status: Suspended – Initial development has started, but there has not yet been a stable, usable release; work has been stopped for the time being but the author(s) intend on resuming work.](http://www.repostatus.org/badges/latest/suspended.svg)](http://www.repostatus.org/#suspended)

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

This project uses a very traditional GNU Make makefile to build and run tests,
however the makefile itself uses a handful of tricks to make everything work:

* The vendored Lua libraries are built using their own makefiles, but then the
  resulting object files are bundled as a retargeted object file for later
  inclusion in the main build step.

* The Lua libraries themselves are compiled to object files using LuaJIT, but in
  such a way that `require` still works as expected.

* In order to accomplish the required renaming of the Lua files for compilation,
  a make include file is generated as part of the build process.

* All targets are specified in such a way that they will only be rebuilt when
  something changes, making incremental builds extremely efficient.

For all the details, see the comments in the [Makefile](Makefile) itself.
