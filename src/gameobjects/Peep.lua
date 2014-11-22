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
    GameObject.init(self, x, y, 5)
    self.peepType = peepType
    self.state = { update = function(dt) self:setState(self.stateWander) end}
    self.ammo = 0
  end,
}
Peep:include(GameObject)

--[[------------------------------------------------------------
Sub-types
--]]--

Peep.types = {
  Beggar = {
  },
  Citizen = {
  },
  Farmer = {
  },
  Soldier = {
    onBecome = function(peep)
      peep:setState(Peep.stateWander)
    end
  },
  Engineer = {
    onBecome = function(peep, building)
      peep:setState(Peep.stateBuild, building)
    end
  }
}
for name, type in pairs(Peep.types) do
  Peep[name] = type
  type.name = name
end

function Peep:isPeepType(type)
  return self.peepType == Peep[type]
end

function Peep:setPeepType(type, ...)
  type = Peep[type]
  if type.onBecome then
    type.onBecome(self, ...)
  end
  self.peepType = type
end

--[[------------------------------------------------------------
Destruction
--]]--

function Peep:onPurge()
end

--[[------------------------------------------------------------
States
--]]--

function Peep:setState(newState, ...)
  newState = newState(self, ...)
  local oldState = self.state
  if oldState.exitTo then
    oldState.exitTo(newState)
  end
  if newState.enterFrom then
    newState.enterFrom(oldState)
  end
  self.state = newState
end

Peep.stateGetAmmo = function(peep) 
  local armoury = GameObject.getNearestOfType("Building", peep.x, peep.y,
    function(building) return building:isBuildingType("Base") end)

  return {

    name = "getAmmo",

    update = function(dt)
      if not armoury then
        peep:setState(Peep.stateIdle)
        return
      end
      if peep:isNear(armoury) then
        peep.ammo = 1
        peep:setState(Peep.stateIdle)
        return
      else
        peep:accelerateTowardsObject(armoury, 128*dt)
      end
    end
  }
end

Peep.stateBuild = function(peep, building) 
  return {

    name = "build",

    update = function(dt)
      if peep:isNear(building) then
        building:build(dt*0.2)
      else
        peep:accelerateTowardsObject(building, 128*dt)
      end
    end
  }
end

Peep.stateWander = function(peep, ...) 
  local dest = nil
  return {

    name = "wander",

    enterFrom = function(prev)
      dest = { 
        x = base_grid.x + math.random(base_grid.w)*base_grid.tilew,
        y = base_grid.y + math.random(base_grid.h)*base_grid.tileh
      }
    end,

    update = function(dt)
      peep:accelerateTowardsObject(dest, 128*dt)
      if peep:isNear(dest) then
        peep:setState(peep.stateIdle)
        return
      end
    end
  }
end

Peep.stateIdle = function(peep)
  local t = nil
  return {

    name = "idle",

    enterFrom = function(prev)
      t = 0
    end,

    update = function(dt)
      t = t + dt
      if t > 3 then
        peep:setState(peep.stateWander)
      end
    end
  }
end

--[[------------------------------------------------------------
Game loop
--]]--

function Peep:update(dt)

  if self.x > LAND_W then
    self.dx = self.dx - 32*dt
  end

  GameObject.update(self, dt)

  self.state.update(dt)

  if self.job and self.job.buildingType.updatePeep then
    self.job.buildingType.updatePeep(self, dt)
  end
end

function Peep:draw(x, y)
	love.graphics.setColor(0, 0, 0)
		self.DEBUG_VIEW:draw(self)
		love.graphics.printf(self.peepType.name, x, y + 4, 0, "center")
    love.graphics.printf(self.state.name, x, y - 16, 0, "center")
	useful.bindWhite()
end

--[[------------------------------------------------------------
Combat
--]]--

function Peep:canFireAt(x, y)
  return (self:isPeepType("Soldier") and self.ammo > 0)
end

function Peep:fireAt(x, y)
  self.ammo = math.max(0, self.ammo - 1)
  Missile(self.x, self.y, x, y)
end

--[[------------------------------------------------------------
Collisions
--]]--

function Peep:isAt(x, y)
  return (Vector.dist2(self.x, self.y, x, y) < self.r*self.r)
end


function Peep:isNear(obj)
  local r = self.r + (obj.r or 0)
  return (Vector.dist2(self.x, self.y, obj.x, obj.y) < 2*r*r)
end

function Peep:eventCollision(other, dt)
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