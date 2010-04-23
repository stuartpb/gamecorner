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
require "drawing"

--bring in the function to make the controls and sizestr
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
  end
end

-------------------------------------------------------------------------------
-- Central object construction
-------------------------------------------------------------------------------

-- Canvas Creation
local iupcanvas=iup.canvas{
  rastersize=sizestr(canvassize,canvassize),
  bgcolor=iup.GetGlobal"DLGBGCOLOR", border="NO",
  cx=sizes.margin,
  cy=sizes.margin}

local cdcanvas
function iupcanvas:map_cb()
  cdcanvas=cd.CreateCanvas(cd.IUP,self)
end

do
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

  function iupcanvas:action()
    cdcanvas:Activate()
    cdcanvas:Background(dlgbgcolor)
    cdcanvas:Clear()
    draw_bars(cdcanvas)
    drawcards(cdcanvas,cardcolors)
  end
end

--Make all the controls and place them into the layout
make_controls(layout,rows,columns,updateheatmap,defaults)

--Layout Construction
local layout = iup.cbox{
  rastersize=sizestr(
    canvassize+sizes.margin*2+
      sizes.rspace,
    canvassize+sizes.margin*2+
      sizes.controls.gap*2+sizes.controls.textbox.height*2),
  iupcanvas}

local function updateheatmap()
  calculate_probs(rows,columns,probabilities)
  generate_colors(probabilities,cardcolors,cd.EncodeColor)
  drawcards(cdcanvas,cardcolors)
end

iup.Append(layout, iup.button{active="NO",
  title="Undo Selection",rastersize=sizestr(
    sizes.rspace-sizes.margin,
    sizes.controls.textbox.height*2+sizes.controls.gap),
    cx=canvassize+sizes.margin+sizes.controls.gap,
    cy=canvassize+sizes.margin+sizes.controls.gap})

calculate_probs(rows,columns,probabilities)
generate_colors(probabilities,cardcolors,cd.EncodeColor)

local mainwin = iup.dialog{title="Game Corner",layout}
mainwin:show()
iup.MainLoop()
