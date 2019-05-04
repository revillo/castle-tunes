local Class = {}

local DefaultBackgroundColor = {0,0,0,0}
local DefaultTextColor = {1,1,1,1}

function Class:new(o)
    o = o or {};
    
    setmetatable(o, self);
    self.__index = self;
    
    if (o.init) then
        o:init();
    end
    
    return o;
end 

local UIElement = Class:new();
local UUID = 0;

function UIElement:clear()
  
  self.children = {};

end

function UIElement:init()

    self.id = UUID;
    self.x = self.x or 0;
    self.y = self.y or 0;
    self.width = self.width or 50;
    self.height = self.height or 20;
    self.parent = nil;
    self.children = {};
    self.backgroundColor = self.backgroundColor or DefaultBackgroundColor;
    self.color = self.color or DefaultTextColor;
    self.textIndent = 5;
    
    UUID = UUID + 1;
end

function UIElement:setParent(parent)
  self.parent = parent;  
end

function UIElement:getGlobalBounds()
  local x, y = self:getGlobalCoords();
  return x, y, self.width, self.height;
end

function UIElement:getGlobalCoords()
  if (self.parent) then
    local px, py = self.parent:getGlobalCoords();
    return self.x + px, self.y + py;
  else
    return 0, 0;
  end
end

function UIElement:removeElement(elem)
  self.children[elem.id] = nil;
  elem.parent = nil;
end

function UIElement:addElement(elem)

  assert(self.children[elem.id] == nil or self.children[elem.id] == elem, "Can't add two UI elements with same ID to UI Element");
  
  self.children[elem.id] = elem;
  elem.parent = self;
end

--[[
UIElement:drawSelf()

end]]

function UIElement:draw()
  if (self.drawSelf) then
    self:drawSelf();
  end

  for id, elem in pairs(self.children) do
     elem:draw();
  end
end

function UIElement:update(dt)
  
  if (self.updateSelf) then
    self:updateSelf(dt);
  end
  
  for id, elem in pairs(self.children) do
     elem:update(dt);
  end
  
  if (self.postupdateSelf) then
    self:postupdateSelf(dt);
  end
end

local root = UIElement:new();

local Button = UIElement:new();

function Button:init()
  UIElement.init(self);
  self.mouseOver = false;
end

function UIElement:drawSelf()
    
    local x, y, w, h = self:getGlobalBounds();
    
    if (self.backgroundColor[4] > 0.0) then
      love.graphics.setColor(self.backgroundColor);
      love.graphics.rectangle("fill", x, y, w, h);  
    end
    
    --love.graphics.setColor(0,0,0,0.5);
    --love.graphics.print(self.text, self.x + self.size * 30 - 1, self.y + self.size * 16 - 1, 0, self.size, self.size);
    
    love.graphics.setColor(self.color)
    --love.graphics.print(self.text, self.x + self.size * 30, self.y + self.size * 16, 0, self.size, self.size);
    
    if (self.text) then
      love.graphics.print(self.text, x + self.textIndent, y + 2, 0, 1, 1);
    end
end

function Button:updateSelf(dt)
  x, y = love.mouse.getPosition();
  
  if (self:isHover(x,y)) then
    
    if (not self.isHover and self.onMouseOver) then
      self:onMouseOver();
    end
    
    self.mouseOver = true;
    root:requestCursor("hand");
    
    if (self.onClick and root.mouseDown) then
        self:onClick(x, y);
        root.mouseDown = false;
    end
  else
    
    if (self.mouseOver) then
      self.mouseOver = false;
      if (self.onMouseOut) then
        self:onMouseOut();
      end
    end
  
  end
end

function root:handleTextinput(text)
  
  if(self.activeTextBox) then
    self.activeTextBox:handleTextinput(text)
    return true
  end
  
  return false

end

function root:handleKeypressed(key)
  if(self.activeTextBox) then
    self.activeTextBox:handleKeypress(key)
    return true
  end
  
  return false
end

function root:handleMousepressed(button)
  self.mouseDown = true;
end

function root:updateSelf(dt)
  
  local didSet = false;
  
  for ctype in pairs(self.cursorReqs or {}) do
    local c = love.mouse.getSystemCursor( ctype );
    love.mouse.setCursor(c);
    didSet = true;
  end
  
  if (not didSet) then
    love.mouse.setCursor();
  end
  
  self.cursorReqs = {};
end

function root:postupdateSelf(dt)
  self.mouseDown = false;
end

function root:requestCursor(ctype)
  self.cursorReqs[ctype] = 1;
end

function root:unfocus()
  self.activeTextBox = nil;
end

function Button:isHover(mx, my)
  local x, y, w, h = self:getGlobalBounds();

  return mx > x and mx < (x + w)
      and my > y and my < (y + h);
end

local TextBox = Button:new()

function TextBox:handleTextinput(text)
  self.text = self.text..text;
end

function TextBox:handleKeypress(key)
  if (key == "backspace") then
    self.text = string.sub(self.text, 1, -2);
  end
end

function TextBox:drawSelf()
  UIElement.drawSelf(self);
    local x, y, w, h = self:getGlobalBounds();

  if (self.placeholder) then
    love.graphics.setColor(self.placeholderColor);
    love.graphics.print(self.placeholder, x + self.textIndent, y + 2, 0, 1, 1);
  end
end

function TextBox:getText()
  return self.text;
end

function TextBox:init()
  Button.init(self);
  self.active = false;
  self.text = self.text or "";
  self.placeholderColor = self.placeholderColor or {0.5, 0.5, 0.5, 0.5};
  
  --self.backgroundColor = self.backgroundColor or {
  function self:onClick()
     self.active = true;
     self.placeholder = nil;
     root.activeTextBox = self;
  end
  
end

function TextBox:updateSelf(dt)
  Button.updateSelf(self, dt);
  
  if (self.isHover) then
    root:requestCursor("ibeam");
  end
end

return {

    root = root,
    Box = UIElement,
    Button = Button,
    TextBox = TextBox
}