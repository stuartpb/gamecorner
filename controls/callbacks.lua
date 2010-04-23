--Used to get controls to move to when traversing controls.
local traversal = require "controls.traversal"
--Used to keep values valid in relation to each other.
local inter = require "controls.relations"
--Used to synchroniza values from the model.
local syncing = require "controls.synchronization"
--Used to check that values are within the valid range.
local is_legal = require "controls.validation"

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

  local from_model = syncing(thisline,model)

  local constrain_to = inter.constraint(model,from_model)
  local is_valid = inter.validation(model)

  function thisline.sum:action(c, newvalue)
    local number=tonumber(newvalue)
    if number then
      if is_legal.sum(number) then
        if is_valid.sum(number) then
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

  function thisline.voltorb:action(c, newvalue)
    local number=tonumber(newvalue)
    if number then
      if is_legal.voltorb(number) then
        if is_valid.voltorb(number) then
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

  --Define functions that are identical for both controls
  for _, datum in pairs(boxtypes) do
    local thisbox=thisline[datum]

    --Traversal function callbacks
    --for handling Tab key and company
    function thisbox:k_any(c)
      --If the user pressed Enter or Tab
      if c == iup.K_CR or c == iup.K_TAB then
        --advance from this box
        iup.SetFocus(traversals[datum].advance)
        return iup.IGNORE
      --If they pressed Shift+Tab
      elseif c== iup.K_sTAB then
        --go back from this box
        iup.SetFocus(traversals[datum].retract)
        return iup.IGNORE
      end
    end

    --Spin callback when spinning
    function thisbox:spin_cb(number)
      --update the model count (which we know to be legal
      --  as it came from spinning which is bound etc)
      model[datum] = number
      from_model[datum].pulltext()

      --constrain the other datum within the valid range
      --for this new value
      constrain_to[datum](number)

      --and update the heatmap
      updateheatmap()
    end

    --Function to highlight the entire number when getting
    --keyboard focus
    function thisbox:getfocus_cb()
      self.selection="ALL"
    end

    --Function called when losing keyboard focus
    function thisbox:killfocus_cb()
      --Convert this box's value to a number
      number=tonumber(self.value)

      --If the box contains a valid number
      --(which it should unless it's blank)
      --and the number is in the valid range for this datum
      if number and is_legal[datum](number) then
        --Make this the new value for this datum
        model[datum]=number
        --Constrain the other datum to this one
        constrain_to[datum](number)
        --Update the heatmap with this new data
        updateheatmap()
      end

      --Set this control's value to the formatted version
      --of its value in the model
      from_model[datum].pull()
    end

  end
end


function make_callbacks(textboxes,rows,columns,updateheatmap)
  for line=1, lines do
    make_line_callbacks(line,rows[line],textboxes.rows,textboxes.columns,updateheatmap)
    make_line_callbacks(line,columns[line],textboxes.columns,textboxes.rows,updateheatmap)
  end
end
