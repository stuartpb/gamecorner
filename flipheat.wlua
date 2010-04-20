-- VOLTORB Flip Probability Heatmap Generator --
-- Libraries

require 'cdlua'
require 'iuplua'
require 'iupluacd'

--grab the dialog's RGB (and convert it to numbers to be safe)
local bgcolors={
  string.match(iup.GetGlobal"DLGBGCOLOR",
    "^(%d+) (%d+) (%d+)$")}
for _, each in pairs(bgcolors) do each=tonumber(each) end

local sizes={
  --Width/height of a card
  card=120,
  --Width of gaps between cards
  cardgap=12,
  --Width of the colored bars behind the cards
  bars=16,
  --Margin between window edge and all controls
  margin=3,
  --Space for controls to right of canvas
  rspace=100,
  controls={
    --Gap between controls
    gap=2,
    --Sizes of textboxes
    textbox={
      width=40,
      height=20
    },
  },
}

--Number of rows/columns
local lines=5

--this value is calculated and stored because it gets used a LOT
local canvassize=(sizes.card+sizes.cardgap)*lines

local defaults={
  sum=5,
  voltorb=0
}

local draw_bars; do
  local barcolors={ --left to right/top to bottom
    {224,112,80},
    {64,168,64},
    {232,160,56},
    {48,144,248},
    {192,96,224}
  }

  function draw_bars(can)
    local scard=sizes.card+sizes.cardgap
    local half=sizes.card/2
    local sixth=sizes.bars/2
    for line=1, lines do
      can:Foreground(cd.EncodeColor(unpack(barcolors[line])))
      can:Box(0, canvassize,
        canvassize+sizes.cardgap-scard*(line)+half-sixth,
        canvassize+sizes.cardgap-scard*(line)+half+sixth)
      can:Box(scard*(line-1)+half-sixth,
        scard*(line-1)+half+sixth,canvassize,0)
    end
  end
end

local function coordstr(width, height)
  return string.format("%ix%i",width,height)
end

local function sqsz(size)
  return coordstr(size,size)
end

-- Example Map Generation

local function encodergb(r,g,b)
  return cd.EncodeColor(r,g,b)
end

local function lin(position, zero, one)
  return zero * (1-position) + one * position
end

local columns={}
local rows={}
--initialize column and row data
for line=1, lines do
  columns[line]={sum=defaults.sum, voltorb=defaults.voltorb}
  rows[line]={sum=defaults.sum, voltorb=defaults.voltorb}
end

--table of determined
local probabilities={}

local function calculate_probabilities(rows,cols,probs)
  local rowprobs, colprobs={},{}
  for rcprobs, data in pairs{[rowprobs]=rows,[colprobs]=cols} do
    for line=1, lines do
      local nonzero = lines-data[line].voltorb
      local average = data[line].sum/(nonzero)
      local function oneoff(num)
        return 1-math.min(1,math.abs(average-num))
      end

      local threeodds = oneoff(3)
      local twoodds = oneoff(2)
      local oneodds = oneoff(1)

      rcprobs[line]={
        [0]=data[line].voltorb/lines,
        [1]=oneodds*(nonzero/lines),
        [2]=twoodds*(nonzero/lines),
        [3]=threeodds*(nonzero/lines),
      }
    end
  end

  for row=1,lines do
    probs[row]={}
    for col=1, lines do
        probs[row][col]={}
          for num=0,3 do
            probs[row][col][num]=rowprobs[row][num]*.5+colprobs[col][num]*.5
          end
    end
  end
end

local cardcolors={}
local generate_colors
do
  local heatrgb; do
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
      --scale up color
      for rgbi=1,3 do
        colors[rgbi]=math.min(255,colors[rgbi]*multiplier)
      end

      return unpack(colors)
    end
  end

  function generate_colors(probs,cardcolors)
    for rownum=1, lines do
      local row={}
      cardcolors[rownum]=row
      for colnum=1, lines do
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
  end
end

local font="Consolas"

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

local function drawcards(can,cardcolors)
  for row_index, row in ipairs(cardcolors) do
    for col_index, cell in ipairs(row) do
      drawcard(can,row_index, col_index, cell)
    end
  end
end

-- Canvas Creation
local iupcanvas=iup.canvas{
  rastersize=sqsz(canvassize),
  bgcolor=iup.GetGlobal"DLGBGCOLOR", border="NO",
  cx=sizes.margin,
  cy=sizes.margin}

local cdcanvas
function iupcanvas:map_cb()
  cdcanvas=cd.CreateCanvas(cd.IUP,self)
end

function iupcanvas:action()
  cdcanvas:Activate()
  cdcanvas:Background(cd.EncodeColor(unpack(bgcolors)))
  cdcanvas:Clear()
  draw_bars(cdcanvas)
  drawcards(cdcanvas,cardcolors)
end

local layout = iup.cbox{
  rastersize=coordstr(
    canvassize+sizes.margin*2+
      sizes.rspace,
    canvassize+sizes.margin*2+
      sizes.controls.gap*2+sizes.controls.textbox.height*2),
  iupcanvas}

local function updateheatmap()
  calculate_probabilities(rows,columns,probabilities)
  generate_colors(probabilities,cardcolors)
  drawcards(cdcanvas,cardcolors)
end

-- Text Box / Spin Control Code -----------------------------------------------
local textboxes={rows={},columns={}}; do

  local function makecontrols(position, rownotcol)
    local thisaxis = rownotcol and rows or columns
    local otheraxis = rownotcol and columns or rows
    local thisline = thisaxis[position]

    local left, right, sumtop, voltorbtop
    if rownotcol then
      left= sizes.margin + canvassize + sizes.controls.gap
      spinleft = left + sizes.rspace
        - sizes.controls.textbox.width - sizes.margin
      sumtop = sizes.margin + position*(sizes.card+sizes.cardgap)
        - sizes.card/2 - sizes.controls.gap
        - sizes.controls.textbox.height - sizes.cardgap
      voltorbtop = sumtop + sizes.controls.gap*2
        + sizes.controls.textbox.height
    else
      left= sizes.margin +
        (position-1)*(sizes.card+sizes.cardgap) + sizes.controls.gap
      spinleft= left + sizes.card
        - sizes.controls.textbox.width - sizes.controls.gap
      sumtop = sizes.margin
        + canvassize + sizes.controls.gap
      voltorbtop= sumtop
        + sizes.controls.textbox.height + sizes.controls.gap
    end

    iup.Append(layout,iup.label{title="Sum:", cx=left,cy=sumtop})
    iup.Append(layout,iup.label{title="VOLTORB:", cx=left,cy=voltorbtop})
    local newboxes={}

    local function advancesum()
      iup.SetFocus(newboxes.voltorb)
    end
    local function retractsum()
      if position > 1 then
        iup.SetFocus(textboxes[rownotcol and "rows" or "columns"][position-1].voltorb)
      else
        iup.SetFocus(textboxes[rownotcol and "columns" or "rows"][lines].voltorb)
      end
    end
    local function advancevoltorb()
      if position < lines then
        iup.SetFocus(textboxes[rownotcol and "rows" or "columns"][position+1].sum)
      else
        iup.SetFocus(textboxes[rownotcol and "columns" or "rows"][1].sum)
      end
    end
    local function retractvoltorb()
      iup.SetFocus(newboxes.sum)
    end

    --Syncs the sum control's value with the internal data.
    --Only used by spin_cb because syncing the spin value causes
    --problems with redundancy. In most cases syncsum should be used.
    local function syncsumtext()
      newboxes.sum.value=string.format("%02i",thisline.sum)
    end

    --Syncs the sum control's values with the internal data.
    local function syncsum()
      newboxes.sum.spinvalue=thisline.sum
      syncsumtext()
    end

    --Syncs the Voltorb control's text value with the internal data.
    --Only used by spin_cb because syncing the spin value causes
    --problems with redundancy. In most cases syncvoltorb should be used.
    local function syncvoltorbtext()
      newboxes.voltorb.value=string.format("%01i",thisline.voltorb)
    end

    --Syncs the Voltorb control's values with the internal data.
    local function syncvoltorb()
      newboxes.voltorb.spinvalue=thisline.voltorb
      syncvoltorbtext()
    end

    --Updates the sum value to be within the realm of possibility with
    --the passed number of voltorb.
    local function bindsumtovoltorb(number)
      local lowest= lines-number
      local highest= lowest*3

      thisline.sum=math.max(math.min(thisline.sum,highest),lowest)

      --update the sum count displayed
      syncsum()
    end

    --Binds the Voltorb count to be within the realm of possibility
    --for the passed sum.
    local function bindvoltorbtosum(number)
      local lowest= lines-thisline.voltorb
      local highest= lowest*3

      --if sum is impossible with current Voltorb count,
      --tweak Voltorb count to permit sum spun to
      while number > highest do
        thisline.voltorb= thisline.voltorb-1
        highest = (lines-thisline.voltorb)*3
      end

      while number < lowest do
        thisline.voltorb= thisline.voltorb+1
        lowest = lines-thisline.voltorb
      end

      --update the Voltorb count displayed
      syncvoltorb()
    end

    local function possiblesum(num)
      local lowest= lines-thisline.voltorb
      local highest= lowest*3

      return lowest <= num and num <= highest
    end

    local function possiblevoltorb(num)
      local lowest= math.max(0,lines-thisline.sum)
      local highest= math.max(0,lines-math.ceil(thisline.sum/3))

      return lowest <= num and num <= highest
    end

    local function validsum(num)
      return 0 <= num and num <= lines*3
    end

    local function validvoltorb(num)
      return 0 <= num and num <= lines
    end

    newboxes.sum=iup.text{spin="YES", mask=iup.MASK_UINT,
      cx=spinleft,cy=sumtop, spinauto="NO",
      spinmax=3*lines, spinvalue=thisline.sum,
      value=string.format("%02i",thisline.sum),
      rastersize=coordstr(sizes.controls.textbox.width,
        sizes.controls.textbox.height)}

    function newboxes.sum:action(c, newvalue)
      local number=tonumber(newvalue)
      if number then
        if validsum(number) then
          if possiblesum(number) then
            thisline.sum = number
            updateheatmap()
          end
          if #newvalue > 1 or number > 1 then
            --the number has been fully entered
            self.value=newvalue
            advancesum()
            return iup.IGNORE
          end
        else
          --return iup.IGNORE
        end
      end
    end

    function newboxes.sum:spin_cb(number)
      --update the sum count (which we know to be valid
      --  as it came from spinning which is bound etc)
      thisline.sum = number
      syncsumtext()

      bindvoltorbtosum(number)

      --and update the heatmap
      updateheatmap()
    end

    function newboxes.sum:getfocus_cb()
      self.selection="ALL"
    end

    function newboxes.sum:killfocus_cb()
      number=tonumber(self.value)
      if number and validsum(number) then
        thisline.sum=number
        bindvoltorbtosum(number)
        updateheatmap()
      end
      syncsum()
    end

    function newboxes.sum:k_any(c)
      if c == iup.K_CR or c == iup.K_TAB then
        advancesum()
        return iup.IGNORE
      elseif c== iup.K_sTAB then
        retractsum()
        return iup.IGNORE
      end
    end

    newboxes.voltorb=iup.text{spin="YES", mask=iup.MASK_UINT,
      cx=spinleft,cy=voltorbtop, spinauto="NO",
      spinmax=lines, value=thisline.voltorb,
      value=string.format("%01i",thisline.voltorb),
      rastersize=coordstr(sizes.controls.textbox.width,
        sizes.controls.textbox.height)}

    function newboxes.voltorb:action(c, newvalue)
      local number=tonumber(newvalue)
      if number then
        if validvoltorb(number) then
          if possiblevoltorb(number) then
            thisline.voltorb = number
            updateheatmap()
          end
          --with this digit, the number has been fully entered
          self.value=newvalue
          advancevoltorb()
          return iup.IGNORE
        else
          --return iup.IGNORE
        end
      end
    end

    function newboxes.voltorb:spin_cb(number)
      --update the voltorb count (which we know to be valid
      --  as it came from spinning which is bound etc)
      thisline.voltorb=number
      syncvoltorbtext()

      bindsumtovoltorb(number)

      --and update the heatmap
      updateheatmap()
    end

    function newboxes.voltorb:getfocus_cb()
      self.selection="ALL"
    end

    function newboxes.voltorb:killfocus_cb()
      number=tonumber(self.value)
      if number and validvoltorb(number) then
        thisline.voltorb=number
        bindsumtovoltorb(number)
        updateheatmap()
      end

      syncvoltorb()
    end

    function newboxes.voltorb:k_any(c)
      if c == iup.K_CR or c == iup.K_TAB then
        advancevoltorb()
        return iup.IGNORE
      elseif c== iup.K_sTAB then
        retractvoltorb()
        return iup.IGNORE
      end
    end

    textboxes[rownotcol and "rows" or "columns"][position]=newboxes
    iup.Append(layout,newboxes.sum)
    iup.Append(layout,newboxes.voltorb)
  end

  for line=1, lines do
    makecontrols(line,true)
    makecontrols(line,false)
  end
end

local function update_controls()
  for line=1, lines do
    textboxes.rows[line].sum.value=rows[line].sum
    textboxes.rows[line].voltorb.value=rows[line].voltorb
    textboxes.columns[line].sum.value=columns[line].sum
    textboxes.columns[line].voltorb.value=columns[line].voltorb
  end
end

iup.Append(layout, iup.button{active="NO",
  title="Undo Selection",rastersize=coordstr(
    sizes.rspace-sizes.margin,
    sizes.controls.textbox.height*2+sizes.controls.gap),
    cx=canvassize+sizes.margin+sizes.controls.gap,
    cy=canvassize+sizes.margin+sizes.controls.gap})

calculate_probabilities(rows,columns,probabilities)
generate_colors(probabilities,cardcolors)

local mainwin = iup.dialog{title="Game Corner",layout}
mainwin:show()
iup.MainLoop()
