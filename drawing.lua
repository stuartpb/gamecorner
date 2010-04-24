--Sizes are required to know where to draw anything
local sizes = require "sizes"

local font="Consolas"

--this value is calculated and stored because it gets used a LOT
local canvassize=(sizes.card+sizes.cardgap)*lines

local draw={}

function draw.clear(can, bgcolor)
  can:Background(bgcolor)
  can:Clear()
end

do
  local barcolors={ --left to right/top to bottom
    {224,112,80},
    {64,168,64},
    {232,160,56},
    {48,144,248},
    {192,96,224}
  }

  for line, rgbtable in pairs(barcolors) do
    barcolors[line]=cd.EncodeColor(unpack(rgbtable))
  end

  function draw.bars(can)
    local scard=sizes.card+sizes.cardgap
    local half=sizes.card/2
    local sixth=sizes.bars/2
    for line=1, lines do
      can:Foreground(barcolors[line])
      can:Box(0, canvassize,
        canvassize+sizes.cardgap-scard*(line)+half-sixth,
        canvassize+sizes.cardgap-scard*(line)+half+sixth)
      can:Box(scard*(line-1)+half-sixth,
        scard*(line-1)+half+sixth,canvassize,0)
    end
  end
end

local drawcard; do
  local scard = sizes.card
  local third = scard/3
  local height = canvassize

  function drawcard(can,row,col,card)
    local resx, resy = can:Pixel2MM(1,1)
    local function fontsize(px)
      return cd.MM2PT * px*resy
    end

    can:Font(font,cd.BOLD,fontsize(third))
    can:MarkType(cd.CIRCLE)
    can:MarkSize(third*4/5)
    can:TextAlignment(cd.CENTER)

    local left=(scard+sizes.cardgap)*(col-1)
    local top = height-(scard+sizes.cardgap)*(row-1)
    local right, bottom= left+scard, top-scard
    can:Foreground(card.overall)
    can:Box(left, right, bottom, top)

    can:Foreground(card.subsquares[0])
    can:Box(left, left+third, top, top-third)

    can:Foreground(card.subsquares[1])
    can:Box(right-third, right, top, top-third)

    can:Foreground(card.subsquares[2])
    can:Box(left, left+third, bottom+third, bottom)

    can:Foreground(card.subsquares[3])
    can:Box(right-third, right, bottom+third, bottom)

    can:Foreground(card.subsquares[4])
    can:Box(left+third, right-third, top-third, bottom+third)

    can:Foreground(card[0])
    can:Mark(left+third/2, top-third/2)

    can:Foreground(card[1])
    can:Text(right-third/2,top-third/2,"1")

    can:Foreground(card[2])
    can:Text(left+third/2,bottom+third/2,"2")

    can:Foreground(card[3])
    can:Text(right-third/2,bottom+third/2,"3")
  end
end

function draw.cards(can,cardcolors)
  for row_index, row in ipairs(cardcolors) do
    for col_index, cell in ipairs(row) do
      drawcard(can,row_index, col_index, cell)
    end
  end
end

return draw
