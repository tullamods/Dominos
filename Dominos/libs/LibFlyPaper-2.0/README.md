# FlyPaper

A library for finding the closest points between regions, usually for anchoring

## Examples

```lua
local FlyPaper = LibStub("FlyPaper-2.0")

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

-- returns the nearest points between frame and the closest registered frame
local point, relFrame, relPoint, x, y, distance = FlyPaper.GetBestAnchor(frame, [tolerance, xOff, yOff])

-- returns the nearest points between frame and the closest frame in groupName
local point, relFrame, relPoint, x, y, distance = FlyPaper.GetBestAnchorForGroup(frame, groupName, [tolerance, xOff, yOff])

-- returns the nearest points between frame and relFrame
local point, relPoint, x, y, distance = FlyPaper.GetBestAnchorForFrame(frame, relFrame, [tolerance, xOff, yOff])

-- returns the nearest relative point on any registrered frame to point on frrame
local relFrame, relPoint, x, y, distance = FlyPaper.GetBestAnchorToPoint(frame, point, [tolerance, xOff, yOff])

-- returns the nearest relative point on any frame within group to point on frrame
local relFrame, relPoint, x, y, distance = FlyPaper.GetBestAnchorToPointForGroup(frame, groupName, [tolerance, xOff, yOff])

-- returns the nearest relative point on relFrame to point on frrame
local relPoint, x, y, distance = FlyPaper.GetBestAnchorToPointForFrame(frame, point, relFrame, [tolerance, xOff, yOff])

-- returns the nearest anchor to the frame's parent
local point, relPoint, x, y, distance = FlyPaper.GetBestAnchorForParent(frame, [tolerance, xOff, yOff])

-- returns the nearest anchor for point to the frame's parent
local relPoint, x, y, distance = FlyPaper.GetBestAnchorToPointForParent(frame, point, [tolerance, xOff, yOff])

-- returns the nearest point on frame relative to the position of the mouse cursor
-- relPoint is BOTTOMLEFT
local point, relPoint, x, y, distance = FlyPaper.GetBestAnchorToParentGridPoint(frame, xScale, yScale, [tolerance, xOff, yOff])

-- returns the nearest point on frame relative to the position of the mouse cursor
-- relFrame is UIParent, relPoint is BOTTOMLEFT
local point, relFrame, relPoint, x, y, distance = FlyPaper.GetNearestPointToCursor(frame, [tolerance, xOff, yOff])

-- sets scale while keeping frame in the same relative place
local changed = FlyPaper.SetScale(frame, scale)

-- returns true if frame is anchored to a frame other than its parent and false otherwise
local hasAnchor = FlyPaper.IsAnchored(frame)

-- Attempts to anchor frame to a specific anchor point on otherFrame
-- point: any non nil return value of FlyPaper.Stick
-- xOff: horizontal spacing to include between each frame
-- yOff: vertical spacing to include between each frame
-- returns an anchor point if attached and nil otherwise
local anchor = FlyPaper.StickToAnchor(frame, otherFrame, anchor, [xOff, yOff])

-- Iterates through all frames registered with FlyPaper and anchors to the
-- closest one that is within tolerance distance, if it exists
local anchor, group, id = FlyPaper.StickToClosestFrame(frame, [tolerance, xOff, yOff])

-- Iterates through all frames registered with FlyPaper within the specified
-- group and anchors to the closest one that is within tolerance distance
-- if it exists
local anchor, id = FlyPaper.StickToClosestFrameInGroup(frame, groupName, [tolerance, xOff, yOff])

-- registers the frame with FlyPaper
local registered = FlyPaper.AddFrame(groupName, id, frame)

-- unregisters the frame with flypaper
local uregistered = FlyPaper.RemoveFrame(groupName, id)

-- retrieves the specified frame, if it exists
local frame = FlyPaper.GetFrame(groupName, id)

-- retrieves the group information for the specified frame, if it exists
local groupName, id = FlyPaper.GetFrameInfo(frame)

--------------------------------------------------------------------------------
-- Callbacks
--------------------------------------------------------------------------------

local owner = {}

FlyPaper.AddCallback(owner, 'OnAddFrame')
FlyPaper.AddCallback(owner, 'OnRemoveFrame')

-- called when a frame is registered with FlyPaper
-- frame: what frame was added
-- group: the group the frame was added to
-- id: the id of the frame within the group
function owner:OnAddFrame(msg, frame, groupName, id) end

-- called when a frame is unregistered from FlyPaper
-- frame: what frame was removed
-- group: the group the frame was removed to from
-- id: the id of the frame within the group
function owner:OnRemoveFrame(msg, frame, groupName, id) end
```
