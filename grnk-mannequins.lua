-- GRNK Mannequins
-- norns powered mannequins system

engine.name = 'Autumn'
hs = include('lib/halfsecond')

Tab = require('tabutil')
MusicUtil = require('musicutil')

s = require 'sequins'

notes = s{50,52,70,60,63}
current_note_name = '_'

local playing = true
local step = 1
local prob = 100
local cutoff = 1500
local pw = 0.5
local attack = 0.01
local decay = 0.3
local randomized = false
local alt_mode = false

function init()
  engine.pw(pw)
  engine.attack(attack)
  engine.release(decay)
  
  crow.output[2].action = "ar(dyn{att = 0.01},dyn{dec = 0.3})"
 
  hs.init()

  clock.run(redraw_clock)
  clock.run(clk)
  screen_dirty = true
end

function clk()
  while true do
    clock.sync(1/2)
    if playing then
      if math.random(0,99) < prob then
        local note = notes()
        current_note_name = MusicUtil.note_num_to_name(note,true)
        if randomized then randomize() end
        crow.output[2].dyn.att = attack
        crow.output[2].dyn.dec = decay
        crow.output[1].volts = (note-60)/12
        crow.output[2]()
        -- engine.cutoff(cutoff)
        -- engine.attack(attack)
        -- engine.release(decay)
        -- engine.hz(MusicUtil.note_num_to_freq(note))
        screen_dirty = true
      end
    end
  end
end

function randomize()
  step = math.random(-5,5)
  prob = 20
  cutoff = math.random(500,2000)
  attack = math.random(5,10)*0.1
  decay = math.random(1,5)*0.01
  engine.pw(math.random(3,7)*0.1)
  randomized = true
  screen_dirty = true
end

function unrandomize()
  prob = 100
  cutoff = 1500
  attack = 0.01
  decay = 0.3
  engine.pw(0.5)
  randomized = false
  screen_dirty = true
end


function key(n,z)
  if n == 1 and z == 1 then
    alt_mode = true
  elseif n == 1 and z == 0 then
    alt_mode = false
  elseif n == 2 and z == 1 then
    -- print('Key 2')
    if randomized then unrandomize() else randomize() end
  elseif n == 3 and z == 1 then
    --print('Key 3')
    if playing then
      playing = false
    else
      playing = true
    end
  end
  screen_dirty = true
end


function enc(n,d)
  if n == 1 then
    step = util.clamp(step + d,-5,5) -- FIX top limit is the max number of notes in the notes variable
    notes:step(step)
  elseif n == 2 and alt_mode == false then
    prob = util.clamp(prob + d,0,100)
  elseif n == 2 and alt_mode == true then
    attack = util.clamp(attack + d*0.01,0.01,5)

  elseif n == 3 and alt_mode == false then
    cutoff = util.clamp(cutoff + d*10,0,5000)
  elseif n == 3 and alt_mode == true then
    decay = util.clamp(decay + d*0.01,0.01,5)
  end
  screen_dirty = true
end


function redraw()
  if playing then
    play_text = 'playing'
  else
    play_text = 'stopped'
  end
  screen.clear() --------------- clear space
  screen.aa(1) ----------------- enable anti-aliasing
  screen.font_face(1) ---------- set the font face to "04B_03"
  screen.font_size(8) ---------- set the size to 8
  screen.level(6) --------------
  screen.move(127, 60)
  screen.text_right(play_text)
  screen.level(15) ------------- max
  if alt_mode == false then
    screen.move(0, 23)
    if randomized then
      screen.text('randomized')
    else
      screen.text('probability: ' .. prob)
    end
    screen.move(0, 35)
    screen.text('cutoff: ' .. cutoff)
  else
    screen.move(0, 23)
    screen.text('attack: ' .. attack)
    screen.move(0, 35)
    screen.text('decay: ' .. decay)
  end

  screen.move(0, 60) ---------- move the pointer to x = 64, y = 32
  screen.text('step: ' .. step) -- center our message at (64, 32)
  screen.move(75, 40)
  screen.font_size(24)
  screen.text(current_note_name)

  screen.fill() ---------------- fill the termini and message at once
  screen.update() -------------- update space

  screen_dirty = false
end


function redraw_clock()
  while true do
    clock.sleep(1/15)
    if screen_dirty then
      redraw()
      screen_dirty = false
    end
  end
end



-- UTILITY TO RESTART SCRIPT FROM MAIDEN
function r()
  norns.script.load(norns.state.script)
end
