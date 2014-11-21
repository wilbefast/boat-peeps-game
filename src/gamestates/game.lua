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

--[[------------------------------------------------------------
Defines
--]]--

local LAND_W = WORLD_W*0.2

local t = 0

local spawn_positions = useful.deck()
for i = 1, 9 do
	spawn_positions.stack(i*0.1*WORLD_H)
end

local base_grid = nil

--[[------------------------------------------------------------
Gamestate navigation
--]]--

function state:init()
end


function state:enter()
	t = 0
	base_grid = CollisionGrid(BaseSlot, LAND_W/4, WORLD_H/10, 4, 10)
end


function state:leave()
	GameObject.purgeAll()
end

--[[------------------------------------------------------------
Callbacks
--]]--

function state:keypressed(key, uni)
  if key == "escape" then
    gamestate.switch(title)
  end
end

function state:mousepressed(x, y)
	local t = base_grid:pixelToTile(x, y)
	if t then
	else
		Explosion(x, y)
	end
end

function state:update(dt)
	GameObject.updateAll(dt, self.view)

	t = t + dt
	if t > 3 then
		Boat(WORLD_W + 128, spawn_positions.draw())
		t = 0
	end
end

function state:draw()
	-- background
	love.graphics.rectangle("fill", 0, 0, LAND_W, WORLD_H)
	base_grid:draw()

	-- objects
	fudge.set( { current = foregroundb } )
	GameObject.drawAll(self.view)
	love.graphics.draw(foregroundb)
	foregroundb.batch:clear()

	-- interface

end


--[[------------------------------------------------------------
EXPORT
--]]------------------------------------------------------------

return state