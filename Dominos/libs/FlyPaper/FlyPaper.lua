--[[
	FlyPaper
		Functionality for sticking one frame to another frame

	Methods:
		FlyPaper.Stick(frame, otherFrame, tolerance, xOff, yOff) - Attempts to attach <frame> to <otherFrame>
			tolerance - how close the frames need to be to attach
			xOff - how close, horizontally, the frames should be attached
			yOff - how close, vertically, the frames should be attached

		FlyPaper.StickToPoint(frame, otherFrame, point, xOff, yOff) - attempts to anchor <frame> to a specific point on <otherFrame>
			point - any non nil return value of FlyPaper.Stick
--]]

--[[
		This work is in the Public Domain. To view a copy of the public domain certification, 
		visit http://creativecommons.org/licenses/publicdomain/ or send a letter to Creative Commons, 
		171 Second Street, Suite 300, San Francisco, California, 94105, USA.
--]]

--[[ library stuff ]]--
local VERSION = 3
if FlyPaper and tonumber(FlyPaper.version) and tonumber(FlyPaper.version) >= VERSION then 
	return 
end

if not FlyPaper then
	FlyPaper = {version = VERSION}
else
	FlyPaper.version = VERSION
end

--returns true if <frame>, or one of the frames that <frame> is dependent on, is anchored to <otherFrame>.  Returns nil otherwise.
local function FrameIsDependentOnFrame(frame, otherFrame)
	if (frame and otherFrame) then
		if frame == otherFrame then 
			return true 
		end
		local points = frame:GetNumPoints()
		for i = 1, points do
			local parent = select(2, frame:GetPoint(i))
			if FrameIsDependentOnFrame(parent, otherFrame) then
				return true
			end
		end
	end
end

--returns true if its actually possible to attach the two frames without error
local function CanAttach(frame, otherFrame)
	if not(frame and otherFrame) then
		return
	elseif frame:GetNumPoints() == 0 or otherFrame:GetNumPoints() == 0 then
		return
	elseif frame:GetWidth() == 0 or frame:GetHeight() == 0 or otherFrame:GetWidth() == 0 or otherFrame:GetHeight() == 0 then
		return
	elseif FrameIsDependentOnFrame(otherFrame, frame) then
		return
	end
	return true
end

--[[ Attachment Functions ]]--
local function WithinRange(value, otherValue, tolerance)
	return ((value >= otherValue - tolerance and value <= otherValue + tolerance) or nil)
end

local function smallest(tableWithNumbers)
	local index
	local small = math.huge
	for i, b in pairs(tableWithNumbers) do
		if b and b < small then
			small, index = b, i
		end
	end
	return index
end

local points = {
	TL = "TopLeft",
	TC = "Top",
	TR = "TopRight",
	BL = "BottomLeft",
	BC = "Bottom",
	BR = "BottomRight",
	LB = "BottomLeft",
	LC = "Left",
	LT = "TopLeft",
	RB = "BottomRight",
	RC = "Right",
	RT = "TopRight",
}

local opposite = {
	--needed for legacy compatibility 
	TL = "BOTTOMLEFT",
	TC = "BOTTOM",
	TR = "BOTTOMRIGHT",
	BL = "TOPLEFT",
	BC = "TOP",
	BR = "TOPRIGHT",
	LB = "BOTTOMRIGHT",
	LC = "RIGHT",
	LT = "TOPRIGHT",
	RB = "BOTTOMLEFT",
	RC = "LEFT",
	RT = "TOPLEFT",
}

local function Convert(a, b)
	if (a == "R") or (a == "L") or (a == "C") then
		return b..a
	else
		return a..b
	end
end

--[[ Usable Functions ]]--
function FlyPaper.Stick(frame, otherFrame, tolerance, xOff, yOff)
	local xOff = xOff or 0
	local yOff = yOff or 0

	if not CanAttach(frame, otherFrame) then 
		return 
	end

	--get anchoring points
	local left = frame:GetLeft()
	local right = frame:GetRight()
	local top = frame:GetTop()
	local bottom = frame:GetBottom()
	local centerX, centerY = frame:GetCenter()

	if left and right and top and bottom and centerX then
		local oScale = otherFrame:GetScale()
		left = left / oScale
		right = right / oScale
		top = top / oScale
		bottom = bottom /oScale
		centerX = centerX / oScale
		centerY = centerY / oScale
	else return end

	local oLeft = otherFrame:GetLeft()
	local oRight = otherFrame:GetRight()
	local oTop = otherFrame:GetTop()
	local oBottom = otherFrame:GetBottom()
	local oCenterX, oCenterY = otherFrame:GetCenter()

	if oLeft and oRight and oTop and oBottom and oCenterX then
		local scale = frame:GetScale()
		oCenterX = oCenterX / scale
		oCenterY = oCenterY / scale
		oLeft = oLeft / scale
		oRight = oRight / scale
		oTop = oTop / scale
		oBottom = oBottom / scale
	else return end

	--[[ Start Attempting to Anchor <frame> to <otherFrame> ]]--
	local horiAnchor, oHoriAnchor, vertAnchor, oVertAnchor
	local x = smallest({
		LtoL = WithinRange(left, oLeft, tolerance) and math.abs(left - oLeft),
		LtoC = WithinRange(left, oCenterX, tolerance) and math.abs(left - oCenterX),
		LtoR = WithinRange(left, oRight, tolerance) and math.abs(left - oRight),
		CtoL = WithinRange(centerX, oLeft, tolerance) and math.abs(centerX - oLeft),
		CtoC = WithinRange(centerX, oCenterX, tolerance) and math.abs(centerX - oCenterX),
		CtoR = WithinRange(centerX, oRight, tolerance) and math.abs(centerX - oRight),
		RtoL = WithinRange(right, oLeft, tolerance) and math.abs(right - oLeft),
		RtoC = WithinRange(right, oCenterX, tolerance) and math.abs(right - oCenterX),
		RtoR = WithinRange(right, oRight, tolerance) and math.abs(right - oRight)
	})
	local y = smallest({
		TtoT = WithinRange(top, oTop, tolerance) and math.abs(top - oTop),
		TtoC = WithinRange(top, oCenterY, tolerance) and math.abs(top - oCenterY),
		TtoB = WithinRange(top, oBottom, tolerance) and math.abs(top - oBottom),
		CtoT = WithinRange(centerY, oTop, tolerance) and math.abs(centerY - oTop),
		CtoC = WithinRange(centerY, oCenterY, tolerance) and math.abs(centerY - oCenterY),
		CtoB = WithinRange(centerY, oBottom, tolerance) and math.abs(centerY - oBottom),
		BtoT = WithinRange(bottom, oTop, tolerance) and math.abs(bottom - oTop),
		BtoC = WithinRange(bottom, oCenterY, tolerance) and math.abs(bottom - oCenterY),
		BtoB = WithinRange(bottom, oBottom, tolerance) and math.abs(bottom - oBottom),
	})
	if x and y then
		local a, _, b = string.split("to", y)
		local c, _, d = string.split("to", x) 
		local anchors = {
			T = "Top",
			C = "",
			B = "Bottom",
			L = "Left",
			R = "Right",
		}	
		frame:ClearAllPoints()
		local A, C = anchors[a], anchors[c]
		local B, D = anchors[b], anchors[d]
		if (A ~= C and B ~= D and A..C ~= B..D and A ~= B..D) or otherFrame:GetName() == "UIParent" then
			--prevent bars from snapping inside of each other. example: topleft to topleft (unless you are snapping to UIParent!)
			frame:SetPoint(A..C, otherFrame, B..D, 0, 0)		
			return Convert(a, c), Convert(b, d)
		end
	end
end

function FlyPaper.StickToPoint(frame, otherFrame, point, otherPoint, xOff, yOff) --do we really need the offsets? will take some effort to work with this implementation
	local xOff = xOff or 0
	local yOff = yOff or 0
	if otherPoint == "" then
		otherPoint = nil
	end
	--check to make sure its actually possible to attach the frames
	if not(point and CanAttach(frame, otherFrame)) then 
		return 
	end

	--[[ Start Attempting to Anchor <frame> to <otherFrame> ]]--
	frame:ClearAllPoints()
	if points[point] then
		if otherPoint then
			local otherPoint = points[otherPoint] or opposite[point]
			frame:SetPoint(points[point], otherFrame, otherPoint, 0, 0)
			return point
		else
			--legacy compatibility
			local otherPoint = opposite[point]
			frame:SetPoint(otherPoint, otherFrame, points[point], 0, 0)
			return point
		end
	end
end
