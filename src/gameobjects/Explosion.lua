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

local Explosion = Class
{
  type = GameObject.newType("Explosion"),

  init = function(self, x, y)
    GameObject.init(self, x, y, 0, 0)
    self.t = 0
    self.alreadyHit = {}
    shake = shake + 10

    for i = 1, 10 do
    	local angle = math.random()*math.pi*2
    	local dx, dy, dz = math.cos(angle), math.sin(angle), math.random()
    	local speed = 128 + math.random()*64
    	Particle.Smoke(self.x, self.y, speed*dx, speed*dy, speed*dz)
    end
    for i = 1, 30 do
    	local angle = math.random()*math.pi*2
    	local dx, dy, dz = math.cos(angle), math.sin(angle), math.random()
    	local speed = 128 + math.random()*64
    	Particle.Fire(self.x, self.y, speed*dx, speed*dy, speed*0.5*dz)
    end

    audio:play_sound("explosion", 0.4)
  end,
}
Explosion:include(GameObject)

--[[------------------------------------------------------------
Game loop
--]]--

function Explosion:update(dt)
	self.t = self.t + dt
	local size = math.sin(self.t*math.pi*2) * 32
	self.w, self.h = size, size
	if self.t > 0.5 then
		self.purge = true
	end
end

function Explosion:draw(x, y)
end


--[[------------------------------------------------------------
Export
--]]--

return Explosion