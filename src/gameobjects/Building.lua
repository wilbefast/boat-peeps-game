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

local Building = Class
{
  type = GameObject.newType("Building"),

  init = function(self, tile, buildingType)
  	local x, y = tile.x + tile.w*0.5, tile.y + tile.h*0.5
    GameObject.init(self, x, y, tile.w*0.4)
    self.buildingType = self.ConstructionSite
    self.futureBuildingType = buildingType
    self.workers = {}
    self.construction = 0
  end,
}
Building:include(GameObject)

--[[------------------------------------------------------------
Sub-types
--]]--

Building.types = {
  ConstructionSite = {
    jobType = "Engineer",
    updatePeep = function(peep, building, dt)
      if (peep.hunger < 1) then
        peep:setState(Peep.stateBuild, building)
      end
    end,
    draw = function(self)
      fudge.addb("construction", self.x, self.y, 0, 1, 1, 32, 32)
    end,
    icon = "farm_icon"
  },
  Farm = {
    jobType = "Farmer",
    updatePeep = function(peep, farm, dt)
      if (peep.hunger < 1) and (peep.state.name ~= "farm") then
        peep:setState(Peep.stateFarm, farm)
      end
    end,
    draw = function(self)
      fudge.addb("farm", self.x, self.y, 0, 1, 1, 32, 32)
    end,
    icon = "farm_icon"
  },
  Base = {
    jobType = "Soldier",
    updatePeep = function(peep, base, dt)
      if (peep.ammo < 1) 
        and (peep.hunger < 1) 
        and (peep.state.name ~= "reloading")
        and (peep.state.name ~= "firing") 
      then
        peep:setState(Peep.stateGetAmmo, base)
      end
    end,
    draw = function(self)
      fudge.addb("base", self.x, self.y, 0, 1, 1, 32, 32)
    end,
    icon = "base_icon"
  },
  Prison = {
    jobType = "Policeman",
    updatePeep = function(peep, base, dt)
      if (peep.hunger < 1) and (n_unmolested > 0) then
        peep:setState(Peep.stateRiot)
      end
    end,
    draw = function(self)
      fudge.addb("policestation", self.x, self.y, 0, 1, 1, 32, 32)
    end,
    icon = "policestation_icon"
  },
  Church = {
    jobType = "SocialWorker",
    updatePeep = function(peep, base, dt)
      if (peep.hunger < 1) and (n_unmolested > 0) then
        peep:setState(Peep.stateConvert)
      end
    end,
    draw = function(self)
      fudge.addb("church", self.x, self.y, 0, 1, 1, 32, 32)
    end,
    icon = "church_icon"
  }
}
for name, type in pairs(Building.types) do
  Building[name] = type
  type.name = name
end

function Building:isBuildingType(type)
  return self.buildingType == Building[type]
end

--[[------------------------------------------------------------
Job management
--]]--

function Building:hirePeep(peep)
  peep:setPeepType(self.buildingType.jobType, self)
  peep.job = self
  table.insert(self.workers, peep)
end

function Building:firePeep(peep)
  peep:setPeepType("Citizen")
  peep.job = nil
  for i, p in ipairs(self.workers) do
    if p == peep then
      table.remove(self.workers, i)
      return
    end
  end
end

function Building:fireAll()
  for i, p in ipairs(self.workers) do
    p.job = nil
    p:setPeepType("Citizen")
  end
  self.workers = {}
end

function Building:maxWorkers()
  return 1
end

--[[------------------------------------------------------------
Construction / repairs
--]]--


function Building:build(amount)
  if self.construction < 1 then
    self.construction = math.min(1, self.construction + amount)
    if self.construction >= 1 then
      self.buildingType = self.futureBuildingType
      self.futureBuildingType = nil
      self:fireAll()
    end
  end
end

--[[------------------------------------------------------------
Destruction
--]]--

function Building:onPurge()
end

--[[------------------------------------------------------------
Game loop
--]]--

function Building:update(dt)
  useful.purge(self.workers)
  if #self.workers < self.maxWorkers() then
    local newbie = GameObject.getNearestOfType("Peep", self.x, self.y, function(peep)
      return peep:isPeepType("Citizen")
    end)
    if newbie then
      self:hirePeep(newbie)
    end
  end
end

function Building:draw(x, y)
  if DEBUG then
  	love.graphics.setColor(0, 0, 255)
  		self.DEBUG_VIEW:draw(self)
  		love.graphics.printf(self.buildingType.name, x, y, 0, "center")
  	useful.bindWhite()
  end

  if self.buildingType.draw then
    self.buildingType.draw(self)
  end
  useful.pushCanvas(SHADOW_CANVAS)
    useful.bindBlack()
      love.graphics.rectangle("fill", self.x - self.r*1.5, self.y - self.r*1.5 + 4, self.r*3, self.r*3)
    useful.bindWhite()
  useful.popCanvas()
end

--[[------------------------------------------------------------
Export
--]]--

return Building