-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- Your code here
local rng = require("rng")

display.setStatusBar(display.HiddenStatusBar);

local FULL = 4  -- number of drops to full a tube

local tubes = { }
local selectedDrop
local fromTube

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
local undoText
local resetText
local levelSeed

local resetLevel = nil

local function updateText()
    timeRemainingText.text = "Time remaining: " .. timeRemaining
    movesText.text = "Moves: " .. #moves
end

local function transformDrop(drop, x, y, animate, callback)
    if animate then        
        --animate onComplete
        transition.moveTo( drop, {x = x, y = y, time = 100, onComplete = callback})
        
        updateText()
    else
        --set position
        drop.x = x
        drop.y = y
    end
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
        local color = tube.drops[1].color
        for _, drop in ipairs(tube.drops) do
            if drop.color ~= color then return false end
        end
        return true
    end
end

local function isAllSolved()
    -- Are all tubes complete (or empty)
    for _, t in ipairs(tubes) do
        if not isEmpty(t) then
            if not (isSolved(t)) then return false end
        end
    end

    return true
end

local function addDrop(drop, tube, animate, callback)
    -- place drop into tube.
    table.insert( tube.drops, drop ) --place and append different?
    local x, y = tube.x, tube.y + tube.height / 2 + 8 - 34 * #tube.drops
    transformDrop(drop, x, y, animate, callback)
end


local function removeDrop(tube, animate, callback)
    -- remove and return the top drop from given tube or nil.

    -- if tube is empty then return nill
    if #tube.drops == 0 then return nil end

    local x, y = tube.x, tube.y - tube.height/2 - 20
    -- take the top most drop and move it to top of test tube.
    -- remove drop from tube drop collection.
    -- return drop
    local drop = tube.drops[#tube.drops]
    transformDrop(drop, x, y, animate, callback)
    table.remove( tube.drops, #tube.drops )

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
        selectedDrop, fromTube = removeDrop(tube, true), tube

    elseif selectedDrop ~= nil and not isFull(tube) then
        --Don't add moves if moving to same tube
        if tube ~= fromTube then
            table.insert( moves, {from = fromTube, to = tube, drop = selectedDrop})
        end
        addDrop(selectedDrop, tube, true)
        selectedDrop, fromTube = nil
        if isAllSolved() then levelOver = true end
    end
end

local function undoMove(animate)
    if #moves > 0 and selectedDrop == nil then
        local move = moves[#moves]

        --Need to create the callback function first (inline doesn't wait for complete)
        local function callAdd()
            addDrop(move.drop, move.from, animate)
        end

        removeDrop(move.to, animate, callAdd)
        -- addDrop(move.drop, move.from, true)

        table.remove( moves, #moves )
        updateText()
    end
end

local function startLevel(level)
    -- create level with given parameters

    -- number of colors, number of spare tubes, level difficulty and duration
    local nColors, nSwap, nDifficulty, duration, seed = unpack(level)
    local nTubes = nColors + nSwap

    --Set up text display for moves and timer
    movesText = display.newText( "Moves: ", display.contentWidth - 50, 20, native.systemFont, 12 )
    timeRemainingText = display.newText( "Time remaining: ", 80, 20, native.systemFont, 12 )
    undoText = display.newText( "UNDO", display.contentCenterX - 40, 20, native.systemFont, 18 )
    resetText = display.newText( "RESET", display.contentCenterX + 40, 20, native.systemFont, 18 )

    undoText:addEventListener("tap", undoMove)
    resetText:addEventListener("tap", resetLevel)

    -- instaniate all of the tubes
        -- put in correct position
        -- table property drops to store drops
        -- add tap event lisenter to call moveDrop
        -- first nColors start being full of drops of one color
    for k = 1, nTubes do
        local tube = display.newImageRect("assets/tube.png", 70, 197);
        tube.y = display.contentHeight - tube.height/2 - 20
        tube.x = display.contentCenterX + (k - .5 - nTubes/2) * 80
        tube.drops = {}
        tube.label = "Tube " .. k
        tube:addEventListener("tap", moveDrop )
        table.insert( tubes, tube )

        if k <= nColors then
            for d = 1, FULL do
                local drop = display.newCircle(0, 0, 16);
                drop.color = colors[k]
                drop:setFillColor(colorsRGB.RGB(colors[k]));

                addDrop(drop, tube, false)
            end
        end
    end

    levelSeed = seed and seed or 42    
    rng.randomseed(levelSeed)

    -- using nDifficulty randomise the starting position
       -- possible algorithm:
          -- pick random source and destination tubes and move drop if allowed.
          -- repeat based on nDifficulty
    for k = 1, nDifficulty do
        local fromTube = tubes[rng.random( #tubes )]
        local toTube = tubes[rng.random( #tubes )]

        if fromTube ~= toTube and not isEmpty(fromTube) and not isFull(toTube) then
            local drop = removeDrop(fromTube)
            addDrop(drop, toTube, false)
        end
    end

    -- initialise game variables (moves, etc)
    moves = {}
    timeRemaining = duration + 1
    updateClock()

    -- start countdown clock
    timer.performWithDelay( 1000, updateClock, 0 )
       -- Use timer.performWithDelay with 1 second delay
       -- Need function updateClock to update timeRemaining and text label

end

resetLevel = function()
    moves = {}
    
    for _, tube in ipairs(tubes) do 
        tube:removeSelf()
    end
    startLevel({3, 2, 100, 90, levelSeed})
end

startLevel({3, 2, 100, 90})