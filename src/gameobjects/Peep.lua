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

--[[------------------------------------------------------------
Initialisation
--]]--

local Peep = Class
{
  FRICTION = 100,

  type = GameObject.newType("Peep"),

  init = function(self, x, y, peepType)
    GameObject.init(self, x, y, 8, 8)
    self.peepType = peepType
    self.state = { update = function(self, dt) self:setState(self.stateIdle()) end}
  end,
}
Peep:include(GameObject)

--[[------------------------------------------------------------
Sub-types
--]]--

Peep.types = {
  Beggar = {
  },
  Farmer = {
  },
  Soldier = {
  },
  Engineer = {
  }
}
for name, type in pairs(Peep.types) do
  Peep[name] = type
  type.name = name
end


--[[------------------------------------------------------------
Destruction
--]]--

function Peep:onPurge()
end

--[[------------------------------------------------------------
States
--]]--

function Peep:setState(newState)
  local oldState = self.state
  if oldState.exitTo then
    oldState.exitTo(newState)
  end
  if newState.enterFrom then
    newState.enterFrom(oldState)
  end
  self.state = newState
end

Peep.stateWander = function(self) return {
  name = "idle",
  update = function(dt)
  end
}
end

Peep.stateIdle = function(self) return {
  name = "idle",
  update = function(dt)
  end
}
end

--[[------------------------------------------------------------
Game loop
--]]--

function Peep:update(dt)
  GameObject.update(self, dt)

  self.state.update(self, dt)

  if not self.dest then
    self.dest = { 
      x = base_grid.x + math.random(base_grid.w)*base_grid.tilew,
      y = base_grid.y + math.random(base_grid.h)*base_grid.tileh
  }
  else
    self:accelerateTowardsObject(self.dest, 128*dt)
    if math.abs(self.x - self.dest.x) < self.w and math.abs(self.y - self.dest.y) < self.h then
      self.dest = nil
    end
  end
end

function Peep:draw(x, y)
	love.graphics.setColor(0, 0, 0)
		self.DEBUG_VIEW:draw(self)
		love.graphics.printf(self.peepType.name, x, y, 0, "center")
	useful.bindWhite()
end

--[[------------------------------------------------------------
Collisions
--]]--

function Peep:eventCollision(other, dt)
  log:write(other.name, dt)
  if other:isType("Peep") then
    other:shoveAwayFrom(self, 100*dt)
  elseif other:isType("Building") then
    self:shoveAwayFrom(other, 200*dt)
  end
end


--[[------------------------------------------------------------
Export
--]]--

return Peep