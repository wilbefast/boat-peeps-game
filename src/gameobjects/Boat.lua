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
	MAX_DX = 32,
	MAX_DY = 32,

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

	self.dx = useful.lerp(self.dx, -self.MAX_DX, dt)
	self.dy = self.dy + useful.signedRand(dt)

	if (self.y < 32 and self.dy < 0) or (self.y > WORLD_H - 32 and self.dy > 0) then
		self.dy = -self.dy
	end

	if self.x < LAND_W + 16 then
		self.purge = true
		for i = 1, 3 do
			Peep(self.x + useful.signedRand(4), self.y + useful.signedRand(4), Peep.Beggar)
		end
	end
end

function Boat:draw(x, y)
	--fudge.current:addb("boat", self.x, self.y)
	self.DEBUG_VIEW:draw(self)
	--GameObject.draw(self)
end

--[[------------------------------------------------------------
Collisions
--]]--

function Boat:eventCollision(other, dt)
	if other:isType("Explosion") then
		self.purge = true
	elseif other:isType("Boat") then
		other:shoveAwayFrom(self, 10*dt)
	end
end

--[[------------------------------------------------------------
Export
--]]--

return Boat