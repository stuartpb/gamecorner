--Used to get controls to move to when traversing controls.
local traversal=require "controls.traversal"

--used for loops that do stuff to both textboxes.
local boxtypes={"sum","voltorb"}

--Function that adds callback functionality to the controls of a line.
local function make_line_callbacks(position, model, thisaxis, otheraxis, updateheatmap)
  local thisline=thisaxis[position]

  local traversals=traversal(position,thisaxis,otheraxis)

  --Used for advancing the focus after entering a "final" value.
  local function advance(from)
    iup.SetFocus(traversals[from].advance)
  end

  --pulls the sum control's value with the internal data.
  --Only used by spin_cb because pulling the spin value causes
  --problems with redundancy. In most cases pullsum should be used.
  local function pullsumtext()
    thisline.sum.value=string.format("%02i",model.sum)
  end

  --pulls the sum control's values with the internal data.
  local function pullsum()
    --pull the spin value
    thisline.sum.spinvalue=model.sum
    --pull the text value
    pullsumtext()
  end

  --pulls the Voltorb control's text value with the internal data.
  --Only used by spin_cb because pulling the spin value causes
  --problems with redundancy. In most cases pullvoltorb should be used.
  local function pullvoltorbtext()
    thisline.voltorb.value=string.format("%01i",model.voltorb)
  end

  --pulls the Voltorb control's values with the internal data.
  local function pullvoltorb()
    thisline.voltorb.spinvalue=model.voltorb
    pullvoltorbtext()
  end

  --Updates the sum value to be within the realm of possibility with
  --the passed number of voltorb.
  local function bindsumtovoltorb(number)
    local lowest= lines-number
    local highest= lowest*3

    model.sum=math.max(math.min(model.sum,highest),lowest)

    --update the sum count displayed
    pullsum()
  end

  --Binds the Voltorb count to be within the realm of possibility
  --for the passed sum.
  local function bindvoltorbtosum(number)
    local lowest= lines-model.voltorb
    local highest= lowest*3

    --if sum is impossible with current Voltorb count,
    --tweak Voltorb count to permit sum spun to
    while number > highest do
      model.voltorb= model.voltorb-1
      highest = (lines-model.voltorb)*3
    end

    while number < lowest do
      model.voltorb= model.voltorb+1
      lowest = lines-model.voltorb
    end

    --update the Voltorb count displayed
    pullvoltorb()
  end

  local function possiblesum(num)
    local lowest= lines-model.voltorb
    local highest= lowest*3

    return lowest <= num and num <= highest
  end

  local function possiblevoltorb(num)
    local lowest= math.max(0,lines-model.sum)
    local highest= math.max(0,lines-math.ceil(model.sum/3))

    return lowest <= num and num <= highest
  end

  local function validsum(num)
    return 0 <= num and num <= lines*3
  end

  local function validvoltorb(num)
    return 0 <= num and num <= lines
  end

  function thisline.sum:action(c, newvalue)
    local number=tonumber(newvalue)
    if number then
      if validsum(number) then
        if possiblesum(number) then
          model.sum = number
          updateheatmap()
        end
        if #newvalue > 1 or number > 1 then
          --the number has been fully entered
          self.value=newvalue
          advance"sum"
          return iup.IGNORE
        end
      else
        --return iup.IGNORE
      end
    end
  end

  function thisline.sum:spin_cb(number)
    --update the sum count (which we know to be valid
    --  as it came from spinning which is bound etc)
    model.sum = number
    pullsumtext()

    bindvoltorbtosum(number)

    --and update the heatmap
    updateheatmap()
  end

  function thisline.sum:getfocus_cb()
    self.selection="ALL"
  end

  function thisline.sum:killfocus_cb()
    number=tonumber(self.value)
    if number and validsum(number) then
      model.sum=number
      bindvoltorbtosum(number)
      updateheatmap()
    end
    pullsum()
  end

  function thisline.sum:k_any(c)
    if c == iup.K_CR or c == iup.K_TAB then
      advance"sum"
      return iup.IGNORE
    elseif c== iup.K_sTAB then
      retractsum()
      return iup.IGNORE
    end
  end

  function thisline.voltorb:action(c, newvalue)
    local number=tonumber(newvalue)
    if number then
      if validvoltorb(number) then
        if possiblevoltorb(number) then
          model.voltorb = number
          updateheatmap()
        end
        --with this digit, the number has been fully entered
        self.value=newvalue
        advance"voltorb"
        return iup.IGNORE
      else
        --return iup.IGNORE
      end
    end
  end

  function thisline.voltorb:spin_cb(number)
    --update the voltorb count (which we know to be valid
    --  as it came from spinning which is bound etc)
    model.voltorb=number
    pullvoltorbtext()

    bindsumtovoltorb(number)

    --and update the heatmap
    updateheatmap()
  end

  function thisline.voltorb:getfocus_cb()
    self.selection="ALL"
  end

  function thisline.voltorb:killfocus_cb()
    number=tonumber(self.value)
    if number and validvoltorb(number) then
      model.voltorb=number
      bindsumtovoltorb(number)
      updateheatmap()
    end

    pullvoltorb()
  end

  --Define the traversal function callbacks.
  for _, box in pairs(boxtypes) do
    thisline[box].k_any = function (self, c)
      if c == iup.K_CR or c == iup.K_TAB then
        iup.SetFocus(traversals[box].advance)
        return iup.IGNORE
      elseif c== iup.K_sTAB then
        iup.SetFocus(traversals[box].controls)
        return iup.IGNORE
      end
    end
  end
end


function make_callbacks(textboxes,rows,columns,updateheatmap)
  for line=1, lines do
    make_line_callbacks(line,rows[line],textboxes.rows,textboxes.columns,updateheatmap)
    make_line_callbacks(line,columns[line],textboxes.columns,textboxes.rows,updateheatmap)
  end
end
