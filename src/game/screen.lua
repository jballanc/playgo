local screen = {}

function screen.new()
  print("Initializing screen...")
  return { setup = function()
                     print("Configuring parameters...")
                   end }
end

return screen
