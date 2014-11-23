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

  init = function(self, x, y, size)


  	size = 1

    GameObject.init(self, x, y, 32*size, 16)
    self.size = size
    self.hits = size
    self.MAX_DX = self.MAX_DX/size
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

	if self.x < LAND_W + 16*self.size then
		self.purge = true
		for i = 1, self.size do
			Peep(self.x + useful.signedRand(4), self.y + useful.signedRand(4), Peep.Beggar)
		end
	end

	local life = (self.size - self.hits)/self.size
	if math.random() < life then
		local angle = math.random()*math.pi*2
		local speed = 12 + math.random()*8
		Particle.TrailSmoke(self.x + useful.signedRand(self.w*0.5), self.y, 
			math.cos(angle)*speed, 
			math.sin(angle)*speed, 
			math.random()*speed)
	end

end

function Boat:draw(x, y)
	if self.size == 1 then
		fudge.addb("boat_small", x - self.w*0.5, y - self.h)
	elseif self.size == 2 then
		-- TODO
	elseif self.size == 3 then
		-- TODO
	end

  useful.pushCanvas(SHADOW_CANVAS)
    useful.bindBlack()
      love.graphics.rectangle("fill", 
      	self.x - self.w*0.5, 
      	self.y - self.h*0.5 + 4, 
      	self.w, self.h)
    useful.bindWhite()
  useful.popCanvas()


	if DEBUG then
		self.DEBUG_VIEW:draw(self)
	end
end

--[[------------------------------------------------------------
Collisions
--]]--

function Boat:eventCollision(other, dt)
	if other:isType("Explosion") and (not other.alreadyHit[self]) then
		other.alreadyHit[self] = true
		self.hits = self.hits - 1
		if self.hits <= 0 then
			self.purge = true
			for i = 1, self.size do
				Explosion(self.x + useful.signedRand(self.w*0.5), self.y)
			end
		else
			self:shoveAwayFrom(other, 700/self.size*dt)
		end
	elseif other:isType("Boat") then
		if self.size >= other.size then
			other:shoveAwayFrom(self, 100*(1 + self.size - other.size)*dt)
		end
	end
end

--[[------------------------------------------------------------
Export
--]]--

return Boat