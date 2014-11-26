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

img_bubble = nil
img_bubble_eat = nil
img_bubble_convert = nil
img_bubble_police = nil
img_bubble_ammo = nil
img_bubble_build = nil

local gameover_t = nil
local game_t = nil

local building_menu = nil

time_left = nil

--[[------------------------------------------------------------
Gamestate navigation
--]]--

function state:init()

	img_coast = love.graphics.newImage("assets/coast.png")
	img_bubble = love.graphics.newImage("assets/popup.png")
	img_bubble_eat = love.graphics.newImage("assets/popup_eat.png")
	img_bubble_convert = love.graphics.newImage("assets/popup_convert.png")
	img_bubble_police = love.graphics.newImage("assets/popup_police.png")
	img_bubble_ammo = love.graphics.newImage("assets/popup_ammo.png")
	img_bubble_build = love.graphics.newImage("assets/popup_build.png")

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
	if playing_music_menu then
		music_game:play()
		music_game:seek(music_menu:tell())
		music_menu:pause()
		playing_music_menu = false
	end


	spawn_t = 0
	wave = 1
	gameover_t = 0
	game_t = 0
	time_left = 305

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
		if selected_tile then
			audio:play_sound("menu_close")
		end
	else
		if active_option then
			selected_tile.building = Building(selected_tile, active_option.type)
			selected_tile = nil
			audio:play_sound("select")
		elseif active_citizen then
			local t = base_grid:pixelToTile(x, y)
			if t and not t.building then
				selected_tile = t
				audio:play_sound("menu_open")
			else
				selected_tile = nil
				if selected_tile then
					audio:play_sound("menu_close")
				end
			end
		else
			selected_tile = nil
			if selected_tile then
				audio:play_sound("menu_close")
			end
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
	local n_boats = GameObject.countOfTypeSuchThat("Boat")

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
			if selected_tile then
				audio:play_sound("menu_close")
			end
			selected_tile = nil
		end
		if hovered_tile and hovered_tile.building then
			hovered_tile = nil
		end
	end

	-- count time
	game_t = game_t + dt
	time_left = math.max(0, time_left - dt)
	if (time_left <= 0) then -- and (n_boats <= 0) then

		local n_prisons = GameObject.countOfTypeSuchThat("Building", function(b) 
			return b:isBuildingType("Prison")
		end)
		local n_churches = GameObject.countOfTypeSuchThat("Building", function(b) 
			return b:isBuildingType("Church")
		end)
		local n_bases = GameObject.countOfTypeSuchThat("Building", function(b) 
			return b:isBuildingType("Base")
		end)
		local n_farms = GameObject.countOfTypeSuchThat("Building", function(b) 
			return b:isBuildingType("Farm")
		end)
		local n_total = n_prisons + n_farms + n_bases + n_churches
		log:write(n_prisons, "prisons")
		log:write(n_churches, "churches")
		log:write(n_bases, "bases")
		log:write(n_farms, "farms")
		log:write(n_total, "total")

		n_prisons = n_prisons/(n_total - n_farms)
		n_bases = n_bases/(n_total - n_farms)
		n_farms = n_farms/n_total
		n_churches = n_churches/(n_total - n_farms)

		if n_prisons > 0.5 then
			ending_title = "A Police State"
			ending_description = "'Being poor's against the laws!'"
		elseif n_bases > 0.7 then
			ending_title = "A Military Despotism"
			ending_description = "'Might is right!'"
		elseif n_farms > 0.9 then
			ending_title = "An Agrarian Utopia"
			ending_description = "'Imagine all the people...'"
		elseif n_churches > 0.5 then
			ending_title = "A Totalitarian Theocracy"
			ending_description = "'Strength Through Unity, Unity Through Faith'"
		else
			ending_title = "A Pie Refuge"
			ending_description = "'Only pastries are welcome here...'"
		end

		gamestate.switch(win)
		return
	end

	-- spawn boats
	if (gameover_t <= 0) and (time_left > 0) then
		spawn_t = spawn_t + dt
		if spawn_t > math.max(0.5, (5*time_left/300)*(0.5 + 0.5*(1 + math.cos(game_t / 10)))) then
			local max_boats = (game_t/300)*20
			if n_boats <= max_boats then
				Boat(WORLD_W + 128, spawn_positions.draw(), math.random(3))
				spawn_t = 0
			else
				spawn_t = -3
			end
			
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
	-- clear
	local mx, my = love.mouse.getPosition()
	local cursor_drawn = false
	UI_CANVAS:clear()

	-- sea
	love.graphics.setColor(10, 162, 200)
		love.graphics.rectangle("fill", LAND_W, 0, WORLD_W - LAND_W, WORLD_H)
	useful.bindWhite()

	-- land
	love.graphics.setColor(200, 100, 10)
		love.graphics.rectangle("fill", 0, 0, LAND_W, WORLD_H)
		love.graphics.draw(img_coast, LAND_W, 0)
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

	-- interface overlay
	useful.pushCanvas(UI_CANVAS)
		
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
					cursor_drawn = true
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
					cursor_drawn = true
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
					cursor_drawn = true
				useful.bindWhite()
			end
		end
		love.graphics.setLineWidth(1)

		base_grid:map(function(t)
			t.menu:draw()
		end)

		if not cursor_drawn then
			love.graphics.setLineWidth(2)
				love.graphics.line(mx, my - 8, mx, my + 8)
				love.graphics.line(mx - 8, my, mx + 8, my)
			love.graphics.setLineWidth(1)
		end

	useful.popCanvas(UI_CANVAS)
	love.graphics.draw(UI_CANVAS)

	local offset = 8*math.sin(2*game_t)
	if game_t < 5 then
		

		love.graphics.setFont(FONT_BIG)
		love.graphics.printf("Protect your pie!", 
			VIEW_W*0.5 - VIEW_W*0.05, VIEW_H*0.3 + offset, VIEW_W*0.1, "center")
	else
		love.graphics.setFont(FONT_MEDIUM)

		local minutes_left = math.floor(time_left/60)
		local seconds_left = math.floor(time_left - 60*minutes_left)
		local format = string.format("%02d : %02d", minutes_left, seconds_left)

		love.graphics.printf(format, 
			VIEW_W*0.5 - VIEW_W*0.05, VIEW_H*0.05 + offset*0.5, VIEW_W*0.1, "center")
	end

end


--[[------------------------------------------------------------
EXPORT
--]]------------------------------------------------------------

return state