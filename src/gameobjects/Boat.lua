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

local Boat = Class
{
  type = GameObject.newType("Boat"),

  init = function(self, x, y)
    GameObject.init(self, x, y, 32, 16)
  end,
}
Boat:include(GameObject)



--[[------------------------------------------------------------
Destruction
--]]--

function Boat:onPurge()
end

--[[------------------------------------------------------------
Game loop
--]]--

function Boat:update(dt)

	GameObject.update(self, dt)

	self.dx = useful.lerp(self.dx, -32, dt)
	self.dy = self.dy + math.random()*dt
end

function Boat:draw(x, y)
	--fudge.current:addb("boat", self.x, self.y)
	self.DEBUG_VIEW:draw(self)
	--GameObject.draw(self)
end

--[[------------------------------------------------------------
Collisions
--]]--

function Boat:eventCollision(other)
	if other:isType("Explosion") then
		self.purge = true
	end
end

--[[------------------------------------------------------------
Export
--]]--

return Boat