--castle://localhost:4000/melodo.castle

local client = love;
local List = require("lib/list");
local Sound = require("lib/sound");
local Synth = require("lib/synth");
local UI = require("lib/ui");

local GamePlayer = {};
local gameState = {};
local audioState = {};
local assets = {};
local uiState = {};

local GameMode = {
  PLAYBACK = 0,
  RECORD = 1,
  FREEPLAY = 2,
  LISTEN = 3
}

local PITCH_NOTES = {60, 62, 64, 65, 67, 69, 71, 72};
local PITCH_FREQS = {440, 493.883, 554.365, 587.330, 659.255, 739.989, 830.609, 880};
local NUM_NOTES = #PITCH_NOTES;
local PITCH_KEYS = {"a", "s", "d", "f", "j", "k", "l", ";"};
local KEY_PITCHES = {};
local Y_SCALE = 100
  
local gfx = {
  ox = 100,
  oy = 0,
  lineY = 300,
  keyX = 18,
  keySpace = 50
}
  
for i, key in pairs(PITCH_KEYS) do
  KEY_PITCHES[key] = i;
end


local lo = 0.5;
local hi = 1.0;

local PITCH_COLORS = {{1,1,1,1}, {1,1,lo,1}, {lo,1,1,1}, {1,lo,1,1}, {lo,lo,1,1}, {lo,1,lo,1}, {1, lo , lo,1}, {lo,lo,lo,1}};


function setupAudio()
  
  assets.audio = {};
  
  for i,mid in pairs(PITCH_NOTES) do
    
    --assets.audio["note"..mid] = Sound:new("audio/pluck"..mid..".ogg", 10);
    assets.audio["note"..mid] = Synth:new({
      frequency = PITCH_FREQS[i]
    });
    
  end
end

function updateSounds()
  for i,mid in pairs(PITCH_NOTES) do
    assets.audio["note"..mid]:update();
  end
end

function createFreeplayUI()
  UI.root:clear();
  
  local buttonBox = UI.Box:new({
    x = gfx.ox,
    y = gfx.oy + gfx.lineY + 60
  });
  
  local record = UI.Button:new({
    text = "Record",
    x = 100,
    y = 0,
    width = 60,
    onClick = function(b)
      recordSong();
    end
  });
  
  buttonBox:addElement(record);
  UI.root:addElement(buttonBox);
end

function createRecordingUI()
  UI.root:clear();
  
  local buttonBox = UI.Box:new({
    x = gfx.ox,
    y = gfx.oy + gfx.lineY + 60
  });
  
  local finish = UI.Button:new({
    text = "Submit",
    x = 0,
    y = 0,
    width = 60,

    onClick = function(b)
      finishRecording();
    end
  });
 
  local restart = UI.Button:new({
    text = "Restart",
    x = 100,
    y = 0,
    width = 60,
    onClick = function(b)
      recordSong();
    end
  });
  
  local freeplay = UI.Button:new({
    text = "Freeplay",
    x = 200,
    y = 0,
    width = 60,
    onClick = function(b)
      freeplaySong();
    end
  });
  
  buttonBox:addElement(finish);
  buttonBox:addElement(restart);
  buttonBox:addElement(freeplay);
  
  UI.root:addElement(buttonBox);
end

function createPlaybackUI()
  UI.root:clear();
  
  local buttonBox = UI.Box:new({
    x = gfx.ox,
    y = gfx.oy + gfx.lineY + 60
  });
  
  local listen = UI.Button:new({
    text = "Listen",
    x = 0,
    y = 0,
    width = 60
  });
  
   local restart = UI.Button:new({
    text = "Retry",
    x = 100,
    y = 0,
    width = 60,
    onClick = function(b)
      replaySong();
    end
  });
  
   local record = UI.Button:new({
    text = "Record New Song",
    x = 200,
    y = 0,
    width = 100,
    onClick = function(b)
      recordSong();
    end
  });
  
  buttonBox:addElement(listen);
  buttonBox:addElement(restart);
  buttonBox:addElement(record);
  
  UI.root:addElement(buttonBox);

end

function resetState()
  gameState.songTime = 0.0;
  gameState.headStartDuration = 4.0;
  gameState.wiggleRoom = 0.2;
  gameState.firstDrawIndex = 1;
  gameState.lastDrawIndex = 0;
  gameState.score = 0;
  gameState.inputs = {};
  gameState.hotNotes = {};
  audioState.pitchesPlaying = {};
  gameState.liveNotes = {};
  gameState.errors = {};
end

function loadSong(notes)
  resetState();
  
  gameState.mode = GameMode.PLAYBACK;
  gameState.notes = notes;
  
  List.each(notes, function(note)
    note.wasActive = false;
  end);

  createPlaybackUI();
end

function replaySong()
  loadSong(gameState.notes);
end

function freeplaySong()
  resetState();
  
  gameState.mode = GameMode.FREEPLAY;
  
  createFreeplayUI();
end

function recordSong()
  resetState();
  gameState.notes = List.new(1);
  gameState.mode = GameMode.RECORD;
  
  createRecordingUI();
end

function postSong(notes, title)

  network.async(function()
      castle.post.create {
          message = title,
          media = 'capture',
          data = {
              notes = gameState.notes,
          }
      }
  end)
end

function displaySubmitPrompt()
  
  local prompt = UI.Box:new({
    x = gfx.ox + 100,
    y = gfx.oy + 100,
    id = "prompt",
    width = 220,
    height = 80,
    backgroundColor = {0.3, 0.3, 0.3, 1.0}
  });
  
  local input = UI.TextBox:new({
    x = 10,
    y = 20,
    width = 200,
    placeholder = "Untitled",
    placeholderColor = {0.2, 0.2, 0.2, 0.5},
    backgroundColor = {0.8, 0.8, 0.8, 1.0},
    color = {0, 0, 0, 1}
  });
  
  local post = UI.Button:new({
    x = 20,
    y = 50,
    text = "Post!",
    onClick = function()
      local title = input.text;
      if (not title or #title == 0) then
        title = "Untitled"
      end
    
      postSong(gameState.notes, title);
      UI.root:removeElement(prompt);
      UI.root:unfocus();
    end
  });
  
  local cancel = UI.Button:new({
    x = 140,
    y = 50,
    text = "Cancel",
    onClick = function()
      UI.root:removeElement(prompt);
      UI.root:unfocus();
    end
  });
  
  UI.root:addElement(prompt);
  prompt:addElement(input);
  prompt:addElement(post);
  prompt:addElement(cancel);
  
end

function finishRecording()
    --loadSong(gameState.notes);
    displaySubmitPrompt();
end


local FromPost = false;
function client.load()
  setupAudio();
  
  if (not FromPost) then
    freeplaySong();
  end
end

function castle.postopened(post)
  
  FromPost = true;
  loadSong(post.data.notes);
  
end

function GamePlayer.update(gameState, dt)
  
  if (gameState.mode == GameMode.PLAYBACK) then
    GamePlayer.updatePlayback(gameState, dt);
  elseif (gameState.mode == GameMode.RECORD) then
    GamePlayer.updateRecording(gameState, dt);
  elseif (gameState.mode == GameMode.FREEPLAY) then
    --GamePlayer.updateFreeplay(gameState, dt);
  end
  
  for pitch, info in pairs(gameState.inputs) do    
    if (info.state == 1) then
      if (audioState.pitchesPlaying[pitch] == nil) then
        audioState.pitchesPlaying[pitch] = 1;
        assets.audio["note"..PITCH_NOTES[pitch]]:play();
      end
    end
    
    if (info.state == 0) then
    
      if audioState.pitchesPlaying[pitch] == 1 then
         assets.audio["note"..PITCH_NOTES[pitch]]:fadeOut();
      end
    
      audioState.pitchesPlaying[pitch] = nil;
    end  
  end
end

function GamePlayer.updateRecording(gameState, dt)

  gameState.songTime = gameState.songTime + dt;
  for pitch, info in pairs(gameState.inputs) do
    
    if (info.state == 1) then
      if (gameState.liveNotes[pitch]) then
    
        gameState.liveNotes[pitch].endTime = gameState.songTime
    
      else
      
        List.pushright(gameState.notes, {
          startTime = gameState.songTime,
          endTime = gameState.songTime,
          pitch = pitch
        });
        
        gameState.liveNotes[pitch] = gameState.notes[gameState.notes.last];
        
        gameState.lastDrawIndex = gameState.notes.last;
      end
    else -- key up
    
      gameState.liveNotes[pitch] = nil;
    
    end
  end
  
  local firstNote = gameState.notes[gameState.firstDrawIndex];
  
  while(firstNote and firstNote.endTime > gameState.songTime + gameState.headStartDuration) do
    gameState.firstDrawIndex = gameState.firstDrawIndex + 1;
    firstNote = gameState.notes[gameState.firstDrawIndex];
  end
  
end

function GamePlayer.updatePlayback(gameState, dt)
  
  gameState.songTime = gameState.songTime + dt;
  local wig = gameState.wiggleRoom;

  --Update which notes are displayed
  local nextNote = gameState.notes[gameState.lastDrawIndex + 1];
  
  while(nextNote and nextNote.startTime <= gameState.songTime + gameState.headStartDuration) do
    gameState.lastDrawIndex = gameState.lastDrawIndex + 1;
    nextNote = gameState.notes[gameState.lastDrawIndex + 1];
  end
  
  local firstNote = gameState.notes[gameState.firstDrawIndex];
  
  while(firstNote and firstNote.endTime + wig < gameState.songTime) do
    gameState.firstDrawIndex = gameState.firstDrawIndex + 1;
    firstNote = gameState.notes[gameState.firstDrawIndex];
  end
  
  -- Update score based on song and inputs
  gameState.hotNotes = {};
  local songT = gameState.songTime;
  
  for noteIndex = gameState.firstDrawIndex, gameState.lastDrawIndex do
 
    local note = gameState.notes[noteIndex];
    --note.isActive = false;

    local key = PITCH_KEYS[note.pitch];
    
    if ((note.startTime - wig) <= songT  and (note.endTime + wig) >= songT) then
      gameState.hotNotes[note.pitch] = note;
      --print(note.endTime + wig, songT);
    end
    
  end
  
  gameState.errors = {};
  
  for pitch, info in pairs(gameState.inputs) do
    local hotNote = gameState.hotNotes[pitch];
    local superHot = false;
    
    if (hotNote) then
      superHot = hotNote.startTime <= songT and hotNote.endTime >= songT;
    end
  
    if ((info.state == 1 and not hotNote) or (info.state == 0 and superHot)) then
      gameState.score = gameState.score - dt;
      gameState.errors[pitch] = 1;
    elseif (info.state == 1 and hotNote) then
      hotNote.wasActive = true;
      gameState.score = gameState.score + dt;
    end     
  end
  
end

function drawNote(note, now, gfx)
  
  love.graphics.setColor(PITCH_COLORS[note.pitch]);
  
  if (note.wasActive) then
    love.graphics.setColor(1,1,1,1);
  end
  
  local h = note.endTime - note.startTime;
  local w = 10;
  local x = gfx.ox + gfx.keyX + note.pitch * gfx.keySpace;
  if note.pitch > 4 then
    x = x + 20
  end 
  local y = gfx.oy + (now - note.startTime) - h;
  
  if (gameState.mode == GameMode.RECORD) then
    y = (note.startTime - now);
  end
  
  --print(x, y, w, h, note.pitch);
  
  love.graphics.rectangle("fill", x, gfx.lineY + y * 100, w, h * 100);
end

function drawKeys(gfx)

--Horizontal bar
  love.graphics.setColor(1,1,1,1);
  love.graphics.rectangle("fill", gfx.ox, gfx.oy + gfx.lineY, 520, 3);
  
  
  for pitch = 1,NUM_NOTES do
    love.graphics.setColor(PITCH_COLORS[pitch]);
    local x = gfx.ox + gfx.keyX + pitch * gfx.keySpace;
   
   if pitch > 4 then
      x = x + 20
    end 
     
    local y = gfx.oy + gfx.lineY + 10;
    local size = 10;
    
    love.graphics.rectangle("fill", x, y, size, size);
    love.graphics.print( PITCH_KEYS[pitch], x, y + size, 0, 1, 1);

    local key = PITCH_KEYS[pitch];
    local input = gameState.inputs[pitch];
    
    if (input and input.state == 1) then
      love.graphics.setColor(1,1,1,1);
      love.graphics.rectangle("line", x, y, size, size);
      
      if (gameState.errors[pitch]) then
        love.graphics.setColor(1,0,0,1);
        love.graphics.circle("fill", x, y, size, size);
      end
    end
  end

end

--https://gist.github.com/jesseadams/791673
function SecondsToClock(seconds)
  local seconds = tonumber(seconds)

  if seconds <= 0 then
    return "00:00:00";
  else
    hours = string.format("%02.f", math.floor(seconds/3600));
    mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
    secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
    return hours..":"..mins..":"..secs
  end
end

function drawUI(gfx)
  
  local y = gfx.oy + gfx.lineY + 60;
  local x = gfx.ox;
  
  local st = gameState.songTime;
  
  --local displayTime = math.floor(gameState.songTime * 100) / 100.0;
  --local seconds = math.floor(gameState.songTime);
  --local minutes = math.floor(st / 60);
  --local seconds = math.floor(st - minutes * 60);
  
  local displayTime = SecondsToClock(gameState.songTime);
  
  love.graphics.setColor(1,1,1,1);
  
  if (gameState.mode == GameMode.RECORD) then
    --love.graphics.print(displayTime.."  Recording. Press SPACE to finish", x, y); 
  else
    --love.graphics.print(displayTime.."  Score: "..gameState.score, x, y);
  end
  
  
end

function drawNotes(gfx)
  if (gameState.firstDrawIndex < 1) then return end;
  local now = gameState.songTime;

  love.graphics.setScissor(gfx.ox, gfx.oy, 520, gfx.lineY);
    
  for noteIndex = gameState.firstDrawIndex, gameState.lastDrawIndex do
  
    local note = gameState.notes[noteIndex];    
    if note then drawNote(note, now, gfx) end;
    
  end
  
  love.graphics.setScissor();
    
end

function GamePlayer.draw(gameState)
  
  drawKeys(gfx);
  drawUI(gfx);
  drawNotes(gfx);
 
end


function client.mousepressed()
  UI.root:handleMousepressed();
end

function client.textinput(text)
  if (UI.root:handleTextinput(text)) then
    return
  end
end

function client.keypressed(key)

  if (UI.root:handleKeypressed(key)) then
    return
  end

  if (key == "space" and gameState.mode == GameMode.RECORD) then
    finishRecording();    
  end

  local pitch = KEY_PITCHES[key];
  if not pitch then return end;
  
  gameState.inputs[pitch] = {
    state = 1,
    time = gameState.songTime
  };
end

function client.keyreleased(key)
  local pitch = KEY_PITCHES[key];

  if not pitch then return end;
  
  gameState.inputs[pitch] = {
    state = 0,
    time = gameState.songTime
  }
end

function client.draw()
  GamePlayer.draw(gameState);
  UI.root:draw();
end

function client.update(dt)
  
  GamePlayer.update(gameState, dt);
  updateSounds();
  UI.root:update(dt);
  
end

