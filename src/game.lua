local screen = require("game.screen")
local server = require("game.server")

local game = {}

-- Setup for display and server communications
game.screen = screen.new()
game.server = server.new()

function game.play()
  game.screen.setup()
  print("Let's play!")
end

return game
