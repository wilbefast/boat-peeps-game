--[[
(C) Copyright 2014 William Dyce

All rights reserved. This program and the accompanying materials
are made available under the terms of the GNU Lesser General Public License
(LGPL) version 2.1 which accompanies this distribution, and is available at
http://www.gnu.org/licenses/lgpl-2.1.html

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
Lesser General Public License for more details.
--]]

-------------------------------------------------------------------------------
-- LIBRARY INCLUDES
-------------------------------------------------------------------------------

fudge = require("fudge/src/fudge")

gamestate = require("hump/gamestate")
Class = require("hump/class")
Vector = require("hump/vector-light")

useful = require("unrequited/useful")
audio = require("unrequited/audio")
log = require("unrequited/log")
GameObject = require("unrequited/GameObject")
Animation = require("unrequited/Animation")
AnimationView = require("unrequited/AnimationView")
Controller = require("unrequited/Controller")
RadialMenu = require("unrequited/RadialMenu")
CollisionGrid = require("unrequited/CollisionGrid")

-------------------------------------------------------------------------------
-- MONKEY PATCHING
-------------------------------------------------------------------------------

function GameObject:shove(dx, dy, force)
	if self.isStatic then
		return
	end
	dx, dy = Vector.normalize(dx, dy)
	self.dx, self.dy = self.dx + dx*force, self.dy + dy*force
end

function GameObject:shoveAwayFrom(from, force)
	local dx, dy = self.x - from.x, self.y - from.y
	self:shove(dx, dy, force)
end

local __old_love_mouse_getPosition = love.mouse.getPosition

love.mouse.getPosition = function()
	local x, y = __old_love_mouse_getPosition()
	return x/VIEW_SCALE, y/VIEW_SCALE
end

-------------------------------------------------------------------------------
-- GAME INCLUDES
-------------------------------------------------------------------------------

BaseSlot = require("BaseSlot")

Food = require("gameobjects/Food")
Missile = require("gameobjects/Missile")
Peep = require("gameobjects/Peep")
Building = require("gameobjects/Building")
Boat = require("gameobjects/Boat")
Explosion = require("gameobjects/Explosion")
Particle = require("gameobjects/Particle")

-------------------------------------------------------------------------------
-- DEFINES
-------------------------------------------------------------------------------

WORLD_W = 1280
WORLD_H = 720
WORLD_CANVAS = love.graphics.newCanvas(WORLD_W, WORLD_H)
SHADOW_CANVAS = love.graphics.newCanvas(WORLD_W, WORLD_H)
UI_CANVAS = love.graphics.newCanvas(WORLD_W, WORLD_H)

LAND_W = WORLD_W*0.2

TILE_W = LAND_W/4
TILE_H = TILE_W
N_TILES_ACROSS = math.floor(LAND_W/TILE_W - 1)
N_TILES_DOWN = math.floor(WORLD_H/TILE_H - 1)
GRID_W = TILE_W*N_TILES_ACROSS
GRID_H = TILE_H*N_TILES_DOWN
GRID_X = (LAND_W - GRID_W)/2
GRID_Y = (WORLD_H - GRID_H)/2

VIEW_W = 0
VIEW_H = 0

VIEW_OBLIQUE = 0.75

VIEW_SCALE = 1

DEBUG = false

FONT_SMALL = nil
FONT_MEDIUM = nil
FONT_BIG = nil

-------------------------------------------------------------------------------
-- GLOBAL VARIABLES
-------------------------------------------------------------------------------

shake = 0

-------------------------------------------------------------------------------
-- GAME STATES
-------------------------------------------------------------------------------

game = require("gamestates/game")
title = require("gamestates/title")
gameover = require("gamestates/gameover")

-------------------------------------------------------------------------------
-- LOVE CALLBACKS
-------------------------------------------------------------------------------
love.load = function()
	VIEW_W = love.graphics.getWidth()
	VIEW_H = love.graphics.getHeight()

	while (WORLD_W*VIEW_SCALE < VIEW_W) and (WORLD_H*VIEW_SCALE < VIEW_H) do
		VIEW_SCALE = VIEW_SCALE + 0.0001
	end
	VIEW_SCALE = VIEW_SCALE - 0.0001
	love.graphics.setDefaultFilter("nearest", "nearest", 1)

  fudge.set({ monkey = true })
  foregroundb = fudge.new("assets/foreground", { npot = false })

	gamestate.registerEvents{ 'quit', 'keypressed', 'keyreleased' }
	gamestate.switch(title)

	FONT_SMALL = love.graphics.newFont("assets/ttf/Romulus_by_pix3m.ttf", 32)
	FONT_SMALL:setFilter("nearest", "nearest", 1)
	love.graphics.setFont(FONT_SMALL)

	FONT_MEDIUM = love.graphics.newFont("assets/ttf/Romulus_by_pix3m.ttf", 48)
	FONT_MEDIUM:setFilter("nearest", "nearest", 1)

	FONT_BIG = love.graphics.newFont("assets/ttf/Romulus_by_pix3m.ttf", 64)
	FONT_BIG:setFilter("nearest", "nearest", 1)

end

love.draw = function()
	useful.pushCanvas(WORLD_CANVAS)
		gamestate.draw()
	useful.popCanvas()

	love.graphics.push()
		love.graphics.scale(VIEW_SCALE, VIEW_SCALE)
		love.graphics.translate(useful.signedRand(shake), useful.signedRand(shake))
		love.graphics.draw(WORLD_CANVAS)
		useful.recordGIF("x")
	love.graphics.pop()

	if DEBUG then
		log:draw(32, 32)
	end
end

love.update = function(dt)

	if love.keyboard.isDown("x") then
    dt = 1/30
 	end

  if shake > 0 then
    shake = math.max(0, shake - 10*dt*shake)
  end
  gamestate.update(dt)
end

love.mousepressed = function(x, y, button)
	gamestate.mousepressed(x/VIEW_SCALE, y/VIEW_SCALE, button)
end

love.mousereleased = function(x, y, button)
	gamestate.mousereleased(x/VIEW_SCALE, y/VIEW_SCALE, button)
end

love.keypressed = function(key)
	if key == "o" then
		DEBUG = (not DEBUG)
	end
end