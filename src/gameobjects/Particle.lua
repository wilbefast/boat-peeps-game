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

local Particle = {
	type = GameObject.newType("Particle")
}

--[[------------------------------------------------------------
Fire
--]]--

local Fire = Class
{
  type = Particle.type,

  FRICTION = 6,

  init = function(self, x, y, dx, dy, dz)
    GameObject.init(self, x, y, 0)
    self.dx, self.dy, self.dz = dx, dy, dz or 0
    self.z = 0
    self.t = 0
    self.red = 200 + math.random()*55
    self.green = 200 + math.random()*25
    self.blue = 10 + math.random()*5
    self.dieSpeed = 1 + math.random()
    self.size = 10 + math.random()*6
  end,
}
Fire:include(GameObject)

function Fire:update(dt)
	self.t = self.t + self.dieSpeed*dt
	self.r = (1 - self.t)*self.size
	if self.t > 1 then
		self.purge = true
	end

	GameObject.update(self, dt)
	self.z = self.z + self.dz*dt
end

function Fire:draw(x, y)
	fudge.setColorb(self.red, self.green, self.blue)
		fudge.addb("circle", x, y - self.z, 0, self.r/64, self.r/64, 32, 32)
	fudge.setWhiteb()
end

Particle.Fire = Fire

--[[------------------------------------------------------------
Smoke
--]]--

local Smoke = Class
{
  type = Particle.type,

  FRICTION = 100,

  init = function(self, x, y, dx, dy, dz)
    GameObject.init(self, x, y, 0)
    self.dx, self.dy, self.dz = dx, dy, dz or 0
    self.z = 0
    self.t = 0
    self.a = 50 + math.random()*55
    self.size = 24 + 12*math.random()
    self.dieSpeed = 0.3 + math.random()*0.6
  end,
}
Smoke:include(GameObject)

function Smoke:update(dt)
	self.t = self.t + self.dieSpeed*dt
	self.r = math.max(0, (1 - self.t)*self.size)
	if self.t > 1 then
		self.purge = true
	end

	GameObject.update(self, dt)
	self.z = self.z + self.dz*dt
end

function Smoke:draw(x, y)
	local r = self.r
	local shad_r = math.min(r, 32*r/self.z)

	useful.pushCanvas(SHADOW_CANVAS)
		useful.bindBlack()
			useful.oval("fill", x, y, shad_r, shad_r*VIEW_OBLIQUE)
		useful.bindWhite()
	useful.popCanvas()

	fudge.setColorb(self.a, self.a, self.a)
		fudge.addb("circle", x, y - self.z, 0, r/64, r/64, 32, 32)
	fudge.setWhiteb()
end

Particle.Smoke = Smoke

--[[------------------------------------------------------------
Trail smoke
--]]--

local TrailSmoke = Class
{
  type = Particle.type,

  FRICTION = 2,

  init = function(self, x, y, dx, dy, dz)
    GameObject.init(self, x, y, 0)
    self.dx, self.dy, self.dz = dx, dy, dz or 0
    self.z = 0
    self.t = 0
    self.a = 50 + math.random()*55
    self.size = 8 + 4*math.random()
    self.dieSpeed = 1 + math.random()*0.6
    self.r = 1
  end,
}
TrailSmoke:include(GameObject)

function TrailSmoke:update(dt)
	self.t = self.t + self.dieSpeed*dt
	self.r = math.max(1, math.sin(self.t*math.pi)*self.size)
	if self.t > 1 then
		self.purge = true
	end
	log:write(self.dx, self.dy)
	GameObject.update(self, dt)
	self.z = self.z + self.dz*dt
end

function TrailSmoke:draw(x, y)
	local r = self.r
	local shad_r = math.min(r, 32*r/self.z)

	useful.pushCanvas(SHADOW_CANVAS)
		useful.bindBlack()
			useful.oval("fill", x, y, shad_r, shad_r*VIEW_OBLIQUE)
		useful.bindWhite()
	useful.popCanvas()

	fudge.setColorb(self.a, self.a, self.a)
		fudge.addb("circle", x, y - self.z, 0, r/64, r/64, 32, 32)
	fudge.setWhiteb()
end

Particle.TrailSmoke = TrailSmoke

--[[------------------------------------------------------------
Trail fire
--]]--

local TrailFire = Class
{
  type = Particle.type,

  FRICTION = 18,

  init = function(self, x, y, dx, dy, dz)
    GameObject.init(self, x, y, 0)
    self.dx, self.dy, self.dz = dx, dy, dz or 0
    self.z = 0
    self.t = 0
    self.red = 200 + math.random()*55
    self.green = 200 + math.random()*25
    self.blue = 10 + math.random()*5
    self.dieSpeed = 4 + 2*math.random()
    self.size = 3 + 2*math.random()
  end,
}
TrailFire:include(GameObject)

function TrailFire:update(dt)
	self.t = self.t + self.dieSpeed*dt
	self.r = math.max(0, math.sin(self.t*math.pi)*self.size)
	if self.t > 1 then
		self.purge = true
	end

	GameObject.update(self, dt)
	self.z = self.z + self.dz*dt
end

function TrailFire:draw(x, y)
	fudge.setColorb(self.red, self.green, self.blue)
		fudge.addb("circle", x, y - self.z, 0, self.r/64, self.r/64, 32, 32)
	fudge.setWhiteb()
end

Particle.TrailFire = TrailFire

--[[------------------------------------------------------------
Export
--]]--

return Particle