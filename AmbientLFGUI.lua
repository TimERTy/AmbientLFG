local _, ns = ...

local FRAME_WIDTH = 400
local FRAME_HEIGHT = 444 -- the raid role row costs the match list its height otherwise
local PADDING = 10
local ROW_HEIGHT = 24

local ui

local ROLE_ORDER = { "TANK", "HEALER", "DAMAGER" }
local ROLE_UI = {
	TANK = { label = "Tank", atlas = "roleicon-tiny-tank" },
	HEALER = { label = "Healer", atlas = "roleicon-tiny-healer" },
	DAMAGER = { label = "DPS", atlas = "roleicon-tiny-dps" },
}

-- The label sits outside the button's hit rect, so clicking the word did
-- nothing. A transparent button over the text forwards the click. The label
-- is parented to the button so it shows and hides with it.
local function attachLabel(cb, label)
	local text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	text:SetPoint("LEFT", cb, "RIGHT", 2, 0)
	text:SetText(label)
	local hit = CreateFrame("Button", nil, cb)
	hit:SetAllPoints(text)
	hit:SetScript("OnClick", function()
		cb:Click()
	end)
	cb.label = text
	return cb
end

-- Checkboxes ship at a different size from the surrounding controls, which
-- left adjacent rows sitting at different heights. One size for all of them;
-- the templates size their textures explicitly, so those have to be
-- re-anchored to follow the button.
local CONTROL_SIZE = 24

local function sizeControl(cb)
	cb:SetSize(CONTROL_SIZE, CONTROL_SIZE)
	for _, get in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture", "GetCheckedTexture", "GetDisabledTexture" }) do
		local tex = cb[get] and cb[get](cb)
		if tex then
			tex:ClearAllPoints()
			tex:SetAllPoints(cb)
		end
	end
	return cb
end

local function MakeCheckbox(parent, label, onClick)
	local cb = sizeControl(CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate"))
	cb:SetScript("OnClick", function(self)
		onClick(self:GetChecked() and true or false)
	end)
	return attachLabel(cb, label)
end

local function MakeButton(parent, label, width, onClick)
	local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	btn:SetSize(width, 22)
	btn:SetText(label)
	btn:SetScript("OnClick", onClick)
	return btn
end

local Refresh -- forward declaration

local function AcquireRow(f, i)
	f.rows = f.rows or {}
	local row = f.rows[i]
	if not row then
		row = CreateFrame("Frame", nil, f.scrollChild)
		row:SetHeight(ROW_HEIGHT)
		row:SetPoint("LEFT", f.scrollChild, "LEFT", 0, 0)
		row:SetPoint("RIGHT", f.scrollChild, "RIGHT", 0, 0)

		row.bg = row:CreateTexture(nil, "BACKGROUND")
		row.bg:SetAllPoints()

		row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		row.text:SetPoint("LEFT", row, "LEFT", 6, 0)
		row.text:SetPoint("RIGHT", row, "RIGHT", -28, 0)
		row.text:SetJustifyH("LEFT")
		row.text:SetWordWrap(false)

		row.block = CreateFrame("Button", nil, row, "UIPanelCloseButton")
		row.block:SetSize(20, 20)
		row.block:SetPoint("RIGHT", row, "RIGHT", -2, 0)
		row.block:SetScript("OnClick", function(self)
			if self.matchLeader then
				ns.BlockLeader(self.matchLeader)
				Refresh()
			end
		end)
		row.block:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(("Block %s — never alert for their groups again"):format(
				self.matchLeader or "this leader"))
			GameTooltip:Show()
		end)
		row.block:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		f.rows[i] = row
	end
	row:Show()
	return row
end

Refresh = function()
	if not ui or not ui:IsShown() then
		return
	end
	local db = ns.GetDB()
	if not db then
		return
	end

	ui.enabledCB:SetChecked(db.enabled)
	ui.soundCB:SetChecked(db.sound)
	ui.debugCB:SetChecked(db.debug)
	local seats = {}
	for _, role in ipairs(ROLE_ORDER) do
		if ns.GetWantedRoles()[role] then
			seats[#seats + 1] = CreateAtlasMarkup(ROLE_UI[role].atlas, 14, 14) .. " " .. ROLE_UI[role].label
		end
	end
	local category = ns.WatchedCategory()
	local dungeons = category == ns.Match.CATEGORY_DUNGEONS
	local raids = category == ns.Match.CATEGORY_RAIDS
	if not category then
		-- nothing is being watched, so there are no seats to speak of; the
		-- status line already says so and says what to do about it
		ui.rolesText:SetText("")
	elseif #seats > 0 then
		ui.rolesText:SetText(("Alerting on an open seat for |cffffd100%s|r — %s"):format(
			table.concat(seats, ", "),
			dungeons and "set in the Group Finder's Filter"
				or "the game has no role filter for raids, so this one is set below"))
	elseif dungeons then
		ui.rolesText:SetText("Alerting on |cffffd100every group|r the search returns — tick a \"role available\" box in the Group Finder's Filter to narrow it")
	else
		-- the Filter's role boxes go out with Dungeons searches only, so saying
		-- "tick one in the Filter" here would be advice that does nothing
		ui.rolesText:SetText("Alerting on |cffffd100every group|r the search returns — tick a role below to narrow it")
	end

	-- The raid role choice is the addon's own filter and applies to raid
	-- searches alone, so it is only on screen while one is being watched. A
	-- control that cannot affect the running search is one you set and then
	-- watch do nothing.
	local auto = ns.RaidRolesAreAuto()
	local raid = ns.GetRaidRoles()
	ui.raidAutoCB:SetShown(raids)
	ui.raidAutoCB:SetChecked(auto)
	for _, role in ipairs(ROLE_ORDER) do
		local cb = ui.raidRoleCB[role]
		cb:SetShown(raids)
		cb:SetChecked(raid[role] and true or false)
		cb:SetEnabled(not auto)
		cb.label:SetTextColor(auto and 0.5 or 1, auto and 0.5 or 1, auto and 0.5 or 1)
	end
	-- a hidden frame still anchors, so what follows would keep its gap
	ui.watchText:ClearAllPoints()
	ui.watchText:SetPoint("TOPLEFT", raids and ui.raidRoleCB[ROLE_ORDER[1]] or ui.rolesText,
		"BOTTOMLEFT", raids and -16 or 0, -8)
	ui.watchText:SetPoint("RIGHT", ui, "RIGHT", -PADDING, 0)
	if not ui.intervalBox:HasFocus() then
		ui.intervalBox:SetText(tostring(db.interval))
	end
	if not ui.ignoreBox:HasFocus() then
		ui.ignoreBox:SetText(table.concat(db.ignores or {}, ", "))
	end

	-- The watched search is the whole filter now, and it lives in the Group
	-- Finder rather than here, so the window has to say what it currently is —
	-- unsaid, it is invisible state that reads as the addon being broken. It
	-- names the search and nothing else: with no search there is nothing to
	-- name, and the status line already says so and says what to do about it.
	local watching = ns.GetWatchedSearch()
	local hint, narrowed = ns.RaidDifficultyHint()
	ui.watchText:SetText(watching
		and ("Watching |cffffd100%s|r"):format(watching)
			.. (hint and ("\n%s%s|r"):format(narrowed and "|cff66ff66" or "|cffffcc00", hint) or "")
		or "")

	-- live list of currently-listed groups; the opaque title tokens render as
	-- real text inside a FontString
	local matchStore = ns.GetMatches()
	local matchList = {}
	-- expire a match only when it was absent from NEWER search results;
	-- wall-clock aging made entries flicker out whenever the player stopped
	-- clicking (no clicks = no searches = nothing refreshing lastSeen)
	local lastResults = ns.GetStats().lastResultsAt or 0
	for key, m in pairs(matchStore) do
		-- A title is a token the client resolves as it draws it. Once the client
		-- has dropped the listing it can no longer resolve it and the row draws
		-- "Unknown" — and a listing the client has dropped is not a current
		-- match anyway, so it leaves the list rather than sitting there nameless.
		local info = m.resultID and C_LFGList.GetSearchResultInfo(m.resultID)
		local gone = not info or ns.Match.safeBool(info.isDelisted)
		if gone or lastResults - m.lastSeen > (db.interval or 10) + 5 then
			matchStore[key] = nil
		else
			matchList[#matchList + 1] = m
		end
	end
	table.sort(matchList, function(a, b) return a.lastSeen > b.lastSeen end)

	local y = 0
	for i, m in ipairs(matchList) do
		local row = AcquireRow(ui, i)
		row:SetPoint("TOP", ui.scrollChild, "TOP", 0, -y)
		y = y + ROW_HEIGHT
		row.bg:SetColorTexture(0.1, 0.25, 0.12, i % 2 == 0 and 0.35 or 0.15)
		local comp = ("%s%s %s%s %s%s"):format(
			CreateAtlasMarkup(ROLE_UI.TANK.atlas, 12, 12), m.tanks or "?",
			CreateAtlasMarkup(ROLE_UI.HEALER.atlas, 12, 12), m.healers or "?",
			CreateAtlasMarkup(ROLE_UI.DAMAGER.atlas, 12, 12), m.dps or "?")
		local activity = m.activity and ("|cffffd100%s|r "):format(m.activity) or ""
		-- the leader leads the row because it is the only part guaranteed to be
		-- real text; a title token the client has not resolved yet draws as
		-- "Unknown", and a row that says only that identifies nothing
		local who = ns.Match.shortName(m.leader)
		local title = (m.name and m.name ~= m.leader) and (" " .. m.name) or ""
		row.text:SetText(("%s  %s|cff9999ff%s|r%s"):format(comp, activity, who, title))
		row.block.matchLeader = m.leader
	end

	if ui.rows then
		for i = #matchList + 1, #ui.rows do
			ui.rows[i]:Hide()
		end
	end

	ui.emptyText:SetShown(#matchList == 0)
	ui.scrollChild:SetHeight(math.max(y, 1))

	local stats = ns.GetStats()
	local heartbeat = ""
	if stats.lastResultsAt then
		heartbeat = ("\nLast results: %ds ago (%d groups)"):format(
			math.max(0, math.floor(GetTime() - stats.lastResultsAt)),
			stats.lastResultCount or 0)
	end
	if stats.autoIssued > 0 then
		heartbeat = heartbeat .. (" | %d auto-searches"):format(stats.autoIssued)
	end
	local listed = ns.CannotSearchReason()
	if not db.enabled then
		ui.statusText:SetText("|cffff6666Off|r" .. heartbeat)
	elseif listed then
		-- a live listing stops watching whether or not a search was ever armed,
		-- so it answers before "search once to arm it", which cannot be done
		ui.statusText:SetText(("|cffffcc00Paused — %s|r"):format(listed) .. heartbeat)
	elseif not ns.IsArmed() then
		ui.statusText:SetText("|cffffcc00Idle — fill in the Group Finder's search box and search once to arm it|r" .. heartbeat)
	elseif stats.browsing then
		-- silence here reads as the addon being broken; it is deliberate
		ui.statusText:SetText("|cffffcc00Paused while the Group Finder is open|r — searching now would stomp the results you're looking at" .. heartbeat)
	elseif stats.suspended then
		ui.statusText:SetText("|cffff6666Suspended — searches keep failing (Group Finder not usable right now?). Untick and retick to retry.|r" .. heartbeat)
	elseif stats.backoffUntil and GetTime() < stats.backoffUntil then
		ui.statusText:SetText(("|cffff9933Search throttled — pausing %ds|r"):format(
			math.ceil(stats.backoffUntil - GetTime())) .. heartbeat)
	elseif stats.pending then
		ui.statusText:SetText("|cff66ff66Search queued — fires on your next click in the world|r" .. heartbeat)
	else
		ui.statusText:SetText(("|cff66ff66Watching — searches every %ds, on your next click|r"):format(db.interval) .. heartbeat)
	end
end

local function CreateUI()
	local f = CreateFrame("Frame", "AmbientLFGFrame", UIParent, "BackdropTemplate")
	f:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
	f:SetPoint("CENTER")
	f:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	f:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
	f:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
	f:SetFrameStrata("HIGH")
	f:SetMovable(true)
	f:SetClampedToScreen(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:Hide()

	local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOPLEFT", f, "TOPLEFT", PADDING, -PADDING)
	title:SetText("AmbientLFG")
	title:SetTextColor(1, 0.84, 0)

	local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
	close:SetScript("OnClick", function() f:Hide() end)

	-- Escape-to-close without UISpecialFrames: inserting there taints
	-- CloseSpecialWindows, which Blizzard's LFGList code calls while secure.
	-- Keyboard is fully disabled in combat because SetPropagateKeyboardInput
	-- is itself restricted during lockdown.
	f:SetScript("OnKeyDown", function(self, key)
		if InCombatLockdown() then
			return
		end
		if key == "ESCAPE" then
			self:SetPropagateKeyboardInput(false)
			self:Hide()
		else
			self:SetPropagateKeyboardInput(true)
		end
	end)
	f:SetScript("OnShow", function(self)
		self:EnableKeyboard(not InCombatLockdown())
		Refresh()
		self.refreshTicker = C_Timer.NewTicker(1, Refresh)
	end)
	f:SetScript("OnHide", function(self)
		if self.refreshTicker then
			self.refreshTicker:Cancel()
			self.refreshTicker = nil
		end
	end)
	f:RegisterEvent("PLAYER_REGEN_DISABLED")
	f:RegisterEvent("PLAYER_REGEN_ENABLED")
	f:SetScript("OnEvent", function(self, event)
		self:EnableKeyboard(event == "PLAYER_REGEN_ENABLED")
	end)

	-- One switch, not two: watching means searching. Enabled without
	-- auto-search saw only the searches the player ran by hand, in the window
	-- they were already looking at, which is the addon doing nothing.
	local getDb = ns.GetDB
	f.enabledCB = MakeCheckbox(f, "Watch every", function(checked)
		getDb().enabled = checked
		ns.restartTicker()
		Refresh()
	end)
	f.enabledCB:SetPoint("TOPLEFT", f, "TOPLEFT", PADDING, -30)

	f.intervalBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
	f.intervalBox:SetSize(36, 20)
	f.intervalBox:SetPoint("LEFT", f.enabledCB.label, "RIGHT", 10, 0)
	f.intervalBox:SetAutoFocus(false)
	f.intervalBox:SetNumeric(true)
	f.intervalBox:SetMaxLetters(3)
	local function commitInterval(self)
		local n = tonumber(self:GetText())
		if n and n >= 5 then
			getDb().interval = math.floor(n)
			ns.restartTicker()
		end
		Refresh()
	end
	f.intervalBox:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	f.intervalBox:SetScript("OnEditFocusLost", commitInterval)
	f.intervalBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

	local secText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	secText:SetPoint("LEFT", f.intervalBox, "RIGHT", 4, 0)
	secText:SetText("sec")

	f.soundCB = MakeCheckbox(f, "Sound", function(checked)
		getDb().sound = checked
	end)
	f.soundCB:SetPoint("LEFT", secText, "RIGHT", 16, 0)

	f.debugCB = MakeCheckbox(f, "Chat log", function(checked)
		getDb().debug = checked
	end)
	f.debugCB:SetPoint("LEFT", f.soundCB.label, "RIGHT", 16, 0)

	-- Which seats you can take is Blizzard's own "role available" filter,
	-- shown here rather than asked for again: a second copy of a setting can
	-- disagree with the first, and the disagreement matches nothing.
	f.rolesText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	f.rolesText:SetPoint("TOPLEFT", f.enabledCB, "BOTTOMLEFT", 0, -10)
	f.rolesText:SetPoint("RIGHT", f, "RIGHT", -PADDING, 0)
	f.rolesText:SetJustifyH("LEFT")
	f.rolesText:SetWordWrap(true)

	-- Raids have no role filter in the game, so this one is the addon's own —
	-- the only setting here with no Blizzard counterpart to disagree with. It
	-- follows the spec being played rather than storing a role, so it cannot go
	-- stale on a respec; pinning it is a deliberate second click.
	local function pinnedRaidRoles()
		local set = {}
		for role, on in pairs(ns.GetRaidRoles()) do
			set[role] = on and true or nil
		end
		return set
	end

	f.raidAutoCB = MakeCheckbox(f, "Raids: filter to my current spec's role", function(checked)
		-- unticking pins exactly what is on screen, so it changes nothing until
		-- a role is actually clicked
		ns.SetRaidRoles(not checked and pinnedRaidRoles() or nil)
		Refresh()
	end)
	f.raidAutoCB:SetPoint("TOPLEFT", f.rolesText, "BOTTOMLEFT", 0, -8)

	f.raidRoleCB = {}
	local prev
	for _, role in ipairs(ROLE_ORDER) do
		local cb = MakeCheckbox(f, ROLE_UI[role].label, function(checked)
			local set = pinnedRaidRoles()
			set[role] = checked or nil
			ns.SetRaidRoles(set)
			Refresh()
		end)
		if prev then
			cb:SetPoint("LEFT", prev.label, "RIGHT", 12, 0)
		else
			cb:SetPoint("TOPLEFT", f.raidAutoCB, "BOTTOMLEFT", 16, -2)
		end
		prev = cb
		f.raidRoleCB[role] = cb
	end

	-- What is being watched, above the list it produces
	f.watchText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	f.watchText:SetPoint("TOPLEFT", f.raidRoleCB[ROLE_ORDER[1]], "BOTTOMLEFT", -16, -8)
	f.watchText:SetPoint("RIGHT", f, "RIGHT", -PADDING, 0)
	f.watchText:SetJustifyH("LEFT")
	f.watchText:SetWordWrap(true)

	-- setting the search up is the one thing the player must do in Blizzard's
	-- own window, so the addon offers the door rather than describing it
	f.openGF = MakeButton(f, "Open Group Finder", 150, function()
		PVEFrame_ShowFrame("GroupFinderFrame", "LFGListPVEStub")
	end)
	f.openGF:SetPoint("TOPLEFT", f.watchText, "BOTTOMLEFT", 0, -8)

	local listHeader = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	listHeader:SetPoint("TOPLEFT", f.openGF, "BOTTOMLEFT", 0, -8)
	listHeader:SetText("Current matches")
	listHeader:SetTextColor(0.7, 0.7, 0.7)

	local listBg = CreateFrame("Frame", nil, f, "BackdropTemplate")
	listBg:SetPoint("TOPLEFT", listHeader, "BOTTOMLEFT", 0, -4)
	listBg:SetPoint("RIGHT", f, "RIGHT", -PADDING, 0)
	listBg:SetPoint("BOTTOM", f, "BOTTOM", 0, 70)
	listBg:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	listBg:SetBackdropColor(0, 0, 0, 0.4)
	listBg:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)

	local scrollFrame = CreateFrame("ScrollFrame", nil, listBg, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", listBg, "TOPLEFT", 4, -4)
	scrollFrame:SetPoint("BOTTOMRIGHT", listBg, "BOTTOMRIGHT", -24, 4)

	local scrollChild = CreateFrame("Frame", nil, scrollFrame)
	scrollChild:SetWidth(FRAME_WIDTH - PADDING * 2 - 32)
	scrollChild:SetHeight(1)
	scrollFrame:SetScrollChild(scrollChild)
	f.scrollChild = scrollChild

	f.emptyText = listBg:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	f.emptyText:SetPoint("CENTER")
	f.emptyText:SetText("No matching groups right now")
	f.emptyText:SetTextColor(0.5, 0.5, 0.5)

	-- Ignore words qualify every alert, so they sit below the list rather than
	-- inside the controls that decide what is searched.
	local ignoreLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	ignoreLabel:SetPoint("TOPLEFT", listBg, "BOTTOMLEFT", 0, -10)
	ignoreLabel:SetText("Ignore:")
	ignoreLabel:SetTextColor(0.7, 0.7, 0.7)

	f.ignoreBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
	f.ignoreBox:SetHeight(20)
	f.ignoreBox:SetPoint("LEFT", ignoreLabel, "RIGHT", 10, 0)
	f.ignoreBox:SetPoint("RIGHT", f, "RIGHT", -PADDING, 0)
	f.ignoreBox:SetAutoFocus(false)
	local function commitIgnores(self)
		local words = {}
		for word in (self:GetText() or ""):gmatch("[^,%s]+") do
			words[#words + 1] = word:lower()
		end
		getDb().ignores = words
		Refresh()
	end
	f.ignoreBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	f.ignoreBox:SetScript("OnEditFocusLost", commitIgnores)
	f.ignoreBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

	-- Footer: status + test
	f.statusText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	f.statusText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PADDING, 12)
	f.statusText:SetPoint("RIGHT", f, "RIGHT", -90, 0)
	f.statusText:SetJustifyH("LEFT")
	f.statusText:SetWordWrap(true)

	f.testButton = MakeButton(f, "Test alert", 74, function()
		ns.TestAlert()
	end)
	f.testButton:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PADDING, 8)

	return f
end

local function ToggleUI()
	if not ui then
		ui = CreateUI()
	end
	if ui:IsShown() then
		ui:Hide()
	else
		ui:Show()
	end
end
ns.ToggleUI = ToggleUI

-- Bare /alfg (or /alfg ui) opens the window; everything else falls through to
-- the core handler, then the open window refreshes to reflect it.
local origHandler = SlashCmdList.AMBIENTLFG
SlashCmdList.AMBIENTLFG = function(input)
	local trimmed = strtrim(input or ""):lower()
	if trimmed == "" or trimmed == "ui" then
		ToggleUI()
		return
	end
	origHandler(input)
	Refresh()
end
