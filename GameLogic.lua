local RunService = game:GetService("RunService")
local TweeenService = game:GetService("TweenService")
local ResizeModule = require(script.Parent.Parent:WaitForChild("PlayerRes"):WaitForChild("ResizeModule"))

-- Setup UI Element variables
local SG = script.Parent
local grid = SG.Grid
local CF = SG.CenterFrame
local SBR = SG.SideBarRight
local SBL = SG.SideBarLeft
local gameOver = CF.GameOver
local gameWon = CF.GameWon
local banner = CF.Banner
local font = Enum.Font.SourceSansBold --Highway
local sounds = script.Parent.Sounds
local UIElements = script.Parent.UIElements
local contButton = CF.ContinueButton
local flag = UIElements.Flag
local uiBomb = UIElements.Bomb

local status = nil
local hoverDebounce = false
local clickCont = false

local totalFlags = 0

local Info = SBR.Info

local connections = {}
local tempArray = {}
local gridArray = {}

local colors = {
	["BG"] = Color3.fromRGB(74, 117, 44);
	["Board_1"] = Color3.fromRGB(170, 215, 81);
	["Board_2"] = Color3.fromRGB(162, 209, 73);
	["Selected_1"] = Color3.fromRGB(229, 194, 159);
	["Selected_2"] = Color3.fromRGB(215, 184, 153);
	["Flag"] = Color3.fromRGB(25, 118, 210); -- 14, 255, 50 -- 242, 54, 7

	["#1"] = Color3.fromRGB(25, 118, 210);
	["#2"] = Color3.fromRGB(59, 143, 62);
	["#3"] = Color3.fromRGB(211, 47, 47);
	["#4"] = Color3.fromRGB(123, 31, 162);
	["#5"] = Color3.fromRGB(255, 143, 0);
	["#6"] = Color3.fromRGB(35, 162, 115);
	["#7"] = Color3.fromRGB(200, 159, 33);
	["#8"] = Color3.fromRGB(191, 39, 108);
	
	["Bomb"] = Color3.fromRGB(255, 44, 83);
	["Square"] = Color3.fromRGB(28, 183, 255);
	["Selected"] = Color3.fromRGB(24, 112, 255);
	
}

local bombBG = {
	Color3.fromRGB(48, 102, 190);
	Color3.fromRGB(96, 175, 255);
	Color3.fromRGB(150, 52, 132);
	Color3.fromRGB(40, 194, 255);
	Color3.fromRGB(42, 245, 255);
	Color3.fromRGB(72, 191, 132);
	Color3.fromRGB(97, 208, 149);
	Color3.fromRGB(67, 151, 117);
	Color3.fromRGB(225, 96, 54);
	Color3.fromRGB(160, 26, 125);
	Color3.fromRGB(242, 95, 92);
}

local flags = 0;
local totalSquares = 0;
local identified = 0;
local DimX = 1000;
local DimY = 1000;
local Bombs = 250;
local Scale = 20;
local gameStart = false

local maxX;
local maxY;

local Minesweeper = {}
Minesweeper.animation = false

function Minesweeper.Initialize(x, y, bombCount, scale) -- Initialize the game with the given properties
	DimX = x;
	DimY = y;
	Bombs = bombCount;
	Scale = scale;
	
	--RESET ALL HERE
	totalFlags = 0
	identified = 0
	gameOver.Visible = false
	gameStart = false
	tempArray = nil
	tempArray = {}
	gridArray = nil
	gridArray = {}
	
	--Need to delete all button connections
	for i, v in pairs(connections) do
		v:Disconnect() -- disconnect connection.
		connections[i] = nil
	end
	
	connections = {}
	
	for i,v in pairs(grid:GetChildren()) do
		v:Destroy()
	end
	
	grid.Size = UDim2.new(0,x,0,y)
	
	maxX = scale--math.floor(x/Scale)
	maxY = scale--math.floor(y/Scale)
	
	totalSquares = maxX * maxY
	
	for i = 0, maxX-1 do
		local temp = {}
		for n = 0, maxY-1 do
			temp[n+1] = {0, false, Minesweeper.CreateButton(i,n), false} -- Value Explored Button Flagged
			table.insert(tempArray, {i+1,n+1})
		end
		gridArray[i+1] = temp
	end
	
	for bomb = 1, Bombs do
		local rand = math.random(1,#tempArray)
		gridArray[tempArray[rand][1]][tempArray[rand][2]][1] = 'B'
		local bombClone = uiBomb:Clone()
		bombClone.Parent = gridArray[tempArray[rand][1]][tempArray[rand][2]][3]
		table.remove(tempArray, rand)
	end
	
	for i = 1, maxX do
		for n = 1, maxY do
			if gridArray[i][n][1] == 'B' then
				continue
			end
			
			local bombTouch = 0
			local neighbors = Minesweeper.Neighbors(i,n)
			for z = 1, #neighbors do
				if gridArray [neighbors[z][1]] [neighbors[z][2]] [1] == 'B' then
					bombTouch = bombTouch + 1
				end
			end
			gridArray[i][n][1] = bombTouch
			gridArray[i][n][3].Text = gridArray[i][n][1]
			
			if bombTouch > 0 then
				gridArray[i][n][3].TextColor3 = colors["#" .. tostring(bombTouch)]
			end
		end
	end
	
	for i = 1, maxX do
		for n = 1, maxY do
			table.insert(connections, gridArray[i][n][3].MouseButton1Click:Connect(function()
				Minesweeper.LClick(i,n)
			end))
			table.insert(connections, gridArray[i][n][3].MouseButton2Click:Connect(function()
				Minesweeper.RClick(i,n)
			end))
		end
	end
	
	gameStart = true
	
end

function Minesweeper.ClickCont(--[[passed]])
	if clickCont == true --[[or passed ~= nil and status ~= nil]] then
		clickCont = false
		contButton.Position = UDim2.new(0.5,0,-0.5,0)
		sounds.Click:Play()
		sounds.Ambience:Play()
		
		local uiText = gameOver
		local sound = sounds.SadMusic
			
		if status == "Won" then
			sound = sounds.Victory
			uiText = gameWon
		end
		
		Info.Flags.TextLabel.Text = "FLAGS: 0"
		Info.Identified.TextLabel.Text = "IDENTIFIED: 0"
		
		sound:Stop()
		banner.Visible = false
		uiText.Visible = false
			
		banner.Position = UDim2.new(0.5,0,-1.013,0)
		uiText.Position = UDim2.new(0.5,0,-1,0)
		banner.Rotation = 15
		uiText.Rotation = 15
			
		status = nil
		Minesweeper.Initialize(ResizeModule.dim, ResizeModule.dim, Bombs, Scale)
	end
end

function Minesweeper.ContinueButtonSetup()
	contButton.MouseButton1Click:Connect(function()
		Minesweeper.ClickCont()
	end)
	contButton.MouseEnter:Connect(function()
		contButton.ImageColor3 = Color3.fromRGB(117, 154, 42)
		Minesweeper.HoverSound()
	end)
	contButton.MouseLeave:Connect(function()
		contButton.ImageColor3 = Color3.fromRGB(136, 182, 50)
	end)
end

function Minesweeper.HoverSound()
	if hoverDebounce == false then
		hoverDebounce = true
		sounds.Hover:Play()
		wait(0.4)
		hoverDebounce = false
	end
end

function Minesweeper.LClick(x,y) -- Select a node and do respective sequence
	if gameStart == true then
		if gridArray[x][y][2] == true then
			return
		end
		
		
		local color = colors.Selected_2
		if x%2 == y%2 then
			color = colors.Selected_1
		end
		
		local val = gridArray[x][y][1]
		if val == 'B' then
			gameStart = false
			Minesweeper.Bomb()
			return
		elseif val == 0 then
			sounds.Coin:Play()
			identified = identified + 1
			Info.Identified.TextLabel.Text = "IDENTIFIED: " .. identified
			gridArray[x][y][2] = true
			gridArray[x][y][3].BackgroundColor3 = color
			
			if gridArray[x][y][4] == true then
				local flagClone = gridArray[x][y][3]:FindFirstChild("Flag")
				if flagClone then
					flagClone:Destroy()
				end
				totalFlags = totalFlags - 1
				Info.Flags.TextLabel.Text = "FLAGS: " .. totalFlags
				gridArray[x][y][4] = false
			end
			
			Minesweeper.ExploreNeighbors(x,y)
		else
			sounds.Coin:Play()
			identified = identified + 1
			Info.Identified.TextLabel.Text = "IDENTIFIED: " .. identified
			gridArray[x][y][3].TextTransparency = 0
			gridArray[x][y][3].BackgroundColor3 = color
			gridArray[x][y][2] = true
			
			if gridArray[x][y][4] == true then
				local flagClone = gridArray[x][y][3]:FindFirstChild("Flag")
				if flagClone then
					flagClone:Destroy()
				end
				totalFlags = totalFlags - 1
				Info.Flags.TextLabel.Text = "FLAGS: " .. totalFlags
				gridArray[x][y][4] = false
			end
		end
		
		if identified == totalSquares - Bombs then
			gameStart = false
			sounds.Ambience:Stop()
			sounds.Victory:Play()
			sounds.Won:Play()
			Minesweeper.GameEnd("Won")
		end
		
	end
end

function Minesweeper.RClick(x,y) -- Right click a node to mark it as a bomb
	--Add unflagging
	if gameStart == false then return end
	if gridArray[x][y][2] == true then
		return
	else
		sounds.Click:Play()
		if gridArray[x][y][4] == false then
			local flagClone = flag:Clone()
			flagClone.Parent = gridArray[x][y][3]
			flagClone.Visible = true
			gridArray[x][y][4] = true
			totalFlags = totalFlags + 1
			Info.Flags.TextLabel.Text = "FLAGS: " .. totalFlags
		else
			local flagClone = gridArray[x][y][3]:FindFirstChild("Flag")
			if flagClone then
				flagClone:Destroy()
			end
			totalFlags = totalFlags - 1
			Info.Flags.TextLabel.Text = "FLAGS: " .. totalFlags
			gridArray[x][y][4] = false
		end
		
		
	end
end

function Minesweeper.ExploreNeighbors(x,y) -- Explore the neighbors of a safe node and reveal them if they are not bombs
	local neighbors = Minesweeper.Neighbors(x,y)
	
	for i = 1, #neighbors do
		local color = colors.Selected_2
		if gridArray [neighbors[i][1]] [neighbors[i][2]] [2] == true then
			continue
		end
		
		if neighbors[i][1]%2 == neighbors[i][2]%2 then
			color = colors.Selected_1
		end
		
		if gridArray [neighbors[i][1]] [neighbors[i][2]] [1] == 0 then
			if gridArray [neighbors[i][1]] [neighbors[i][2]] [4] == true then
				local flagClone = gridArray [neighbors[i][1]] [neighbors[i][2]] [3]:FindFirstChild("Flag")
				if flagClone then
					flagClone:Destroy()
				end
				totalFlags = totalFlags - 1
				Info.Flags.TextLabel.Text = "FLAGS: " .. totalFlags
				gridArray [neighbors[i][1]] [neighbors[i][2]] [4] = false
			end
			identified = identified + 1
			gridArray [neighbors[i][1]] [neighbors[i][2]] [2] = true
			
			gridArray [neighbors[i][1]] [neighbors[i][2]] [3].BackgroundColor3 = color
			Minesweeper.ExploreNeighbors(neighbors[i][1], neighbors[i][2])
			
		elseif gridArray [neighbors[i][1]] [neighbors[i][2]] [1] ~= 'B' then
			if gridArray [neighbors[i][1]] [neighbors[i][2]] [4] == true then
				local flagClone = gridArray [neighbors[i][1]] [neighbors[i][2]] [3]:FindFirstChild("Flag")
				if flagClone then
					flagClone:Destroy()
				end
				totalFlags = totalFlags - 1
				Info.Flags.TextLabel.Text = "FLAGS: " .. totalFlags
				gridArray [neighbors[i][1]] [neighbors[i][2]] [4] = false
			end
			identified = identified + 1
			gridArray [neighbors[i][1]] [neighbors[i][2]] [2] = true
			gridArray [neighbors[i][1]] [neighbors[i][2]] [3].BackgroundColor3 = color
			gridArray [neighbors[i][1]] [neighbors[i][2]] [3].TextTransparency = 0
		end
	end
	Info.Identified.TextLabel.Text = "IDENTIFIED: " .. identified
end

function Minesweeper.GameEnd(result) -- Play the game end animation sequence
	Minesweeper.animation = true
	local Goal
	local Tween
	local uiText = gameOver
	
	status = "Lost"
	
	if result == "Won" then
		status = "Won"
		uiText = gameWon
	end
	
	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
	
	
	Goal = {Position = UDim2.new(0.5, 0, 0.5, 0)}
	Tween = TweeenService:Create(uiText, tweenInfo, Goal)
	Tween:Play()
	
	Goal = {Position = UDim2.new(0.5, 0, 0.487, 0)}
	Tween = TweeenService:Create(banner, tweenInfo, Goal)
	Tween:Play()
	
	wait(0.5)
	
	Goal = {Rotation = 0}
	Tween = TweeenService:Create(uiText, tweenInfo, Goal)
	Tween:Play()
	
	Goal = {Rotation = 0}
	Tween = TweeenService:Create(banner, tweenInfo, Goal)
	Tween:Play()
	
	banner.Visible = true
	uiText.Visible = true
	
	wait(1)
	
	--tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
	
	Goal = {Position = UDim2.new(0.5, 0, 0.7, 0)}
	Tween = TweeenService:Create(contButton, tweenInfo, Goal)
	Tween:Play()
	
	wait(1)
	
	clickCont = true
	Minesweeper.animation = false
	--Let the local script Know
end

function Minesweeper.Bomb() -- Action after bomb is selected
	sounds.Bomb:Play()
	sounds.Ambience:Stop()
	sounds.SadMusic:Play()
	
	local Goal
	local Tween
	
	for i = 1, maxX do
		for n = 1, maxY do
			if gridArray[i][n][1] == 'B' then
				local num = math.random(1,#bombBG)
				
				local h,s,v = Color3.toHSV(bombBG[num])
				
				if gridArray[i][n][4] == true then
					local flagClone = gridArray[i][n][3]:FindFirstChild("Flag")
					if flagClone then
						flagClone:Destroy()
					end
					gridArray[i][n][4] = false
				end
				
				local Button = gridArray[i][n][3].Bomb
				Button.ImageColor3 = Color3.fromHSV(h,s,v/1.5)
				Button.Visible = true
				Goal = {ImageTransparency = 0}
				Tween = TweeenService:Create(Button, TweenInfo.new(2), Goal)
				Tween:Play()
				
				Button = gridArray[i][n][3]
				Goal = {BackgroundColor3 = bombBG[num]}
				Tween = TweeenService:Create(Button, TweenInfo.new(2), Goal)
				Tween:Play()
			end
		end
	end
	
	Minesweeper.GameEnd("Lost")
end

function Minesweeper.CreateButton(x,y) -- Create a button for the node at the given location
	local fr = Instance.new("TextButton")
	fr.Font = font
	fr.TextScaled = true
	fr.Name = (x+1 .. ":" .. y+1)
	fr.TextTransparency = 1
	fr.Text = ""
	fr.ZIndex = 2
	local color = colors.Board_2
	if x%2 == y%2 then
		color = colors.Board_1
	end
	fr.BackgroundColor3 = color
	fr.Size = UDim2.new(1/Scale, 0, 1/Scale, 0)
	fr.Position = UDim2.new(1/Scale*x, 0, 1/Scale*y, 0)
	fr.BorderSizePixel = 0
	
	fr.Parent = grid
	
	return fr
end

function Minesweeper.Neighbors(x, y) -- Return all the neighbors of a given node
	if x == 1 or y == 1 then
		if x == 1 and y == 1 then
			return({{1,2},{2,1},{2,2}})
		elseif x == 1 then
			if y < maxY then
				return({{x+1,y},{x,y-1},{x,y+1},{x+1,y+1},{x+1,y-1}})
			else
				return({{x+1,y},{x,y-1},{x+1,y-1}})
			end
			
		elseif y == 1 then
			if x < maxX then
				return({{x-1,y},{x+1,y},{x,y+1},{x-1,y+1},{x+1,y+1}})
			else
				return({{x-1,y},{x,y+1},{x-1,y+1}})
			end
			
		end
	elseif x == maxX or y == maxY then
		if x == maxX and y == maxY then
			return({{x-1,y},{x,y-1},{x-1,y-1}})
		elseif x == maxX then
			return({{x-1,y},{x,y+1},{x,y-1},{x-1,y+1},{x-1,y-1}})
		elseif y == maxY then
			return({{x+1,y},{x-1,y},{x,y-1},{x-1,y-1},{x+1,y-1}})
		end
	else
		return({{x,y+1},{x,y-1},{x+1,y},{x-1,y},{x-1,y-1},{x-1,y+1},{x+1,y-1},{x+1,y+1}})
	end
end

return Minesweeper
