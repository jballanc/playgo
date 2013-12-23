local curses = require 'curses'
curses.initscr()
curses.cbreak()
curses.echo(false)  -- not noecho !
curses.nl(false)    -- not nonl !
local stdscr = curses.stdscr()  -- it's a userdatum
stdscr:clear()
local a = {};  for k in pairs(curses) do a[#a+1]=k end
stdscr:mvaddstr(14,20, 'Currrent screen dimensions: '..curses.cols()..'x'..curses.lines())
stdscr:mvaddstr(15,20,'print out curses table (y/n) ? ')
stdscr:refresh()
local c
while true do
  c = stdscr:getch()
  if c == curses.KEY_RESIZE then
    stdscr:mvaddstr(14, 48, ''..curses.cols()..'x'..curses.lines())
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
  for _,k in ipairs(a) do print(type(curses[k])..'  '..k) end
end
