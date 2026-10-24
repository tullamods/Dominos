local _, Addon = ...

local ScrollableContainerMixin = {}

ScrollableContainerMixin.scrollBarX = -10
ScrollableContainerMixin.scrollBarHideIfUnscrollable = true
ScrollableContainerMixin.scrollBarHideTrackIfThumbExceedsTrack = true
ScrollableContainerMixin.scrollBarTemplate = "MinimalScrollBar"

function ScrollableContainerMixin:SetContent(content)
	self:SetScrollChild(content)
	self:SetHorizontalScroll(0)
	self:SetVerticalScroll(0)
	self:MarkDirty()
end

function ScrollableContainerMixin:GetContent()
	return self:GetScrollChild()
end

function ScrollableContainerMixin:SetHideIfUnscrollable(hide)
	self.ScrollBar:SetHideIfUnscrollable(hide)
	return self
end

function ScrollableContainerMixin:SetHideTrackIfThumbExceedsTrack(hide)
	self.ScrollBar:SetHideTrackIfThumbExceedsTrack(hide)
	return self
end

function ScrollableContainerMixin:SetScrollBarOffsets(left, top, bottom)
	left = left or SCROLL_FRAME_SCROLL_BAR_OFFSET_LEFT
	top = top or SCROLL_FRAME_SCROLL_BAR_OFFSET_TOP
	bottom = bottom or SCROLL_FRAME_SCROLL_BAR_OFFSET_BOTTOM

	self.ScrollBar:SetPoint("TOPLEFT", self, "TOPRIGHT", left, top)
	self.ScrollBar:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", left, bottom)
	return self
end

function Addon:CreateScrollableContainer(parent)
	local frame = CreateFrame('ScrollFrame', nil, parent, 'ResizeLayoutFrame')

	Mixin(frame, ScrollableContainerMixin)

	ScrollFrame_OnLoad(frame)

	frame.ScrollBar:HookScript('OnShow', function()
		if frame.fixedWidth then
			local content = frame:GetScrollChild()

			content.fixedWidth = frame.fixedWidth + (frame.scrollBarX - 4)

			if content.MarkDirty then
				content:MarkDirty()
			end

			frame:MarkDirty()
		end
	end)

	frame.ScrollBar:HookScript('OnHide', function()
		if frame.fixedWidth then
			local content = frame:GetScrollChild()

			content.fixedWidth = frame.fixedWidth

			if content.MarkDirty then
				content:MarkDirty()
			end

			frame:MarkDirty()
		end
	end)

	return frame
end
