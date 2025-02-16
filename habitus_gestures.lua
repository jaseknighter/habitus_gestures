-- habitus gestures
-- 1.0 @dani_derks, @leshy, @infinitedigits, @jaseknighter
-- l.llllllll.co/<insert link to lines thread>
--
--
-- E1 
-- E2 
-- E3 
--
-- K2 
-- K3 

-- lines starting with "--" are comments, they don't get executed

-- find the --[[ 0_0 ]]-- for good places to edit!

-- https://monome.org/docs/norns/reference/lib/reflection
reflection = require 'reflection' -- a gesture library built into norns

-- alt_key variable to track when K1 is held down
alt_key = false

-- etch-a-sketch table
e_s = {}
e_s.cursor = {}
e_s.cursor.x_loc_default = 64
e_s.cursor.y_loc_default = 32
e_s.cursor.x_loc = 64
e_s.cursor.y_loc = 32

e_s.drawing = {}
e_s.drawing.coords = {}
e_s.drawing.prev_sketch_start = 1
e_s.drawing.history = {}


--------------------------------------------------------------------------------
-- init runs first!
function init()
  -- create an instance of reflection
  reflect = reflection.new()
  reflect:set_loop(1)
  reflect.process = function (event)
    --do something with the event
    print("playing: event: ",print(event[1]))
  end
  reflect.start_callback = function()
    --do something when the something starts??????
    -- print("start something??? what's this for????")
  end

  reflect.end_callback = function()
    print("stop recording")
    --do something when the reflection stops recording?
  end
  reflect.end_of_loop_callback = function()
    print("loop has ended")
    --do something when the loop ends
  end
  reflect.end_of_rec_callback = function()
    -- print("something has ended???")
    --do something when something ends??? whats this for???
  end

  clock.run(function()  -- redraw the screen and grid at 15fps
    while true do
      clock.sleep(1/5)
      redraw()
    end
  end)
end

--------------------------------------------------------------------------------
-- etch as sketch code
local sketch_clock
function sketching()
  -- if this is the start of a sketch, sketch_in_progress will be false
  -- and then we can capture when the previous sketch began
  print(sketch_in_progress)
  if sketch_in_progress == false then
    print("sketch not in progress",#e_s.drawing.coords)
    e_s.drawing.prev_sketch_start = #e_s.drawing.coords
  end
  if sketch_clock then 
    clock.cancel(sketch_clock)
    -- print("cancel")
  end
  sketch_clock = clock.run(function()
    sketch_in_progress = true
    clock.sleep(1)
    sketch_in_progress = false
    print("done sketching")
    table.insert(e_s.drawing.history,e_s.drawing.prev_sketch_start)
  end)
end

function erase_last_gesture()
  print("erase", e_s.drawing.prev_sketch_start)
  --erase the set of coordinates previously saved for drawing
  e_s.drawing.history[#e_s.drawing.history] = nil
  for i=e_s.drawing.prev_sketch_start,#e_s.drawing.coords do
    e_s.drawing.coords[i] = nil
  end
  if #e_s.drawing.coords > 0 then
    e_s.cursor.x_loc = e_s.drawing.coords[#e_s.drawing.coords][1]
    e_s.cursor.y_loc = e_s.drawing.coords[#e_s.drawing.coords][2]
  else
    e_s.cursor.x_loc = e_s.cursor.x_loc_default
    e_s.cursor.y_loc = e_s.cursor.y_loc_default
  end
  e_s.drawing.prev_sketch_start = e_s.drawing.history[#e_s.drawing.history]
end

--------------------------------------------------------------------------------
-- encoder
function enc(n, delta)
  if n==1 then
    -- do something with E1
    
  elseif n==2 then
    -- add x_locations to the e_s.cursor.coords table
    e_s.cursor.x_loc = e_s.cursor.x_loc + delta
    e_s.cursor.x_loc = util.clamp(e_s.cursor.x_loc,1,127)
    if alt_key == false then
      table.insert(e_s.drawing.coords,{e_s.cursor.x_loc,e_s.cursor.y_loc})
      sketching()
    end
    -- if recording, E2 will add the value to the reflection
    if reflect.rec == 1 then
      print("recording: ", delta)
      reflect:watch({delta})
    end
  elseif n==3 then
    -- add y_locations to the e_s.cursor.coords table
    e_s.cursor.y_loc = e_s.cursor.y_loc + delta
    e_s.cursor.y_loc = util.clamp(e_s.cursor.y_loc,1,64)
    if alt_key == false then
      table.insert(e_s.drawing.coords,{e_s.cursor.x_loc,e_s.cursor.y_loc})
      sketching()
    end
  end
end

--------------------------------------------------------------------------------
-- key
local k1_pressed = false
function key(n,z)
  if n==1 then
    if z==1 then
      --if K1 is pressed longer than 0.5 seconds, turn the alt_key to true
      clock.run(function()
        k1_pressed = true
        clock.sleep(0.25)
        if k1_pressed == true then
          alt_key = true
        end
      end)
    elseif z==0 then
      --if K1 is released, turn k1_pressed and alt_key to false
      k1_pressed = false
      alt_key = false
    end
  elseif n==2 and z==1 then
    if alt_key == true and e_s.drawing.prev_sketch_start > 0 then
      erase_last_gesture()
    else
      -- start/stop reflection recording
      if reflect.rec == 0 then
        reflect:set_rec(1)
      else
        reflect:set_rec(0)
      end
      print("reflection recording? ", reflect.rec)
    end
    
  elseif n==3 and z==1 then
    -- K3, on key down start/stop playing the reflection
    if reflect.play == 1 then
      reflect:stop()
      print("stop playing")
    elseif reflect.play == 0 and reflect.count > 0 then
      reflect:start()
      print("start playing")
    elseif reflect.play == 0 and reflect.count == 0 then
      print("nothing to play yet")
    end
  end
end


--------------------------------------------------------------------------------
-- screen redraw
function redraw()
  screen.clear()
  screen.line_width(1)
  screen.aa(0)

  -- draw the sketch
  screen.level(5)
  for i=1,#e_s.drawing.coords do
    screen.pixel(e_s.drawing.coords[i][1],e_s.drawing.coords[i][2])
  end
  screen.stroke()
  
  -- draw the cursor
  screen.level(15)
  screen.move(e_s.cursor.x_loc-3,e_s.cursor.y_loc)
  screen.line_rel(5,0)
  screen.move(e_s.cursor.x_loc,e_s.cursor.y_loc-3)
  screen.line_rel(0,5)
  screen.stroke()
  
  --[[
  draw_wind()

  -- draw bars for numbers
  offset = 64 - delays.length*2
  for i=1,delays.length do
    screen.level(i==delays.ix and 15 or 1)
    screen.move(offset+i*4,60)
    screen.line_rel(0,delays[i]*-4+-1)
    screen.stroke()
  end

  -- draw edit position
  screen.level(10)
  screen.move(offset+edit*4,62)
  screen.line_rel(0,2)
  screen.stroke()
  ]]

  screen.update()
end
