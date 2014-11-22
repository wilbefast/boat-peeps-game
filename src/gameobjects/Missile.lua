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
    self.dx, self.dy = (tx - x)/self.dist, (ty - y)/self.dist

    for i = 1, 3 do
    	local angle = math.random()*math.pi*2
    	local dx, dy, dz = math.cos(angle) - self.dx, math.sin(angle) - self.dy, math.random()
    	local speed = 64 + math.random()*32
    	Particle.Smoke(self.x, self.y, speed*dx, speed*dy, speed*dz)
    end

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
	local prev_t = self.t
	self.t = self.t + math.min(3*dt, 300*dt/self.dist)
	self.x = useful.lerp(self.start_x, self.target_x, self.t)
	self.y = useful.lerp(self.start_y, self.target_y, self.t)

	local life = 1-self.t
	-- 1 - (2x - 1)^2
  local parabola = -(2*life-1)*(2*life-1) + 1
  self.z = parabola*48*self.dist/WORLD_W

  -- smoke!
  if math.random() > 0.3 then
		local s = Particle.TrailSmoke(self.x, self.y, 
			-128*self.dx + useful.signedRand(8), 
			-128*self.dy + useful.signedRand(8),
			-4*(life-10 - 2) + useful.signedRand(10))
		s.z = self.z
	end

	if self.t > 1 then
		self.purge = true
	end
end

function Missile:draw(x, y)

	local dx, dy = 8*self.dx, 8*self.dy
	local tx, ty = x, y - self.z
	useful.bindBlack()
	love.graphics.polygon("fill", 
		tx + dx, ty + dy, 
		tx + dy*0.2, ty - dx*0.2, 
		tx - dy*0.2, ty + dx*0.2)


	useful.pushCanvas(SHADOW_CANVAS)
		useful.bindBlack()
			useful.oval("fill", self.x, self.y, 2, 2*VIEW_OBLIQUE)
		useful.bindWhite()
	useful.popCanvas()
end

--[[------------------------------------------------------------
Export
--]]--

return Missile