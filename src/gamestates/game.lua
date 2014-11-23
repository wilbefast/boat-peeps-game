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

local spawn_t = 0

local spawn_positions = useful.deck()
for i = 1, 9 do
	spawn_positions.stack(i*0.1*WORLD_H)
end

local active_soldier = nil
local active_citizen = nil

base_grid = nil

local gameover_t = 0

local hovered_tile = nil
local selected_tile = nil

local active_missile = nil

local building_menu = nil
for name, t in pairs(Building.types) do
	t.menuOption = {
		type = t,
		draw = function(self, x, y)
			love.graphics.setColor(0, 0, 255)
				love.graphics.printf(name, x, y, 0, "center")
				love.graphics.circle("line", x, y, 24)
			useful.bindWhite()
		end
	}
end

--[[------------------------------------------------------------
Gamestate navigation
--]]--

function state:init()
end


function state:enter()
	spawn_t = 0
	gameover_t = 0

	base_grid = CollisionGrid(BaseSlot, TILE_W, TILE_H, N_TILES_ACROSS, N_TILES_DOWN, GRID_X, GRID_Y)
	base_grid:map(function(t)
		local m = RadialMenu(32, t.x + t.w*0.5, t.y + t.w*0.5)
		m:addOption(Building.Farm.menuOption, 0)
		m:addOption(Building.SocialServices.menuOption, math.pi*0.5)
		m:addOption(Building.Base.menuOption, math.pi)
		m:addOption(Building.PoliceStation.menuOption, math.pi*1.5)
		t.menu = m
	end)
	selected_tile = nil
	active_soldier = nil
	active_citizen = nil
	hovered_tile = nil
	active_missile = nil

	-- spawn initial units
	for i = 1, 3 do 
		Peep(LAND_W + useful.signedRand(4), WORLD_H*0.5 + useful.signedRand(4), Peep.Soldier).ammo = 100
	end
	for i = 1, 9 do
		Food(LAND_W + useful.signedRand(4), WORLD_H*0.5 + useful.signedRand(4))
	end

end


function state:leave()
	GameObject.purgeAll()
	--WORLD_CANVAS:clear()
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
		if active_soldier then
			active_missile = active_soldier:fireAt(x, y)
			active_missile.homing = true
		end
		selected_tile = nil
	else
		local opt = selected_tile and selected_tile.menu:pick(x, y)

		if opt then
			selected_tile.building = Building(selected_tile, opt.type)
			selected_tile = nil
		elseif active_citizen then
			local t = base_grid:pixelToTile(x, y)
			if t and not t.building then
				selected_tile = t
			else
				selected_tile = nil
			end
		else
			selected_tile = nil
		end
	end	
end

function state:mousereleased()
	if active_missile then
		active_missile.homing = false
		active_missile = nil
	end
end

function state:update(dt)
	local mx, my = love.mouse.getPosition()

	GameObject.updateAll(dt, { oblique = VIEW_OBLIQUE })

	-- highlight active objects
	local mx, my = love.mouse.getPosition()
	active_soldier = GameObject.getNearestOfType("Peep", mx, my, function(peep)
		return peep:canFireAt(mx, my) end)
	active_citizen = GameObject.getNearestOfType("Peep", mx, my, function(peep)
		return peep:isPeepType("Citizen") and (peep.hunger < 1) end)

	if selected_tile and selected_tile.menu:pick(mx, my) then
		hovered_tile = selected_tile
	else
		hovered_tile = base_grid:pixelToTile(mx, my)
		if hovered_tile ~= selected_tile then
			selected_tile = nil
		end
		if hovered_tile and hovered_tile.building then
			hovered_tile = nil
		end
	end

	-- spawn boats
	if gameover_t <= 0 then
		spawn_t = spawn_t + dt
		if spawn_t > 3 then
			Boat(WORLD_W + 128, spawn_positions.draw(), math.random(3))
			spawn_t = 0
		end
	end

	-- close menus
	base_grid:map(function(t)
		if t == selected_tile then
			t.menu:open(3*dt)
		else
			t.menu:close(3*dt)
		end
	end)

	-- gameover ?
	if gameover_t > 0 then
		gameover_t = gameover_t + dt
		if gameover_t > 3 then
			gamestate.switch(gameover)
		end
	else
		local citizens = GameObject.countOfTypeSuchThat("Peep", function(peep)
				return (not peep:isPeepType("Beggar") and (peep.hunger < 1))
			end)
		log:write(citizens)
		if citizens <= 0 then
			-- fail!
			if not GameObject.getObjectOfType("Food") then
				gameover_t = gameover_t + dt
			end
		end
	end

	-- clean
	if active_soldier and active_soldier.purge then
		active_soldier = nil
	end
	if active_citizen and active_citizen.purge then
		active_citizen = nil
	end
	if active_missile and active_missile.purge then
		active_missile = nil
	end
end

function state:draw()
	-- land
	love.graphics.setColor(250, 130, 30)
		love.graphics.rectangle("fill", 0, 0, LAND_W, WORLD_H)
	useful.bindWhite()
	base_grid:draw()

	-- sea
	love.graphics.setColor(30, 200, 250)
		love.graphics.rectangle("fill", LAND_W, 0, WORLD_W - LAND_W, WORLD_H)
	useful.bindWhite()

	-- shadows
	useful.bindWhite(128)
		love.graphics.draw(SHADOW_CANVAS, 0, 0)
		SHADOW_CANVAS:clear()
	useful.bindWhite(255)

	-- objects
	fudge.set( { current = foregroundb } )
	GameObject.drawAll(self.view)
	love.graphics.draw(foregroundb)
	foregroundb.batch:clear()

	-- interface
	base_grid:map(function(t)
		t.menu:draw()
	end)


	local mx, my = love.mouse.getPosition()
	if mx > LAND_W + 32 then
		if active_missile then
			love.graphics.circle("line", mx, my, 10)
			love.graphics.circle("line", active_missile.x, active_missile.y, 10)
			love.graphics.line(active_missile.x, active_missile.y, mx, my)
		elseif active_soldier then
			love.graphics.circle("line", mx, my, 10)
			love.graphics.circle("line", active_soldier.x, active_soldier.y, 10)
			love.graphics.line(active_soldier.x, active_soldier.y, mx, my)
		end
	else
		if active_citizen and hovered_tile then
			local hx, hy = hovered_tile.x + hovered_tile.w*0.5, hovered_tile.y + hovered_tile.h*0.5
			love.graphics.rectangle("line", hx - 24, hy - 24, 48, 48)
			love.graphics.circle("line", active_citizen.x, active_citizen.y, 10)
			love.graphics.line(active_citizen.x, active_citizen.y, hx, hy)
		end
	end
end


--[[------------------------------------------------------------
EXPORT
--]]------------------------------------------------------------

return state