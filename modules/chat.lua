pfUI:RegisterModule("chat", 20400, function ()
  local panelfont = C.panel.use_unitfonts == "1" and pfUI.font_unit or pfUI.font_default
  local panelfont_size = C.panel.use_unitfonts == "1" and C.global.font_unit_size or C.global.font_size

  local default_border = C.appearance.border.default
  if C.appearance.border.chat ~= "-1" then
    default_border = C.appearance.border.chat
  end

  _G.CHAT_FONT_HEIGHTS = { 8, 10, 12, 14, 16, 18, 20 }


  -- add dropdown menu button to ignore player
  UnitPopupButtons["IGNORE_PLAYER"] = { text = IGNORE_PLAYER, dist = 0 }
  for index,value in ipairs(UnitPopupMenus["FRIEND"]) do
    if value == "GUILD_LEAVE" then
      table.insert(UnitPopupMenus["FRIEND"], index+1, "IGNORE_PLAYER")
    end
  end

  hooksecurefunc("UnitPopup_OnClick", function(self)
    if this.value == "IGNORE_PLAYER" then
      AddIgnore(_G[UIDROPDOWNMENU_INIT_MENU].name)
    end
  end)

  pfUI.chat = CreateFrame("Frame",nil,UIParent)

  pfUI.chat.left = CreateFrame("Frame", "pfChatLeft", UIParent)
  pfUI.chat.left.OnMove = function()
    pfUI.chat:RefreshChat()
  end

  pfUI.chat.left:SetFrameStrata("BACKGROUND")
  pfUI.chat.left:SetWidth(C.chat.left.width)
  pfUI.chat.left:SetHeight(C.chat.left.height)
  pfUI.chat.left:SetPoint("BOTTOMLEFT", 5,5)
  pfUI.chat.left:SetScript("OnShow", function() pfUI.chat:RefreshChat() end)
  UpdateMovable(pfUI.chat.left)
  CreateBackdrop(pfUI.chat.left, default_border, nil, .8)
  if C.chat.global.custombg == "1" then
    local r, g, b, a = strsplit(",", C.chat.global.background)
    pfUI.chat.left.backdrop:SetBackdropColor(tonumber(r), tonumber(g), tonumber(b), tonumber(a))

    local r, g, b, a = strsplit(",", C.chat.global.border)
    pfUI.chat.left.backdrop:SetBackdropBorderColor(tonumber(r), tonumber(g), tonumber(b), tonumber(a))
  end

  pfUI.chat.left.panelTop = CreateFrame("Frame", "leftChatPanelTop", pfUI.chat.left)
  pfUI.chat.left.panelTop:ClearAllPoints()
  pfUI.chat.left.panelTop:SetHeight(C.global.font_size+default_border*2)
  pfUI.chat.left.panelTop:SetPoint("TOPLEFT", pfUI.chat.left, "TOPLEFT", default_border, -default_border)
  pfUI.chat.left.panelTop:SetPoint("TOPRIGHT", pfUI.chat.left, "TOPRIGHT", -default_border, -default_border)
  if C.chat.global.tabdock == "1" then
    CreateBackdrop(pfUI.chat.left.panelTop, default_border, nil, .8)
  end

  pfUI.chat.URLPattern = {
    WWW = {
      ["rx"]=" (www%d-)%.([_A-Za-z0-9-]+)%.(%S+)%s?",
      ["fm"]="%s.%s.%s"},
    PROTOCOL = {
      ["rx"]=" (%a+)://(%S+)%s?",
      ["fm"]="%s://%s"},
    EMAIL = {
      ["rx"]=" ([_A-Za-z0-9-%.:]+)@([_A-Za-z0-9-]+)(%.)([_A-Za-z0-9-]+%.?[_A-Za-z0-9-]*)%s?",
      ["fm"]="%s@%s%s%s"},
    PORTIP = {
      ["rx"]=" (%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?):(%d%d?%d?%d?%d?)%s?",
      ["fm"]="%s.%s.%s.%s:%s"},
    IP = {
      ["rx"]=" (%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%s?",
      ["fm"]="%s.%s.%s.%s"},
    SHORTURL = {
      ["rx"]=" (%a+)%.(%a+)/(%S+)%s?",
      ["fm"]="%s.%s/%s"},
    URLIP = {
      ["rx"]=" ([_A-Za-z0-9-]+)%.([_A-Za-z0-9-]+)%.(%S+)%:([_0-9-]+)%s?",
      ["fm"]="%s.%s.%s:%s"},
    URL = {
      ["rx"]=" ([_A-Za-z0-9-]+)%.([_A-Za-z0-9-]+)%.(%S+)%s?",
      ["fm"]="%s.%s.%s"},
  }

  pfUI.chat.URLFuncs = {
    ["WWW"] = function(a1,a2,a3) return pfUI.chat:FormatLink(pfUI.chat.URLPattern.WWW.fm,a1,a2,a3) end,
    ["PROTOCOL"] = function(a1,a2) return pfUI.chat:FormatLink(pfUI.chat.URLPattern.PROTOCOL.fm,a1,a2) end,
    ["EMAIL"] = function(a1,a2,a3,a4) return pfUI.chat:FormatLink(pfUI.chat.URLPattern.EMAIL.fm,a1,a2,a3,a4) end,
    ["PORTIP"] = function(a1,a2,a3,a4,a5) return pfUI.chat:FormatLink(pfUI.chat.URLPattern.PORTIP.fm,a1,a2,a3,a4,a5) end,
    ["IP"] = function(a1,a2,a3,a4) return pfUI.chat:FormatLink(pfUI.chat.URLPattern.IP.fm,a1,a2,a3,a4) end,
    ["SHORTURL"] = function(a1,a2,a3) return pfUI.chat:FormatLink(pfUI.chat.URLPattern.SHORTURL.fm,a1,a2,a3) end,
    ["URLIP"] = function(a1,a2,a3,a4) return pfUI.chat:FormatLink(pfUI.chat.URLPattern.URLIP.fm,a1,a2,a3,a4) end,
    ["URL"] = function(a1,a2,a3) return pfUI.chat:FormatLink(pfUI.chat.URLPattern.URL.fm,a1,a2,a3) end,
  }

  -- url copy dialog
  function pfUI.chat:FormatLink(formatter,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10)
    if not (formatter and a1) then return end
    local newtext = string.format(formatter,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10)

    -- check the last capture index for consecutive trailing dots (invalid top level domain)
    local invalidtld
    for _, arg in pairs({a10,a9,a8,a7,a6,a5,a4,a3,a2,a1}) do
      if arg then
        invalidtld = string.find(arg, "(%.%.)$")
        break
      end
    end

    if (invalidtld) then return newtext end
    if formatter == self.URLPattern.EMAIL.fm then -- email parser
      local colon = string.find(a1,":")
      if (colon) and string.len(a1) > colon then
        if not (string.sub(a1,1,6) == "mailto") then
          local prefix,address = string.sub(newtext,1,colon),string.sub(newtext,colon+1)
          return string.format(" %s|cffccccff|Hurl:%s|h[%s]|h|r ",prefix,address,address)
        end
      end
    end
    return " |cffccccff|Hurl:" .. newtext .. "|h[" .. newtext .. "]|h|r "
  end

  pfUI.chat.urlcopy = CreateFrame("Frame", "pfURLCopy", UIParent)
  pfUI.chat.urlcopy:Hide()
  pfUI.chat.urlcopy:SetWidth(270)
  pfUI.chat.urlcopy:SetHeight(65)
  pfUI.chat.urlcopy:SetFrameStrata("FULLSCREEN")
  pfUI.chat.urlcopy:SetPoint("CENTER", 0, 0)
  CreateBackdrop(pfUI.chat.urlcopy, nil, nil, 0.8)

  pfUI.chat.urlcopy:SetMovable(true)
  pfUI.chat.urlcopy:EnableMouse(true)
  pfUI.chat.urlcopy:SetScript("OnMouseDown",function()
    this:StartMoving()
  end)

  pfUI.chat.urlcopy:SetScript("OnMouseUp",function()
    this:StopMovingOrSizing()
  end)

  pfUI.chat.urlcopy:SetScript("OnShow", function()
    this.text:HighlightText()
  end)

  pfUI.chat.urlcopy.text = CreateFrame("EditBox", "pfURLCopyEditBox", pfUI.chat.urlcopy)
  pfUI.chat.urlcopy.text:SetTextColor(.2,1,.8,1)
  pfUI.chat.urlcopy.text:SetJustifyH("CENTER")

  pfUI.chat.urlcopy.text:SetWidth(250)
  pfUI.chat.urlcopy.text:SetHeight(20)
  pfUI.chat.urlcopy.text:SetPoint("TOP", pfUI.chat.urlcopy, "TOP", 0, -10)
  pfUI.chat.urlcopy.text:SetFontObject(GameFontNormal)
  CreateBackdrop(pfUI.chat.urlcopy.text)

  pfUI.chat.urlcopy.text:SetScript("OnEscapePressed", function(self)
    pfUI.chat.urlcopy:Hide()
  end)

  pfUI.chat.urlcopy.text:SetScript("OnEditFocusLost", function(self)
    pfUI.chat.urlcopy:Hide()
  end)

  pfUI.chat.urlcopy.close = CreateFrame("Button", "pfURLCopyClose", pfUI.chat.urlcopy, "UIPanelButtonTemplate")
  pfUI.api.SkinButton(pfUI.chat.urlcopy.close)
  pfUI.chat.urlcopy.close:SetWidth(70)
  pfUI.chat.urlcopy.close:SetHeight(18)
  pfUI.chat.urlcopy.close:SetPoint("BOTTOMRIGHT", pfUI.chat.urlcopy, "BOTTOMRIGHT", -10, 10)

  pfUI.chat.urlcopy.close:SetText(T["Close"])
  pfUI.chat.urlcopy.close:SetScript("OnClick", function()
    pfUI.chat.urlcopy:Hide()
  end)

  pfUI.chat.urlcopy.SetItemRef = SetItemRef
  pfUI.chat.urlcopy.CopyText = function(text)
    pfUI.chat.urlcopy.text:SetText(text)
    pfUI.chat.urlcopy:Show()
  end

  function _G.SetItemRef(link, text, button)
    if (strsub(link, 1, 3) == "url") then
      if string.len(link) > 4 and string.sub(link,1,4) == "url:" then
        pfUI.chat.urlcopy.CopyText(string.sub(link,5, string.len(link)))
      end
      return
    end
    pfUI.chat.urlcopy.SetItemRef(link, text, button)
  end

  pfUI.chat.right = CreateFrame("Frame", "pfChatRight", UIParent)
  pfUI.chat.right:SetFrameStrata("BACKGROUND")
  pfUI.chat.right:SetWidth(C.chat.right.width)
  pfUI.chat.right:SetHeight(C.chat.right.height)
  pfUI.chat.right:SetPoint("BOTTOMRIGHT", -5,5)
  pfUI.chat.right:SetScript("OnShow", function() pfUI.chat:RefreshChat() end)
  UpdateMovable(pfUI.chat.right)
  CreateBackdrop(pfUI.chat.right, default_border, nil, .8)
  if C.chat.global.custombg == "1" then
    local r, g, b, a = strsplit(",", C.chat.global.background)
    pfUI.chat.right.backdrop:SetBackdropColor(tonumber(r), tonumber(g), tonumber(b), tonumber(a))

    local r, g, b, a = strsplit(",", C.chat.global.border)
    pfUI.chat.right.backdrop:SetBackdropBorderColor(tonumber(r), tonumber(g), tonumber(b), tonumber(a))
  end

  pfUI.chat.right.panelTop = CreateFrame("Frame", "rightChatPanelTop", pfUI.chat.right)
  pfUI.chat.right.panelTop:ClearAllPoints()
  pfUI.chat.right.panelTop:SetHeight(C.global.font_size+default_border*2)
  pfUI.chat.right.panelTop:SetPoint("TOPLEFT", pfUI.chat.right, "TOPLEFT", default_border, -default_border)
  pfUI.chat.right.panelTop:SetPoint("TOPRIGHT", pfUI.chat.right, "TOPRIGHT", -default_border, -default_border)
  if C.chat.global.tabdock == "1" then
    CreateBackdrop(pfUI.chat.right.panelTop, default_border, nil, .8)
  end

  pfUI.chat:RegisterEvent("PLAYER_ENTERING_WORLD")
  pfUI.chat:RegisterEvent("UI_SCALE_CHANGED")

  local function ChatOnMouseWheel()
    if (arg1 > 0) then
      if IsShiftKeyDown() then
        this:ScrollToTop()
      else
        for i=1, C.chat.global.scrollspeed do
          this:ScrollUp()
        end
      end
    elseif (arg1 < 0) then
      if IsShiftKeyDown() then
        this:ScrollToBottom()
      else
        for i=1, C.chat.global.scrollspeed do
          this:ScrollDown()
        end
      end
    end
  end

  function pfUI.chat:RefreshChat()
    local panelheight = C.global.font_size+default_border*5

    if C.chat.global.sticky == "1" then
      ChatTypeInfo.WHISPER.sticky = 1
      ChatTypeInfo.OFFICER.sticky = 1
      ChatTypeInfo.RAID_WARNING.sticky = 1
      ChatTypeInfo.CHANNEL.sticky = 1
    end

    ChatFrameMenuButton:Hide()
    ChatMenu:SetClampedToScreen(true)
    CreateBackdrop(ChatMenu)
    CreateBackdrop(EmoteMenu)
    CreateBackdrop(LanguageMenu)
    CreateBackdrop(VoiceMacroMenu)

    for i=1, NUM_CHAT_WINDOWS do
      local frame = _G["ChatFrame"..i]
      local tab = _G["ChatFrame"..i.."Tab"]

      if not frame.pfStartMoving then
        frame.pfStartMoving = frame.StartMoving
        frame.StartMoving = function(a1)
          pfUI.chat.hideLock = true
          frame.pfStartMoving(a1)
        end
      end

      if not frame.pfStopMovingOrSizing then
        frame.pfStopMovingOrSizing = frame.StopMovingOrSizing
        frame.StopMovingOrSizing = function(a1)
          frame.pfStopMovingOrSizing(a1)
          pfUI.chat.RefreshChat()
          pfUI.chat.hideLock = false
        end
      end

      if C.chat.global.fadeout == "1" then
        frame:SetFading(true)
        frame:SetTimeVisible(tonumber(C.chat.global.fadetime))
      else
        frame:SetFading(false)
      end

      if i == 3 and C.chat.right.enable == "1" then
        -- Loot & Spam
        local bottompadding = pfUI.panel and not pfUI_config.position["pfPanelRight"] and panelheight or default_border
        tab:SetParent(pfUI.chat.right.panelTop)
        frame:SetParent(pfUI.chat.right)
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", pfUI.chat.right ,"TOPLEFT", default_border, -panelheight)
        frame:SetPoint("BOTTOMRIGHT", pfUI.chat.right ,"BOTTOMRIGHT", -default_border, bottompadding)
        frame:Show()
      elseif i == 2 and C.chat.global.combathide == "1" then
        -- Combat Log
        FCF_UnDockFrame(frame)
        FCF_Close(frame)
      elseif frame.isDocked then
        -- Left Chat
        local bottompadding = pfUI.panel and not pfUI_config.position["pfPanelLeft"] and panelheight or default_border
        FCF_DockFrame(frame)
        tab:SetParent(pfUI.chat.left.panelTop)
        frame:SetParent(pfUI.chat.left)
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", pfUI.chat.left ,"TOPLEFT", default_border, -panelheight)
        frame:SetPoint("BOTTOMRIGHT", pfUI.chat.left ,"BOTTOMRIGHT", -default_border, bottompadding)
      else
        FCF_UnDockFrame(frame)
        frame:SetParent(UIParent)
        tab:SetParent(UIParent)
      end

      -- hide textures
      for j,v in ipairs({tab:GetRegions()}) do
        if j==5 then v:SetTexture(0,0,0,0) end
        v:SetHeight(C.global.font_size+default_border*2)
      end

      _G["ChatFrame" .. i .. "ResizeBottom"]:Hide()
      _G["ChatFrame" .. i .. "TabText"]:SetJustifyV("CENTER")
      _G["ChatFrame" .. i .. "TabText"]:SetHeight(C.global.font_size+default_border*2)
      _G["ChatFrame" .. i .. "TabText"]:SetPoint("BOTTOM", 0, default_border)
      _G["ChatFrame" .. i .. "TabLeft"]:SetAlpha(0)
      _G["ChatFrame" .. i .. "TabMiddle"]:SetAlpha(0)
      _G["ChatFrame" .. i .. "TabRight"]:SetAlpha(0)

      if C.chat.global.chatflash == "1" then
        _G["ChatFrame" .. i .. "TabFlash"]:SetAllPoints(_G["ChatFrame" .. i .. "TabText"])
      else
        _G["ChatFrame" .. i .. "TabFlash"].Show = function() return end
      end

      local _, class = UnitClass("player")
      _G["ChatFrame" .. i .. "TabText"]:SetTextColor(RAID_CLASS_COLORS[class].r + .3 * .5, RAID_CLASS_COLORS[class].g + .3 * .5, RAID_CLASS_COLORS[class].b + .3 * .5, 1)
      _G["ChatFrame" .. i .. "TabText"]:SetFont(panelfont,panelfont_size, "OUTLINE")

      if _G["ChatFrame" .. i].isDocked or _G["ChatFrame" .. i]:IsVisible() then
        _G["ChatFrame" .. i .. "Tab"]:Show()
      end

      frame:EnableMouseWheel(true)
      frame:SetScript("OnMouseWheel", ChatOnMouseWheel)
    end

    -- update dock frame for all windows
    for index, value in pairs(DOCKED_CHAT_FRAMES) do
      FCF_UpdateButtonSide(value)
    end
  end

  hooksecurefunc("FCF_SaveDock", pfUI.chat.RefreshChat)

  if C.chat.global.tabmouse == "1" then
    pfUI.chat.mouseovertab = CreateFrame("Frame")
    pfUI.chat.mouseovertab:SetScript("OnUpdate", function()

      if pfUI.chat.hideLock then return end

      if MouseIsOver(pfUI.chat.left, 10, -10, -10, 10) then
        pfUI.chat.left.panelTop:Show()
        FCF_DockUpdate()
      elseif MouseIsOver(pfUI.chat.right, 10, -10, -10, 10) then
        pfUI.chat.right.panelTop:Show()
        FCF_DockUpdate()
      else
        pfUI.chat.left.panelTop:Hide()
        pfUI.chat.right.panelTop:Hide()
      end
    end)
  end

  function pfUI.chat.SetupRightChat(state)
    if state then
      C.chat.right.enable = "1"
      pfUI.chat.right:Show()
    else
      C.chat.right.enable = "0"
      pfUI.chat.right:Hide()
    end
  end

  function pfUI.chat.SetupPositions()
    -- close all chat windows
    for i=1, NUM_CHAT_WINDOWS do
      FCF_Close(_G["ChatFrame"..i])
      FCF_DockUpdate()
    end

    -- Main Window
    ChatFrame1:ClearAllPoints()
    ChatFrame1:SetPoint("TOPLEFT", pfUI.chat.left ,"TOPLEFT", 5, -25)
    ChatFrame1:SetPoint("BOTTOMRIGHT", pfUI.chat.left ,"BOTTOMRIGHT", -5, 25)

    FCF_SetLocked(ChatFrame1, 1)
    FCF_SetWindowName(ChatFrame1, GENERAL)
    FCF_SetWindowColor(ChatFrame1, 0, 0, 0)
    FCF_SetWindowAlpha(ChatFrame1, 0)
    FCF_SetChatWindowFontSize(ChatFrame1, 12)
    ChatFrame1:SetUserPlaced(1)

    -- Combat Log
    FCF_SetLocked(ChatFrame2, 1)
    FCF_SetWindowName(ChatFrame2, COMBAT_LOG)
    FCF_SetWindowColor(ChatFrame2, 0, 0, 0)
    FCF_SetWindowAlpha(ChatFrame2, 0)
    FCF_SetChatWindowFontSize(ChatFrame2, 12)
    ChatFrame2:SetUserPlaced(1)

    -- Loot & Spam
    if C.chat.right.enable == "1" then
      -- set position of Loot & Spam
      FCF_SetLocked(ChatFrame3, 1)
      FCF_SetWindowName(ChatFrame3, T["Loot & Spam"])
      FCF_SetWindowColor(ChatFrame3, 0, 0, 0)
      FCF_SetWindowAlpha(ChatFrame3, 0)
      FCF_SetChatWindowFontSize(ChatFrame3, 12)
      FCF_UnDockFrame(ChatFrame3)
      FCF_SetTabPosition(ChatFrame3, 0)
      ChatFrame3:ClearAllPoints()
      ChatFrame3:SetPoint("TOPLEFT", pfUI.chat.right ,"TOPLEFT", 5, -25)
      ChatFrame3:SetPoint("BOTTOMRIGHT", pfUI.chat.right ,"BOTTOMRIGHT", -5, 25)
      ChatFrame3:SetUserPlaced(1)
    end

    pfUI.chat:RefreshChat()
    FCF_DockUpdate()
  end

  function pfUI.chat.SetupChannels()
    ChatFrame_RemoveAllMessageGroups(ChatFrame1)
    ChatFrame_RemoveAllMessageGroups(ChatFrame2)
    ChatFrame_RemoveAllMessageGroups(ChatFrame3)

    ChatFrame_RemoveAllChannels(ChatFrame1)
    ChatFrame_RemoveAllChannels(ChatFrame2)
    ChatFrame_RemoveAllChannels(ChatFrame3)

    local normalg = {"SYSTEM", "SAY", "YELL", "WHISPER", "PARTY", "GUILD", "CREATURE", "CHANNEL"}
    for _,group in pairs(normalg) do
      ChatFrame_AddMessageGroup(ChatFrame1, group)
    end

    ChatFrame_ActivateCombatMessages(ChatFrame2)

    if C.chat.right.enable == "1" then
      local spamg = { "COMBAT_XP_GAIN", "COMBAT_HONOR_GAIN", "COMBAT_FACTION_CHANGE", "SKILL", "LOOT" }
      for _,group in pairs(spamg) do
        ChatFrame_AddMessageGroup(ChatFrame3, group)
      end

      for _, chan in pairs({EnumerateServerChannels()}) do
        ChatFrame_AddChannel(ChatFrame3, chan)
        ChatFrame_RemoveChannel(ChatFrame1, chan)
      end

      JoinChannelByName("World")
      ChatFrame_AddChannel(ChatFrame3, "World")
    end
    pfUI.chat:RefreshChat()
  end

  pfUI.chat:SetScript("OnEvent", function()
    pfUI.chat:RefreshChat()
    FCF_DockUpdate()
    if C.chat.right.enable == "0" and C.chat.right.alwaysshow == "0" then
      pfUI.chat.right:Hide()
    end
  end)

  for i=1, NUM_CHAT_WINDOWS do
    _G["ChatFrame" .. i .. "UpButton"]:Hide()
    _G["ChatFrame" .. i .. "UpButton"].Show = function() return end
    _G["ChatFrame" .. i .. "DownButton"]:Hide()
    _G["ChatFrame" .. i .. "DownButton"].Show = function() return end
    _G["ChatFrame" .. i .. "BottomButton"]:Hide()
    _G["ChatFrame" .. i .. "BottomButton"].Show = function() return end
  end

  -- orig. function but removed flashing
  function _G.FCF_OnUpdate(elapsed)
    -- Need to draw the dock regions for a frame to define their rects
    if ( not ChatFrame1.init ) then
      for i=1, NUM_CHAT_WINDOWS do
        _G["ChatFrame"..i.."TabDockRegion"]:Show()
        FCF_UpdateButtonSide(_G["ChatFrame"..i])
      end
      ChatFrame1.init = 1
      return
    elseif ( ChatFrame1.init == 1 ) then
      for i=1, NUM_CHAT_WINDOWS do
        _G["ChatFrame"..i.."TabDockRegion"]:Hide()
      end
      ChatFrame1.init = 2
    end

    -- Detect if mouse is over any chat frames and if so show their tabs, if not hide them
    local chatFrame, chatTab

    if ( MOVING_CHATFRAME ) then
      -- Set buttons to the left or right side of the frame
      -- If the the side of the buttons changes and the frame is the default frame, then set every docked frames buttons to the same side
      local updateAllButtons = nil
      if (FCF_UpdateButtonSide(MOVING_CHATFRAME) and MOVING_CHATFRAME == DEFAULT_CHAT_FRAME ) then
        updateAllButtons = 1
      end
      local dockRegion
      for index, value in DOCKED_CHAT_FRAMES do
        if ( updateAllButtons ) then
          FCF_UpdateButtonSide(value)
        end

        dockRegion = _G[value:GetName().."TabDockRegion"]
        if ( MouseIsOver(dockRegion) and MOVING_CHATFRAME ~= DEFAULT_CHAT_FRAME ) then
          dockRegion:Show()
        else
          dockRegion:Hide()
        end
      end
    end

    -- If the default chat frame is resizing, then resize the dock
    if ( DEFAULT_CHAT_FRAME.resizing ) then
      FCF_DockUpdate()
    end
  end

  pfUI.chat.editbox = CreateFrame("Frame", "pfChatInputBox", UIParent)
  if C.chat.text.input_height == "0" then
    pfUI.chat.editbox:SetHeight(22)

    if ChatFrameEditBoxLanguage then
      pfUI.api.SkinButton(ChatFrameEditBoxLanguage)
      ChatFrameEditBoxLanguage:SetWidth(22)
      ChatFrameEditBoxLanguage:SetHeight(22)
    end
  else
    pfUI.chat.editbox:SetHeight(C.chat.text.input_height)

    if ChatFrameEditBoxLanguage then
      pfUI.api.SkinButton(ChatFrameEditBoxLanguage)
      ChatFrameEditBoxLanguage:SetWidth(C.chat.text.input_height)
      ChatFrameEditBoxLanguage:SetHeight(C.chat.text.input_height)
    end
  end

  -- to make sure the bars are set up properly, we need to wait.
  local pfChatArrangeFrame = CreateFrame("Frame", "pfChatArrange", UIParent)
  pfChatArrangeFrame:RegisterEvent("CVAR_UPDATE")
  pfChatArrangeFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  pfChatArrangeFrame:SetScript("OnEvent", function()
    pfUI.chat.editbox:ClearAllPoints()

    local anchor = pfUI.chat.left
    if pfUI.bars and pfUI.bars[6]:IsShown() then
      anchor = pfUI.bars[6]
    elseif pfUI.bars and pfUI.bars[1]:IsShown() then
      anchor = pfUI.bars[1]
    end

    if C.chat.text.input_width ~= "0" then
      pfUI.chat.editbox:SetPoint("BOTTOM", anchor, "TOP", 0, default_border*3)
      pfUI.chat.editbox:SetWidth(C.chat.text.input_width)
    else
      pfUI.chat.editbox:SetWidth(anchor:GetWidth())
      pfUI.chat.editbox:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, default_border*3)
      pfUI.chat.editbox:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", 0, default_border*3)
    end

    UpdateMovable(pfUI.chat.editbox)
  end)


  ChatFrameEditBox:SetParent(pfUI.chat.editbox)
  ChatFrameEditBox:SetAllPoints(pfUI.chat.editbox)
  CreateBackdrop(ChatFrameEditBox, default_border)

  for i,v in ipairs({ChatFrameEditBox:GetRegions()}) do
    if i==6 or i==7 or i==8 then v:Hide() end
    if v.SetFont then
      v:SetFont(pfUI.font_default, C.global.font_size + 1, "OUTLINE")
    end
  end
  ChatFrameEditBox:SetAltArrowKeyMode(false)

  if C.chat.text.mouseover == "1" then
    for i=1, NUM_CHAT_WINDOWS do
      local frame = _G["ChatFrame" .. i]
      frame:SetScript("OnHyperlinkEnter", function()
        local _, _, linktype = string.find(arg1, "^(.-):(.+)$")
        if linktype == "item" then
          GameTooltip:SetOwner(this, "ANCHOR_CURSOR")
          GameTooltip:SetHyperlink(arg1)
          GameTooltip:Show()
        end
      end)

      frame:SetScript("OnHyperlinkLeave", function()
        GameTooltip:Hide()
      end)
    end
  end

  -- read and parse whisper color settings
  local cr, cg, cb, ca = strsplit(",", C.chat.global.whisper)
  cr, cg, cb = tonumber(cr), tonumber(cg), tonumber(cb)
  local wcol = string.format("%02x%02x%02x",cr * 255,cg * 255, cb * 255)

  -- read and parse chat bracket settings
  local left = "|r" .. string.sub(C.chat.text.bracket, 1, 1)
  local right = string.sub(C.chat.text.bracket, 2, 2) .. "|r"

  -- read and parse chat time bracket settings
  local tleft = string.sub(C.chat.text.timebracket, 1, 1)
  local tright = string.sub(C.chat.text.timebracket, 2, 2)

  -- shorten chat channel indicators
  local default = " " .. "%s" .. "|r:" .. "\32"
  _G.CHAT_CHANNEL_GET = "%s" .. "|r:" .. "\32"
  _G.CHAT_GUILD_GET = left .. "G" .. right .. default
  _G.CHAT_OFFICER_GET = left .. "O" .. right .. default
  _G.CHAT_PARTY_GET = left .. "P" .. right .. default
  _G.CHAT_RAID_GET = left .. "R" .. right .. default
  _G.CHAT_RAID_LEADER_GET = left .. "RL" .. right .. default
  _G.CHAT_RAID_WARNING_GET = left .. "RW" .. right .. default
  _G.CHAT_BATTLEGROUND_GET = left .. "BG" .. right .. default
  _G.CHAT_BATTLEGROUND_LEADER_GET = left .. "BL" .. right .. default
  _G.CHAT_SAY_GET = left .. "S" .. right .. default
  _G.CHAT_YELL_GET = left .. "Y" .. right ..default

  if C.chat.global.whispermod == "1" then
    _G.CHAT_WHISPER_GET = '|cff' .. wcol .. '[W]' .. default
    _G.CHAT_WHISPER_INFORM_GET = '[W]' .. default
  end

  local r,g,b,a = strsplit(",", C.chat.text.timecolor)
  local timecolorhex = string.format("%02x%02x%02x%02x", a*255, r*255, g*255, b*255)

  local r,g,b = strsplit(",", C.chat.text.unknowncolor)
  local unknowncolorhex = string.format("%02x%02x%02x", r*255, g*255, b*255)

  for i=1,NUM_CHAT_WINDOWS do
    if not _G["ChatFrame"..i].HookAddMessage then
      _G["ChatFrame"..i].HookAddMessage = _G["ChatFrame"..i].AddMessage
      _G["ChatFrame"..i].AddMessage = function(frame, text, a1, a2, a3, a4, a5)
        if text then
          -- Remove prat's CLINK itemlinks.
          text = gsub(text, '%{CLINK:(%x%x%x%x%x%x%x%x):(%d*):(%d*):(%d*):(%d*):(.-)%}', function(color, id, enchant, suffix, uuid, name)
            return format('|c%s|Hitem:%s:%s:%s:%s|h[%s]|h|r', color, id, enchant, suffix, uuid, name)
          end)

          -- detect urls
          if C.chat.text.detecturl == "1" then
            local URLPattern = pfUI.chat.URLPattern
            text = string.gsub (text, URLPattern.WWW.rx, pfUI.chat.URLFuncs.WWW)
            text = string.gsub (text, URLPattern.PROTOCOL.rx, pfUI.chat.URLFuncs.PROTOCOL)
            text = string.gsub (text, URLPattern.EMAIL.rx, pfUI.chat.URLFuncs.EMAIL)
            text = string.gsub (text, URLPattern.PORTIP.rx, pfUI.chat.URLFuncs.PORTIP)
            text = string.gsub (text, URLPattern.IP.rx, pfUI.chat.URLFuncs.IP)
            text = string.gsub (text, URLPattern.SHORTURL.rx, pfUI.chat.URLFuncs.SHORTURL)
            text = string.gsub (text, URLPattern.URLIP.rx, pfUI.chat.URLFuncs.URLIP)
            text = string.gsub (text, URLPattern.URL.rx, pfUI.chat.URLFuncs.URL)
          end

          -- display class colors if already indexed
          if C.chat.text.classcolor == "1" then

            for name in gfind(text, "|Hplayer:(.-)|h") do
              local color = unknowncolorhex
              local match = false
              local class = GetUnitData(name)
              if class then
                if class ~= UNKNOWN then
                  color = string.format("%02x%02x%02x",
                    RAID_CLASS_COLORS[class].r * 255,
                    RAID_CLASS_COLORS[class].g * 255,
                    RAID_CLASS_COLORS[class].b * 255)
                  match = true
                end
              end

              if C.chat.text.tintunknown == "1" or match then
                text = string.gsub(text, "|Hplayer:"..name.."|h%["..name.."%]|h(.-:-)",
                    left.."|cff"..color.."|Hplayer:"..name.."|h" .. name .. "|h|r"..right.."%1")
              end
            end
          end

          -- reduce channel name to number
          if C.chat.text.channelnumonly == "1" then
            local channel = string.gsub(text, ".*%[(.-)%]%s+(.*|Hplayer).+", "%1")
            if string.find(channel, "%d+%. ") then
              channel = string.gsub(channel, "(%d+)%..*", "channel%1")
              channel = string.gsub(channel, "channel", "")
              text = string.gsub(text, "%[%d+%..-%]%s+(.*|Hplayer)", left .. channel .. right .. " %1")
            end
          end

          -- show timestamp in chat
          if C.chat.text.time == "1" then
            text = "|c" .. timecolorhex .. tleft .. date(C.chat.text.timeformat) .. tright .. "|r " .. text
          end

          if C.chat.global.whispermod == "1" then
            -- patch incoming whisper string to match the colors
            if string.find(text, '|cff'..wcol, 1) == 1 then
              text = string.gsub(text, "|r", "|r|cff" .. wcol)
            end
          end

          _G["ChatFrame"..i].HookAddMessage(frame, text, a1, a2, a3, a4, a5)
        end
      end
    end
  end

  -- create playerlinks on shift-click
  if C.chat.text.playerlinks == "1" then
    local pfHookSetItemRef = SetItemRef
    _G.SetItemRef = function(link, text, button)
      if ( strsub(link, 1, 6) == "player" ) then
        local name = strsub(link, 8)
        if ( name and (strlen(name) > 0) ) then
          name = gsub(name, "([^%s]*)%s+([^%s]*)%s+([^%s]*)", "%3");
          name = gsub(name, "([^%s]*)%s+([^%s]*)", "%2");
          if IsShiftKeyDown() and ChatFrameEditBox:IsVisible() then
            ChatFrameEditBox:Insert("|cffffffff|Hplayer:"..name.."|h["..name.."]|h|r")
            return
          end
        end
      end
      pfHookSetItemRef(link, text, button)
    end
  end
end)
