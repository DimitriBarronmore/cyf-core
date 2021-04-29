local current_folder = (...):gsub('%init$', '') 

Arena.Hide()

local arenas = require(current_folder.."arena_creation")
local movement = require(current_folder.."player_movement")

local real_arena = Arena

Arena = arenas(real_arena.x, real_arena.y, real_arena.width, real_arena.height)

local arinn = getmetatable(Arena)
arinn.currentwidth = real_arena.currentwidth
arinn.currentheight = real_arena.currentheight

return function() return arenas, movement end
