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

local Missile = Class
{
  type = GameObject.newType("Missile"),

  init = function(self, x, y, tx, ty)
    GameObject.init(self, x, y, 2)
    self.start_x, self.start_y = x, y
    self.target_x, self.target_y = tx, ty
    self.t = 0
    self.z = 0
    self.dist = Vector.dist(x, y, tx, ty)
  end,
}
Missile:include(GameObject)



--[[------------------------------------------------------------
Destruction
--]]--

function Missile:onPurge()
	Explosion(self.x, self.y)
end

--[[------------------------------------------------------------
Game loop
--]]--

function Missile:update(dt)
	self.t = self.t + math.min(3*dt, 300*dt/self.dist)
	self.x = useful.lerp(self.start_x, self.target_x, self.t)
	self.y = useful.lerp(self.start_y, self.target_y, self.t)

	local life = 1-self.t
  local parabola = -(2*life-1)*(2*life-1) + 1
  self.z = parabola*48*self.dist/WORLD_W

	if self.t > 1 then
		self.purge = true
	end
end

function Missile:draw(x, y)
	love.graphics.circle("fill", self.x, self.y - self.z, 4)
	useful.bindBlack()
		love.graphics.circle("fill", self.x, self.y, 2)
	useful.bindWhite()
end

--[[------------------------------------------------------------
Export
--]]--

return Missile