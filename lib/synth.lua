Synth = {}

local samplerate = 44100;
local bitdepth = 16;
local channels = 1;

function sinWave(sample, tone, offset)
  return  math.sin((sample * tone + offset) * 2 * math.pi);
end

function Synth:new(properties) 
  
  local o = {};
  
  o.source = love.audio.newQueueableSource( samplerate , bitdepth, channels );
  
  
  o.soundData = love.sound.newSoundData( samplerate * 10, samplerate, bitdepth, channels );
  
  local tone = properties.frequency / samplerate;
  o.maxVolume = 0.2;
  o.volume = 0.0;
  
  for i = 1, samplerate * 10 do 
    local sample = 0.6 * sinWave(i, tone, 0) + (0.3 * sinWave(i, tone, 0.23)) + (0.1 * sinWave(i, tone, 0.45));
    o.soundData:setSample(i-1, sample);
  end
  
  o.source:setVolume(o.volume);
  
  self.__index = self;
  setmetatable(o, self);
  return o;

end

local rampTime = 0.05;
local decayTime = 0.1;

function Synth:update(dt)

--[[
  local now = love.timer.getTime() - self.playTime;
  
  if (now < rampTime) then
    self.source:setVolume(self.maxVolume * (now / rampTime));
  end
  ]]
  
  --[[
  if (self.fadeTime) then
    self.volume = self.volume / 1.1;
    if (self.volume < 0.001) then
      self.volume = 0;
    end
  elseif (self.playTime) then
    local newVol = math.max(self.volume * 2, 0.001); 
    self.volume = math.min(self.maxVolume, newVol); 
    --self.volume = math.min(self.maxVolume, self.volume + (self.maxVolume / 10)); 
  end
  ]]
  
  if (self.playTime) then
    local now = love.timer.getTime() - self.playTime;
    
    if (now < rampTime) then
      self.volume = self.maxVolume * (now / rampTime);
    elseif (now < decayTime) then
      self.volume = self.maxVolume - ((now-rampTime) / decayTime) * 0.6;
    else
      self.volume = self.maxVolume * 0.4;
    end  
  
  elseif (self.fadeTime) then
    
    self.volume = math.max(0, self.volume - dt * 0.5);
    
  end
  
  
  self.source:setVolume(self.volume);
end

function Synth:fadeOut()
  self.fadeTime = love.timer.getTime();
  self.playTime = nil;
end

function Synth:play()
  self.fadeTime = nil;
  self.playTime = love.timer.getTime();
  
  local success = self.source:queue(self.soundData);
  self.source:play();
  self.source:setVolume(self.volume);
end


return Synth;
