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

--Bring in the algorithm to calculate the probabilities
local calculate_probs = require "probabilities"

--Bring in the algorithm to calculate the colors from those probabilities
local generate_colors= require "coloring"

--Sizes are required for the construction of the canvas and layout
local sizes = require "minor.sizes"

--Bring in the drawing functions
local draw = require "drawing"

--bring in the function to make the controls
require "controls"

-------------------------------------------------------------------------------
-- "Constant" value definitions
-------------------------------------------------------------------------------

--this value is calculated and stored because it gets used a LOT
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

local columns={}
local rows={}
--initialize column and row data
for line=1, lines do
  for _, axis in pairs{rows,columns} do
    axis[line]={sum=defaults.sum, voltorb=defaults.voltorb}
  end
end

--table determined probabilities get stored in.
local probabilities={}

--table determined cards get stored in.
local cardcolors={}

--Create all tables for each row and card.
for row=1,lines do
  probabilities[row]={}
  cardcolors[row]={}
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
function iupcanvas:map_cb()
  --Create the front buffer (which is never really used,
  --but that's no reason not to keep it referenced)
  frontbuffer=cd.CreateCanvas(cd.IUP,self)

  --double-buffer to eliminate flickering.
  --In testing this didn't change memory consumption.
  backbuffer=cd.CreateCanvas(cd.DBUFFER,frontbuffer)
end

function iupcanvas:action()
  backbuffer:Activate()
  draw.clear(backbuffer,dlgbgcolor)
  draw.bars(backbuffer)
  draw.cards(backbuffer,cardcolors)
  backbuffer:Flush()
end

--Layout Construction
local layout = iup.cbox{
  rastersize=sizes.wxh(
    canvassize+sizes.margin*2+
      sizes.rspace,
    canvassize+sizes.margin*2+
      sizes.controls.gap*2+sizes.controls.textbox.height*2),
  iupcanvas}

local function updateheatmap()
  calculate_probs(rows,columns,probabilities)
  generate_colors(probabilities,cardcolors,cd.EncodeColor)
  backbuffer:Activate()
  draw.cards(backbuffer,cardcolors)
  backbuffer:Flush()
end

-------------------------------------------------------------------------------
-- Control creation
-------------------------------------------------------------------------------

--Make all the controls and place them into the layout
make_controls(layout,rows,columns,updateheatmap,defaults)

-------------------------------------------------------------------------------
-- Data initialization
-------------------------------------------------------------------------------

calculate_probs(rows,columns,probabilities)
generate_colors(probabilities,cardcolors,cd.EncodeColor)

-------------------------------------------------------------------------------
-- Program start
-------------------------------------------------------------------------------

--Store the main window just because it's good form
local mainwin = iup.dialog{title="Game Corner",layout}
--show the main window
mainwin:show()
--Relinquish flow control to IUP
iup.MainLoop()
