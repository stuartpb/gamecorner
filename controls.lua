--upvalues that get set when the function is called
local textboxes,layout,rows,columns,updateheatmap

local sizes = require "sizes"

--this value is calculated and stored because it gets used a LOT
local canvassize=(sizes.card+sizes.cardgap)*lines

function coordstr(width, height)
  return string.format("%ix%i",width,height)
end

function sqsz(size)
  return coordstr(size,size)
end

local function make_line_controls(position, rownotcol)
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

function make_controls(...)
  textboxes,layout,rows,columns,updateheatmap = ...
  for line=1, lines do
    make_line_controls(line,true)
    make_line_controls(line,false)
  end
end
