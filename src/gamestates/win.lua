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

local state = gamestate.new()

local img_coast = nil
local t = nil

ending_title = nil
ending_description = nil

--[[------------------------------------------------------------
Gamestate navigation
--]]--

function state:init()
	img_coast = love.graphics.newImage("assets/coast.png")
end

function state:enter()
	if not playing_music_menu then
		music_menu:play()
		music_menu:seek(music_game:tell())
		music_game:pause()
		playing_music_menu = true
	end
	
	t = 0
end

function state:leave()
	WORLD_CANVAS:clear()
end

--[[------------------------------------------------------------
Callbacks
--]]--

function state:keypressed(key, uni)
  if key=="escape" then
    gamestate.switch(title)
  end
end

function state:mousepressed(x, y, button)
  gamestate.switch(title)
end

function state:update(dt)
	t = t + dt
end

function state:draw()

	-- sea
	love.graphics.setColor(10, 162, 200)
		love.graphics.rectangle("fill", LAND_W, 0, WORLD_W - LAND_W, WORLD_H)
	useful.bindWhite()

	-- land
	love.graphics.setColor(200, 100, 10)
		love.graphics.rectangle("fill", 0, 0, LAND_W, WORLD_H)
		love.graphics.draw(img_coast, LAND_W, 0)
	useful.bindWhite()

	local offset = 8*math.sin(2*t)

	love.graphics.setFont(FONT_BIG)
	love.graphics.printf("CONGRATULATIONS!", 
		(VIEW_W*0.5 - VIEW_W*0.2)/VIEW_SCALE, (VIEW_H*0.1 + offset)/VIEW_SCALE, (VIEW_W*0.4)/VIEW_SCALE, "center")

	love.graphics.setFont(FONT_MEDIUM)
	love.graphics.printf("You created", 
		(VIEW_W*0.5 - VIEW_W*0.15)/VIEW_SCALE, (VIEW_H*0.2 + offset)/VIEW_SCALE, (VIEW_W*0.3)/VIEW_SCALE, "center")

	love.graphics.setFont(FONT_BIG)
	love.graphics.printf(ending_title, 
		(VIEW_W*0.5 - VIEW_W*0.2)/VIEW_SCALE, (VIEW_H*0.4 + offset)/VIEW_SCALE, (VIEW_W*0.4)/VIEW_SCALE, "center")

	love.graphics.setFont(FONT_MEDIUM)
	love.graphics.printf(ending_description, 
		(VIEW_W*0.5 - VIEW_W*0.3)/VIEW_SCALE, (VIEW_H*0.6 + offset)/VIEW_SCALE, (VIEW_W*0.6)/VIEW_SCALE, "center")

	love.graphics.setFont(FONT_SMALL)
end


--[[------------------------------------------------------------
EXPORT
--]]------------------------------------------------------------

return state