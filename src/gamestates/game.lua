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

local img_coast = nil

local spawn_t = nil

local spawn_positions = useful.deck()
for i = 1, 9 do
	spawn_positions.stack(i*0.1*WORLD_H)
end

local active_soldier = nil
local active_citizen = nil
local hovered_tile = nil
local selected_tile = nil
local active_missile = nil
local active_option = nil

base_grid = nil

n_unmolested = 0

local gameover_t = nil
local game_t = nil

local building_menu = nil

--[[------------------------------------------------------------
Gamestate navigation
--]]--

function state:init()
	img_coast = love.graphics.newImage("assets/coast.png")


	for name, t in pairs(Building.types) do
		local icon = love.graphics.newImage(t.icon)
		t.menuOption = {
			type = t,
			draw = function(self, x, y)
				local scale = 1
				local black = false
				if active_option == t.menuOption then
					scale = 2
					love.graphics.setLineWidth(4)
					love.graphics.printf(t.name, x - 200, y + 32, 400, "center")
				else
					black = true
				end
				love.graphics.draw(icon, x, y, 0, scale, scale, 16, 16)
				if black then
					useful.bindBlack()
				end
				love.graphics.circle("line", x, y, scale*16)
				useful.bindWhite()

				if DEBUG then
					love.graphics.setColor(0, 0, 255)
						love.graphics.printf(t.name, x, y, 0, "center")
						if active_option == t.menuOption then
							love.graphics.circle("line", x, y, 28)
						else
							love.graphics.circle("line", x, y, 24)
						end
					useful.bindWhite()
				end
				love.graphics.setLineWidth(1)
			end
		}
	end

end


function state:enter()
	spawn_t = 0
	wave = 1
	gameover_t = 0
	game_t = 0

	base_grid = CollisionGrid(BaseSlot, TILE_W, TILE_H, N_TILES_ACROSS, N_TILES_DOWN, GRID_X, GRID_Y)
	base_grid:map(function(t)
		local m = RadialMenu(32, t.x + t.w*0.5, t.y + t.w*0.5)
		m:addOption(Building.Farm.menuOption, 0)
		m:addOption(Building.Church.menuOption, math.pi*0.5)
		m:addOption(Building.Base.menuOption, math.pi)
		m:addOption(Building.Prison.menuOption, math.pi*1.5)
		t.menu = m
	end)
	selected_tile = nil
	active_soldier = nil
	active_citizen = nil
	hovered_tile = nil
	active_missile = nil

	-- spawn initial units
	for i = 1, 3 do 
		Peep(LAND_W + useful.signedRand(4), WORLD_H*0.5 + useful.signedRand(4), Peep.Citizen)
	end
	for i = 1, 9 do
		Food(LAND_W + useful.signedRand(4), WORLD_H*0.5 + useful.signedRand(4))
	end

end


function state:leave()
	GameObject.purgeAll()
	SHADOW_CANVAS:clear()
	WORLD_CANVAS:clear()
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
		if active_option then
			selected_tile.building = Building(selected_tile, active_option.type)
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
	active_soldier = GameObject.getNearestOfType("Peep", mx, my, function(peep)
		return peep:canFireAt(mx, my) end)
	active_citizen = GameObject.getNearestOfType("Peep", mx, my, function(peep)
		return peep:isPeepType("Citizen") and (peep.hunger < 1) end)
	
	if selected_tile then
		selected_tile.menu:setPosition(0, 0)
		active_option = selected_tile.menu:pick(mx, my)
	else
		active_option = nil
	end
	
	if active_option then
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

	-- count time
	game_t = game_t + dt

	-- spawn boats
	if gameover_t <= 0 then
		spawn_t = spawn_t + dt
		if spawn_t > 15/(game_t*0.05) then
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

	-- count beggars
	n_unmolested = GameObject.countOfTypeSuchThat("Peep", function(peep)
				return peep:isPeepType("Beggar") and (not peep.brutaliser) and (not peep.convertor) end)
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


	--base_grid:draw()

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

	-- interface overlay
	UI_CANVAS:clear()
	useful.pushCanvas(UI_CANVAS)
		local mx, my = love.mouse.getPosition()
		love.graphics.setLineWidth(2)
		if mx > LAND_W + 32 then

			if active_missile then
				love.graphics.setColor(255, 100, 255)
					love.graphics.circle("fill", mx, my, 10)
					love.graphics.circle("fill", active_missile.x, active_missile.y, 6)
					love.graphics.line(active_missile.x, active_missile.y, mx, my)
					love.graphics.setBlendMode("subtractive")
						love.graphics.circle("fill", mx, my, 8)
						love.graphics.circle("fill", active_missile.x, active_missile.y, 4)
					love.graphics.setBlendMode("alpha")
					love.graphics.line(mx, my - 4, mx, my - 12)
					love.graphics.line(mx - 4, my, mx - 12, my)
					love.graphics.line(mx + 4, my, mx + 12, my)
					love.graphics.line(mx, my + 4, mx, my + 12)
				useful.bindWhite()

			elseif active_soldier then
				love.graphics.setColor(255, 50, 50)
					love.graphics.circle("fill", mx, my, 10)
					love.graphics.rectangle("fill", active_soldier.x - 16, active_soldier.y - 40, 32, 50)
					love.graphics.line(active_soldier.x, active_soldier.y, mx, my)
					love.graphics.setBlendMode("subtractive")
						love.graphics.circle("fill", mx, my, 8)
						love.graphics.rectangle("fill", active_soldier.x - 14, active_soldier.y - 38, 28, 46)
					love.graphics.setBlendMode("alpha")
					love.graphics.line(mx, my - 4, mx, my - 12)
					love.graphics.line(mx - 4, my, mx - 12, my)
					love.graphics.line(mx + 4, my, mx + 12, my)
					love.graphics.line(mx, my + 4, mx, my + 12)
				useful.bindWhite()
			end
		else
			if active_citizen and hovered_tile and (not selected_tile) then
				love.graphics.setColor(255, 255, 50)
					local hx, hy = hovered_tile.x + hovered_tile.w*0.5, hovered_tile.y + hovered_tile.h*0.5
					love.graphics.rectangle("fill", hx - 24, hy - 24, 48, 48)
					love.graphics.rectangle("fill", active_citizen.x - 16, active_citizen.y - 40, 32, 50)
					love.graphics.line(active_citizen.x, active_citizen.y, hx, hy)
					love.graphics.setBlendMode("subtractive")
						love.graphics.rectangle("fill", hx - 22, hy - 22, 44, 44)
						love.graphics.rectangle("fill", active_citizen.x - 14, active_citizen.y - 38, 28, 46)
					love.graphics.setBlendMode("alpha")
				useful.bindWhite()
			end
		end
		love.graphics.setLineWidth(1)

		base_grid:map(function(t)
			t.menu:draw()
		end)

	useful.popCanvas(UI_CANVAS)
	love.graphics.draw(UI_CANVAS)


	if game_t < 5 then
		local offset = 8*math.sin(2*game_t)

		love.graphics.setFont(FONT_BIG)
		love.graphics.printf("Protect your pies!", 
			VIEW_W*0.5 - VIEW_W*0.05, VIEW_H*0.3 + offset, VIEW_W*0.1, "center")
	end

end


--[[------------------------------------------------------------
EXPORT
--]]------------------------------------------------------------

return state