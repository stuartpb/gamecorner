--[[---------------------------------------------------------------------------
-- Game Corner                                                               --
-- A VOLTORB Flip Probability Heatmap Generator                              --
-- Project Page: launchpad.net/gamecorner                                    --
---------------------------------------------------------------------------]]--

-------------------------------------------------------------------------------
-- C Libraries
-------------------------------------------------------------------------------

--Required for the interface (controls and whatnot).
require 'iuplua'
--Required for drawing the probability table.
require 'cdlua'

-- The library that allows for the interoperation of the two.
-- NOTICE! This MUST be included AFTER cdlua or else you will get WEIRD ERRORS
-- that don't report to Lua like the executable exiting with 0xC0000005.
require 'iupluacd'

-------------------------------------------------------------------------------
-- Game Corner modules
-------------------------------------------------------------------------------

--Basically everything hinges on the number of lines on a Voltorb Flip board,
--so I'm just making it a global before I require them rather than make
--every single module explicitly require it or define it
lines=5

--If we've got the filename the script was run with
if arg and arg[0] then
  --find the path to this file, if there is one
  local directory=(string.find(arg[0],[=[[/\][^/\]-$]=]))
  --If this script was run from some sort of path up to the script
  if directory then
    --make sure that all module operations start their search in this path
    package.path=';'..string.sub(arg[0],1,directory)..'?.lua'..package.path
  end
end

--Bring in the algorithm to calculate the probabilities
local calculate_probs = require "probabilities"

--Bring in the algorithm to calculate the colors from those probabilities
local generate_colors= require "coloring"

--Sizes are required for the construction of the canvas and layout
local sizes = require "settings.sizes"

--Bring in the drawing functions
local draw = require "drawing"

--Bring in the function to make the controls
local make_controls = require "controls"

--Bring in the Voltorb image used for the window icon
local voltorb_icon = require "images.voltorb"

--Bring in the window's menu
local menu = require "menu"

--Bring in the callbacks for the canvas
local cancb = require "canvas"
-------------------------------------------------------------------------------
-- "Constant" value definitions
-------------------------------------------------------------------------------

--Used for constructing the canvas and layout
local canvassize=(sizes.card+sizes.cardgap)*lines

local defaults={
  sum=5,
  voltorb=0
}

local dlgbgcolor
do
  --grab strings for dialog's red, green, and blue values
  local bgcolors={
    string.match(iup.GetGlobal"DLGBGCOLOR",
      "^(%d+) (%d+) (%d+)$")}

  --convert them to numbers
  for _, each in pairs(bgcolors) do each=tonumber(each) end

  --encode the color
  dlgbgcolor = cd.EncodeColor(unpack(bgcolors))
end

-------------------------------------------------------------------------------
-- Central table construction
-------------------------------------------------------------------------------

--Table for data for row and column sums and Voltorb counts.
local model={rows={},columns={}}
--initialize model data
for line=1, lines do
  for axisname, axis in pairs(model) do
    axis[line]={sum=defaults.sum, voltorb=defaults.voltorb}
  end
end

--table determined probabilities get stored in.
local probabilities={}

--table determined cards get stored in.
local cardcolors={}

--table of revealed cards
local revealed={}

--Table storing card selection info.
local selection={
  --Table storing the current information for the cursor state
  --in terms of card selection
  focus={},
  revealed=revealed
}

--Create all tables for each row and card.
for row=1,lines do

  probabilities[row]={}
  cardcolors[row]={}
  revealed[row]={}

  for col=1, lines do
    probabilities[row][col]={}
    cardcolors[row][col]={subsquares={}}
    --initialize all indices where values go
    do
      for sub=0,4 do
        if sub~=4 then --because 4 is for the center subsquare only
          probabilities[row][col][sub]=.25
          cardcolors[row][col][sub]=dlgbgcolor
        end
        cardcolors[row][col].subsquares[sub]=dlgbgcolor
      end
      cardcolors[row][col].overall=dlgbgcolor
    end
  end
end

-------------------------------------------------------------------------------
-- Central object construction
-------------------------------------------------------------------------------

-- Canvas Creation
local iupcanvas=iup.canvas{
  rastersize=sizes.wxh(canvassize,canvassize),
  bgcolor=iup.GetGlobal"DLGBGCOLOR", border="NO",
  cx=sizes.margin,
  cy=sizes.margin}

--Declare variables for buffers that are initialized
--after the canvas is mapped.
local frontbuffer,backbuffer

--Function that updates the heatmap whenver the values change.
local function updateheatmap()
  calculate_probs(model,revealed,probabilities)
  generate_colors(probabilities,cardcolors,cd.EncodeColor)
  backbuffer:Activate()
  draw.cards(backbuffer,cardcolors,revealed)
  backbuffer:Flush()
end

function iupcanvas:map_cb()
  --Create the front buffer (which is never really used,
  --but that's no reason not to keep it referenced)
  frontbuffer=cd.CreateCanvas(cd.IUP,self)

  --double-buffer to eliminate flickering.
  --In testing this didn't change memory consumption.
  backbuffer=cd.CreateCanvas(cd.DBUFFER,frontbuffer)

  --Give the canvas the rest of its callbacks
  cancb(iupcanvas,backbuffer,selection,cardcolors,updateheatmap)
end

function iupcanvas:action()
  backbuffer:Activate()
  draw.clear(backbuffer,dlgbgcolor)
  draw.bars(backbuffer)
  draw.cards(backbuffer,cardcolors,revealed)
  backbuffer:Flush()
end

--Layout Construction
local layout = iup.cbox{
  rastersize=sizes.wxh(
    canvassize -- the width of the canvas
      + sizes.margin*2 -- plus the left and right margin
      + sizes.controls.gap -- plus the gap between the canvas and controls
      + sizes.controls.width, --plus the width of the controls
    canvassize
      + sizes.margin*2
      + sizes.controls.gap*2
      + sizes.controls.height*2),
  iupcanvas}

-------------------------------------------------------------------------------
-- Control creation
-------------------------------------------------------------------------------

--Make all the controls and place them into the layout
local textboxes = make_controls(layout,model,updateheatmap,defaults)

-------------------------------------------------------------------------------
-- Data initialization
-------------------------------------------------------------------------------

calculate_probs(model,revealed,probabilities)
generate_colors(probabilities,cardcolors,cd.EncodeColor)

-------------------------------------------------------------------------------
-- Program start
-------------------------------------------------------------------------------

--Store the main window just because it's good form
local mainwin = iup.dialog{
  icon=voltorb_icon,
  title="Game Corner",
  menu=menu,
  --since we really have NO support for resizing we just flat out disable it
  resize="no",
  startfocus=textboxes.columns[1].sum;
  layout}
--show the main window
mainwin:show()
--Relinquish flow control to IUP
iup.MainLoop()
