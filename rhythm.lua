--castle://localhost:4000/rhythm.lua

local client = love;
local List = require("lib/list");

local GamePlayer = {};
local gameState = {};

function client.load()
  
  gameState.notes = List.new();
 
  for i = 1,50  do
    
    local offset = i + math.random();
    
    List.pushright(gameState.notes, {
      startTime = offset,
      endTime = offset + (0.25),
      pitch = math.random(1,3)
    });
      
  end

  gameState.songTime = 0.0;
  gameState.headStartDuration = 4.0;
  
  gameState.firstDrawIndex = 1;
  gameState.lastDrawIndex = 0;
  gameState.score = 0;
  gameState.inputs = {};
  gameState.hotPitches = {};
  
end

local PITCH_KEYS = {"a", "s", "d"};
local KEY_PITCHES = {};

for i, key in pairs(PITCH_KEYS) do
  KEY_PITCHES[key] = i;
end

local PITCH_COLORS = {{1,0,0,1}, {0.2,0.8,0.2,1}, {0,0,1,1}}

function GamePlayer.update(gameState, dt)
  
  gameState.songTime = gameState.songTime + dt;
  
  local nextNote = gameState.notes[gameState.lastDrawIndex + 1];
  
  while(nextNote and nextNote.startTime <= gameState.songTime + gameState.headStartDuration) do
    gameState.lastDrawIndex = gameState.lastDrawIndex + 1;
    nextNote = gameState.notes[gameState.lastDrawIndex + 1];
  end
  
  local firstNote = gameState.notes[gameState.firstDrawIndex];
  
  while(firstNote and firstNote.endTime < gameState.songTime) do
    gameState.firstDrawIndex = gameState.firstDrawIndex + 1;
    firstNote = gameState.notes[gameState.firstDrawIndex];
  end
  
  gameState.hotPitches = {};
  
  for noteIndex = gameState.firstDrawIndex, gameState.lastDrawIndex do
 
    local note = gameState.notes[noteIndex];
    note.isActive = false;

    local key = PITCH_KEYS[note.pitch];

    if (note.startTime <= gameState.songTime and note.endTime >= gameState.songTime) then
      if love.keyboard.isDown(key) then
        gameState.score = gameState.score + dt;      
        note.isActive = true;
        note.wasActive = true;
      end
      
      gameState.hotPitches[note.pitch] = 1;
    end
    
  end
  
  gameState.errors = {};
  
  for pitch, info in pairs(gameState.inputs) do
    if (info.state == 1 and not gameState.hotPitches[pitch]) then
      gameState.score = gameState.score - dt;
      gameState.errors[pitch] = 1;
    end
  end
  
end

local Y_SCALE = 100
local Y_BOTTOM = 550;

function drawNote(note, now)
  
  love.graphics.setColor(PITCH_COLORS[note.pitch]);
  
  if (note.isActive) then
    love.graphics.setColor(1,1,1,1);
  end
  
  local h = note.endTime - note.startTime;
  local w = 10;
  local x = 10 + note.pitch * 50;
  local y = (now - note.startTime) - h;
  
  love.graphics.rectangle("fill", x, Y_BOTTOM + y * 100, w, h * 100);
  
end

function GamePlayer.draw(gameState)
  
  local now = gameState.songTime;
  
  love.graphics.setColor(1,1,1,1);
  love.graphics.rectangle("fill", 0, Y_BOTTOM, 200, 3);
  
  
  for pitch = 1,3 do
    love.graphics.setColor(PITCH_COLORS[pitch]);
    love.graphics.rectangle("fill", 10 + pitch * 50, Y_BOTTOM + 10, 10, 10);
    
    local key = PITCH_KEYS[pitch];
    
    if (love.keyboard.isDown(key)) then
      love.graphics.setColor(1,1,1,1);
      love.graphics.rectangle("line", 10 + pitch * 50, Y_BOTTOM + 10, 10, 10);
      
      if (gameState.errors[pitch]) then
        love.graphics.circle("fill", 10 + pitch * 50 + 5, Y_BOTTOM + 10, 10, 10);
      end
    end
  end
  
  if (gameState.firstDrawIndex < 1) then return end;
  
  for noteIndex = gameState.firstDrawIndex, gameState.lastDrawIndex do
  
    love.graphics.setScissor(0, 0, 200, Y_BOTTOM);
    local note = gameState.notes[noteIndex];
    love.graphics.setScissor();
    
    drawNote(note, now);
  end

end

function client.keypressed(key)

  local pitch = KEY_PITCHES[key];
  
  gameState.inputs[pitch] = {
    state = 1,
    time = gameState.songTime
  };
end

function client.keyreleased(key)
  local pitch = KEY_PITCHES[key];

  gameState.inputs[pitch] = {
    state = 0,
    time = gameState.songTime
  }
end

function client.draw()
  GamePlayer.draw(gameState);
end

function client.update(dt)
  
  GamePlayer.update(gameState, dt);

end

