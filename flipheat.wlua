-- VOLTORB Flip Probability Heatmap Generator --
-- Libraries

require 'cdlua'
require 'iuplua'
require 'iupluacd'

local sizes={
  card=120,
  canvas={
    gap=0,
    margin=0
  },
  margins={
      right=100,
      edges=3
    },
  controls={
    gap=2,
    textbox={
      width=40,
      height=20
    },
  },
}

--I use 1 loop for control creation,
--so rows and columns are the same size.
--So this won't work for non-square fields.
--I'm fairly sure Game Freak isn't going to issue
--a post-release patch that changes the number of
--rows and columns at the Game Corner, and if they do,
--I can live with copying and pasting a few lines.
local rowcols=5

local function coordstr(width, height)
  return string.format("%ix%i",width,height)
end

local function sqsz(size)
  return coordstr(size,size)
end

-- Example Map Genration

local function rgbstring(r,g,b)
  return string.format("%i %i %i",r,g,b)
end

local function encodergb(r,g,b)
  return cd.EncodeColor(math.floor(r),math.floor(g),math.floor(b))
end

function lin(position, zero, one)
  return zero * (1-position) + one * position
end

local function heatrgb(heat)
  if heat < 1/3 then --representing the inverval between only a voltorb and a 1
    return 255, lin(heat*3,0,255), 0
  elseif heat < 2/3 then --like the interval between a 1 and a 2
    return lin((heat-1/3)*3,255,0), 255, 0
  else --like the interval between a 2 and a 3
    return 0, lin((heat-2/3)*3,255,0), lin((heat-2/3)*3,0,255)
  end
end

--voltorb probability is straight RED
--1 probability is 255 red and 224 green
--2 probability is 255 blue and 128 green
--3 probability is straight BLUE

--a spot with high VOLTORB and 3 probability would be BRIGHT PURPLE

local example= {
  {{}, {}, {}, {}, {}},
  {{}, {}, {}, {}, {}},
  {{}, {}, {}, {}, {}},
  {{}, {}, {}, {}, {}},
  {{}, {}, {}, {}, {}},
}

for row_index, row in ipairs(example) do
  for col_index, cell in ipairs(row) do
    local cellheat = (row_index-.5)/10 + (col_index-.5)/10
    local r,g,b = heatrgb(cellheat)
    cell.overall = encodergb(r,g,b)

    local function whitehotrgb(heat)
      return lin(heat,r,255), lin(heat,g,255), lin(heat,b,255)
    end

    local function peak(bottom, mid, top)
      local indheat
      if cellheat < mid then
        indheat = (bottom-math.max(bottom,cellheat))/(bottom-mid)
      else
        indheat = (top-math.min(top, cellheat))/(top-mid)
      end
      return encodergb(whitehotrgb(lin(indheat,.25,1)))
    end

    local function edge(low)
      return encodergb(whitehotrgb(lin(math.max(low,0),.25,1)))
    end

    cell.individual = {
      [0]=edge((1/2-cellheat)*2), --voltorb
      [1]=peak(0, 1/3, 2/3),
      [2]=peak(1/3, 2/3, 1),
      [3]=edge((cellheat-2/3)*3),
    }
  end
end

-- Canvas Creation
local canvassize=sizes.card*rowcols+sizes.canvas.margin*2

local iupcanvas=iup.canvas{
  rastersize=sqsz(canvassize),border="NO",
  cx=sizes.margins.edges,
  cy=sizes.margins.edges}

local cdcanvas
function iupcanvas:map_cb()
  cdcanvas=cd.CreateCanvas(cd.IUP,self)
end

local font="Consolas"

function drawheatmap(can)
    local width, height = can:GetSize()
    local resx, resy = can:Pixel2MM(1,1)
    local function fontsize(px)
      return cd.MM2PT * px*resy
    end

    local cellh = sizes.card
    local cellw = sizes.card
    local numh = sizes.card/3

    local height = canvassize

    can:Font(font,cd.BOLD,fontsize(numh))
    can:MarkType(cd.CIRCLE)
    can:MarkSize(numh)
    for row_index, row in ipairs(example) do
      for col_index, cell in ipairs(row) do
          can:Foreground(cell.overall)
          can:Box(cellw*(row_index-1),cellw*row_index,
            height-cellh*(col_index-1),height-cellh*col_index)

          can:Foreground(cell.individual[0])
          can:Mark(cellw*(row_index-1)+numh/2,
            height-cellh*(col_index-1)-numh/2)

          can:Foreground(cell.individual[1])
          can:TextAlignment(cd.NORTH_EAST)
          can:Text(cellw*row_index,height-cellh*(col_index-1),"1")

          can:Foreground(cell.individual[2])
          can:TextAlignment(cd.SOUTH_WEST)
          can:Text(cellw*(row_index-1),height-cellh*col_index,"2")

          can:Foreground(cell.individual[3])
          can:TextAlignment(cd.SOUTH_EAST)
          can:Text(cellw*row_index,height-cellh*col_index,"3")
      end
    end
end

function iupcanvas:action()
  cdcanvas:Activate()
  cdcanvas:Clear()
  drawheatmap(cdcanvas)
end

local layout = iup.cbox{
  rastersize=coordstr(
    canvassize+sizes.margins.edges*2+
      sizes.margins.right,
    canvassize+sizes.margins.edges*2+
      sizes.controls.gap*2+sizes.controls.textbox.height*2),
  iupcanvas}

local function makecontrols(position, rownotcol)
  local left, right, sumtop, voltorbtop

  if rownotcol then
    left= sizes.margins.edges + canvassize + sizes.controls.gap
    spinleft = left + sizes.margins.right - sizes.controls.textbox.width - sizes.margins.edges
    sumtop = sizes.margins.edges + position*sizes.card - sizes.card/2
      - sizes.controls.gap - sizes.controls.textbox.height
    voltorbtop= sumtop + sizes.controls.gap*2 + sizes.controls.textbox.height
  else
    left= sizes.margins.edges +(position-1)*(sizes.card) + sizes.controls.gap
    spinleft= left + sizes.card - sizes.controls.textbox.width - sizes.controls.gap
    sumtop = sizes.margins.edges + canvassize + sizes.controls.gap
    voltorbtop= sumtop + sizes.controls.textbox.height + sizes.controls.gap
  end

  iup.Append(layout,iup.label{title="Sum:", cx=left,cy=sumtop})
  iup.Append(layout,iup.label{title="VOLTORB:", cx=left,cy=voltorbtop})
  iup.Append(layout,iup.text{spin="YES", cx=spinleft,cy=sumtop,
    spinmax=3*rowcols, value='?',
    rastersize=coordstr(sizes.controls.textbox.width,
      sizes.controls.textbox.height)})
  iup.Append(layout,iup.text{spin="YES", cx=spinleft,cy=voltorbtop,
    spinmax=rowcols, value='?',
    rastersize=coordstr(sizes.controls.textbox.width,
      sizes.controls.textbox.height)})
end

for rowcol=1, rowcols do
  makecontrols(rowcol,true)
  makecontrols(rowcol,false)
end

local mainwin = iup.dialog{title="Flip the Cards and Collect Coins!",layout}
mainwin:show()
iup.MainLoop()
