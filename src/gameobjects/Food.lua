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

local Food = Class
{
  FRICTION = 200,

  type = GameObject.newType("Food"),

  init = function(self, x, y)
    GameObject.init(self, x, y, 4)
  end,
}
Food:include(GameObject)



--[[------------------------------------------------------------
Destruction
--]]--

function Food:onPurge()
end

--[[------------------------------------------------------------
Game loop
--]]--

function Food:update(dt)
  if self.x > LAND_W then
    self.dx = self.dx - 128*dt
  elseif self.x < 0 then
    self.dx = self.dx + 128*dt
  end

	GameObject.update(self, dt)
end

function Food:draw(x, y)
	love.graphics.setColor(255, 0, 255)
		self.DEBUG_VIEW:draw(self)
	useful.bindWhite()
end

--[[------------------------------------------------------------
Collisions
--]]--

function Food:eventCollision(other, dt)
  if other:isType("Food") or other:isType("Building") then
  	self:shoveAwayFrom(other, 100*dt)
  end
end

--[[------------------------------------------------------------
Export
--]]--

return Food