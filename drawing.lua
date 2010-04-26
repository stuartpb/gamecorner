-------------------------------------------------------------------------------
-- Required C Libraries
-------------------------------------------------------------------------------

--on top of calling several functions from a CanvasDraw canvas, this module
--calls cd.MM2PT and cd.EncodeColor directly.
require "cdlua"

-------------------------------------------------------------------------------
-- Game Corner modules
-------------------------------------------------------------------------------

--Sizes are required to know where to draw anything
local sizes = require "settings.sizes"

--Required for drawing the "1", "2", and "3".
local fonts = require "settings.fonts"

--Required for the background bars.
local colors = require "settings.colors"

--Used for drawing numbers.
local digits = require "images.digits"

-------------------------------------------------------------------------------
-- "Constant" value definitions
-------------------------------------------------------------------------------

--The font to write the numbers in.
local font= fonts.drawing

--the height of the canvas, for determining distances from the top.
local canheight=(sizes.card+sizes.cardgap)*lines

--The size of a card, for drawing cards.
local scard = sizes.card
--The size of a third of a card, for drawing subsquares.
local third = scard/3
--The height of
local memosize=scard/4

-------------------------------------------------------------------------------
-- Module definition
-------------------------------------------------------------------------------

-- Standards and Practices:
-- All Box drawing goes from smaller values to higher values,
-- with the higher values being decreased by 1.

--Define the table to store the module's functions in.
local draw={}

local function drawsmalldigit(can,number,xcenter,ycenter)
  local pixel = memosize/5
  local left, top = xcenter-pixel*2, ycenter+pixel*2.5
  local digit = digits.small[number]

  for y=1,5 do
    for x=1,4 do
      if digit[y][x] >= 3 then
        can:Box(
          left+pixel*(x-1),
          left+pixel*x-1,
          top-pixel*y,
          top-pixel*(y-1)-1)
      end
    end
  end
end

--Function to clear the canvas with a given color.
function draw.clear(can, bgcolor)
  can:Background(bgcolor)
  can:Clear()
end

--Function for drawing colored bars behind cards.
do
  local barcolors={}

  --Exchange all color sets for CD encoded colors
  for line, rgbtable in pairs(colors.lines) do
    barcolors[line]=cd.EncodeColor(unpack(rgbtable))
  end

  function draw.bars(can)
    local scard=sizes.card+sizes.cardgap
    local half=sizes.card/2
    local sixth=sizes.bars/2
    for line=1, lines do
      can:Foreground(barcolors[line])
      can:Box(0, canheight-1,
        canheight+sizes.cardgap-scard*(line)+half-sixth,
        canheight+sizes.cardgap-scard*(line)+half+sixth-1)
      can:Box(scard*(line-1)+half-sixth,
        scard*(line-1)+half+sixth-1,0,canheight-1)
    end
  end
end

--Function for drawing an individual card.
function draw.card(can,row,col,card)
  local resx, resy = can:Pixel2MM(1,1)
  local function fontsize(px)
    return cd.MM2PT * px*resy
  end

  can:Font(font,cd.BOLD,fontsize(third))
  can:MarkType(cd.CIRCLE)
  can:MarkSize(memosize)
  can:TextAlignment(cd.CENTER)

  local left=(scard+sizes.cardgap)*(col-1)
  local top = canheight-(scard+sizes.cardgap)*(row-1)
  local right, bottom= left+scard, top-scard
  can:Foreground(card.overall)
  can:Box(left, right-1, bottom, top-1)

  can:Foreground(card.subsquares[0])
  can:Box(left, left+third-1, top-third, top-1)

  can:Foreground(card.subsquares[1])
  can:Box(right-third, right-1, top-third, top-1)

  can:Foreground(card.subsquares[2])
  can:Box(left, left+third-1, bottom, bottom+third-1)

  can:Foreground(card.subsquares[3])
  can:Box(right-third, right-1, bottom, bottom+third-1)

  can:Foreground(card.subsquares[4])
  can:Box(left+third, right-third-1, bottom+third, top-third-1)

  can:Foreground(card[0])
  can:Mark(left+third/2, top-third/2)

  can:Foreground(card[1])
  drawsmalldigit(can,1,right-third/2,top-third/2)

  can:Foreground(card[2])
  drawsmalldigit(can,2,left+third/2,bottom+third/2)

  can:Foreground(card[3])
  drawsmalldigit(can,3,right-third/2,bottom+third/2)
end

function draw.cards(can,cardcolors)
  for row_index, row in ipairs(cardcolors) do
    for col_index, cell in ipairs(row) do
      draw.card(can,row_index, col_index, cell)
    end
  end
end

return draw
