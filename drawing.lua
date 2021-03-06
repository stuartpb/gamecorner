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

--Required for drawing error messages.
local fonts = require "settings.fonts"

--Required for the background bars.
local colors = require "settings.colors"

--Used for drawing numbers.
local digits = require "images.digits"

-------------------------------------------------------------------------------
-- "Constant" value definitions
-------------------------------------------------------------------------------

--The number of rows and columns.
local lines = 5

--The font to write errors in.
local font= fonts.drawing

--the height of the canvas, for determining distances from the top.
local canheight=(sizes.card+sizes.cardgap)*lines

--The size of a card, for drawing cards.
local scard = sizes.card
--The size of a card and gap, for calculating offsets.
local carddist = scard+sizes.cardgap
--The size of a third of a card, for drawing subsquares.
local third = scard/3
--The height of
local memosize=scard/4

-------------------------------------------------------------------------------
-- Helper functions
-------------------------------------------------------------------------------

--Encodes a table of RGB values into a CD color.
local function encodect(ct)
  return cd.EncodeColor(unpack(ct))
end

-------------------------------------------------------------------------------
-- Module definition
-------------------------------------------------------------------------------

-- Standards and Practices:
-- All Box drawing goes from smaller values to higher values,
-- with the higher values being decreased by 1.

--Define the table to store the module's functions in.
local draw={}

local function drawdigit(can,set,number,xcenter,ycenter,size,colors)
  local digit = digits[set][number]
  local width, height = #digit[1], #digit
  local pixel = size/height
  local left, top = xcenter-pixel*(width/2), ycenter+pixel*(height/2)

  for y=1,height do
    for x=1,width do
      if digit[y][x] >= (colors and 1 or 3) then
        if colors then
          can:Foreground(colors[digit[y][x]])
        end
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
function draw.clear(can, bgcolort)
  can:Background(encodect(bgcolort))
  can:Clear()
end

--Function for drawing colored bars behind cards.
do
  local barcolors={}

  --Exchange all color sets for CD encoded colors
  for line, rgbtable in pairs(colors.lines) do
    barcolors[line]=encodect(rgbtable)
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

do
  local cardback=encodect(colors.rust)
  local cardedge=encodect(colors.darkrust)
  local ldcolors={
    encodect(colors.grey),
    encodect(colors.white),
    encodect(colors.black),
    }
  local edge=scard/20

  function draw.flippedcard(can,row,col,card)

    local left=(scard+sizes.cardgap)*(col-1)
    local top = canheight-(scard+sizes.cardgap)*(row-1)
    local right, bottom= left+scard, top-scard

    can:Foreground(cardedge)
    can:Box(left, right-1,
      bottom, top-1)

    can:Foreground(cardback)
    can:Box(left+edge, right-edge-1,
      bottom+edge, top-edge-1)

    drawdigit(can,'large',card,
      left+scard/2,top-scard/2,
      scard/2,ldcolors)
  end
end

do
  --Used for background of hovered sector.
  local darkgreen=encodect(colors.darkgreen)
  --Used for numbers in non-numbered sectors.
  local lightgreen=encodect(colors.lightgreen)
  --Used for backgrounds of non-hovered sectors.
  local grey=encodect(colors.grey)
  --Used for edges of non-hovered sectors.
  local darkgrey=encodect(colors.darkgrey)
  --Used for number of hovered sector.
  local gold=encodect(colors.gold)
  --Used for pushed numbers and edge of hovered sector.
  local black=encodect(colors.black)

  local edge=scard/40

  function draw.cardfocus(can,row,col,sector,pressed)

    local cardleft=(scard+sizes.cardgap)*(col-1)
    local cardhmiddle=cardleft+scard/2
    local cardright=cardleft+scard

    local cardtop = canheight-(scard+sizes.cardgap)*(row-1)
    local cardvmiddle=cardtop-scard/2
    local cardbottom=cardtop-scard

    for quad=0,3 do
      local left, right, bottom,top
      if quad%2==0 then
        left=cardleft
        right=cardhmiddle
      else
        left=cardhmiddle
        right=cardright
      end
      if quad<2 then
        top=cardtop
        bottom=cardvmiddle
      else
        top=cardvmiddle
        bottom=cardbottom
      end

      can:Foreground(quad==sector and black or darkgrey)
      can:Box(left, right-1,
        bottom, top-1)

      can:Foreground(quad==sector and darkgreen or grey)
      can:Box(left+edge, right-edge-1,
        bottom+edge, top-edge-1)

      can:Foreground(quad==sector and (pressed and black or gold) or lightgreen)
      drawdigit(can,'large',quad,
        left+scard/4,top-scard/4,
        scard/4)
    end
  end
end

--Function for drawing an individual card.
function draw.card(can,row,col,card)
  --Sets a table of RGB values as the canvas's foreground color.
  local function foregroundct(ct)
    can:Foreground(encodect(ct))
  end

  can:MarkType(cd.CIRCLE)
  can:MarkSize(memosize)

  local left=(scard+sizes.cardgap)*(col-1)
  local top = canheight-(scard+sizes.cardgap)*(row-1)
  local right, bottom= left+scard, top-scard
  foregroundct(card.overall)
  can:Box(left, right-1, bottom, top-1)

  foregroundct(card.subsquares[0])
  can:Box(left, left+third-1, top-third, top-1)

  foregroundct(card.subsquares[1])
  can:Box(right-third, right-1, top-third, top-1)

  foregroundct(card.subsquares[2])
  can:Box(left, left+third-1, bottom, bottom+third-1)

  foregroundct(card.subsquares[3])
  can:Box(right-third, right-1, bottom, bottom+third-1)

  foregroundct(card.subsquares[4])
  can:Box(left+third, right-third-1, bottom+third, top-third-1)

  foregroundct(card[0])
  can:Mark(left+third/2, top-third/2)

  foregroundct(card[1])
  drawdigit(can,'small',1,right-third/2,top-third/2,memosize)

  foregroundct(card[2])
  drawdigit(can,'small',2,left+third/2,bottom+third/2,memosize)

  foregroundct(card[3])
  drawdigit(can,'small',3,right-third/2,bottom+third/2,memosize)
end

do
  --Used for backgrounds of cards.
  local grey=encodect(colors.grey)
  --Used for edges and subsquares.
  local darkgrey=encodect(colors.darkgrey)
  --Used for bars and numbers on flipped cards.
  local black=encodect(colors.black)
  --Used for text.
  local red=cd.EncodeColor(255,0,0)

  function draw.errbars(can)
    local scard=sizes.card+sizes.cardgap
    local half=sizes.card/2
    local sixth=sizes.bars/2

    can:Foreground(black)

    for line=1, lines do
      can:Box(0, canheight-1,
        canheight+sizes.cardgap-scard*(line)+half-sixth,
        canheight+sizes.cardgap-scard*(line)+half+sixth-1)
      can:Box(scard*(line-1)+half-sixth,
        scard*(line-1)+half+sixth-1,0,canheight-1)
    end
  end

  function draw.errcard(can,row,col)
    local left=(scard+sizes.cardgap)*(col-1)
    local top = canheight-(scard+sizes.cardgap)*(row-1)
    local right, bottom= left+scard, top-scard

    can:Foreground(grey)
    can:Box(left, right-1, bottom, top-1)

    can:Foreground(darkgrey)
    can:Box(left, left+third-1, top-third, top-1)
    can:Box(right-third, right-1, top-third, top-1)
    can:Box(left, left+third-1, bottom, bottom+third-1)
    can:Box(right-third, right-1, bottom, bottom+third-1)
    can:Box(left+third, right-third-1, bottom+third, top-third-1)
  end

  local edge=scard/20

  function draw.errflipped(can,row,col,card)
    local left=(scard+sizes.cardgap)*(col-1)
    local top = canheight-(scard+sizes.cardgap)*(row-1)
    local right, bottom= left+scard, top-scard

    can:Foreground(darkgrey)
    can:Box(left, right-1,
      bottom, top-1)

    can:Foreground(grey)
    can:Box(left+edge, right-edge-1,
      bottom+edge, top-edge-1)

    can:Foreground(black)
    drawdigit(can,'large',card,
      left+scard/2,top-scard/2,
      scard/2)
  end

  function draw.errmsg(can,row,col,msg)
    local resx, resy = can:Pixel2MM(1,1)
    local function fontsize(px)
      return cd.MM2PT * px*resy
    end

    can:Foreground(red)
    can:Font(font,cd.BOLD,fontsize(scard/5))
    can:TextAlignment(cd.BASE_CENTER)

    if row=="column" then
      can:TextOrientation(90)
      can:Text(
        (col-1)*carddist+scard/2,
        canheight/2,
        msg)
    elseif col == "row" then
      can:TextOrientation(0)
      can:Text(
        canheight/2,
        canheight-(row)*carddist+scard/2,
        msg)
    else
      can:TextOrientation(0)
      can:Text(
        (col-1)*carddist+scard/2,
        canheight-(row)*carddist+scard/2,
        msg)
    end
  end
end

function draw.cards(can,cardcolors,flipped,errmsgs)
  local bg_needs_to_be_redrawn
  if errmsgs then
    bg_needs_to_be_redrawn=true
    draw.errbars(can)
  end

  for row_index=1, lines do
    for col_index=1, lines do
      local flip = flipped[row_index][col_index]

      if errmsgs then
        if flip then
          draw.errflipped(can,row_index, col_index,flip)
        else
          draw.errcard(can,row_index, col_index)
        end
        for errnum, err in pairs(errmsgs) do
          draw.errmsg(can,unpack(err))
        end
      else
        if flip then
          draw.flippedcard(can,row_index,col_index, flip)
        else
          draw.card(can,row_index, col_index, cardcolors[row_index][col_index])
        end
      end
    end
  end

  return bg_needs_to_be_redrawn
end

return draw
