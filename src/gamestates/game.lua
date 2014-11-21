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


--[[------------------------------------------------------------
Gamestate navigation
--]]--

function state:init()
end


function state:enter()
	t = 0
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


function state:update(dt)
	GameObject.updateAll(dt, self.view)

	t = t + dt
	if t > 3 then
		Boat(WORLD_W + 128, WORLD_H*math.random())
		t = 0
	end
end

function state:draw()
	-- background
	love.graphics.rectangle("fill", 0, 0, LAND_W, WORLD_H)

	-- objects
	fudge.set( { current = foregroundb } )
	GameObject.drawAll(self.view)
	love.graphics.draw(foregroundb)
	foregroundb.batch:clear()

	-- interface
	love.graphics.print("GAME", 32, 32)
end


--[[------------------------------------------------------------
EXPORT
--]]------------------------------------------------------------

return state