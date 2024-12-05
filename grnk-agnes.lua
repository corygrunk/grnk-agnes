-- GRNK Agnes
-- Play notes on a the grid

g = grid.connect() -- if no argument is provided, defaults to port 1

mxsamples=include("mx.samples/lib/mx.samples")
engine.name = 'MxSamples'
skeys=mxsamples:new()
mxsamples_soundsrc = 'music box' -- IT WOULD BE NICE TO NOT HARD CODE THIS

MusicUtil = require('musicutil')
TAB = require('tabutil')

scale_names = {}

engines = {}
engines[1] = 'engine'
engines[2] = 'crow 1+2'
engines[3] = 'crow 3+4'
engines[4] = 'jf'
engine_counter = 1

amp_amt = 0.5

jitter_amt = 1

notes = {} -- this is the table that holds the scales' notes
note_name = 60

eng_cut = 1200
note_attack = 0.01
note_decay = 1

function init()

  crow.output[2].action = "ar(dyn{ attack = 0.001 }, dyn{ decay = 0.1 }, 10, 'logarithmic')" -- linear sine logarithmic exponential
  crow.output[4].action = "ar(dyn{ attack = 0.001 }, dyn{ decay = 0.1 }, 10, 'logarithmic')" -- linear sine logarithmic exponential

  for i = 1, #MusicUtil.SCALES do
    table.insert(scale_names, MusicUtil.SCALES[i].name)
  end

  params:add_separator("AGNES")
  
  -- setting root notes using params
  params:add{type = "number", id = "root_note", name = "root note",
    min = 0, max = 127, default = 24, formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
    action = function() build_scale() end} -- by employing build_scale() here, we update the scale

  -- setting scale type using params
  params:add{type = "option", id = "scale", name = "scale",
    options = scale_names, default = 1,
    action = function() build_scale() end} -- by employing build_scale() here, we update the scale

  build_scale() -- builds initial scale

  grid_connected = g.device ~= nil and true or false -- ternary operator, eg. http://lua-users.org/wiki/TernaryOperator
  led_intensity = 15 -- scales LED intensity

  note_name = params:get("root_note")

  redraw_clock_id = clock.run(redraw_clock)

  grid_dirty = true -- use flags to keep track of whether hardware needs to be redrawn
  
  screen_dirty = true
end

function build_scale()
  notes = MusicUtil.generate_scale(params:get("root_note"), params:get("scale"), 6)
  for i = 1, 64 do
    table.insert(notes, notes[i])
  end
end

function redraw_clock()
  while true do
    clock.sleep(1/15)
    -- if screen_dirty then
      redraw()
      screen_dirty = false
    -- end
    if grid_dirty then
      grid_redraw()
    end
  end
end

function live_pad(note,z_state)
  if z_state == 1 then -- note pressed
    play_note(engines[1],note,note_attack,note_decay) -- play the note
    jitter_amt = math.random(8,10)
  elseif z_state == 0 then -- note released
    stop_note(engines[1],note) -- stop the note
    jitter_amt = 1
  end
end

function stop_note(source,midi_note_num)
  if type(midi_note_num) ~= 'table' then
    local container = midi_note_num
    midi_note_num = {}
    midi_note_num[1] = container
  end
  if source == "engine" then
    for i = 1, TAB.count(midi_note_num) do
      skeys:off({name=mxsamples_soundsrc,midi=midi_note_num[i]})
    end
  end
end

function play_note(source,midi_note_num,note_att,note_dec)
  if type(midi_note_num) ~= 'table' then
    local container = midi_note_num
    midi_note_num = {}
    midi_note_num[1] = container
  end
  if source == "engine" then
    for i = 1, TAB.count(midi_note_num) do
      skeys:on({name=mxsamples_soundsrc,midi=midi_note_num[i],velocity=120,amp=amp_amt})
      -- LEAVING THIS BELOW FOR REFERENCE
      -- engine.cutoff(eng_cut)
      -- engine.release(note_dec)
      -- engine.hz(MusicUtil.note_num_to_freq(midi_note_num[i]))
    end
  elseif source == "crow 1+2" then
    crow.output[1].volts = (midi_note_num[1] - 60)/12
    crow.output[2].dyn.attack = note_att
    crow.output[2].dyn.decay = note_dec
    crow.output[2]()
  elseif source == "crow 3+4" then
    crow.output[3].volts = (midi_note_num[1] - 60)/12
    crow.output[4].dyn.attack = note_att
    crow.output[4].dyn.decay = note_dec
    crow.output[4]()
  elseif source == "jf" then
    for i = 1, TAB.count(midi_note_num) do
      crow.ii.jf.play_note((midi_note_num[i] - 60)/12, 4)
    end
  end
  note_name = midi_note_num[1]
  screen_dirty = true
end



function grid_redraw()
  if grid_connected then -- only redraw if there's a grid connected
    g:all(0) -- turn all the LEDs off

    -- light up live pads
    for x = 9,16 do
      for y = 1,8 do
        g:led(x,y,3)
        -- manually lighting roots
        g:led(9,1,6)
        g:led(16,1,6)
        g:led(12,2,6)
        g:led(15,3,6)
        g:led(11,4,6)
        g:led(14,5,6)
        g:led(10,6,6)
        g:led(13,7,6)
        g:led(9,8,6)
        g:led(16,8,6)
      end
    end

    g:intensity(led_intensity) -- change intensity
    g:refresh() -- refresh the LEDs
  end
  grid_dirty = false -- reset the flag because changes have been committed
end

function g.key(x,y,z)
  -- live play buttons
  for i = 1, 8 do
    if z == 1 then
      if y == 8 then if x == i + 8 then live_pad(notes[i + 7], z) end end
      if y == 7 then if x == i + 8 then live_pad(notes[i + 10], z) end end
      if y == 6 then if x == i + 8 then live_pad(notes[i + 13], z) end end
      if y == 5 then if x == i + 8 then live_pad(notes[i + 16], z) end end
      if y == 4 then if x == i + 8 then live_pad(notes[i + 19], z) end end
      if y == 3 then if x == i + 8 then live_pad(notes[i + 22], z) end end
      if y == 2 then if x == i + 8 then live_pad(notes[i + 25], z) end end
      if y == 1 then if x == i + 8 then live_pad(notes[i + 28], z) end end
    else
      if y == 8 then if x == i + 8 then live_pad(notes[i + 7], z) end end
      if y == 7 then if x == i + 8 then live_pad(notes[i + 10], z) end end
      if y == 6 then if x == i + 8 then live_pad(notes[i + 13], z) end end
      if y == 5 then if x == i + 8 then live_pad(notes[i + 16], z) end end
      if y == 4 then if x == i + 8 then live_pad(notes[i + 19], z) end end
      if y == 3 then if x == i + 8 then live_pad(notes[i + 22], z) end end
      if y == 2 then if x == i + 8 then live_pad(notes[i + 25], z) end end
      if y == 1 then if x == i + 8 then live_pad(notes[i + 28], z) end end
    end
  end
end


function redraw()
  screen.clear() -- clear screen
  screen.level(15)
  screen.move(0,10)
  screen.text('AGNES')
  screen.move(0,50)
  screen.text(scale_names[params:get("scale")])
  screen.move(0,60)
  screen.text('note: ' .. MusicUtil.note_num_to_name(note_name) .. ' (' .. note_name .. ')')
  
  screen.level(jitter_amt)
  screen.fill('#f0f0f005')
  screen.circle(math.random(60,60+jitter_amt), math.random(30,30+jitter_amt), 2+jitter_amt)
  screen.update()
  screen_dirty = false
end

alt_func = false

function key(n,z)
  if z == 1 and n == 1 then
    alt_func = true
    print('key1')
  else 
    alt_func = false
  end
  if z == 1 and n == 2 then
    print('key2')
    redraw()
  end
  if z == 1 and n == 3 then
    print('key3')
    redraw()
  end
end

function enc(n,d)
  if n == 1 then
    print('enc1')
    redraw()
  end
  if n == 2 then
    print('enc2')
    redraw()    
  elseif n == 3 then
    print('enc3')
    redraw()      
  end
end





function grid.add(new_grid) -- must be grid.add, not g.add (this is a function of the grid class)
  print(new_grid.name.." says 'hello!'")
   -- each grid added can be queried for device information:
  print("new grid found at port: "..new_grid.port)
  g = grid.connect(new_grid.port) -- connect script to the new grid
  grid_connected = true -- a grid has been connected!
  grid_dirty = true -- enable flag to redraw grid, because data has changed
end

function grid.remove(g) -- must be grid.remove, not g.remove (this is a function of the grid class)
  print(g.name.." says 'goodbye!'")
end




-- UTILITY TO RESTART SCRIPT FROM MAIDEN
function r()
  norns.script.load(norns.state.script)
end
