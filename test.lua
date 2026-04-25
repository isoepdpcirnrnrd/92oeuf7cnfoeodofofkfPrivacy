local url=(function()local a={104,116,116,112,115,58,47,47,114,97,119,46,103,105,116,104,117,98,117,115,101,114,99,111,110,116,101,110,116,46,99,111,109,47,81,55,90,120,78,51,76,56,109,84,50,80,69,119,72,107,65,57,99,70,114,88,121,83,47,82,57,118,45,49,122,45,75,45,101,78,112,45,55,87,100,88,50,45,113,76,109,84,45,47,114,101,102,115,47,104,101,97,100,115,47,115,111,109,101,116,104,105,110,103,47,119,111,114,100,115,46,116,120,116}local b={}for i=1,#a do b[i]=string.char(a[i])end;return table.concat(b)end)()

local Words = {}
local loaded = false
local WordDictionary = {}
local searchCache = {}
local cacheSize = 0
local MAX_CACHE = 200
local currentPage = 1
local wordsPerPage = 50
local sortMode = "Random"
local KillerMap1 = {}
local KillerMap2 = {}

local killerUrl1 = "https://raw.githubusercontent.com/Q7ZxN3L8mT2PEwHkA9cFrXyS/R9v-1z-K-eNp-7WdX2-qLmT-/refs/heads/something/modern.txt"
local killerUrl2 = "https://raw.githubusercontent.com/Q7ZxN3L8mT2PEwHkA9cFrXyS/R9v-1z-K-eNp-7WdX2-qLmT-/refs/heads/something/old.txt"

pcall(function()
    local res = request({Url = killerUrl1, Method = "GET"})
    if res and res.Success and res.Body then
        for w in res.Body:gmatch("[^\r\n]+") do
            KillerMap1[w:lower()] = true
        end
    end
end)

pcall(function()
    local res = request({Url = killerUrl2, Method = "GET"})
    if res and res.Success and res.Body then
        for w in res.Body:gmatch("[^\r\n]+") do
            KillerMap2[w:lower()] = true
        end
    end
end)


local function LoadWords()
    if loaded then return end
    pcall(function()
        local res = request({Url = url, Method = "GET"})
        if res and res.Success and res.Body then
            for w in res.Body:gmatch("[^\r\n]+") do
                local wordLower = w:lower()
                table.insert(Words, wordLower)
                local firstLetter = wordLower:sub(1,1)
                if not WordDictionary[firstLetter] then
                    WordDictionary[firstLetter] = {}
                end
                table.insert(WordDictionary[firstLetter], wordLower)
            end
            table.sort(Words)

            for _, list in pairs(WordDictionary) do
                table.sort(list)
            end

            loaded = true
        end
    end)
end
task.spawn(LoadWords)

local function shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

local function formatWord(word, prefix, index)
    local prefixLen = #prefix
    local firstPart = word:sub(1, prefixLen)
    local restPart = word:sub(prefixLen + 1)

    local prefixColor
    if index == 1 then
        prefixColor = "0,255,0"
    elseif index == 2 then
        prefixColor = "255,255,0"
    else
        prefixColor = "255,0,0"
    end

    return string.format(
        '<font color="rgb(%s)">%s</font>%s',
        prefixColor,
        firstPart,
        restPart
    )
end

local function SuggestWords(input, count)
    if not loaded then return {"loading words...", "please wait"} end
    if #Words == 0 then return {"no words available", "check connection"} end

    input = input:lower()
    local cacheKey = input.."_"..count.."_"..sortMode
    if sortMode ~= "Random" and sortMode ~= "Killer" and searchCache[cacheKey] then
        return searchCache[cacheKey]
    end

    local possible = {}
    local results = {}
    local firstLetter = input:sub(1,1)
    local wordList = WordDictionary[firstLetter] or {}
    local searchList = (#wordList > 0) and wordList or Words

    local foundStart = false

    for i = 1, #searchList do
        local word = searchList[i]

        if word:sub(1, #input) == input then
            foundStart = true
            table.insert(possible, word)
        elseif foundStart then
            break
        end
    end

    if sortMode == "Shortest" then
        table.sort(possible, function(a, b) return #a < #b end)

    elseif sortMode == "Longest" then
        table.sort(possible, function(a, b) return #a > #b end)

    elseif sortMode == "Random" then
        shuffle(possible)

    elseif sortMode == "Killer" then
        local link1Words = {}
        local link2Words = {}
        local normalWords = {}

        for i = 1, #possible do
            local word = possible[i]

            if KillerMap1[word] then
                table.insert(link1Words, word)
            elseif KillerMap2[word] then
                table.insert(link2Words, word)
            else
                table.insert(normalWords, word)
            end
        end

        shuffle(link1Words)
        shuffle(link2Words)
        shuffle(normalWords)

        possible = {}

        for i = 1, count do
            local roll = math.random(100)

            if roll <= 75 and #link1Words > 0 then
                table.insert(possible, table.remove(link1Words, 1))
            elseif roll <= 100 and #link2Words > 0 then
                table.insert(possible, table.remove(link2Words, 1))
            elseif #normalWords > 0 then
                table.insert(possible, table.remove(normalWords, 1))
            end
        end
    end

    local maxResults = math.min(count, #possible)
    for i = 1, maxResults do
        table.insert(results, possible[i])
    end

    if sortMode ~= "Random" and sortMode ~= "Killer" then
        if not searchCache[cacheKey] then
            cacheSize += 1
        end

        searchCache[cacheKey] = results

        if cacheSize > MAX_CACHE then
            searchCache = {}
            cacheSize = 0
        end
    end

    return results
end

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local a = Instance.new("ScreenGui")
a.Name = "WordSuggestor"
a.ResetOnSpawn = false
a.Parent = player:WaitForChild("PlayerGui")

local b = Instance.new("Frame", a)
local UserInputService = game:GetService("UserInputService")

local guiVisible = true

local playerGui = player:WaitForChild("PlayerGui")

local gui = playerGui:FindFirstChild("CtrlButtonGui")
if not gui then
    gui = Instance.new("ScreenGui")
    gui.Name = "CtrlButtonGui"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui
end

local hitbox = gui:FindFirstChild("CtrlHitbox")

if not hitbox then
    hitbox = Instance.new("TextButton")
    hitbox.Name = "CtrlHitbox"
    hitbox.Parent = gui
end

hitbox.Size = UDim2.new(0, 40, 0, 40)
hitbox.Position = UDim2.new(0, 10, 0.5, -20)
hitbox.BackgroundTransparency = 1
hitbox.Text = ""
hitbox.BorderSizePixel = 0
hitbox.AutoButtonColor = false

local dot = hitbox:FindFirstChild("Dot")

if not dot then
    dot = Instance.new("Frame")
    dot.Name = "Dot"
    dot.Parent = hitbox
end

dot.Size = UDim2.new(0, 6, 0, 6)
dot.Position = UDim2.new(0.5, 0, 0.5, 0)
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
dot.BackgroundTransparency = 1
dot.BorderSizePixel = 0

local corner = dot:FindFirstChildOfClass("UICorner")
if not corner then
    corner = Instance.new("UICorner")
    corner.Parent = dot
end
corner.CornerRadius = UDim.new(1, 0)

local stroke = dot:FindFirstChildOfClass("UIStroke")
if not stroke then
    stroke = Instance.new("UIStroke")
    stroke.Parent = dot
end

stroke.Thickness = 1
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 1

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        guiVisible = not guiVisible
        a.Enabled = guiVisible
    end
end)

hitbox.MouseButton1Click:Connect(function()
    guiVisible = not guiVisible
    a.Enabled = guiVisible
end)

b.Size = UDim2.new(0,250,0,400)
b.Position = UDim2.new(0,80,0,100)
b.BackgroundColor3 = Color3.fromRGB(30,30,30)
b.BorderSizePixel = 0
b.Active = true
b.Draggable = true
Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
Instance.new("UIStroke",b).Thickness=1.5

local contentFrame = Instance.new("Frame", b)
contentFrame.Size = UDim2.new(1,0,1,0)
contentFrame.Position = UDim2.new(0,0,0,0)
contentFrame.BackgroundTransparency = 1

local title = Instance.new("TextLabel",b)
title.Size=UDim2.new(1,-10,0,25)
title.Position=UDim2.new(0,10,0,5)
title.BackgroundTransparency=1
title.Text="Word Finder V3.5"
title.TextColor3=Color3.fromRGB(255,255,255)
title.Font=Enum.Font.GothamBold
title.TextSize=14
title.TextXAlignment=Enum.TextXAlignment.Left

local minimizeButton = Instance.new("TextButton", b)
minimizeButton.Size = UDim2.new(0,25,0,25)
minimizeButton.Position = UDim2.new(1, -60, 0, 5)
minimizeButton.Text = "-"
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.TextSize = 18
minimizeButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
minimizeButton.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", minimizeButton).CornerRadius = UDim.new(0,4)
minimizeButton.ZIndex = 3

local closeButton = Instance.new("TextButton", b)
closeButton.Size = UDim2.new(0,25,0,25)
closeButton.Position = UDim2.new(1, -30, 0, 5)
closeButton.Text = "X"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 18
closeButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
closeButton.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0,4)
closeButton.ZIndex = 3

local minimized = false
local fullSize = b.Size
local minimizedSize = UDim2.new(0,250,0,35)

minimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    contentFrame.Visible = not minimized
    if minimized then
        b.Size = minimizedSize
    else
        b.Size = fullSize
    end
end)

closeButton.MouseButton1Click:Connect(function()
    a:Destroy()
end)

local prefixLabel = Instance.new("TextLabel", contentFrame)
prefixLabel.Size = UDim2.new(1,-10,0,25)
prefixLabel.Position = UDim2.new(0,5,0,35)
prefixLabel.BackgroundTransparency = 1
prefixLabel.Text = "Prefix: -"
prefixLabel.TextColor3 = Color3.fromRGB(255,255,255)
prefixLabel.Font = Enum.Font.GothamBold
prefixLabel.TextSize = 13
prefixLabel.TextXAlignment = Enum.TextXAlignment.Center
prefixLabel.TextWrapped = false

local sortFrame = Instance.new("Frame", contentFrame)
sortFrame.Size=UDim2.new(1,-20,0,30)
sortFrame.Position=UDim2.new(0,10,0,60)
sortFrame.BackgroundColor3=Color3.fromRGB(40,40,40)
sortFrame.BorderSizePixel=0
Instance.new("UICorner",sortFrame).CornerRadius=UDim.new(0,6)

local sortButton = Instance.new("TextButton",sortFrame)
sortButton.Size=UDim2.new(1,0,1,0)
sortButton.BackgroundColor3=Color3.fromRGB(60,60,60)
sortButton.TextColor3=Color3.fromRGB(255,255,255)
sortButton.Text="Sort Mode: Random"
sortButton.Font=Enum.Font.Gotham
sortButton.TextSize=11
Instance.new("UICorner",sortButton).CornerRadius=UDim.new(0,4)

local sortModes = {"Shortest", "Longest", "Random", "Killer"}
local currentSortIndex = 3

sortButton.MouseButton1Click:Connect(function()
    currentSortIndex = currentSortIndex + 1
    if currentSortIndex > #sortModes then
        currentSortIndex = 1
    end
    
    sortMode = sortModes[currentSortIndex]
    sortButton.Text = "Sort Mode: "..sortMode
    currentPage = 1
    searchCache = {}
    
    if h and h.Parent and h.Text ~= "" then
        UpdateSuggestions()
    end
end)

local h = Instance.new("TextBox", contentFrame)
h.Text = ""
h.PlaceholderText="Type letters..."
h.Size=UDim2.new(1,-20,0,30)
h.Position=UDim2.new(0,10,0,100)
h.BackgroundColor3=Color3.fromRGB(50,50,50)
h.TextColor3=Color3.fromRGB(255,255,255)
h.ClearTextOnFocus=false
h.Font=Enum.Font.Gotham
h.TextSize=14
h.TextXAlignment=Enum.TextXAlignment.Center
Instance.new("UICorner",h).CornerRadius=UDim.new(0,6)

local list = Instance.new("ScrollingFrame", contentFrame)
list.Size=UDim2.new(1,-20,0,200)
list.Position=UDim2.new(0,10,0,140)
list.BackgroundTransparency=1
list.ScrollBarThickness=6
list.CanvasSize=UDim2.new(0,0,0,0)
list.AutomaticCanvasSize=Enum.AutomaticSize.Y

local uiList = Instance.new("UIListLayout",list)
uiList.Padding=UDim.new(0,2)
uiList.SortOrder=Enum.SortOrder.LayoutOrder

local pageFrame = Instance.new("Frame", contentFrame)
pageFrame.Size=UDim2.new(1,-20,0,30)
pageFrame.Position=UDim2.new(0,10,0,350)
pageFrame.BackgroundTransparency=1

local prevButton = Instance.new("TextButton",pageFrame)
prevButton.Size=UDim2.new(0.2,0,1,0)
prevButton.BackgroundColor3=Color3.fromRGB(80,80,80)
prevButton.TextColor3=Color3.fromRGB(255,255,255)
prevButton.Text="< Prev"
prevButton.Font=Enum.Font.Gotham
prevButton.TextSize=12
Instance.new("UICorner",prevButton).CornerRadius=UDim.new(0,4)

local pageLabel = Instance.new("TextLabel",pageFrame)
pageLabel.Size=UDim2.new(0.6,0,1,0)
pageLabel.Position=UDim2.new(0.2,0,0,0)
pageLabel.BackgroundTransparency=1
pageLabel.Text="Page 1/1"
pageLabel.TextColor3=Color3.fromRGB(255,255,255)
pageLabel.Font=Enum.Font.Gotham
pageLabel.TextSize=12
pageLabel.TextXAlignment=Enum.TextXAlignment.Center

local statusLabel = Instance.new("TextLabel", pageFrame)
statusLabel.Size = UDim2.new(1, -10, 0, 30)
statusLabel.Position = UDim2.new(0, 0, 1, -5)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(80, 150, 255)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 10
statusLabel.TextXAlignment=Enum.TextXAlignment.Center
statusLabel.Text = "Loading Words..."

local nextButton = Instance.new("TextButton",pageFrame)
nextButton.Size=UDim2.new(0.2,0,1,0)
nextButton.Position=UDim2.new(0.8,0,0,0)
nextButton.BackgroundColor3=Color3.fromRGB(80,80,80)
nextButton.TextColor3=Color3.fromRGB(255,255,255)
nextButton.Text="Next >"
nextButton.Font=Enum.Font.Gotham
nextButton.TextSize=12
Instance.new("UICorner",nextButton).CornerRadius=UDim.new(0,4)

local function ClearSuggestions()
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
end

local currentResults = {}

function UpdateSuggestions(fromTyping)
    if not loaded then return end
    if not h then return end
    local text = h.Text or ""

    if fromTyping then
        currentPage = 1
        if #text < 1 then
            ClearSuggestions()
            pageLabel.Text = "Page 0/0"
            prevButton.Visible = false
            nextButton.Visible = false
            return
        end
        currentResults = SuggestWords(text, 1000)
    end

    ClearSuggestions()

    local totalPages = math.max(1, math.ceil(#currentResults/wordsPerPage))
    if currentPage > totalPages then currentPage = totalPages end
    if currentPage < 1 then currentPage = 1 end

    pageLabel.Text = "Page "..currentPage.."/"..totalPages
    prevButton.Visible = currentPage > 1
    nextButton.Visible = currentPage < totalPages

    local startIndex = (currentPage-1)*wordsPerPage + 1
    local endIndex = math.min(currentPage*wordsPerPage, #currentResults)
    for i=startIndex,endIndex do
        local word = currentResults[i]
        local btn = Instance.new("TextButton", list)
        btn.Size = UDim2.new(1,0,0,22)
        btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.RichText = true
        btn.Text = formatWord(word, h.Text:lower(), i - startIndex + 1)
        btn.AutoButtonColor = true
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
        btn.Selectable = false
        btn.MouseButton1Click:Connect(function()
            h.Text = word
            UpdateSuggestions(true)
        end)
    end
end

local typingId = 0

h:GetPropertyChangedSignal("Text"):Connect(function()
    typingId += 1
    local currentId = typingId

    task.wait(0.1)

    if currentId ~= typingId then
        return
    end

    if h and h.Parent then
        UpdateSuggestions(true)
    end
end)

prevButton.MouseButton1Click:Connect(function()
    if currentPage > 1 then
        currentPage = currentPage - 1
        UpdateSuggestions(false)
    end
end)

nextButton.MouseButton1Click:Connect(function()
    local totalPages = math.max(1, math.ceil(#currentResults/wordsPerPage))
    if currentPage < totalPages then
        currentPage = currentPage + 1
        UpdateSuggestions(false)
    end
end)

task.spawn(function()
    while not loaded do task.wait(0.1) end

    statusLabel.Text = "Words Loaded Successfully!"
    statusLabel.TextColor3 = Color3.fromRGB(80,150,255)
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = 10
    statusLabel.Position = UDim2.new(0, 0, 1, -5)

    local StarterGui = game:GetService("StarterGui")

    local function notify(message)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Word Finder V3.5",
                Text = message,
                Duration = 10
            })
        end)
    end

    wait(0.1)
    notify("Word Finder V3.5 is now active! All words work on Pro Server.")
    wait(0.1)
    notify("Updated Dictionary By Quavix.")
    task.wait(0.1)
    notify("Script Privated!")
    task.wait(5)
    notify("Dictionary had been Updated But NOT FULLY ACCURATE! (Updated 10)")
    task.wait(10)

    statusLabel.Visible = false

    if h and h.Parent and h.Text ~= "" then
        UpdateSuggestions()
    end
end)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local currentWordGui = nil

task.spawn(function()
    while not currentWordGui do
        currentWordGui = PlayerGui:FindFirstChild("CurrentWord", true)
        task.wait(1)
    end
end)

local function detectPrefix()
    if currentWordGui and currentWordGui.Parent then
        local obj = currentWordGui
        local letters = {}

        for _, child in ipairs(obj:GetChildren()) do
            if child and child:IsA("GuiObject") and child.Visible then
                local letterLabel = child:FindFirstChild("Letter")

                if letterLabel and letterLabel:IsA("TextLabel") then
                    table.insert(letters, {
                        letterLabel.Text,
                        child.AbsolutePosition.X
                    })
                end
            end
        end

        table.sort(letters, function(a, b)
            return a[2] < b[2]
        end)

        local result = ""

        for i = 1, #letters do
            result = result .. letters[i][1]
        end

        return string.lower(result)
    end

    if not currentWordGui or not currentWordGui.Parent then
        currentWordGui = PlayerGui:FindFirstChild("CurrentWord", true)
    end

    return ""
end

local function UpdatePrefixSuggestions(prefix)
    if prefix == "" then return end
    ClearSuggestions()

    local suggestions = SuggestWords(prefix, 50)
    for i = 1, #suggestions do
        local button = Instance.new("TextButton", list)
        button.Size = UDim2.new(1, 0, 0, 22)
        button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Font = Enum.Font.Gotham
        button.TextSize = 12
        button.RichText = true
        button.Text = formatWord(suggestions[i], prefix, i)
        button.AutoButtonColor = true
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 4)
        button.Selectable = false
        button.Active = false
    end
end

local lastPrefix = ""

task.spawn(function()
    while true do
        local prefix = detectPrefix()

        if string.find(prefix, "%.%.%.") or string.find(prefix, "#+") then
            prefixLabel.Text = "Prefix: ..."
            prefixLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
            task.wait(0.25)
        else
            local truncatedPrefix = string.sub(prefix, 1, 11)
            if truncatedPrefix ~= lastPrefix then
                lastPrefix = truncatedPrefix

                if h.Text == "" then
                    ClearSuggestions()
                end

                if truncatedPrefix ~= "" then
                    prefixLabel.Text = "Prefix: " .. truncatedPrefix

                    local exists = false
                    local firstLetter = truncatedPrefix:sub(1, 1)
                    local wordList = WordDictionary[firstLetter] or Words
                    for _, word in ipairs(wordList) do
                        if word == truncatedPrefix then
                            exists = true
                            break
                        end
                    end

                    if exists then
                        prefixLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                    else
                        prefixLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                    end

                    UpdatePrefixSuggestions(truncatedPrefix)
                else
                    prefixLabel.Text = "Prefix: -"
                    prefixLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
            end
        end

        task.wait(0.1)
    end
end)