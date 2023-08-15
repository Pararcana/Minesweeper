_G.love = require("love")


local function isDuplicate(arr, x, y, index)
    for i = 1, #arr do
        if arr[i][1] == x and arr[i][2] == y then
            local data = index and i or true
            return data
        end
    end
    return false
end


local function reset()
    clickedSquares,flagSquares,bombSquares, numSquares = {}, {}, {}, {}
    if boardSize*2 < (5*math.log(level)) then -- magic formula
        boardSize = boardSize + 1
    end
    bombAmount = boardSize - 1 + math.random(1, math.min(boardSize/2)) -- magic formula 2.0
end


local function verify(dt)
    dtotal = dtotal + dt
    if #verifyArr == 0 and #bombSquares ~= 0 then
        sfx["win"]:play()
        level = level + 1
        reset()
    end
    if gameOver then
        if not db then
            startSecs = dtotal
            db = true
        end
        if dtotal > startSecs + 3 then
            verifyArr = {}
            deaths = deaths + 1
            reset()
            gameOver = false
            db = false
        end
    end
end


local function setup()
    local count = 1
    math.randomseed(os.time())
    while count ~= bombAmount + 1 do
        num1, num2 = math.random(1, boardSize), math.random(1, boardSize)
        if not (num1 == rank and num2 == file) and not isDuplicate(bombSquares, rank, file) and not isDuplicate(bombSquares, num1, num2) then
            table.insert(bombSquares, {num1, num2})
            count = count + 1
        end
    end
    for i = 1, boardSize do for j = 1, boardSize do
        if not isDuplicate(bombSquares, i, j) then
            table.insert(verifyArr, {i,j})
        end end
    end
    for v = 1, #bombSquares do for i = -1, 1, 1 do for j = -1, 1, 1 do
        if (i ~= 0 or j ~= 0) and math.max(bombSquares[v][1] + i, bombSquares[v][2] + j) <= boardSize and math.min(bombSquares[v][1] + i, bombSquares[v][2] + j) > 0 and not isDuplicate(bombSquares, bombSquares[v][1] + i, bombSquares[v][2] + j) then
            if isDuplicate(numSquares, bombSquares[v][1] + i,bombSquares[v][2] + j) and #numSquares ~= 0 then 
                local w = isDuplicate(numSquares, bombSquares[v][1] + i,bombSquares[v][2] + j, true)
                numSquares[w][3] = numSquares[w][3] + 1
            else
                table.insert(numSquares, {bombSquares[v][1] + i, bombSquares[v][2] + j, 1})
            end
        end
    end end end
end


local function drawBoard()
    for x = 1, boardSize do
        for y = 1, boardSize do
            if isDuplicate(numSquares, x, y) then
                local num = isDuplicate(numSquares, x, y, true)
                love.graphics.setColor(love.math.colorFromBytes(colorSchema[numSquares[num][3]][1], colorSchema[numSquares[num][3]][2], colorSchema[numSquares[num][3]][3]))
                love.graphics.print(numSquares[num][3], x*square+square*0.225, y*square, 0, square/15, square/15)
            end
            if not isDuplicate(clickedSquares, x, y) then
                love.graphics.setColor(1,1,1)
                local rgb = (x+y+1)%2==0 and {113, 235, 52} or {100, 200, 50}
                love.graphics.setColor(love.math.colorFromBytes(rgb[1], rgb[2], rgb[3]))
                love.graphics.rectangle("fill", (x*square), (y*square), square, square, 0.15*square, 0.15*square)
            end
        end
    end
    love.graphics.setColor(1,1,1)
    for i = 1, #flagSquares do
        love.graphics.draw(sprites["flag"], flagSquares[i][1]*square, flagSquares[i][2]*square,0, square/512, square/512)
    end
    if gameOver then
        for i = 1, #bombSquares do
            love.graphics.draw(sprites["bomb"], bombSquares[i][1]*square, bombSquares[i][2]*square,0, square/2048, square/2048)
        end
    end
    love.graphics.rectangle("line", square, square, square*boardSize, square*boardSize)
end


local function click(x, y, button)
    if not gameOver then
        if math.min(x,y) > square and math.max(x,y) < square * (boardSize+1) then
            rank, file = math.floor(x/square), math.floor(y/square)
            local arr1 = button == 1 and clickedSquares or flagSquares
            local arr2 = button ~= 1 and clickedSquares or flagSquares
            if #clickedSquares == 0 and button == 1 and not isDuplicate(flagSquares, rank, file) then
                setup()
            end
            if (not isDuplicate(arr1, rank, file) or button == 1) and not isDuplicate(arr2, rank, file) then
                if isDuplicate(bombSquares, rank, file) and button == 1 then
                    sfx["boom"]:play()
                    gameOver = true
                else
                    if isDuplicate(verifyArr, rank, file) and not isDuplicate(numSquares, rank, file) and button == 1 then
                        table.insert(clickedSquares, {rank,file})
                        table.remove(verifyArr, isDuplicate(verifyArr, rank, file, true))
                        sfx["blip"]:play()
                        local nilSquares = {{rank, file}}
                        while #nilSquares ~= 0 do
                            for i = -1, 1, 1 do for j = -1, 1, 1 do
                                if i ~= 0 or j ~= 0 and math.max(nilSquares[1][1] + i, nilSquares[1][2] + j) <= boardSize and math.min(nilSquares[1][1] + i, nilSquares[1][2] + j) > 0 then
                                    if isDuplicate(verifyArr, nilSquares[1][1] + i, nilSquares[1][2] + j) and not isDuplicate(flagSquares, nilSquares[1][1] + i, nilSquares[1][2] + j) and not isDuplicate(numSquares, nilSquares[1][1] + i, nilSquares[1][2] + j)then
                                        table.insert(nilSquares, {nilSquares[1][1] + i, nilSquares[1][2] + j})
                                    end
                                    table.insert(clickedSquares, {nilSquares[1][1] + i, nilSquares[1][2] + j})
                                    local index = isDuplicate(verifyArr, nilSquares[1][1] + i, nilSquares[1][2] + j, true)
                                    if type(index) == "number" then
                                        table.remove(verifyArr, index)
                                    end
                                end
                            end end 
                            table.remove(nilSquares, 1)
                        end 
                    else 
                        local sound = button == 1 and "blip" or "flag"
                        sfx[sound]:play()
                        table.insert(arr1, {rank, file})
                        if button == 1 then
                            local index = isDuplicate(verifyArr, rank, file, true)
                            if type(index) == "number" then
                                table.remove(verifyArr, index)
                            end
                        end
                    end
                end
            elseif isDuplicate(arr1,rank, file) then
                table.remove(arr1, isDuplicate(arr1,rank,file,true))
            end
        end
    end
end


---------------------------------------------------------------------------------------------------------------------


function love.mousepressed(x, y, button)
    click(x, y, button) 
end


function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setBackgroundColor(0.15,0.15,0.15)
    _G.db = false
    _G.dtotal = 0
    _G.level = 1
    _G.boardSize = 6
    _G.bombAmount = 5
    _G.deaths = 0
    _G.gameOver = false
    _G.colorSchema = {{66, 135, 245}, {66, 235, 47}, {235, 50, 47}, {99, 14, 179}, {247, 81, 10}, {43, 72, 107}, {25, 25, 26}, {139, 139, 140}}
    _G.sprites = {
        ["flag"] = love.graphics.newImage("Sprites/flag.png"),
        ["bomb"] = love.graphics.newImage("Sprites/bomb.png")
    }
    _G.sfx = {
        ["blip"] = love.audio.newSource("Sounds/Blip.mp3", "static"),
        ["flag"] = love.audio.newSource("Sounds/Flag.mp3", "static"),
        ["boom"] = love.audio.newSource("Sounds/Boom.mp3", "static"),
        ["win"] = love.audio.newSource("Sounds/Win.mp3", "static")
    }
    flagSquares, clickedSquares, bombSquares, verifyArr, numSquares = {}, {}, {}, {}, {}
end


function love.update(dt)
    verify(dt)
end


function love.draw()
    pix = math.min(love.graphics.getDimensions())
    square = pix/(boardSize+2)

    drawBoard()
    love.graphics.setColor(1,1,1)
    love.graphics.print("# of bombs = " .. bombAmount .. "    Level = " .. level.. "    Deaths = " .. deaths.. "    Time = "..math.floor(dtotal))

end
