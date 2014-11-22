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
    GameObject.init(self, x, y, tile.w*0.8, tile.h*0.8)
    self.buildingType = buildingType
  end,
}
Building:include(GameObject)



--[[------------------------------------------------------------
Destruction
--]]--

function Building:onPurge()
end

--[[------------------------------------------------------------
Game loop
--]]--

function Building:update(dt)

end

function Building:draw(x, y)
	love.graphics.setColor(0, 0, 255)
		self.DEBUG_VIEW:draw(self)
		love.graphics.printf(self.buildingType, x, y, 0, "center")
	useful.bindWhite()
end

--[[------------------------------------------------------------
Export
--]]--

return Building