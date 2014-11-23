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
    self.hunger = math.random()*0.2
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
    onBecome = function(peep)
      peep:setState(Peep.stateIdle)
    end
  },
  Farmer = {
    onBecome = function(peep, farm)
      peep:setState(Peep.stateFarm, farm)
    end
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
  },
  SocialWorker = {
  },
  Policeman = {
  },
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
  if self.state.name == newState then
    return
  end
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

Peep.stateRiot = function(peep) 
  return {

    name = "riot",

    update = function(dt)
    end
  }
end

Peep.stateConvert = function(peep) 
  return {

    name = "convert",

    update = function(dt)
    end
  }
end

Peep.stateFarm = function(peep, farm) 
  local t = 0
  return {

    name = "farm",

    update = function(dt)
      if (not farm) or (farm.purge) then
        peep:setState(Peep.stateIdle)
        return
      end
      if peep:isNear(farm) then
        t = t + dt*0.1
        if t > 1 then
          t = 0
          Food(farm.x + useful.signedRand(4), farm.y + useful.signedRand(4))
        end
      else
        peep:accelerateTowardsObject(farm, 128*dt)
      end
    end
  }
end

Peep.stateGetFood = function(peep) 
  local food = GameObject.getNearestOfType("Food", peep.x, peep.y)

  return {

    name = "food",

    update = function(dt)
      if (not food) or (food.purge) then
        peep:setState(Peep.stateIdle)
        return
      end
      if peep:isNear(food) then
        food.purge = true
        peep.hunger = math.max(0, peep.hunger - 1)
        return
      else
        peep:accelerateTowardsObject(food, 128*dt)
      end
    end
  }
end

Peep.stateGetAmmo = function(peep, armoury) 
  return {

    name = "getAmmo",

    update = function(dt)
      if (not armoury) or (armoury.purge) then
        peep:setState(Peep.stateIdle)
        return
      end
      if peep:isNear(armoury) then
        peep:setState(Peep.stateReloading)
        return
      else
        peep:accelerateTowardsObject(armoury, 128*dt)
      end
    end
  }
end

Peep.stateReloading = function(peep) 

  local t = 0

  return {
    name = "reloading",

    update = function(dt)
      t = t + dt
      if t > 1.5 then
        peep.ammo = peep.ammo + 1
        peep:setState(Peep.stateWander)
      end
    end
  }
end

Peep.stateBuild = function(peep, building) 
  log:write("BUILDING")
  return {

    name = "build",

    update = function(dt)
      if (not building) or (building.purge) then
        peep:setState(Peep.stateIdle)
        return
      end
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
    self.dx = self.dx - 128*dt
  elseif self.x < 0 then
    self.dx = self.dx + 128*dt
  end

  GameObject.update(self, dt)

  self.state.update(dt)

  self.hunger = self.hunger + dt/30
  if self.hunger > 1 then
    if self.hunger < 2 then
      self:setState(Peep.stateGetFood)
    else
      self.purge = true
    end
  end

  if self.job and self.job.buildingType.updatePeep then
    self.job.buildingType.updatePeep(self, self.job, dt)
  elseif self.job then
    log:write("no updatePeep method for", self.job.buildingType.name)
  end
end

function Peep:draw(x, y)
	love.graphics.setColor(0, 0, 0)
		self.DEBUG_VIEW:draw(self)
    if self.job then
      love.graphics.line(self.x, self.y, self.job.x, self.job.y)
    end
		love.graphics.printf(self.peepType.name, x, y + 4, 0, "center")
    love.graphics.printf(self.state.name, x, y - 16, 0, "center")
	useful.bindWhite()
end

--[[------------------------------------------------------------
Combat
--]]--

function Peep:canFireAt(x, y)
  return (self:isPeepType("Soldier") and self.ammo > 0 and self.hunger < 1)
end

function Peep:fireAt(x, y)
  self.ammo = math.max(0, self.ammo - 1)
  Missile(self.x, self.y, x, y)
  self:shove(self.x - x, self.y - y, 300)
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