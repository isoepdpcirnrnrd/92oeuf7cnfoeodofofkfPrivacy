local url=(function()local t={104,116,116,112,115,58,47,47,114,97,119,46,103,105,116,104,117,98,117,115,101,114,99,111,110,116,101,110,116,46,99,111,109,47,81,117,97,118,105,120,65,108,116,47,45,81,55,45,90,120,45,78,45,51,76,45,56,109,84,50,80,45,69,119,72,107,65,57,99,70,114,88,121,83,47,114,101,102,115,47,104,101,97,100,115,47,109,97,105,110,47,119,111,114,100,95,98,111,109,98,95,108,105,115,116,46,116,120,116}local s=""for i=1,#t do s=s..string.char(t[i])end return s end)()

local Words = {}
local loaded = false
local WordDictionary = {}
local searchCache = {}
local currentPage = 1
local wordsPerPage = 50
local sortMode = "Contains Exactly"
local randomLoopRunning = false

local function LoadWords()
    if loaded then return end
    pcall(function()
        local res = request({Url = url, Method = "GET"})
        if res and res.Body then
            for w in res.Body:gmatch("[^\r\n]+") do
                local wordLower = w:lower()
                table.insert(Words, wordLower)
                local firstLetter = wordLower:sub(1,1)
                if not WordDictionary[firstLetter] then
                    WordDictionary[firstLetter] = {}
                end
                table.insert(WordDictionary[firstLetter], wordLower)
            end
            loaded = true
        end
    end)
end
spawn(LoadWords)

local function SuggestWords(input, count)
    if not loaded then return {"loading words...", "please wait"} end
    if #Words == 0 then return {"no words available", "check connection"} end
    
    input = input:lower()
    local cacheKey = input.."_"..count.."_"..sortMode
    if sortMode ~= "Random" then
        if searchCache[cacheKey] then
            return searchCache[cacheKey]
        end
    end
    
    local possible = {}
    local results = {}
    local searchList

if sortMode == "Contains Exactly" then
    searchList = Words
else
    local firstLetter = input:sub(1,1)
    local wordList = WordDictionary[firstLetter] or {}
    searchList = #wordList > 0 and wordList or Words
end
    
    for i=1,#searchList do
    local word = searchList[i]

    if sortMode == "Contains Exactly" then
        if string.find(word, input, 1, true) then
            table.insert(possible, word)
        end
    else
        if word:sub(1,#input) == input then
            table.insert(possible, word)
        end
    end

end
    
    if sortMode=="Shortest" then
        table.sort(possible,function(a,b) return #a<#b end)
    elseif sortMode=="Longest" then
        table.sort(possible,function(a,b) return #a>#b end)
    elseif sortMode=="Random" or sortMode=="Contains Exactly" then
        for i=#possible,2,-1 do
            local j = math.random(i)
            possible[i],possible[j] = possible[j],possible[i]
        end
    end
    
    local maxResults = math.min(count,#possible)
    for i=1,maxResults do
        table.insert(results, possible[i])
    end
    
    if sortMode ~= "Random" and sortMode ~= "Contains Exactly" then
        searchCache[cacheKey] = results
    end
    return results
end

local a = Instance.new("ScreenGui", game.CoreGui)
a.Name = "WordSuggestor"

local b = Instance.new("Frame", a)
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
title.Position=UDim2.new(0,5,0,5)
title.BackgroundTransparency=1
title.Text="Word Finder"
title.TextColor3=Color3.fromRGB(255,255,255)
title.Font=Enum.Font.GothamBold
title.TextSize=14
title.TextXAlignment=Enum.TextXAlignment.Center

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
    b:Destroy()
end)

local info = Instance.new("TextLabel", contentFrame)
info.Size=UDim2.new(1,-10,0,30)
info.Position=UDim2.new(0,5,0,30)
info.BackgroundTransparency=1
info.Text="Word Bomb Searcher (286k)"
info.TextColor3=Color3.fromRGB(100,255,100)
info.Font=Enum.Font.Gotham
info.TextSize=10
info.TextXAlignment=Enum.TextXAlignment.Center
info.TextWrapped=true

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
sortButton.Text="Sort Mode: Contains Exactly"
sortButton.Font=Enum.Font.Gotham
sortButton.TextSize=11
Instance.new("UICorner",sortButton).CornerRadius=UDim.new(0,4)

local sortModes = {"Contains Exactly", "Shortest", "Longest", "Random"}
local currentSortIndex = 1

sortButton.MouseButton1Click:Connect(function()
    currentSortIndex = currentSortIndex + 1
    if currentSortIndex > #sortModes then
        currentSortIndex = 1
    end
    
    sortMode = sortModes[currentSortIndex]
    sortButton.Text = "Sort Mode: "..sortMode
    currentPage = 1
    searchCache = {}
    
    if h.Text ~= "" then
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
statusLabel.Position = UDim2.new(0, 0, 1, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 10
statusLabel.TextXAlignment=Enum.TextXAlignment.Center
statusLabel.Text = "Loading words, please wait..."

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

function UpdateSuggestions()
    if not loaded then return end
    ClearSuggestions()
    local text = h.Text
    if #text < 1 then return end
    local suggests = SuggestWords(text,1000)
    
    if #suggests == 0 then
        local message = Instance.new("TextLabel",list)
        message.Size=UDim2.new(1,0,0,22)
        message.BackgroundTransparency=1
        message.Text="No words found for: '"..text.."'"
        message.TextColor3=Color3.fromRGB(255,100,100)
        message.Font=Enum.Font.Gotham
        message.TextSize=12
        message.TextXAlignment=Enum.TextXAlignment.Center
    else
        local totalPages = math.ceil(#suggests/wordsPerPage)
        local startIndex=(currentPage-1)*wordsPerPage+1
        local endIndex=math.min(currentPage*wordsPerPage,#suggests)
        pageLabel.Text="Page "..currentPage.."/"..totalPages
        prevButton.Visible=currentPage>1
        nextButton.Visible=currentPage<totalPages

        for i=startIndex,endIndex do
            local word = suggests[i]
            local btn = Instance.new("TextButton",list)
            btn.Size=UDim2.new(1,0,0,22)
            btn.BackgroundColor3=Color3.fromRGB(45,45,45)
            btn.TextColor3=Color3.fromRGB(255,255,255)
            btn.Font=Enum.Font.Gotham
            btn.TextSize=12
            btn.Text=word
            btn.AutoButtonColor=true
            Instance.new("UICorner",btn).CornerRadius=UDim.new(0,4)
            btn.Selectable=false
            btn.MouseButton1Click:Connect(function()
                h.Text=word
            end)
        end
    end
end

prevButton.MouseButton1Click:Connect(function()
    if currentPage>1 then
        currentPage=currentPage-1
        UpdateSuggestions()
    end
end)

nextButton.MouseButton1Click:Connect(function()
    local text=h.Text
    if #text<1 then return end
    local suggests=SuggestWords(text,1000)
    local totalPages=math.ceil(#suggests/wordsPerPage)
    if currentPage<totalPages then
        currentPage=currentPage+1
        UpdateSuggestions()
    end
end)

h:GetPropertyChangedSignal("Text"):Connect(function()
    currentPage = 1
    ClearSuggestions()

    if not loaded then
        local message = Instance.new("TextLabel", list)
        message.Size = UDim2.new(1,0,0,22)
        message.BackgroundTransparency = 1
        message.Text = "Loading words, please wait..."
        message.TextColor3 = Color3.fromRGB(100,255,100)
        message.Font = Enum.Font.Gotham
        message.TextSize = 10
        message.TextXAlignment = Enum.TextXAlignment.Center
        return
    end

    if h.Text == "" then
        pageLabel.Text = "Page 0/0"
        prevButton.Visible = false
        nextButton.Visible = false
        return
    end

    UpdateSuggestions()
end)

spawn(function()
    while not loaded do wait(0.1) end
    statusLabel.Text = "Ready! " .. #Words .. " words loaded"
    statusLabel.TextColor3 = Color3.fromRGB(100,255,100)
    statusLabel.TextSize = 10
    wait(3)
    statusLabel.Visible = false

    if h.Text ~= "" then
        UpdateSuggestions()
    end
end)