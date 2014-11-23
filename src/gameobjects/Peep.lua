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
    self.t = math.random()
  end,
}
Peep:include(GameObject)

--[[------------------------------------------------------------
Sub-types
--]]--

Peep.types = {
  Beggar = {
    draw = function(peep, x, y)
      fudge.addb("peep_refugee", x, y, 0, 1, 1, 16, 32)
    end
  },
  Citizen = {
    onBecome = function(peep)
      peep:setState(Peep.stateIdle)
    end,
    draw = function(peep, x, y)
      fudge.addb("peep_citizen", x, y, 0, 1, 1, 16, 32)
    end
  },
  Farmer = {
    onBecome = function(peep, farm)
      peep:setState(Peep.stateFarm, farm)
    end,
    draw = function(peep, x, y)
      fudge.addb("peep_farmer", x, y, 0, 1, 1, 16, 32)
    end
  },
  Soldier = {
    onBecome = function(peep)
      peep:setState(Peep.stateWander)
    end,
    draw = function(peep, x, y)
      fudge.addb("peep_soldier", x, y, 0, 1, 1, 16, 32)
    end
  },
  Engineer = {
    onBecome = function(peep, building)
      peep:setState(Peep.stateBuild, building)
    end,
    draw = function(peep, x, y)
      fudge.addb("peep_construction", x, y, 0, 1, 1, 16, 32)
    end
  },
  SocialWorker = {
    onBecome = function(peep)
      peep:setState(Peep.stateConvert)
    end,
    draw = function(peep, x, y)
      fudge.addb("peep_priest", x, y, 0, 1, 1, 16, 32)
    end
  },
  Policeman = {
    onBecome = function(peep)
      peep:setState(Peep.stateRiot)
    end,
    draw = function(peep, x, y)
      fudge.addb("peep_police", x, y, 0, 1, 1, 16, 32)
    end
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
  local other = GameObject.getNearestOfType("Peep", peep.x, peep.y,
    function(p) return (p:isPeepType("Beggar") 
      and (p.x < LAND_W)
      and (not p.brutaliser)
      and (not p.convertor)) end)
  if other then
    other.brutaliser = peep
    peep.target = other
  end

  return {

    name = "riot",

    exitTo = function()
      if other and other.brutaliser == peep then
        other.brutaliser = nil
        peep.target = nil
      end
    end,

    update = function(dt)
      if (not other) or (other.purge) then
        peep:setState(Peep.stateIdle)
        return
      end
      if peep:isNear(other) then
        other:shove(1, 0, 50)
      else
        if peep.x < LAND_W then
          peep:accelerateTowardsObject(other, 200*dt)
        end
      end
    end
  }
end

Peep.stateConvert = function(peep) 
  local other = GameObject.getNearestOfType("Peep", peep.x, peep.y,
    function(p) return p:isPeepType("Beggar") and not p.convertor end)
  if other then
    other.convertor = peep
    if other.brutaliser then
      other.brutaliser:setState(Peep.stateIdle)
      other.brutaliser = nil
    end
    peep.target = other
  end
  return {

    name = "convert",

    exitTo = function()
      if other and other.convertor == peep then
        other.convertor = nil
        peep.target = nil
      end
    end,

    update = function(dt)
      if (not other) or (other.purge) then
        peep:setState(Peep.stateIdle)
        return
      end
      if peep:isNear(other) then
        other:setState(Peep.stateIdle)
        other.conversion = (other.conversion or 0) + dt*0.1
        if other.conversion > 1 then
          other:setPeepType("Citizen")
          other.brutaliser = nil
          peep:setState(Peep.stateIdle)
          return
        end
      else
        if peep.x < LAND_W then
          peep:accelerateTowardsObject(other, 200*dt)
        end
      end
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
        t = t + dt*0.2
        if t > 1 then
          t = 0
          Food(farm.x + useful.signedRand(4), farm.y + useful.signedRand(4))
        end
      else
        peep:accelerateTowardsObject(farm, 200*dt)
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
        peep:accelerateTowardsObject(food, 200*dt)
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
        peep:accelerateTowardsObject(armoury, 200*dt)
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
        peep:accelerateTowardsObject(building, 200*dt)
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
      peep:accelerateTowardsObject(dest, 100*dt)
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

  self.t = self.t + dt
  if self.state.name == "idle" then
    self.t = 0
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
  end

  -- kludgy clean up
  if self.brutaliser and self.brutaliser.target ~= self then
    self.brutaliser = nil
  end
  if self.convertor and self.convertor.target ~= self then
    self.convertor = nil
  end
end

function Peep:draw(x, y)


  if self.peepType.draw then
    self.peepType.draw(self, x, y - 4 + 4*math.sin(20*self.t))
  end
  useful.pushCanvas(SHADOW_CANVAS)
    useful.bindBlack()
      useful.oval("fill", self.x, self.y, 16, 16*VIEW_OBLIQUE)
    useful.bindWhite()
  useful.popCanvas()

  if DEBUG then
  	love.graphics.setColor(0, 0, 0)
  		love.graphics.circle(self:isPeepType("Beggar") and "line" or "fill", self.x, self.y, self.r)
      if DEBUG then
        if self.job then
          love.graphics.line(self.x, self.y, self.job.x, self.job.y)
        end
        love.graphics.printf(self.peepType.name, x, y + 4, 0, "center")
        love.graphics.printf(self.state.name, x, y - 16, 0, "center")
      end
      if self.convertor then
        love.graphics.setColor(0, 255, 0)
        love.graphics.line(self.x, self.y, self.convertor.x, self.convertor.y)
      end
      if self.brutaliser then
        love.graphics.setColor(255, 0, 0)
        love.graphics.line(self.x, self.y, self.brutaliser.x, self.brutaliser.y)
      end
  	useful.bindWhite()
  end

end

--[[------------------------------------------------------------
Combat
--]]--

function Peep:canFireAt(x, y)
  return (self:isPeepType("Soldier") and self.ammo > 0 and self.hunger < 1)
end

function Peep:fireAt(x, y)
  self.ammo = math.max(0, self.ammo - 1)
  self:shove(self.x - x, self.y - y, 300)
  return Missile(self.x, self.y, x, y)
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