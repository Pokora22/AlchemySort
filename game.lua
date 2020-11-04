
local composer = require( "composer" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local rng = require("rng")

local FULL = 4  -- number of drops to full a tube
local SOLVABLE_LIMIT = 500

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
local levelOver = false
local movesText
local undoText, resetText, hintText, solveText, timeRemainingText, hintUserText, hintUserText2, scoreText
local levelSeed
local levelParams
local gameTimer

local function resetLevel()
	composer.gotoScene( "trans", { time=300, effect="fromTop", params = levelParams } )
end

local function gameOver(time)
	composer.gotoScene( "highscores", { time=300, effect="crossFade", params = {time = time} } )
end

local function updateText()
    timeRemainingText.text = "Time remaining: " .. timeRemaining
	movesText.text = "Moves: " .. #moves 
end

local function translateDrop(drop, x, y, animate, callback, time)
	if time == nil then time = 100 end

    if animate then
        --animate onComplete
        transition.moveTo( drop, {x = x, y = y, time = time, onComplete = callback})

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

local function calcScore()
	local score = 0	
    --for each tube count up consecutive drops from 1 to #drops 
	for _, tube in ipairs(tubes) do		
		local count = 0
		if not isEmpty(tube) then 			
			count = 1
			local color = tube.drops[1].color
			for i = 2, #tube.drops do
				if tube.drops[i].color == color then count = count + 1
				else break end
			end		
		end
		score = score + 2 ^ count
	end

	return score
end

local function addDrop(drop, tube, animate, callback, time)
	-- place drop into tube.	
    table.insert( tube.drops, drop ) --place and append different?
    local x, y = tube.x, tube.y + tube.height / 2 + 8 - 34 * #tube.drops
	translateDrop(drop, x, y, animate, callback, time)
	scoreText.text = calcScore()
end


local function removeDrop(tube, animate, callback, time)
    -- remove and return the top drop from given tube or nil.

    -- if tube is empty then return nill
    if #tube.drops == 0 then return nil end

    local x, y = tube.x, tube.y - tube.height/2 - 20
    -- take the top most drop and move it to top of test tube.
    -- remove drop from tube drop collection.
    -- return drop
    local drop = tube.drops[#tube.drops]
    translateDrop(drop, x, y, animate, callback, time)
	table.remove( tube.drops, #tube.drops )
		
    return drop
end


local function isValidMove(from, to)    
	--is valid if from top color is same as to top color or to is empty
	if not isEmpty(from) then
		if isEmpty(to) then return true end

		local color = from.drops[#from.drops].color
		if to.drops[#to.drops].color == color then return true end
	end

	return false
end

local function reverse(t)
	local n = #t
	local i = 1
	while i < n do
	  t[i],t[n] = t[n],t[i]
	  i = i + 1
	  n = n - 1
	end
  end

local function bfs(moves, iter)
	if isAllSolved() then return end
	if moves == nil then
		moves = {} 
		iter = 1
	end	

	if iter > SOLVABLE_LIMIT then return end
	iter = iter + 1
	
	local bestMove = {from = 0, to = 0, score = calcScore()}

	for iFrom = 1, #tubes do
		for iTo = 1, #tubes do 
			local fromTube, toTube = tubes[iFrom], tubes[iTo]
			if not isEmpty(fromTube) then
				local drop = fromTube.drops[#fromTube.drops]

				if iFrom ~= iTo and not isFull(toTube) and ( isEmpty(toTube) or ( not isEmpty(toTube) and toTube.drops[#toTube.drops].color == drop.color)) then
					addDrop(removeDrop(tubes[iFrom]), tubes[iTo])
					local newScore = calcScore()
					addDrop(removeDrop(tubes[iTo]), tubes[iFrom])

					if newScore >= bestMove.score then 
						bestMove = {from = iFrom, to = iTo, score = newScore}
					end
				end
			end
		end
	end

	--Return if no good move left (unsolvable?)
	if bestMove.from == 0 or bestMove.to == 0 then return end
	--We now have best scoring tube	
	table.insert(moves, bestMove)	

	--Move as best and proceed on new setup
	addDrop(removeDrop(tubes[bestMove.from]), tubes[bestMove.to])	
	bfs(moves, iter)
	
	--Rever the move
	addDrop(removeDrop(tubes[bestMove.to]), tubes[bestMove.from])

	return moves
end

-- local function dfs(depth, maxDepth, score)
-- 	local indent = ""
-- 	for i = 1, depth do indent = indent .. "___ " end
	
-- 	if score == nil then score = calcScore() end
-- 	local move = {from = 1, to = 1, score = score}

-- 	if depth > maxDepth then 
-- 		move = {from = 1, to = 1, score = calcScore()}		
-- 		return move
-- 	end	

-- 	for iFrom = 1, #tubes do
-- 		local fromTube = tubes[iFrom]
		
-- 		if not isEmpty(fromTube) and not isSolved(fromTube) then				
-- 			local drop = fromTube.drops[#fromTube.drops]

-- 			for iTo = 1, #tubes do 
-- 				local toTube = tubes[iTo]

-- 				if iFrom ~= iTo and not isFull(toTube) and ( isEmpty(toTube) or ( not isEmpty(toTube) and toTube.drops[#toTube.drops].color == drop.color)) then
-- 					addDrop(removeDrop(fromTube), toTube)

-- 					local newScore = calcScore()
-- 					if newScore < score then
-- 						print( indent .. "from:" .. iFrom .. " to:" .. iTo .. " is a lower score. Breaking" )
-- 						addDrop(removeDrop(toTube), fromTube)			
-- 						break
-- 					end

-- 					-- print(indent, "from:" .. iFrom, "to:" .. iTo, "...")
-- 					if depth ~= maxDepth then
-- 						print(indent .. "from:" .. iFrom, "to:" .. iTo, "score:" .. calcScore() )
-- 					end

-- 					print(indent .. "Score before dfs: " .. score)
-- 					local score = dfs(depth + 1, maxDepth, score).score

-- 					if depth == maxDepth then
-- 						print(indent .. "from:" .. iFrom, "to:" .. iTo, "score:" .. score .. " (max depth)")
-- 					else
-- 						print(indent .. "Best for batch from:" .. iFrom, "to:" .. iTo, "score:" .. score .. "\n")
-- 					end
					

-- 					if score > move.score then 
-- 						move = { from = iFrom, to = iTo, score = score}						
-- 					end
						
-- 					addDrop(removeDrop(toTube), fromTube)					
-- 				end					
-- 			end
-- 		else
-- 			print(indent .. "from:" .. iFrom, (isSolved(fromTube) and "solved") or "empty")
-- 		end			
-- 	end
		
-- 	return move

-- end

local function hint()
	local moves = bfs()
	reverse(moves)
	if #moves > 0 then
		local move = moves[#moves]
		print("\n\n")		
		local hint = "Best move is from tube " .. move.from .. " to tube " .. move.to
		hintUserText.text = hint
	else
		print("\n\n")
		local hint = "Moves empty?"
		hintUserText.text = hint
	end
end

local function solve(solution, start)
	if start == nil then start = true end
	if start then
		solution = bfs()		
	end
		
	local function autoSolved()
		gameOver(0)
	end

	timer.performWithDelay(#solution * 500 + 2000, autoSolved);
	
	for i = 1, #solution do		
		local move = solution[i]		

		local function animate()			
			local function registerMove()
				table.insert( moves, {from = tubes[move.from], to = tubes[move.to], drop = drop} ) --drop will be nil but irrelevant as this will game over
			end

			local drop = addDrop(removeDrop(tubes[move.from], true, registerMove, 200), tubes[move.to], true, nil, 200) --Register move as a  onEnd callback
		end
		
		timer.performWithDelay((i - 1) * 500, animate);
	end		
end

local function updateClock()
    if not levelOver then
        timeRemaining = timeRemaining - 1
        updateText()
		if(timeRemaining <= 0) then gameOver(0) end
	else
		gameOver(timeRemaining)
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
		hintUserText.text = ""
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


-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen
	local nColors, nSwap, nDifficulty, duration, seed = unpack(event.params)
    local nTubes = nColors + nSwap

    --Set up text display for moves and timer
    movesText = display.newText (sceneGroup, "Moves: ", display.contentWidth - 50, 20, native.systemFont, 12 )
    timeRemainingText = display.newText( sceneGroup, "Time remaining: ", 80, 20, native.systemFont, 12 )
    undoText = display.newText( sceneGroup, "UNDO", display.contentCenterX - 70, 20, native.systemFont, 14 )
	resetText = display.newText( sceneGroup, "RESET", undoText.x + undoText.width + 10, 20, native.systemFont, 14 )
	hintText = display.newText( sceneGroup, "HINT", resetText.x + resetText.width , 20, native.systemFont, 14 )
	solveText = display.newText( sceneGroup, "SOLVE", hintText.x + hintText.width + 12, 20, native.systemFont, 14 )
	hintUserText = display.newText( sceneGroup, "", hintText.x, 40, native.systemFont, 14 )
	hintUserText2 = display.newText( sceneGroup, "", hintText.x, 60, native.systemFont, 14 )
	scoreText = display.newText( sceneGroup, "", movesText.x, 40, native.systemFont, 12 )

	local function printScore()
		print(calcScore())
	end

    undoText:addEventListener("tap", undoMove)
	resetText:addEventListener("tap", resetLevel)
	hintText:addEventListener("tap", hint)
	solveText:addEventListener("tap", solve)
	movesText:addEventListener("tap", printScore)

    -- instaniate all of the tubes
        -- put in correct position
        -- table property drops to store drops
        -- add tap event lisenter to call moveDrop
        -- first nColors start being full of drops of one color
    for k = 1, nTubes do
        local tube = display.newImageRect(sceneGroup, "assets/tube.png", 70, 197);
        tube.y = display.contentHeight - tube.height/2 - 20
        tube.x = display.contentCenterX + (k - .5 - nTubes/2) * 80
        tube.drops = {}
        tube.label = "Tube " .. k
        tube:addEventListener("tap", moveDrop )
        table.insert( tubes, tube )

        if k <= nColors then
            for d = 1, FULL do
                local drop = display.newCircle(sceneGroup, 0, 0, 16);
                drop.color = colors[k]
                drop:setFillColor(colorsRGB.RGB(colors[k]));

                addDrop(drop, tube, false)
            end
        end
	end
	
	local solvable = true

	repeat
		levelSeed = seed and seed or os.clock()
		rng.randomseed(levelSeed)


		levelParams = {unpack(event.params)}
		table.insert(levelParams, levelSeed)

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
				if not isValidMove(toTube, fromTube) then
					-- print("Not solvable?")
					solvable = false
					--can break here to make things faster?
				end
			end
		end
	until true
	
	print(solvable and "Solvable" or "Not Solvable?")
	print(#bfs()) --Record minimum moves to solve

    -- initialise game variables (moves, etc)
    moves = {}
    timeRemaining = duration + 1
	updateClock()
end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen
		gameTimer = timer.performWithDelay( 1000, updateClock, 0 )
	end
end


-- hide()
function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is on screen (but is about to go off screen)

	elseif ( phase == "did" ) then
		-- Code here runs immediately after the scene goes entirely off screen
		composer.removeScene( "game", false )
		timer.cancel(gameTimer);

	end
end


-- destroy()
function scene:destroy( event )

	local sceneGroup = self.view
	-- Code here runs prior to the removal of scene's view

end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------

return scene
