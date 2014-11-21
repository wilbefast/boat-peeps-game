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
-- INCLUDES
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

Boat = require("gameobjects/Boat")

-------------------------------------------------------------------------------
-- DEFINES
-------------------------------------------------------------------------------

WORLD_W = 1280
WORLD_H = 720
WORLD_CANVAS = love.graphics.newCanvas(WORLD_W, WORLD_H)

VIEW_W = 0
VIEW_H = 0

VIEW_SCALE = 1

DEBUG = false

-------------------------------------------------------------------------------
-- GAME STATES
-------------------------------------------------------------------------------

game = require("gamestates/game")
title = require("gamestates/title")

-------------------------------------------------------------------------------
-- LOVE CALLBACKS
-------------------------------------------------------------------------------

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

	gamestate.registerEvents{ 'update', 'quit', 'keypressed', 
		'keyreleased', 'mousepressed', 'mousereleased' }
	gamestate.switch(title)
end

love.draw = function()
	useful.pushCanvas(WORLD_CANVAS)
		gamestate.draw()
	useful.popCanvas()

	love.graphics.push()
		love.graphics.scale(VIEW_SCALE, VIEW_SCALE)
		gamestate.draw()
	love.graphics.pop()

	if DEBUG then
		log:draw(32, 32)
	end
end

love.keypressed = function(key)
	if key == "o" then
		DEBUG = (not DEBUG)
	end
end