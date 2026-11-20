-- Auto Farm (Auto Dig Zona Kerang Default 8 + Teleport Opsional + Move To Aman + Auto Net + Auto Fishing 25% + Auto Sell + Anti AFK)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local GuiService = game:GetService("GuiService")
local okVim, VirtualInputManager = pcall(function() return game:GetService("VirtualInputManager") end)
if not okVim then VirtualInputManager = nil end

local lp = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G
if env.AutoDigCleanup then pcall(env.AutoDigCleanup) end

local alive = true
local conns = {}
local isGliding = false
local isDigging = false
local isFishing = false
local isNetting = false
local isSelling = false

local function trim(s) return (tostring(s or ""):match("^%s*(.-)%s*$")) end
local function splitKeys(s)
    local t = {}
    for k in tostring(s or ""):gmatch("[^,]+") do
        k = trim(k):lower()
        if k ~= "" then t[#t + 1] = k end
    end
    return t
end
local function hit(str, keys)
    str = tostring(str or ""):lower()
    for _, k in ipairs(keys) do
        if str:find(k, 1, true) then return true end
    end
    return false
end
local function getChar() return lp.Character end
local function getHRP()
    local ch = lp.Character
    return ch and ch:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local ch = lp.Character
    return ch and ch:FindFirstChildOfClass("Humanoid")
end
local function getViewport()
    local cam = workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

---------------------------------------------------------------- GUI (5 Tabs)
local COL_BG = Color3.fromRGB(26, 26, 36)
local COL_TAB_BG = Color3.fromRGB(20, 20, 28)
local COL_BTN = Color3.fromRGB(48, 48, 62)
local COL_GREEN = Color3.fromRGB(40, 150, 60)
local COL_BLUE = Color3.fromRGB(55, 105, 200)
local COL_ORANGE = Color3.fromRGB(205, 125, 35)
local COL_PURPLE = Color3.fromRGB(135, 75, 195)
local COL_RED = Color3.fromRGB(200, 60, 55)

local gui = Instance.new("ScreenGui")
gui.Name = "AutoDigGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 998
local okp = false
if gethui then okp = pcall(function() gui.Parent = gethui() end) end
if not okp then okp = pcall(function() gui.Parent = game:GetService("CoreGui") end) end
if not okp then gui.Parent = lp:WaitForChild("PlayerGui") end

local function round(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = o
end

local WIN_W, WIN_H = 340, 385
local main = Instance.new("Frame")
main.Size = UDim2.new(0, WIN_W, 0, WIN_H)
main.Position = UDim2.new(0, 12, 0.5, -192)
main.BackgroundColor3 = COL_BG
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
round(main, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -145, 0, 28)
title.Position = UDim2.new(0, 10, 0, 4)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "Auto Dig, Fish & Net"
title.Parent = main

local function topBtn(text, col, xOff, w)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 0, 22)
    b.Position = UDim2.new(1, xOff, 0, 6)
    b.BackgroundColor3 = col
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.Parent = main
    round(b, 6)
    return b
end
local closeBtn = topBtn("X", COL_RED, -34, 26)
local minBtn = topBtn("-", COL_BTN, -64, 26)
local copyBtn = topBtn("Salin", COL_GREEN, -116, 46)

-- Tab Bar
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -16, 0, 26)
tabBar.Position = UDim2.new(0, 8, 0, 34)
tabBar.BackgroundColor3 = COL_TAB_BG
tabBar.BorderSizePixel = 0
tabBar.Parent = main
round(tabBar, 7)

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabLayout.Padding = UDim.new(0, 3)
tabLayout.Parent = tabBar

local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -16, 1, -68)
contentArea.Position = UDim2.new(0, 8, 0, 64)
contentArea.BackgroundTransparency = 1
contentArea.Parent = main

local tabs = {}
local tabBtns = {}

local function createTab(name, label)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.192, -2, 0, 22)
    btn.BackgroundColor3 = COL_BTN
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Text = label
    btn.Parent = tabBar
    round(btn, 6)

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = contentArea

    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 5)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent = page

    tabs[name] = page
    tabBtns[name] = btn
    return page
end

local function selectTab(name)
    for k, page in pairs(tabs) do
        page.Visible = (k == name)
        tabBtns[k].BackgroundColor3 = (k == name) and COL_BLUE or COL_BTN
    end
end

local pageDig = createTab("dig", "Dig")
local pageFish = createTab("fish", "Fish")
local pageNet = createTab("net", "Net")
local pageSell = createTab("sell", "Sell")
local pageMisc = createTab("misc", "Lainnya")

for k, btn in pairs(tabBtns) do
    btn.Activated:Connect(function() selectTab(k) end)
end
selectTab("dig")

local orders = {}
local function nextOrder(parent)
    orders[parent] = (orders[parent] or 0) + 1
    return orders[parent]
end

local function mkBtn(parent, text, col)
    local b = Instance.new("TextButton")
    b.LayoutOrder = nextOrder(parent)
    b.Size = UDim2.new(1, -2, 0, 27)
    b.BackgroundColor3 = col or COL_BTN
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.Text = text
    b.Parent = parent
    round(b, 7)
    return b
end

local function mkField(parent, label, default)
    local row = Instance.new("Frame")
    row.LayoutOrder = nextOrder(parent)
    row.Size = UDim2.new(1, -2, 0, 24)
    row.BackgroundTransparency = 1
    row.Parent = parent
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.52, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.Gotham
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = Color3.fromRGB(205, 205, 220)
    l.Text = label
    l.Parent = row
    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(0.48, 0, 1, 0)
    tb.Position = UDim2.new(0.52, 0, 0, 0)
    tb.BackgroundColor3 = COL_BTN
    tb.TextColor3 = Color3.new(1, 1, 1)
    tb.Font = Enum.Font.Gotham
    tb.TextSize = 11
    tb.ClearTextOnFocus = false
    tb.Text = default
    tb.Parent = row
    round(tb, 6)
    return tb
end

local function mkZoneSelector(parent, label, default)
    local row = Instance.new("Frame")
    row.LayoutOrder = nextOrder(parent)
    row.Size = UDim2.new(1, -2, 0, 25)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.46, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamBold
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = Color3.fromRGB(255, 220, 130)
    l.Text = label
    l.Parent = row

    local minusBtn = Instance.new("TextButton")
    minusBtn.Size = UDim2.new(0, 25, 1, 0)
    minusBtn.Position = UDim2.new(0.47, 0, 0, 0)
    minusBtn.BackgroundColor3 = COL_ORANGE
    minusBtn.TextColor3 = Color3.new(1, 1, 1)
    minusBtn.Font = Enum.Font.GothamBold
    minusBtn.TextSize = 13
    minusBtn.Text = "-"
    minusBtn.Parent = row
    round(minusBtn, 6)

    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(0.53, -56, 1, 0)
    tb.Position = UDim2.new(0.47, 28, 0, 0)
    tb.BackgroundColor3 = COL_BTN
    tb.TextColor3 = Color3.new(1, 1, 1)
    tb.Font = Enum.Font.GothamBold
    tb.TextSize = 11
    tb.ClearTextOnFocus = false
    tb.PlaceholderText = "8 / all"
    tb.Text = default
    tb.Parent = row
    round(tb, 6)

    local plusBtn = Instance.new("TextButton")
    plusBtn.Size = UDim2.new(0, 25, 1, 0)
    plusBtn.Position = UDim2.new(1, -25, 0, 0)
    plusBtn.BackgroundColor3 = COL_ORANGE
    plusBtn.TextColor3 = Color3.new(1, 1, 1)
    plusBtn.Font = Enum.Font.GothamBold
    plusBtn.TextSize = 13
    plusBtn.Text = "+"
    plusBtn.Parent = row
    round(plusBtn, 6)

    return tb, minusBtn, plusBtn
end

-- TAB 1: DIG (BERDASARKAN ZONA KERANG, DEFAULT ZONA 8)
local digBtn = mkBtn(pageDig, "Auto Dig: OFF", COL_BTN)
local digTpBtn = mkBtn(pageDig, "Teleport Dig: OFF", COL_BTN)
local zoneFilter, zoneMinusBtn, zonePlusBtn = mkZoneSelector(pageDig, "Target Zona Kerang", "8")
local glideBtn = mkBtn(pageDig, "Auto Meluncur ke Titik: ON", COL_GREEN)
local glideSpeed = mkField(pageDig, "Kecepatan meluncur", "90")
local digMaxWait = mkField(pageDig, "Maks tunggu gali (dtk)", "12")
local digEvery = mkField(pageDig, "Jeda antar spot (dtk)", "0.3")
local toolBtn = mkBtn(pageDig, "Equip & klik shovel: ON", COL_GREEN)
local onceBtn = mkBtn(pageDig, "Tes ke spot zona & dig 1x", COL_BLUE)

local digStatusLbl = Instance.new("TextLabel")
digStatusLbl.LayoutOrder = nextOrder(pageDig)
digStatusLbl.Size = UDim2.new(1, -2, 0, 38)
digStatusLbl.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
digStatusLbl.TextColor3 = Color3.fromRGB(255, 225, 150)
digStatusLbl.Font = Enum.Font.Code
digStatusLbl.TextSize = 10
digStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
digStatusLbl.TextYAlignment = Enum.TextYAlignment.Top
digStatusLbl.TextWrapped = true
digStatusLbl.Text = "Status Dig: Target Zona 8 (Sand_Zone8)"
digStatusLbl.Parent = pageDig
round(digStatusLbl, 6)

local digKeysText = "dig,sand,gali,pasir"
local digRadiusNum = 0
local toolKeysText = "shovel,shove,dig,sekop"

-- TAB 2: FISH
local fishBtn = mkBtn(pageFish, "Auto Fishing: OFF", COL_BTN)
local fishTpBtn = mkBtn(pageFish, "Teleport Spot Fish: OFF", COL_BTN)
local saveFishPosBtn = mkBtn(pageFish, "Simpan Posisi Mancing Sekarang", COL_BLUE)
local targetLuckBox = mkField(pageFish, "Target Luck Cast (%)", "25")
local tapDelayBox = mkField(pageFish, "Jeda Tap Kanan Bawah (dtk)", "0.03")
local biteWaitBox = mkField(pageFish, "Maks tunggu ikan (dtk)", "25")
local rodKeysBox = mkField(pageFish, "Kata kunci Rod", "rod,pancing")
local fishOnceBtn = mkBtn(pageFish, "Tes Cast 25% + Reel 1x", COL_BLUE)
local fishStatusLbl = Instance.new("TextLabel")
fishStatusLbl.LayoutOrder = nextOrder(pageFish)
fishStatusLbl.Size = UDim2.new(1, -2, 0, 44)
fishStatusLbl.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
fishStatusLbl.TextColor3 = Color3.fromRGB(170, 225, 185)
fishStatusLbl.Font = Enum.Font.Code
fishStatusLbl.TextSize = 10
fishStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
fishStatusLbl.TextYAlignment = Enum.TextYAlignment.Top
fishStatusLbl.TextWrapped = true
fishStatusLbl.Text = "Status Fish: Siap (Teleport OFF = Move To)"
fishStatusLbl.Parent = pageFish
round(fishStatusLbl, 6)

-- TAB 3: NET
local netBtn = mkBtn(pageNet, "Auto Hunt Ikan Laut: OFF", COL_BTN)
local netTpBtn = mkBtn(pageNet, "Teleport Net: OFF", COL_BTN)
local rarityFilterBox = mkField(pageNet, "Target Rarity / Ikan", "legendary,prismatic")
local netKeysBox = mkField(pageNet, "Kata kunci Net", "net,jaring")
local autoNetToggleBtn = mkBtn(pageNet, "Auto Nyalakan 'AUTO ON': ON", COL_GREEN)
local scanRareBtn = mkBtn(pageNet, "Scan All Area (IkanHidupRender)", COL_BLUE)
local netOnceBtn = mkBtn(pageNet, "Ke Area Ikan Terdekat 1x", COL_ORANGE)
local netStatusLbl = Instance.new("TextLabel")
netStatusLbl.LayoutOrder = nextOrder(pageNet)
netStatusLbl.Size = UDim2.new(1, -2, 0, 46)
netStatusLbl.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
netStatusLbl.TextColor3 = Color3.fromRGB(255, 215, 130)
netStatusLbl.Font = Enum.Font.Code
netStatusLbl.TextSize = 10
netStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
netStatusLbl.TextYAlignment = Enum.TextYAlignment.Top
netStatusLbl.TextWrapped = true
netStatusLbl.Text = "Status Net: Siap (Teleport OFF = Move To permukaan)"
netStatusLbl.Parent = pageNet
round(netStatusLbl, 6)

-- TAB 4: SELL
local sellBtn = mkBtn(pageSell, "Auto Sell: OFF", COL_BTN)
local sellTpBtn = mkBtn(pageSell, "Teleport Sell: OFF", COL_BTN)
local sellModeBtn = mkBtn(pageSell, "Mode: Remote / Tanpa Jalan", COL_BLUE)
local recSellBtn = mkBtn(pageSell, "Rekam Remote (klik SELL ALL 1x)", COL_ORANGE)
local sellEvery = mkField(pageSell, "Auto Sell tiap (detik)", "30")
local sellKeys = mkField(pageSell, "Kata kunci Sell / NPC", "sell,shell,trader,jual,merchant,npcsell")
local sellNowBtn = mkBtn(pageSell, "Tes Sell All Sekarang", COL_BLUE)

-- TAB 5: LAINNYA & LOG
local speedBtn = mkBtn(pageMisc, "Speed Jalan: OFF", COL_BTN)
local speedVal = mkField(pageMisc, "Nilai WalkSpeed", "40")
local afkBtn = mkBtn(pageMisc, "Anti AFK: ON", COL_GREEN)
local scanBtn = mkBtn(pageMisc, "Deep Scan (zona kerang, penjual, remote)", COL_BLUE)

local logBox = Instance.new("TextLabel")
logBox.LayoutOrder = nextOrder(pageMisc)
logBox.Size = UDim2.new(1, -2, 0, 125)
logBox.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
logBox.TextColor3 = Color3.fromRGB(210, 210, 220)
logBox.Font = Enum.Font.Code
logBox.TextSize = 10
logBox.TextXAlignment = Enum.TextXAlignment.Left
logBox.TextYAlignment = Enum.TextYAlignment.Top
logBox.TextWrapped = true
logBox.Text = ""
logBox.Parent = pageMisc
round(logBox, 6)

local minimized = false
minBtn.Activated:Connect(function()
    minimized = not minimized
    tabBar.Visible = not minimized
    contentArea.Visible = not minimized
    main.Size = minimized and UDim2.new(0, WIN_W, 0, 34) or UDim2.new(0, WIN_W, 0, WIN_H)
    minBtn.Text = minimized and "+" or "-"
end)

---------------------------------------------------------------- Log
local lines = {}
local function logLine(s)
    lines[#lines + 1] = s
    if #lines > 400 then table.remove(lines, 1) end
    local from = math.max(1, #lines - 8)
    logBox.Text = table.concat(lines, "\n", from, #lines)
end
copyBtn.Activated:Connect(function()
    if setclipboard then
        pcall(setclipboard, table.concat(lines, "\n"))
        logLine("(log disalin ke clipboard)")
    else
        logLine("setclipboard tidak tersedia di executor ini")
    end
end)

local function setToggle(btn, text, on, activeColor)
    btn.Text = text .. (on and "ON" or "OFF")
    btn.BackgroundColor3 = on and (activeColor or COL_GREEN) or COL_BTN
end

---------------------------------------------------------------- State
local digOn, glideOn, toolOn, fishOn, netOn, autoNetPullOn, sellOn, speedOn, afkOn =
    false, true, true, false, false, true, false, false, true
local digTpOn, fishTpOn, netTpOn, sellTpOn = false, false, false, false
local sellRemoteMode = true
local savedFishPos = nil
local lastTarget = nil

local function formatZoneDisplay(raw)
    local f = trim(raw):lower()
    if f == "" or f == "all" or f == "semua" or f == "*" then
        return "Semua Zona (KerangSand)"
    elseif f:match("^%d+$") then
        return "Zona " .. f .. " (Sand_Zone" .. f .. ")"
    else
        return "Filter: " .. trim(raw)
    end
end

local function onZoneFilterChanged(announce)
    lastTarget = nil
    local desc = formatZoneDisplay(zoneFilter.Text)
    digStatusLbl.Text = "Status Dig: Target " .. desc
    if announce then
        logLine("[dig] Target diubah -> " .. desc)
    end
end

zoneMinusBtn.Activated:Connect(function()
    local cur = tonumber(trim(zoneFilter.Text)) or 8
    local nextZ = math.max(1, cur - 1)
    zoneFilter.Text = tostring(nextZ)
    onZoneFilterChanged(true)
end)

zonePlusBtn.Activated:Connect(function()
    local cur = tonumber(trim(zoneFilter.Text)) or 8
    local nextZ = math.min(25, cur + 1)
    zoneFilter.Text = tostring(nextZ)
    onZoneFilterChanged(true)
end)

zoneFilter.FocusLost:Connect(function()
    onZoneFilterChanged(true)
end)

local function stopGlide()
    isGliding = false
end

local function disableOtherModes(except)
    if except ~= "dig" and digOn then
        digOn = false
        setToggle(digBtn, "Auto Dig: ", false)
        isDigging = false
    end
    if except ~= "fish" and fishOn then
        fishOn = false
        setToggle(fishBtn, "Auto Fishing: ", false)
        isFishing = false
        fishStatusLbl.Text = "Status Fish: OFF"
    end
    if except ~= "net" and netOn then
        netOn = false
        setToggle(netBtn, "Auto Hunt Ikan Laut: ", false)
        isNetting = false
        netStatusLbl.Text = "Status Net: OFF"
    end
    stopGlide()
end

digBtn.Activated:Connect(function()
    digOn = not digOn
    setToggle(digBtn, "Auto Dig: ", digOn)
    if digOn then
        disableOtherModes("dig")
        onZoneFilterChanged(true)
    else
        stopGlide()
        isDigging = false
        digStatusLbl.Text = "Status Dig: OFF (" .. formatZoneDisplay(zoneFilter.Text) .. ")"
    end
end)

digTpBtn.Activated:Connect(function()
    digTpOn = not digTpOn
    setToggle(digTpBtn, "Teleport Dig: ", digTpOn, COL_PURPLE)
    logLine("[dig] Mode gerak: " .. (digTpOn and "TELEPORT" or "MOVE TO (Meluncur)"))
end)

fishBtn.Activated:Connect(function()
    fishOn = not fishOn
    setToggle(fishBtn, "Auto Fishing: ", fishOn)
    if fishOn then
        disableOtherModes("fish")
        if not savedFishPos then
            local hrp = getHRP()
            if hrp then savedFishPos = hrp.Position end
        end
    else
        isFishing = false
        fishStatusLbl.Text = "Status Fish: OFF"
    end
end)

fishTpBtn.Activated:Connect(function()
    fishTpOn = not fishTpOn
    setToggle(fishTpBtn, "Teleport Spot Fish: ", fishTpOn, COL_PURPLE)
    logLine("[fish] Mode gerak ke spot: " .. (fishTpOn and "TELEPORT" or "MOVE TO (Meluncur)"))
end)

saveFishPosBtn.Activated:Connect(function()
    local hrp = getHRP()
    if hrp then
        savedFishPos = hrp.Position
        logLine(string.format("[fish] Posisi mancing disimpan (%.0f, %.0f, %.0f)", savedFishPos.X, savedFishPos.Y, savedFishPos.Z))
        fishStatusLbl.Text = string.format("Status Fish: Spot tersimpan (%.0f, %.0f)", savedFishPos.X, savedFishPos.Z)
    end
end)

netBtn.Activated:Connect(function()
    netOn = not netOn
    setToggle(netBtn, "Auto Hunt Ikan Laut: ", netOn)
    if netOn then
        disableOtherModes("net")
    else
        stopGlide()
        isNetting = false
        netStatusLbl.Text = "Status Net: OFF"
    end
end)

netTpBtn.Activated:Connect(function()
    netTpOn = not netTpOn
    setToggle(netTpBtn, "Teleport Net: ", netTpOn, COL_PURPLE)
    logLine("[net] Mode gerak: " .. (netTpOn and "TELEPORT" or "MOVE TO (Meluncur)"))
end)

autoNetToggleBtn.Activated:Connect(function()
    autoNetPullOn = not autoNetPullOn
    setToggle(autoNetToggleBtn, "Auto Nyalakan 'AUTO ON': ", autoNetPullOn)
end)

glideBtn.Activated:Connect(function()
    glideOn = not glideOn
    setToggle(glideBtn, "Auto Meluncur ke Titik: ", glideOn)
    if not glideOn then stopGlide() end
end)

toolBtn.Activated:Connect(function()
    toolOn = not toolOn
    setToggle(toolBtn, "Equip & klik shovel: ", toolOn)
end)

sellBtn.Activated:Connect(function()
    sellOn = not sellOn
    setToggle(sellBtn, "Auto Sell: ", sellOn)
end)

sellTpBtn.Activated:Connect(function()
    sellTpOn = not sellTpOn
    setToggle(sellTpBtn, "Teleport Sell: ", sellTpOn, COL_PURPLE)
    if sellTpOn and sellRemoteMode then
        sellRemoteMode = false
        sellModeBtn.Text = "Mode: Ke Penjual"
        sellModeBtn.BackgroundColor3 = COL_ORANGE
    end
    logLine("[sell] Mode gerak ke penjual: " .. (sellTpOn and "TELEPORT" or "MOVE TO (Meluncur)"))
end)

sellModeBtn.Activated:Connect(function()
    sellRemoteMode = not sellRemoteMode
    sellModeBtn.Text = sellRemoteMode and "Mode: Remote / Tanpa Jalan" or "Mode: Ke Penjual"
    sellModeBtn.BackgroundColor3 = sellRemoteMode and COL_BLUE or COL_ORANGE
end)

afkBtn.Activated:Connect(function()
    afkOn = not afkOn
    setToggle(afkBtn, "Anti AFK: ", afkOn)
end)

---------------------------------------------------------------- Helper UI & Tap Layar
local function isGuiVisible(obj)
    if not obj then return false end
    if obj:IsA("GuiObject") then
        if obj.AbsoluteSize.X < 2 or obj.AbsoluteSize.Y < 2 then
            return false
        end
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.TextTransparency >= 0.9 then
            return false
        end
    end

    local curr = obj
    while curr and curr ~= game do
        if curr:IsA("GuiObject") then
            if not curr.Visible then
                return false
            end
            if curr:IsA("CanvasGroup") and curr.GroupTransparency >= 0.9 then
                return false
            end
        elseif curr:IsA("ScreenGui") and not curr.Enabled then
            return false
        end
        curr = curr.Parent
    end
    return true
end

local function getScreenCenter(obj)
    if not (obj and obj:IsA("GuiObject")) then return nil, nil end
    local rootGui = obj:FindFirstAncestorWhichIsA("ScreenGui")
    local insetY = 0
    if not (rootGui and rootGui.IgnoreGuiInset) then
        local inset = GuiService:GetGuiInset()
        insetY = inset.Y
    end
    local pos = obj.AbsolutePosition
    local size = obj.AbsoluteSize
    return pos.X + (size.X / 2), pos.Y + (size.Y / 2) + insetY
end

local function tapScreenPoint(sx, sy)
    if not VirtualInputManager then return false end
    local ok = pcall(function()
        VirtualInputManager:SendMouseButtonEvent(sx, sy, 0, true, game, 1)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(sx, sy, 0, false, game, 1)
    end)
    return ok
end

local function singleTapGui(obj)
    if not obj then return false end
    local targetBtn = obj:IsA("GuiButton") and obj or (obj:FindFirstAncestorWhichIsA("GuiButton") or obj)

    if VirtualInputManager then
        local cx, cy = getScreenCenter(targetBtn)
        if cx and cy then
            if tapScreenPoint(cx, cy) then return true end
        end
    end

    if firesignal then
        for _, sigName in ipairs({ "Activated", "MouseButton1Click" }) do
            local ok, sig = pcall(function() return targetBtn[sigName] end)
            if ok and sig then
                pcall(firesignal, sig)
                return true
            end
        end
    end
    return false
end

---------------------------------------------------------------- Helper Tool, Raycast Permukaan & Gerak (Teleport / Move To)
local function findTool(keys)
    local ch, bp = getChar(), lp:FindFirstChildOfClass("Backpack")
    for _, holder in ipairs({ ch, bp }) do
        if holder then
            for _, t in ipairs(holder:GetChildren()) do
                if t:IsA("Tool") and hit(t.Name, keys) then return t end
            end
        end
    end
    return nil
end

local function equipToolByKeys(keys)
    if #keys == 0 then return nil end
    local tool = findTool(keys)
    if not tool then return nil end
    local hum = getHum()
    if hum and tool.Parent ~= getChar() then
        pcall(function() hum:EquipTool(tool) end)
        task.wait(0.15)
    end
    return tool
end

local function getIkanHidupFolder()
    local direct = workspace:FindFirstChild("IkanHidupRender")
    if direct then return direct end
    for _, child in ipairs(workspace:GetChildren()) do
        local n = child.Name:lower()
        if n:find("ikanhidup", 1, true) or n == "fishes" or n == "spawnedfish" then
            return child
        end
    end
    return nil
end

local function getObjectPos(obj)
    if not (obj and obj.Parent) then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Attachment") then return obj.WorldPosition end
    if obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart.Position end
        local ok, cf = pcall(function() return obj:GetPivot() end)
        if ok then return cf.Position end
        local bp = obj:FindFirstChildWhichIsA("BasePart", true)
        if bp then return bp.Position end
    end
    local ancPart = obj:FindFirstAncestorWhichIsA("BasePart")
    if ancPart then return ancPart.Position end
    local ancModel = obj:FindFirstAncestorWhichIsA("Model")
    if ancModel and ancModel ~= workspace then
        local ok, cf = pcall(function() return ancModel:GetPivot() end)
        if ok then return cf.Position end
    end
    return nil
end

local function getSafeSurfaceY(x, z, fallbackY)
    local originY = math.max((fallbackY or 0) + 120, 150)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = false
    params.RespectCanCollide = false

    local ignoreList = {}
    local ch = getChar()
    if ch then ignoreList[#ignoreList + 1] = ch end
    local ikanFolder = getIkanHidupFolder()
    if ikanFolder then ignoreList[#ignoreList + 1] = ikanFolder end
    params.FilterDescendantsInstances = ignoreList

    local res = workspace:Raycast(Vector3.new(x, originY, z), Vector3.new(0, -350, 0), params)
    if res then
        return res.Position.Y
    end
    return fallbackY or 0
end

local function computeSafeHoldY(rawPos, clearanceY)
    local surfY = getSafeSurfaceY(rawPos.X, rawPos.Z, rawPos.Y)
    local safeY = math.max(rawPos.Y + clearanceY, surfY + clearanceY)
    local h = getHRP()
    local hum = getHum()
    if h and hum and hum:GetState() == Enum.HumanoidStateType.Swimming then
        safeY = math.max(safeY, h.Position.Y + 3.2)
    end
    return safeY
end

local function teleportToDynamic(targetObjOrPos, clearanceY)
    local hrp = getHRP()
    local hum = getHum()
    if not (hrp and hum and hum.Health > 0) then return false end

    local clearY = clearanceY or 3.0
    local rawPos = nil
    if typeof(targetObjOrPos) == "Vector3" then
        rawPos = targetObjOrPos
    elseif typeof(targetObjOrPos) == "Instance" and targetObjOrPos.Parent then
        rawPos = getObjectPos(targetObjOrPos)
    end
    if not rawPos then return false end

    stopGlide()
    local safeY = computeSafeHoldY(rawPos, clearY)
    local lookAt = Vector3.new(rawPos.X, safeY, rawPos.Z - 1)
    if (Vector3.new(rawPos.X, safeY, rawPos.Z) - hrp.Position).Magnitude > 0.5 then
        lookAt = Vector3.new(
            rawPos.X + (rawPos.X - hrp.Position.X),
            safeY,
            rawPos.Z + (rawPos.Z - hrp.Position.Z)
        )
    end

    hrp.CFrame = CFrame.new(Vector3.new(rawPos.X, safeY, rawPos.Z), lookAt)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    task.wait(0.06)
    return true
end

local function glideToDynamic(targetObjOrPos, stopFlatDist, clearanceY)
    local hrp = getHRP()
    local hum = getHum()
    if not (hrp and hum and hum.Health > 0) then return false end

    local reachFlat = stopFlatDist or 5.5
    local clearY = clearanceY or 3.0

    local function resolveRawPos()
        if typeof(targetObjOrPos) == "Vector3" then
            return targetObjOrPos
        elseif typeof(targetObjOrPos) == "Instance" and targetObjOrPos.Parent then
            return getObjectPos(targetObjOrPos)
        end
        return nil
    end

    local rawPos = resolveRawPos()
    if not rawPos then return false end

    local initFlat = Vector2.new(rawPos.X - hrp.Position.X, rawPos.Z - hrp.Position.Z).Magnitude
    local initTargetY = computeSafeHoldY(rawPos, clearY)
    if initFlat <= reachFlat and math.abs(hrp.Position.Y - initTargetY) <= 4.0 then
        return true
    end

    stopGlide()
    isGliding = true

    local spd = math.clamp(tonumber(glideSpeed.Text) or 90, 15, 500)
    local startClock = os.clock()

    while alive and isGliding do
        local h = getHRP()
        local hu = getHum()
        if not (h and hu and hu.Health > 0) then break end

        rawPos = resolveRawPos()
        if not rawPos then break end

        local targetY = computeSafeHoldY(rawPos, clearY)
        local flatVec = Vector2.new(rawPos.X - h.Position.X, rawPos.Z - h.Position.Z)
        local flatDist = flatVec.Magnitude

        if flatDist <= reachFlat and math.abs(h.Position.Y - targetY) <= 4.0 then
            h.CFrame = CFrame.new(
                Vector3.new(h.Position.X, targetY, h.Position.Z),
                Vector3.new(rawPos.X, targetY, rawPos.Z)
            )
            h.AssemblyLinearVelocity = Vector3.zero
            h.AssemblyAngularVelocity = Vector3.zero
            isGliding = false
            return true
        end

        if (os.clock() - startClock) > 25 then
            break
        end

        local dt = RunService.Heartbeat:Wait()
        local curSurfY = getSafeSurfaceY(h.Position.X, h.Position.Z, h.Position.Y)
        local minSafeY = curSurfY + clearY
        if hu:GetState() == Enum.HumanoidStateType.Swimming then
            minSafeY = math.max(minSafeY, h.Position.Y + 3.5)
        end

        local desiredY = math.max(targetY, minSafeY)
        if flatDist > 12 then
            desiredY = math.max(desiredY, targetY + 4.0)
        end

        local stepXZ = math.min(flatDist, spd * dt)
        local nextX = h.Position.X
        local nextZ = h.Position.Z
        if flatDist > 0.05 then
            local dirX = flatVec.X / flatDist
            local dirZ = flatVec.Y / flatDist
            nextX = nextX + dirX * stepXZ
            nextZ = nextZ + dirZ * stepXZ
        end

        local dy = desiredY - h.Position.Y
        local maxStepY = math.max(spd * dt, 60 * dt)
        local nextY = h.Position.Y + math.clamp(dy, -maxStepY, maxStepY)

        h.CFrame = CFrame.new(
            Vector3.new(nextX, nextY, nextZ),
            Vector3.new(rawPos.X, nextY, rawPos.Z)
        )
        h.AssemblyLinearVelocity = Vector3.zero
        h.AssemblyAngularVelocity = Vector3.zero
    end

    isGliding = false
    local hEnd = getHRP()
    if hEnd then hEnd.AssemblyLinearVelocity = Vector3.zero end
    return false
end

local function moveToTarget(targetObjOrPos, useTeleport, stopFlatDist, clearanceY)
    if useTeleport then
        return teleportToDynamic(targetObjOrPos, clearanceY)
    else
        return glideToDynamic(targetObjOrPos, stopFlatDist, clearanceY)
    end
end

local function fireOne(pp)
    if not (pp and pp.Parent and pp.Enabled) then return false end
    if not fireproximityprompt then return false end
    pcall(function() pp.HoldDuration = 0 end)
    return pcall(fireproximityprompt, pp)
end

---------------------------------------------------------------- DATABASE RARITY & SCAN IkanHidupRender
local fishRarityDB = {}
local dbScanned = false

local KNOWN_RARITIES = {
    "prismatic", "secret", "exotic", "mythical", "mythic",
    "legendary", "epic", "rare", "uncommon", "common"
}

local FALLBACK_RARE_SPECIES = {
    ["monster turtle"] = "legendary",
    ["sperm whale"] = "legendary",
    ["megalodon"] = "legendary",
    ["kraken"] = "legendary",
    ["leviathan"] = "prismatic",
    ["mosasaurus"] = "legendary",
    ["great white shark"] = "legendary",
    ["whale shark"] = "legendary",
    ["oarfish"] = "legendary",
    ["coelacanth"] = "legendary",
    ["giant squid"] = "legendary",
    ["colossal squid"] = "prismatic",
    ["sea dragon"] = "prismatic",
    ["sunfish"] = "legendary",
    ["manta ray"] = "legendary",
    ["orca"] = "legendary",
    ["blue whale"] = "legendary",
    ["narwhal"] = "legendary",
}

local function extractRarityFromString(str)
    str = trim(str):lower()
    for _, r in ipairs(KNOWN_RARITIES) do
        if str == r or str:find(r, 1, true) then
            return r
        end
    end
    return nil
end

local function parseTableForFishRarities(tbl, depth, visited, hintName)
    if depth > 4 or type(tbl) ~= "table" or visited[tbl] then return end
    visited[tbl] = true

    local foundName = hintName
    local foundRarity = nil

    for k, v in pairs(tbl) do
        local ks = tostring(k):lower()
        if type(v) == "string" then
            local vs = trim(v)
            if ks == "name" or ks == "kind" or ks == "fish" or ks == "fishname" or ks == "title" or ks == "id" then
                foundName = vs
            elseif ks == "rarity" or ks == "tier" or ks == "grade" or ks == "class" then
                local r = extractRarityFromString(vs)
                if r then foundRarity = r end
            elseif type(k) == "string" and #k >= 3 then
                local r = extractRarityFromString(vs)
                if r then
                    fishRarityDB[trim(k):lower()] = r
                end
            end
        end
    end

    if foundName and foundRarity and #foundName >= 3 then
        fishRarityDB[trim(foundName):lower()] = foundRarity
    end

    for k, v in pairs(tbl) do
        if type(v) == "table" then
            local nextHint = (type(k) == "string" and #k >= 3) and k or foundName
            parseTableForFishRarities(v, depth + 1, visited, nextHint)
        end
    end
end

local function buildFishRarityDatabase(forceRefresh)
    if dbScanned and not forceRefresh then return end
    dbScanned = true

    for k, v in pairs(FALLBACK_RARE_SPECIES) do
        fishRarityDB[k] = v
    end

    local modKeys = { "fish", "ikan", "index", "encyclo", "rarity", "catalog", "data", "config", "marine", "creature", "item" }
    local skipKeys = { "cmdr", "roact", "fusion", "knit", "signal", "promise", "janitor", "profile", "camera", "control" }

    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        if d:IsA("ModuleScript") and require then
            local full = d:GetFullName():lower()
            if hit(full, modKeys) and not hit(full, skipKeys) then
                local okReq, res = pcall(require, d)
                if okReq and type(res) == "table" then
                    parseTableForFishRarities(res, 1, {}, nil)
                end
            end
        elseif d:IsA("StringValue") then
            local r = extractRarityFromString(d.Value)
            if r and d.Parent then
                local pName = trim(d.Parent.Name):lower()
                if #pName >= 3 then
                    fishRarityDB[pName] = r
                end
            end
        end
    end
end

local function getFishKindName(fishObj)
    local okKind, kindAttr = pcall(function() return fishObj:GetAttribute("Kind") end)
    if okKind and type(kindAttr) == "string" and trim(kindAttr) ~= "" then
        return trim(kindAttr)
    end
    return trim(fishObj.Name)
end

local function resolveFishRarity(fishObj, kindName)
    local toCheck = { fishObj }
    for _, desc in ipairs(fishObj:GetDescendants()) do
        if desc:IsA("BasePart") or desc:IsA("StringValue") or desc:IsA("TextLabel") then
            toCheck[#toCheck + 1] = desc
        end
    end

    for _, obj in ipairs(toCheck) do
        local okAttr, attrs = pcall(function() return obj:GetAttributes() end)
        if okAttr and type(attrs) == "table" then
            for k, v in pairs(attrs) do
                local ks = tostring(k):lower()
                if ks ~= "kind" then
                    local r = extractRarityFromString(v)
                    if r then return r end
                end
            end
        end
        if obj:IsA("StringValue") then
            local r = extractRarityFromString(obj.Value)
            if r then return r end
        elseif obj:IsA("TextLabel") then
            local r = extractRarityFromString(obj.Text)
            if r then return r end
        end
    end

    local kl = kindName:lower()
    if fishRarityDB[kl] then
        return fishRarityDB[kl]
    end

    return "unknown"
end

local function scanAllSeaFishes(includeAllForLog)
    buildFishRarityDatabase(false)

    local folder = getIkanHidupFolder()
    if not folder then
        return {}, false
    end

    local targetKeys = splitKeys(rarityFilterBox.Text)
    if #targetKeys == 0 then
        targetKeys = { "legendary", "prismatic" }
    end

    local hrp = getHRP()
    local matched = {}
    local allList = {}

    for _, fishObj in ipairs(folder:GetChildren()) do
        local pos = getObjectPos(fishObj)
        if pos then
            local kind = getFishKindName(fishObj)
            local rarity = resolveFishRarity(fishObj, kind)
            local dist = hrp and (pos - hrp.Position).Magnitude or 1e9

            local info = {
                root = fishObj,
                kind = kind,
                rarity = rarity:upper(),
                pos = pos,
                dist = dist,
            }
            allList[#allList + 1] = info

            if hit(rarity, targetKeys) or hit(kind, targetKeys) then
                matched[#matched + 1] = info
            end
        end
    end

    local function sortFishes(a, b)
        local aPris = a.rarity:find("PRISMATIC", 1, true) ~= nil
        local bPris = b.rarity:find("PRISMATIC", 1, true) ~= nil
        if aPris ~= bPris then return aPris end
        return a.dist < b.dist
    end

    table.sort(matched, sortFishes)
    table.sort(allList, function(a, b) return a.dist < b.dist end)

    if includeAllForLog then
        return matched, true, allList
    end
    return matched, true
end

---------------------------------------------------------------- AUTO ON (Hotbar Bawah & Panel NET PULL)
local function getNetPullPanel()
    local pg = lp:FindFirstChild("PlayerGui")
    if not pg then return nil end
    for _, d in ipairs(pg:GetDescendants()) do
        if not d:IsDescendantOf(gui) and d:IsA("TextLabel") then
            local txt = trim(d.Text):lower()
            if txt == "net pull" and isGuiVisible(d) then
                local p = d.Parent
                if p and p.Parent and p.Parent:IsA("GuiObject") then
                    return p.Parent
                end
                return p
            end
        end
    end
    return nil
end

local function isNetPullActive()
    return getNetPullPanel() ~= nil
end

local lastAutoNetClickClock = 0

local function ensureAutoNetEnabled()
    if not autoNetPullOn then return end
    if os.clock() - lastAutoNetClickClock < 0.8 then return end

    local pg = lp:FindFirstChild("PlayerGui")
    if not pg then return end
    local vp = getViewport()

    local panel = getNetPullPanel()
    if panel then
        for _, d in ipairs(panel:GetDescendants()) do
            if (d:IsA("TextLabel") or d:IsA("TextButton")) and isGuiVisible(d) then
                if trim(d.Text):lower() == "auto off" then
                    lastAutoNetClickClock = os.clock()
                    singleTapGui(d)
                    logLine("[net] Menyalakan AUTO ON pada NET PULL!")
                    return
                end
            end
        end
    end

    for _, d in ipairs(pg:GetDescendants()) do
        if not d:IsDescendantOf(gui) and (d:IsA("TextLabel") or d:IsA("TextButton")) and isGuiVisible(d) then
            local txt = trim(d.Text):lower()
            if txt == "auto off" and d.AbsolutePosition.Y > (vp.Y * 0.78) then
                lastAutoNetClickClock = os.clock()
                singleTapGui(d)
                logLine("[net] Menyalakan tombol AUTO ON di hotbar bawah!")
                return
            end
        end
    end
end

local function setNetStatus(msg)
    netStatusLbl.Text = "Status Net: " .. msg
end

local function netHuntCycle(forceOnce)
    if isSelling or isNetting then return end
    local hrp = getHRP()
    local hum = getHum()
    if not (hrp and hum and hum.Health > 0) then return end

    isNetting = true

    local ok, err = pcall(function()
        if isNetPullActive() then
            setNetStatus("NET PULL berjalan otomatis...")
            while alive and (netOn or forceOnce) and isNetPullActive() do
                ensureAutoNetEnabled()
                local h = getHRP()
                if h then
                    local holdY = computeSafeHoldY(h.Position, 2.8)
                    h.CFrame = CFrame.new(h.Position.X, holdY, h.Position.Z)
                    h.AssemblyLinearVelocity = Vector3.zero
                    h.AssemblyAngularVelocity = Vector3.zero
                end
                task.wait(0.15)
            end
            setNetStatus("Selesai! Mencari ikan rare berikutnya...")
            return
        end

        setNetStatus("Memindai IkanHidupRender...")
        local fishes, folderExists = scanAllSeaFishes(false)
        if not folderExists then
            setNetStatus("Folder IkanHidupRender tidak ditemukan!")
            task.wait(1.5)
            return
        end

        if #fishes == 0 then
            setNetStatus("Belum ada target rare di IkanHidupRender...")
            task.wait(1.2)
            return
        end

        local target = fishes[1]
        local fishRoot = target.root
        local modeTxt = netTpOn and "Teleport" or "Move To"
        logLine(string.format("[net] (%s) Ke area [%s] %s (jarak=%.0f)", modeTxt, target.rarity, target.kind, target.dist))
        setNetStatus(string.format("%s ke [%s] %s (%.0f m)...", modeTxt, target.rarity, target.kind, target.dist))

        local netTool = equipToolByKeys(splitKeys(netKeysBox.Text))
        if not netTool then
            setNetStatus("Tool Net tidak ditemukan di tas!")
            task.wait(1)
            return
        end

        local arrived = moveToTarget(fishRoot, netTpOn, 5.5, 2.8)
        if not arrived or isSelling or (not netOn and not forceOnce) then
            return
        end

        ensureAutoNetEnabled()
        setNetStatus(string.format("Di atas [%s] %s -> Net bekerja otomatis...", target.rarity, target.kind))

        local stayStart = os.clock()
        local sawNetPull = false

        while alive and (netOn or forceOnce) and fishRoot.Parent do
            if isSelling then break end
            local hu = getHum()
            if not (hu and hu.Health > 0) then break end

            local currentNet = findTool(splitKeys(netKeysBox.Text))
            if currentNet and currentNet.Parent ~= getChar() then
                equipToolByKeys(splitKeys(netKeysBox.Text))
            end
            ensureAutoNetEnabled()

            if isNetPullActive() then
                if not sawNetPull then
                    sawNetPull = true
                    logLine(string.format("[net] Net otomatis menangkap [%s] %s!", target.rarity, target.kind))
                end
                setNetStatus(string.format("NET PULL [%s] %s berjalan...", target.rarity, target.kind))
            elseif sawNetPull then
                break
            end

            local h = getHRP()
            local fPos = getObjectPos(fishRoot)
            if h and fPos then
                local flatDist = Vector2.new(fPos.X - h.Position.X, fPos.Z - h.Position.Z).Magnitude
                if flatDist > 7.5 then
                    moveToTarget(fishRoot, netTpOn, 5.5, 2.8)
                else
                    local safeY = computeSafeHoldY(fPos, 2.8)
                    h.CFrame = CFrame.new(
                        Vector3.new(h.Position.X, safeY, h.Position.Z),
                        Vector3.new(fPos.X, safeY, fPos.Z)
                    )
                    h.AssemblyLinearVelocity = Vector3.zero
                    h.AssemblyAngularVelocity = Vector3.zero
                end
            end

            if not sawNetPull and (os.clock() - stayStart) > 20 then
                logLine("[net] Timeout area ikan, pindah ke target berikutnya...")
                break
            end

            task.wait(0.12)
        end

        if sawNetPull or not fishRoot.Parent then
            logLine(string.format("[net] Selesai [%s] %s! Lanjut target berikutnya...", target.rarity, target.kind))
            setNetStatus("Tertangkap! Mencari area ikan berikutnya...")
            task.wait(0.6)
        end
    end)

    if not ok then
        logLine("[net] error: " .. tostring(err))
    end
    isNetting = false
end

task.spawn(function()
    while alive do
        if netOn and not isSelling and not isNetting then
            netHuntCycle(false)
        end
        task.wait(0.25)
    end
end)

scanRareBtn.Activated:Connect(function()
    task.spawn(function()
        buildFishRarityDatabase(true)
        local dbCount = 0
        for _ in pairs(fishRarityDB) do dbCount = dbCount + 1 end

        logLine("== SCAN IkanHidupRender (DB=" .. dbCount .. " spesies) ==")
        local matched, folderExists, allList = scanAllSeaFishes(true)
        if not folderExists then
            logLine("[error] Folder Workspace.IkanHidupRender tidak ditemukan!")
            return
        end

        logLine(string.format("[ikan laut] total=%d | cocok target=%d", #allList, #matched))
        for i = 1, math.min(#allList, 12) do
            local f = allList[i]
            logLine(string.format("  [%s] %s (jarak=%.0f)", f.rarity, f.kind, f.dist))
        end
        setNetStatus(string.format("Scan: %d cocok dari %d ikan di laut", #matched, #allList))
        logLine("== selesai ==")
    end)
end)

netOnceBtn.Activated:Connect(function()
    task.spawn(function()
        netHuntCycle(true)
    end)
end)

---------------------------------------------------------------- AUTO FISHING (Teleport / Move To ke Spot + 25% Luck)
local roundActionBtn = nil
local lastCastTapClock = 0

local function tapCastButtonOnce(btn)
    if os.clock() - lastCastTapClock < 0.35 then
        return false
    end
    lastCastTapClock = os.clock()
    return singleTapGui(btn)
end

local function findBottomRightActionButton(mode)
    local pg = lp:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local vp = getViewport()

    for _, d in ipairs(pg:GetDescendants()) do
        if not d:IsDescendantOf(gui) and (d:IsA("TextButton") or d:IsA("TextLabel")) then
            local txt = trim(d.Text):lower()
            if txt ~= "" and not txt:find("(", 1, true) and not txt:find("/", 1, true) and isGuiVisible(d) then
                local btnObj = d:IsA("GuiButton") and d or (d:FindFirstAncestorWhichIsA("GuiButton") or d)
                local center = btnObj.AbsolutePosition + (btnObj.AbsoluteSize / 2)

                if center.X > (vp.X * 0.60) and center.Y > (vp.Y * 0.50) then
                    if mode == "cast" and (txt == "cast" or txt == "cast!") then
                        roundActionBtn = btnObj
                        return btnObj
                    elseif mode == "reel" and (txt == "click fast!" or txt == "click fast") then
                        roundActionBtn = btnObj
                        return btnObj
                    end
                end
            end
        end
    end

    if roundActionBtn and roundActionBtn.Parent and isGuiVisible(roundActionBtn) then
        local center = roundActionBtn.AbsolutePosition + (roundActionBtn.AbsoluteSize / 2)
        if center.X > (vp.X * 0.60) and center.Y > (vp.Y * 0.50) then
            return roundActionBtn
        end
    end

    return nil
end

local function getActiveChargeLuckPercent()
    local pg = lp:FindFirstChild("PlayerGui")
    if not pg then return nil end

    local chargeLabel = nil
    for _, d in ipairs(pg:GetDescendants()) do
        if not d:IsDescendantOf(gui) and d:IsA("TextLabel") then
            if trim(d.Text):lower() == "charge" and isGuiVisible(d) then
                chargeLabel = d
                break
            end
        end
    end

    if not chargeLabel then return nil end

    local chargePos = chargeLabel.AbsolutePosition
    for _, d in ipairs(pg:GetDescendants()) do
        if not d:IsDescendantOf(gui) and d:IsA("TextLabel") and d ~= chargeLabel then
            local txt = trim(d.Text):lower()
            if txt:find("luck", 1, true) and not txt:find("500", 1, true) and isGuiVisible(d) then
                local dist = (d.AbsolutePosition - chargePos).Magnitude
                if dist < 180 then
                    local num = tonumber(txt:match("(%d+)%%"))
                    if num then return num end
                end
            end
        end
    end

    return nil
end

local function isReelUIActive()
    local pg = lp:FindFirstChild("PlayerGui")
    if not pg then return false end
    for _, d in ipairs(pg:GetDescendants()) do
        if not d:IsDescendantOf(gui) and (d:IsA("TextLabel") or d:IsA("TextButton")) then
            local txt = trim(d.Text):lower()
            if (txt:find("reel it in", 1, true) or txt == "click fast!") and isGuiVisible(d) then
                return true
            end
        end
    end
    return false
end

local function setFishStatus(msg)
    fishStatusLbl.Text = "Status Fish: " .. msg
end

local function fishCycle(forceOnce)
    if isSelling or isFishing then return end
    local hrp = getHRP()
    local hum = getHum()
    if not (hrp and hum and hum.Health > 0) then return end

    isFishing = true

    local ok, err = pcall(function()
        if savedFishPos then
            local flatDist = Vector2.new(savedFishPos.X - hrp.Position.X, savedFishPos.Z - hrp.Position.Z).Magnitude
            if flatDist > 6 then
                setFishStatus((fishTpOn and "Teleport" or "Move To") .. " ke spot mancing...")
                moveToTarget(savedFishPos, fishTpOn, 4.0, 3.0)
            end
        end

        local rod = equipToolByKeys(splitKeys(rodKeysBox.Text))
        if not rod then
            setFishStatus("Rod tidak ditemukan di tas!")
            task.wait(1)
            return
        end

        if not isReelUIActive() then
            local targetLuck = math.clamp(tonumber(targetLuckBox.Text) or 25, 1, 100)
            local castBtn = findBottomRightActionButton("cast")
            local curLuck = getActiveChargeLuckPercent()

            if curLuck == nil then
                setFishStatus("Tap CAST 1x memunculkan bar...")
                if castBtn then
                    tapCastButtonOnce(castBtn)
                else
                    pcall(function() rod:Activate() end)
                end

                local appearStart = os.clock()
                while alive and (fishOn or forceOnce) and (os.clock() - appearStart) < 1.8 do
                    curLuck = getActiveChargeLuckPercent()
                    if curLuck ~= nil or isReelUIActive() then break end
                    RunService.Heartbeat:Wait()
                end
            end

            if curLuck ~= nil and not isReelUIActive() then
                local seekStart = os.clock()
                local peakLuck = curLuck
                local nilFrames = 0

                while alive and (fishOn or forceOnce) and (os.clock() - seekStart) < 6.0 do
                    local pct = getActiveChargeLuckPercent()
                    if pct ~= nil then
                        nilFrames = 0
                        if pct > peakLuck then peakLuck = pct end
                        setFishStatus(string.format("Mencari %d%% Luck... (+%d%%)", targetLuck, pct))

                        local hitTarget = (pct >= targetLuck)
                        local hitPeak = (peakLuck >= (targetLuck - 1) and pct < peakLuck and (os.clock() - seekStart) > 0.25)

                        if hitTarget or hitPeak then
                            local fireBtn = findBottomRightActionButton("cast") or roundActionBtn
                            if fireBtn then
                                tapCastButtonOnce(fireBtn)
                            else
                                pcall(function() rod:Activate() end)
                            end
                            logLine(string.format("[fish] Lempar kail pada +%d%% Luck", pct))
                            setFishStatus(string.format("Dilempar pada +%d%% Luck!", pct))
                            task.wait(0.45)
                            break
                        end
                    else
                        nilFrames = nilFrames + 1
                        if nilFrames > 15 or isReelUIActive() then break end
                    end
                    RunService.Heartbeat:Wait()
                end
            end
        end

        local biteTimeout = math.clamp(tonumber(biteWaitBox.Text) or 25, 5, 60)
        local waitStart = os.clock()
        local gotBite = false

        setFishStatus("Menunggu ikan menyambar...")
        while alive and (fishOn or forceOnce) and (os.clock() - waitStart) < biteTimeout do
            if isReelUIActive() then
                gotBite = true
                break
            end
            if (os.clock() - waitStart) > 2.5 then
                if getActiveChargeLuckPercent() ~= nil or findBottomRightActionButton("cast") then
                    break
                end
            end
            task.wait(0.06)
        end

        if not gotBite then
            setFishStatus("Belum menyambar / ulang cast...")
            return
        end

        logLine("[fish] Ikan dapat! Tap tombol bulat kanan bawah...")
        setFishStatus("REEL IT IN! Tap tombol kanan bawah...")
        local reelStart = os.clock()
        local tapDelay = math.clamp(tonumber(tapDelayBox.Text) or 0.03, 0.015, 0.25)

        while alive and (fishOn or forceOnce) and (os.clock() - reelStart) < 35 do
            if not isReelUIActive() then break end
            local reelBtn = findBottomRightActionButton("reel") or roundActionBtn
            if reelBtn then singleTapGui(reelBtn) end
            task.wait(tapDelay)
        end

        logLine("[fish] Ikan didapat! Looping cast 25% lagi...")
        setFishStatus("Ikan didapat! Menyiapkan cast berikutnya...")
        task.wait(0.85)
    end)

    if not ok then logLine("[fish] error: " .. tostring(err)) end
    isFishing = false
end

task.spawn(function()
    while alive do
        if fishOn and not isSelling and not isFishing then
            fishCycle(false)
        end
        task.wait(0.12)
    end
end)

fishOnceBtn.Activated:Connect(function()
    task.spawn(function() fishCycle(true) end)
end)

---------------------------------------------------------------- Sell Modal & Auto Sell (Teleport / Move To / Remote)
local function findSellAllElement()
    local pg = lp:FindFirstChild("PlayerGui")
    if not pg then return nil end
    for _, d in ipairs(pg:GetDescendants()) do
        if not d:IsDescendantOf(gui) and (d:IsA("TextButton") or d:IsA("TextLabel")) then
            local txt = trim(d.Text):lower()
            if txt:find("sell all", 1, true) and isGuiVisible(d) then
                return d
            end
        end
    end
    return nil
end

local function closeSellModal(sellEl)
    if not sellEl then return end
    local rootGui = sellEl:FindFirstAncestorWhichIsA("ScreenGui")
    if not rootGui then return end
    for _, d in ipairs(rootGui:GetDescendants()) do
        if (d:IsA("TextButton") or d:IsA("TextLabel")) and isGuiVisible(d) then
            local txt = trim(d.Text):lower()
            if txt == "x" then
                singleTapGui(d)
                break
            end
        end
    end
end

local function clickSellAllAndClose(waitTimeout)
    local startT = os.clock()
    local limit = waitTimeout or 1.5
    local sellEl = nil

    while alive and (os.clock() - startT) < limit do
        sellEl = findSellAllElement()
        if sellEl then break end
        task.wait(0.05)
    end

    if not sellEl then return false end

    local labelTxt = trim(sellEl.Text)
    task.wait(0.1)
    singleTapGui(sellEl)
    logLine("[sell] Klik tombol: " .. labelTxt)
    task.wait(0.35)
    closeSellModal(sellEl)
    return true
end

local capturedRemote = nil
local capturedArgs = nil
local recordingRemote = false
local hookInstalled = false

local function installRemoteHook()
    if hookInstalled then return true end
    if not (hookmetamethod and getnamecallmethod) then return false end
    local ok = pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local isExec = checkcaller and checkcaller() or false
            if recordingRemote and not isExec and (method == "FireServer" or method == "InvokeServer") then
                if typeof(self) == "Instance" and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
                    local full = self:GetFullName():lower()
                    if not full:find("character") and not full:find("control") and not full:find("camera") then
                        capturedRemote = self
                        capturedArgs = { ... }
                        recordingRemote = false
                        task.spawn(function()
                            logLine("[rekam] TERTANGKAP: " .. self:GetFullName())
                        end)
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
    end)
    if ok then hookInstalled = true end
    return ok
end

recSellBtn.Activated:Connect(function()
    if not installRemoteHook() then
        logLine("[rekam] Executor tidak mendukung hookmetamethod.")
        return
    end
    recordingRemote = true
    logLine("[rekam] AKTIF 12 detik! Buka penjual & klik SELL ALL 1x...")
    task.delay(12, function()
        if recordingRemote then
            recordingRemote = false
            logLine("[rekam] Waktu habis, tidak ada remote terekam.")
        end
    end)
end)

local function findSellRemotes()
    local keys = splitKeys(sellKeys.Text)
    local found = {}
    for _, container in ipairs({ ReplicatedStorage, workspace }) do
        for _, d in ipairs(container:GetDescendants()) do
            if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
                local full = d:GetFullName():lower()
                if hit(full, keys) and not full:find("tokenshop") and not full:find("fishermanshop") then
                    found[#found + 1] = d
                end
            end
        end
    end
    return found
end

local function findNearestSellerPrompt()
    local keys = splitKeys(sellKeys.Text)
    local hrp = getHRP()
    if not hrp then return nil end
    local best, bestDist = nil, math.huge
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then
            local p = d.Parent
            if hit(d.ActionText, keys) or hit(d.ObjectText, keys) or hit(d.Name, keys)
                or (p and hit(p:GetFullName(), keys)) then
                local pos = getObjectPos(d)
                if pos then
                    local dist = (pos - hrp.Position).Magnitude
                    if dist < bestDist then
                        best = d
                        bestDist = dist
                    end
                end
            end
        end
    end
    return best, bestDist
end

local function fireRemoteObj(rem, args)
    if not (rem and rem.Parent) then return false end
    args = args or {}
    if rem:IsA("RemoteEvent") then
        return pcall(function() rem:FireServer(table.unpack(args)) end)
    elseif rem:IsA("RemoteFunction") then
        task.spawn(function()
            pcall(function() rem:InvokeServer(table.unpack(args)) end)
        end)
        return true
    end
    return false
end

local function executeAutoSell()
    if isSelling then return end

    if not sellRemoteMode then
        while alive and (isDigging or isFishing or isNetting) do
            task.wait(0.1)
        end
    end

    isSelling = true

    local ok, err = pcall(function()
        if clickSellAllAndClose(0.1) then return end

        if sellRemoteMode then
            if capturedRemote and capturedRemote.Parent then
                fireRemoteObj(capturedRemote, capturedArgs)
                logLine("[sell] Remote SELL ALL dipicu -> " .. capturedRemote.Name)
                return
            end

            local sellerPP = findNearestSellerPrompt()
            if sellerPP then
                fireOne(sellerPP)
                if clickSellAllAndClose(0.8) then return end
            end

            local rems = findSellRemotes()
            if #rems > 0 then
                for _, r in ipairs(rems) do
                    fireRemoteObj(r, {})
                    fireRemoteObj(r, { "SellAll" })
                end
                logLine("[sell] Memicu " .. #rems .. " remote sell")
            else
                logLine("[sell] Jarak NPC dibatasi server. Ubah ke Mode Ke Penjual atau Rekam Remote.")
            end
        else
            local sellerPP, dist = findNearestSellerPrompt()
            if not sellerPP then
                logLine("[sell] Prompt penjual tidak ditemukan.")
                return
            end
            local pos = getObjectPos(sellerPP)
            if pos then
                local modeTxt = sellTpOn and "Teleport" or "Move To"
                logLine(string.format("[sell] %s ke penjual (jarak=%.0f)...", modeTxt, dist))
                stopGlide()
                if moveToTarget(pos, sellTpOn, 5.5, 3.0) then
                    task.wait(0.2)
                    fireOne(sellerPP)
                    clickSellAllAndClose(2.0)
                end
            end
        end
    end)

    if not ok then logLine("[sell] error: " .. tostring(err)) end
    isSelling = false
end

sellNowBtn.Activated:Connect(function() task.spawn(executeAutoSell) end)

task.spawn(function()
    while alive do
        local waitSec = math.max(3, tonumber(sellEvery.Text) or 30)
        task.wait(waitSec)
        if sellOn and alive then executeAutoSell() end
    end
end)

---------------------------------------------------------------- Auto Dig (Filter Zona Kerang: Workspace.KerangSand.Sand_ZoneX)
local function isDiggingUIActive()
    local pg = lp:FindFirstChild("PlayerGui")
    if not pg then return false end
    for _, d in ipairs(pg:GetDescendants()) do
        if not d:IsDescendantOf(gui) and d:IsA("TextLabel") then
            local txt = tostring(d.Text or ""):lower()
            if txt:find("digging", 1, true) and isGuiVisible(d) then
                return true
            end
        end
    end
    return false
end

local function waitForDigComplete(pp, allowOnce)
    local timeout = math.clamp(tonumber(digMaxWait.Text) or 12, 2, 60)
    local startT = os.clock()

    local uiAppeared = false
    while alive and (digOn or allowOnce) and (os.clock() - startT) < 0.8 do
        if isDiggingUIActive() then uiAppeared = true break end
        if not (pp and pp.Parent and pp.Enabled) then return true end
        task.wait(0.05)
    end

    if not uiAppeared then return false end

    isDigging = true
    logLine("[dig] menggali, menunggu 100%...")

    while alive and (digOn or allowOnce) and (os.clock() - startT) < timeout do
        local hrp = getHRP()
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
        if not isDiggingUIActive() then break end
        if not (pp and pp.Parent and pp.Enabled) then break end
        task.wait(0.1)
    end

    task.wait(0.3)
    isDigging = false
    return true
end

local function getSandZoneName(inst, kerangFolder)
    local curr = inst
    while curr and curr ~= workspace do
        if kerangFolder and curr.Parent == kerangFolder then
            return curr.Name
        end
        if curr.Name:lower():find("sand_zone", 1, true) then
            return curr.Name
        end
        curr = curr.Parent
    end
    return (inst.Parent and inst.Parent.Name) or "Sand_Zone"
end

local function matchesClamZone(inst, zoneName, rawFilter)
    local f = trim(rawFilter):lower()
    if f == "" or f == "all" or f == "semua" or f == "*" then
        return true
    end

    local znPadded = zoneName:lower() .. " "
    local fullPadded = inst:GetFullName():lower() .. " "
    local objPadded = (inst:IsA("ProximityPrompt") and tostring(inst.ObjectText or ""):lower() or "") .. " "

    for token in f:gmatch("[^,]+") do
        token = trim(token)
        if token ~= "" then
            if token:match("^%d+$") then
                local pat1 = "sand_zone" .. token .. "[^%d]"
                local pat2 = "zone[_%s]*" .. token .. "[^%d]"
                if znPadded:match(pat1) or znPadded:match(pat2)
                    or fullPadded:match(pat1) or fullPadded:match(pat2)
                    or objPadded:match(pat2) then
                    return true
                end
            else
                if znPadded:find(token, 1, true)
                    or fullPadded:find(token, 1, true)
                    or objPadded:find(token, 1, true) then
                    return true
                end
            end
        end
    end
    return false
end

local function findPrompts(keys, ignoreZoneFilter)
    local list = {}
    local kerangFolder = workspace:FindFirstChild("KerangSand")
    local root = kerangFolder or workspace
    local rawZone = zoneFilter.Text
    local n = 0

    for _, d in ipairs(root:GetDescendants()) do
        n = n + 1
        if n % 5000 == 0 then task.wait() end
        if d:IsA("ProximityPrompt") then
            local p = d.Parent
            local inKerangFolder = (kerangFolder ~= nil)
            local matchKey = inKerangFolder
                or hit(d.ActionText, keys)
                or hit(d.ObjectText, keys)
                or hit(d.Name, keys)
                or (p and hit(p.Name, keys))

            if matchKey then
                local zName = getSandZoneName(d, kerangFolder)
                if ignoreZoneFilter or matchesClamZone(d, zName, rawZone) then
                    list[#list + 1] = d
                end
            end
        end
    end
    return list
end

local function nearbyPrompts()
    local keys = splitKeys(digKeysText)
    local hrp = getHRP()
    if not hrp then return {} end
    local kerangFolder = workspace:FindFirstChild("KerangSand")
    local res = {}
    for _, pp in ipairs(findPrompts(keys, false)) do
        if pp.Parent and pp.Enabled then
            local pos = getObjectPos(pp)
            if pos then
                local d = (pos - hrp.Position).Magnitude
                if digRadiusNum <= 0 or d <= digRadiusNum then
                    res[#res + 1] = {
                        pp = pp,
                        d = d,
                        pos = pos,
                        zoneName = getSandZoneName(pp, kerangFolder)
                    }
                end
            end
        end
    end
    table.sort(res, function(a, b) return a.d < b.d end)
    return res
end

local function digCycle(forceOnce)
    if isSelling or isDigging or isFishing or isNetting then return 0, 0 end
    if isDiggingUIActive() then
        waitForDigComplete(nil, forceOnce)
        return 1, 1
    end

    local hrp = getHRP()
    local hum = getHum()
    if not (hrp and hum and hum.Health > 0) then return 0, 0 end

    local list = nearbyPrompts()
    local zoneDesc = formatZoneDisplay(zoneFilter.Text)
    if #list == 0 then
        digStatusLbl.Text = string.format("Status Dig: %s | Menunggu spawn (0)", zoneDesc)
        return 0, 0
    end

    local target = list[1]
    local pp = target.pp
    local pos = getObjectPos(pp) or target.pos
    local zoneName = target.zoneName

    digStatusLbl.Text = string.format("Status Dig: %s | Aktif: %d (jarak=%.0f)", zoneName, #list, target.d)

    if pp ~= lastTarget then
        lastTarget = pp
        local modeTxt = digTpOn and "Teleport" or "Move To"
        logLine(string.format("[target] (%s) %s (%s) jarak=%.0f", modeTxt, zoneName, pp.ObjectText, target.d))
    end

    local flatDist = Vector2.new(pos.X - hrp.Position.X, pos.Z - hrp.Position.Z).Magnitude
    if flatDist > 6 and (digTpOn or glideOn) then
        local arrived = moveToTarget(pos, digTpOn, 5.5, 3.0)
        if not arrived or isSelling or (not digOn and not forceOnce) then
            return 0, #list
        end
    end

    local tool = nil
    if toolOn then
        tool = equipToolByKeys(splitKeys(toolKeysText))
    end

    local ok = fireOne(pp)
    if ok then
        if tool and tool.Parent == getChar() then
            pcall(function() tool:Activate() end)
        end
        waitForDigComplete(pp, forceOnce)
    end

    return ok and 1 or 0, #list
end

task.spawn(function()
    local lastWarn = 0
    while alive do
        local every = math.max(0.2, tonumber(digEvery.Text) or 0.3)
        if digOn and not isSelling and not isDigging and not isFishing and not isNetting then
            local ok, did, total = pcall(digCycle, false)
            if ok then
                if total == 0 and os.clock() - lastWarn > 6 then
                    lastWarn = os.clock()
                    logLine("[dig] menunggu spot pasir di " .. formatZoneDisplay(zoneFilter.Text) .. "...")
                end
            else
                logLine("[dig] error: " .. tostring(did))
                task.wait(1)
            end
        end
        task.wait(every)
    end
end)

onceBtn.Activated:Connect(function()
    task.spawn(function()
        local ok, did, total = pcall(digCycle, true)
        if ok then logLine(string.format("[tes %s] aktif=%d, dipicu=%d", formatZoneDisplay(zoneFilter.Text), total, did)) end
    end)
end)

---------------------------------------------------------------- Deep Scan
scanBtn.Activated:Connect(function()
    task.spawn(function()
        logLine("== DEEP SCAN ==")
        local kerangFolder = workspace:FindFirstChild("KerangSand")
        local allRows = findPrompts(splitKeys(digKeysText), true)
        local zoneStats = {}
        local zoneNames = {}
        for _, pp in ipairs(allRows) do
            local z = getSandZoneName(pp, kerangFolder)
            if not zoneStats[z] then
                zoneStats[z] = { total = 0, active = 0 }
                zoneNames[#zoneNames + 1] = z
            end
            zoneStats[z].total = zoneStats[z].total + 1
            if pp.Enabled then
                zoneStats[z].active = zoneStats[z].active + 1
            end
        end
        table.sort(zoneNames)
        logLine("[KerangSand] total spot=" .. #allRows .. " | zona=" .. #zoneNames)
        for _, z in ipairs(zoneNames) do
            logLine(string.format("  %s: aktif=%d / %d", z, zoneStats[z].active, zoneStats[z].total))
        end

        local rareFishes = scanAllSeaFishes(false)
        logLine("[IkanHidupRender rare] cocok=" .. #rareFishes)

        local sellerPP, sDist = findNearestSellerPrompt()
        if sellerPP then
            logLine(string.format("[penjual] %s jarak=%.0f", sellerPP.Name, sDist))
        end

        local sRems = findSellRemotes()
        logLine("[remote shell/sell] cocok=" .. #sRems)
        for i = 1, math.min(#sRems, 5) do
            logLine("  R " .. sRems[i]:GetFullName())
        end
        logLine("== selesai ==")
    end)
end)

---------------------------------------------------------------- Speed & Anti AFK
local baseSpeed = nil
speedBtn.Activated:Connect(function()
    speedOn = not speedOn
    setToggle(speedBtn, "Speed Jalan: ", speedOn)
    if not speedOn then
        local hum = getHum()
        if hum and baseSpeed then pcall(function() hum.WalkSpeed = baseSpeed end) end
        baseSpeed = nil
    end
end)
table.insert(conns, RunService.Heartbeat:Connect(function()
    if not speedOn then return end
    local hum = getHum()
    if not hum then return end
    if not baseSpeed then baseSpeed = hum.WalkSpeed end
    local v = math.clamp(tonumber(speedVal.Text) or 40, 1, 300)
    if hum.WalkSpeed ~= v then hum.WalkSpeed = v end
end))

table.insert(conns, lp.Idled:Connect(function()
    if not afkOn then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
end))
task.spawn(function()
    while alive do
        task.wait(240)
        if afkOn and alive then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0, 0))
            end)
        end
    end
end)

---------------------------------------------------------------- Tutup
local function cleanup()
    alive = false
    stopGlide()
    isDigging = false
    isFishing = false
    isNetting = false
    local hum = getHum()
    if hum and baseSpeed then pcall(function() hum.WalkSpeed = baseSpeed end) end
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(function() gui:Destroy() end)
    env.AutoDigCleanup = nil
end
closeBtn.Activated:Connect(cleanup)
env.AutoDigCleanup = cleanup
logLine("Siap! Auto Dig terkunci ke KerangSand dengan default Zona 8 (Sand_Zone8).")