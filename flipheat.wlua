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

local rowcolors={ --left to right/top to bottom
  {224,112,80},
  {64,168,64},
  {232,160,56},
  {48,144,248},
  {192,96,224}
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

local function encodergb(r,g,b)
  return cd.EncodeColor(math.floor(r),math.floor(g),math.floor(b))
end

function lin(position, zero, one)
  return zero * (1-position) + one * position
end

local probs={}
--generate example probabilities
do
  local rowbonus={25,5,0,0,0}
  for row=1,rowcols do
    probs[row]={}
    for col=1, rowcols do
      local voltorb, one, two, three =
        1+rowbonus[col],1+rowbonus[row],
        1+rowbonus[rowcols-col+1],1+rowbonus[rowcols-row+1]
      local sum= voltorb+ one+ two+ three
      probs[row][col]={
        [0]=voltorb/sum,
        [1]=one/sum,
        [2]=two/sum,
        [3]=three/sum
      }
    end
  end
end

local heatrgb; do
  --voltorb probability is straight RED
  --1 probability is 255 red and 224 green
  --2 probability is 255 blue and 128 green
  --3 probability is straight BLUE

  --a spot with high VOLTORB and 3 probability would be BRIGHT PURPLE
  local probabilityheats={
    [0]={255,0,0},
    [1]={255,224,0},
    [2]={0,128,255},
    [3]={0,0,255},
  }

  function heatrgb(card)
    local colors, max, avg = {}, 0, 0
    for rgbi=1,3 do
      colors[rgbi]=0
      for num=0,3 do
        colors[rgbi]=colors[rgbi]+
          card[num]*probabilityheats[num][rgbi]
      end
      max=math.max(max,colors[rgbi])
      avg=avg+colors[rgbi]
    end
    avg=avg/3
    local multiplier=math.max(1,1-((max-164)/164))
    --bring everything up to the max value
    --(the point where at least red, green, or blue
    --  is at 255)
    for rgbi=1,3 do
      colors[rgbi]=math.min(255,colors[rgbi]*multiplier)
    end

    return unpack(colors)
  end
end

local cardcolors={}
for rownum=1, rowcols do
  local row={}
  cardcolors[rownum]=row
  for colnum=1, rowcols do
    local cell={}
    row[colnum]=cell

    local cardprobs=probs[rownum][colnum]

    local r,g,b = heatrgb(cardprobs)
    cell.overall = encodergb(r,g,b)
    cell.subsquares={}

    local function brightrgb(heat)
      return lin(heat,r,255), lin(heat,g,255), lin(heat,b,255)
    end

    local function darkrgb(heat)
      return lin(heat,0,r), lin(heat,0,g), lin(heat,0,b)
    end

    local darkr, darkg, darkb=darkrgb(.8)
    local function dbrgb(heat)
      return lin(heat,darkr,255), lin(heat,darkg,255), lin(heat,darkb,255)
    end

    for i=0,4 do
      cell.subsquares[i]=encodergb(darkrgb(.8))
    end

    cell.individual = {}
    for num=0, 3 do
      cell.individual[num]=encodergb(dbrgb(cardprobs[num]))
    end
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

local drawcard; do
  local scard = sizes.card
  local third = scard/3
  local height = canvassize

  function drawcard(can,row,col)
    local resx, resy = can:Pixel2MM(1,1)
    local function fontsize(px)
      return cd.MM2PT * px*resy
    end

    local card=cardcolors[row][col]
    can:Font(font,cd.BOLD,fontsize(third))
    can:MarkType(cd.CIRCLE)
    can:MarkSize(third*4/5)
    can:TextAlignment(cd.CENTER)

    local right = scard*row
    local bottom = height-scard*col
    local left, top= right-scard, bottom+scard
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

    can:Foreground(card.individual[0])
    can:Mark(left+third/2, top-third/2)

    can:Foreground(card.individual[1])
    can:Text(right-third/2,top-third/2,"1")

    can:Foreground(card.individual[2])
    can:Text(left+third/2,bottom+third/2,"2")

    can:Foreground(card.individual[3])
    can:Text(right-third/2,bottom+third/2,"3")
  end
end

local function drawheatmap(can)
    for row_index, row in ipairs(cardcolors) do
      for col_index, cell in ipairs(row) do
        drawcard(can,col_index, row_index, cell)
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
