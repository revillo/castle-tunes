Synth = {}

local samplerate = 44100;
local bitdepth = 16;
local channels = 1;


function Synth:new(properties) 
  
  local o = {};
  
  o.source = love.audio.newQueueableSource( samplerate , bitdepth, channels );
  
  
  o.soundData = love.sound.newSoundData( samplerate * 10, samplerate, bitdepth, channels );
  
  local samplesPerWave = samplerate / properties.frequency;
  o.maxVolume = 0.2;
  o.volume = 0.0;
  
  for i = 1, samplerate * 10 do 
    local sample = math.sin((i/samplesPerWave) * 2 * math.pi);
    o.soundData:setSample(i-1, sample);
  end
  
  o.source:setVolume(o.volume);
  
  self.__index = self;
  setmetatable(o, self);
  return o;

end

local rampTime = 0.1;

function Synth:update()

--[[
  local now = love.timer.getTime() - self.playTime;
  
  if (now < rampTime) then
    self.source:setVolume(self.maxVolume * (now / rampTime));
  end
  ]]
  
  if (self.fadeTime) then
    self.volume = math.max(0.001, self.volume / 1.1);
  elseif (self.playTime) then
    local newVol = math.max(self.volume * 2, 0.001); 
    self.volume = math.min(self.maxVolume, newVol); 
    --self.volume = math.min(self.maxVolume, self.volume + (self.maxVolume / 10)); 
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
