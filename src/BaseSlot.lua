local BaseSlot = Class
{
  init = function(self)
  end,
}

function BaseSlot:draw()
	love.graphics.setColor(255, 0, 0)
	love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
	useful.bindWhite()
end

return BaseSlot