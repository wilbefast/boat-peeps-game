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

local t = 0

local spawn_positions = useful.deck()
for i = 1, 9 do
	spawn_positions.stack(i*0.1*WORLD_H)
end

local base_grid = nil

local selected_tile = nil

local base_menu = nil
local menu_farm = {
	draw = function(self, x, y)
		love.graphics.setColor(0, 0, 255)
			love.graphics.printf("Farm", x, y, 0, "center")
			love.graphics.circle("line", x, y, 24)
		useful.bindWhite()
	end
}
local menu_factory = {
	draw = function(self, x, y)
		love.graphics.setColor(0, 0, 255)
			love.graphics.printf("Factory", x, y, 0, "center")
			love.graphics.circle("line", x, y, 24)
		useful.bindWhite()
	end
}
local menu_turret = {
	draw = function(self, x, y)
		love.graphics.setColor(0, 0, 255)
			love.graphics.printf("Barracks", x, y, 0, "center")
			love.graphics.circle("line", x, y, 24)
		useful.bindWhite()
	end
}
local menu_university = {
	draw = function(self, x, y)
		love.graphics.setColor(0, 0, 255)
			love.graphics.printf("University", x, y, 0, "center")
			love.graphics.circle("line", x, y, 24)
		useful.bindWhite()
	end
}

--[[------------------------------------------------------------
Gamestate navigation
--]]--

function state:init()
end


function state:enter()
	t = 0
	base_grid = CollisionGrid(BaseSlot, TILE_W, TILE_H, N_TILES_ACROSS, N_TILES_DOWN, GRID_X, GRID_Y)
	base_grid:map(function(t)
		local m = RadialMenu(32, t.x + t.w*0.5, t.y + t.w*0.5)
		m:addOption(menu_farm, 0)
		m:addOption(menu_factory, math.pi*0.5)
		m:addOption(menu_turret, math.pi)
		m:addOption(menu_university, math.pi*1.5)
		t.menu = m
	end)
	selected_tile = nil
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

	if x > LAND_W + 32 then
		Explosion(x, y)
		selected_tile = nil
	else
		local opt = selected_tile and selected_tile.menu:pick(x, y)

		if opt then
			Building(selected_tile, "DERP")
			selected_tile = nil
		else
			local t = base_grid:pixelToTile(x, y)
			if t then
				selected_tile = t
			else
				selected_tile = nil
			end
		end
	end	
end

function state:update(dt)
	GameObject.updateAll(dt, self.view)

	t = t + dt
	if t > 3 then
		Boat(WORLD_W + 128, spawn_positions.draw())
		t = 0
	end

	base_grid:map(function(t)
		if t == selected_tile then
			t.menu:open(3*dt)
		else
			t.menu:close(3*dt)
		end
	end)

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
	base_grid:map(function(t)
		t.menu:draw()
	end)
end


--[[------------------------------------------------------------
EXPORT
--]]------------------------------------------------------------

return state