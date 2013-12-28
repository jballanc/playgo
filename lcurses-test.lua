local curses = require 'curses_c'
curses.initscr()

-- Setup some colors
curses.start_color()
curses.use_default_colors()
curses.init_pair(1, curses.COLOR_GREEN, -1)
curses.init_pair(2, curses.COLOR_RED, -1)
curses.init_pair(3, curses.COLOR_MAGENTA, curses.COLOR_YELLOW)
local green, red, odd =
  curses.color_pair(1), curses.color_pair(2), curses.color_pair(3)

curses.cbreak()
curses.echo(false)  -- not noecho !
curses.nl(false)    -- not nonl !
local stdscr = curses.stdscr()  -- it's a userdatum
stdscr:clear()
local a = {};  for k in pairs(curses) do a[#a+1]=k end
stdscr:attrset(curses.A_REVERSE)
stdscr:mvaddstr(14,20, 'Currrent screen dimensions: ')
stdscr:attrset(bit.bor(odd, curses.A_PROTECT))
stdscr:addstr(curses.cols()..'x'..curses.lines())
stdscr:attrset(curses.A_NORMAL)
stdscr:mvaddstr(15,20,'print out ')
stdscr:attrset(curses.A_UNDERLINE)
stdscr:addstr('curses')
stdscr:attrset(curses.A_NORMAL)
stdscr:addstr(' table (')
stdscr:attrset(green)
stdscr:addch("y")
stdscr:attrset(curses.A_NORMAL)
stdscr:addch("/")
stdscr:attrset(red)
stdscr:addch("n")
stdscr:attrset(curses.A_NORMAL)
stdscr:addstr(") ? ")
stdscr:refresh()
local c
while true do
  c = stdscr:getch()
  if c == curses.KEY_RESIZE then
    stdscr:attrset(bit.bor(odd, curses.A_STANDOUT))
    stdscr:mvaddstr(14, 48, ''..curses.cols()..'x'..curses.lines())
    stdscr:move(15,51)
    stdscr:touchline(0,curses.lines())
    stdscr:redrawwin()
  end
  if c < 256 then
    c = string.char(c)
    break
  end
end
curses.endwin()
if c == 'y' then
  table.sort(a)
  for _, k in ipairs(a) do print(type(curses[k])..'  '..k) end
end
