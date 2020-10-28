-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- Your code here
display.setStatusBar(display.HiddenStatusBar);

local FULL = 4  -- number of drops to full a tube

local tubes = { }
local selectedDrop

local colorsRGB = require("colorsRGB")
local colors = {
    "snow",
    "steelblue",
    "rosybrown",
    "orchid",
    "wheat",
    "thistle",
    "teal"
}

local moves
local timeRemaining
local timeRemainingText
local levelOver = false
local movesText

local function peekTable(t)
    print(t)
    for _, e in ipairs(t) do print(e.color) end
end

local function updateText()
    timeRemainingText.text = "Time remaining: " .. timeRemaining
    movesText.text = "Moves: " .. moves
end

local function isEmpty(tube) 
    -- Empty tube = has no drops
    return #tube.drops == 0
end 

local function isFull(tube) 
    -- Full tube = has FULL drops
    return #tube.drops == FULL
end

local function isSolved(tube)
    --- complete = is full AND all drops have the same color 
    if isFull(tube) then 
        print("Step 3")
        color = tube.drops[1].color
        for _, drop in ipairs(tube.drops) do 
            print("Step 4")
            if drop.color ~= color then return false end
        end
        return true
    end
end

local function isAllSolved()
    -- Are all tubes complete (or empty)
    for _, t in ipairs(tubes) do 
        print("Step 1")
        if not isEmpty(t) then 
            print("Step 2")
            if not (isSolved(t)) then return false end
        end
    end

    return true
end 

local function addDrop(drop, tube, animate)
    -- place drop into tube. 
    table.insert( tube.drops, drop ) --place and append different?

    local x = tube.x
    local y = tube.y + tube.height / 2 + 8 - 34 * #tube.drops

    --animate = user moved -> update moves
    if animate then
        transition.moveTo( drop, {x = x, y = y, time = 100})
        moves = moves - 1
        updateText()
        selectedDrop = nil
    else 
        drop.x = x
        drop.y = y
    end

    -- change drop position so that it is 'inside tube' and 'on top' of other drops 
    -- append drop to tube drop collection
end


local function removeDrop(tube, animate) 
    -- remove and return the top drop from given tube or nil.

    -- if tube is empty then return nill
    if #tube.drops == 0 then return nil end

    x, y = 50, 50
    -- take the top most drop and move it to top of test tube.
    -- remove drop from tube drop collection.
    -- return drop
    local drop = tube.drops[#tube.drops]

    if animate then
        transition.moveTo( drop, {x = x, y = x, time = 100})
        selectedDrop = drop
    else
        drop.x = x
        drop.y = y
    end

    table.remove( tube.drops, #tube.drops )
    -- drop.y = tube.y - tube.height/2 - 30

    return drop

end 

local function updateClock()
    if not levelOver then
        timeRemaining = timeRemaining - 1
        updateText()
    end
end


local function moveDrop( event ) 
    -- Pick up/drop a drop from/to selected tube.

    local tube = event.target

    
    -- if selectedDrop is nil then 
       -- remove drop from selected tubeand save it to selectedDrop
    -- 
       -- place selectedDrop to selected tube if allowed
       -- upate moves count

    -- if game is solved
       -- stop counddown clock
    if selectedDrop == nil and not isEmpty(tube) then                 
        removeDrop(tube, true)        
        
    elseif not isFull(tube) then
        addDrop(selectedDrop, tube, true)        
        if isAllSolved() then levelOver = true end
    end    
end

local function startLevel(level)
    -- create level with given parameters

    -- number of colors, number of spare tubes, level difficulty and duration
    local nColors, nSwap, nDifficulty, duration = unpack(level)
    local nTubes = nColors + nSwap

    --Set up text display for moves and timer
    movesText = display.newText( "Moves: ", display.contentWidth - 50, 20, native.systemFont, 12 )
    timeRemainingText = display.newText( "Time remaining: ", display.contentWidth - 150, 20, native.systemFont, 12 )


    -- instaniate all of the tubes
        -- put in correct position
        -- table property drops to store drops
        -- add tap event lisenter to call moveDrop
        -- first nColors start being full of drops of one color
    for k = 1, nTubes do 
        tube = display.newImageRect("assets/tube.png", 70, 197);
        tube.y = display.contentHeight - tube.height/2 - 20
        tube.x = display.contentCenterX + (k - .5 - nTubes/2) * 80
        tube.drops = {}
        tube:addEventListener("tap", moveDrop )
        table.insert( tubes, tube )

        if k <= nColors then
            for d = 1, FULL do 
                drop = display.newCircle(0, 0, 16);
                drop.color = colors[k]
                drop:setFillColor(colorsRGB.RGB(colors[k]));

                addDrop(drop, tube, false)
            end
        end
    end

    local seed = 42
    math.randomseed(seed)

    -- using nDifficulty randomise the starting position
       -- possible algorithm: 
          -- pick random source and destination tubes and move drop if allowed.
          -- repeat based on nDifficulty
    for k = 1, nDifficulty * 5 do 
        local fromTube = tubes[math.random( #tubes )]
        local toTube = tubes[math.random( #tubes )]

        if fromTube ~= toTube and not isEmpty(fromTube) and not isFull(toTube) then 
            local drop = removeDrop(fromTube)
            addDrop(drop, toTube, false)
        end
    end

    -- initialise game variables (moves, etc)
    moves = nDifficulty * 5
    timeRemaining = nDifficulty * 10 + 1
    updateClock()

    -- start countdown clock     
    timer.performWithDelay( 1000, updateClock, 0 )
       -- Use timer.performWithDelay with 1 second delay
       -- Need function updateClock to update timeRemaining and text label

end

startLevel({3, 2, 5, 90})