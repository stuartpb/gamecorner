-------------------------------------------------------------------------------
-- Required C Libraries
-------------------------------------------------------------------------------

--This module uses values directly from IUPLua.
local iup = require "iuplua"

-------------------------------------------------------------------------------
-- Static helper function modules
-------------------------------------------------------------------------------

--Used to check that values are within the valid range.
local is_legal = require "controls.validation"
--Used to check if a value is "finished" (no valid values could come from
--further keystrokes).
local finished = require "controls.finishing"

-------------------------------------------------------------------------------
-- Per-line helper function creation modules
-------------------------------------------------------------------------------

--Used to get controls to move to when traversing controls.
local traversal = require "controls.traversal"
--Used to keep values valid in relation to each other.
local inter = require "controls.relations"
--Used to synchroniza values from the model.
local syncing = require "controls.synchronization"

-------------------------------------------------------------------------------
-- Callback creation
-------------------------------------------------------------------------------

--Function that adds callback functionality to the controls of a line.
local function make_line_callbacks(position, model, thisaxis, otheraxis, updateheatmap)
  local thisline=thisaxis[position]

  --Adjacent controls to each of these controls.
  local traversals = traversal(position,thisaxis,otheraxis)

  --Functions for setting these controls' values from the model
  local from_model = syncing(thisline,model)
  --Functions for constraining the other datum with a new value on this one
  local constrain_to = inter.constraint(model,from_model)
  --
  local is_valid = inter.validation(model)

  --Define functions that are identical for both controls
  for _, datum in pairs{"sum","voltorb"} do
    local thisbox=thisline[datum]

    function thisbox:action(c, newvalue)
      local number=tonumber(newvalue)
      if number then
        if is_legal[datum](number) then
          if is_valid[datum](number) then
            model[datum] = number
            updateheatmap()
          end
          if finished[datum](newvalue) then
            --Set the new value before this control loses focus
            --and its callback for that scenario is called
            self.value=newvalue
            --Move to the next control
            iup.SetFocus(traversals[datum].advance)
            --tell IUP not to bother with its stuff since we've already
            --changed the value
            return iup.IGNORE
          end
        end
      end
      --If the new value isn't a legal number, do nothing.
      --Let users correct it, or whatever: when they change focus,
      --if the value is still invalid it'll be reverted from the model.
    end

    --Traversal function callbacks
    --for handling Tab key and company
    function thisbox:k_any(c)

      --If the user pressed Enter or Tab
      if c == iup.K_CR or c == iup.K_TAB
      then
        --advance from this box
        iup.SetFocus(traversals[datum].advance)
        --Ignore the keystroke since we handled it
        return iup.IGNORE

      --If they pressed Shift+Tab
      elseif c== iup.K_sTAB
      --or period (for keypad navigation)
       or c==iup.K_period
      --or they pressed Backspace and there's nothing in the control
      --(this one's useful for "right side of the keyboard" navigation,
      --similar to how the Enter key moves forward.
      --If it offends you, you can comment the line out.)

      or (c==iup.K_BS and self.value=="")
      then
        --go back from this box
        iup.SetFocus(traversals[datum].retract)
        --Ignore the keystroke since we handled it
        return iup.IGNORE

      --If they pressed the right arrow key
      elseif c==iup.K_RIGHT
      --and the caret was at the right edge
      and tonumber(self.caretpos)==#self.value
      then
        --advance from this box
        iup.SetFocus(traversals[datum].advance)
        --place the caret at the left edge of that box
        traversals[datum].advance.caretpos=0
        --Ignore the keystroke since we handled it
        return iup.IGNORE

      --If they pressed the left arrow key
      elseif c==iup.K_LEFT
      --and the caret was at the left edge
      and tonumber(self.caretpos)==0
      then
        --go back from this box
        iup.SetFocus(traversals[datum].retract)
        --place the caret at the right edge of that box
        traversals[datum].retract.caretpos=#traversals[datum].retract.value
        --Ignore the keystroke since we handled it
        return iup.IGNORE

      end
    end

    --Spin callback when spinning
    function thisbox:spin_cb(number)
      --update the model count (which we know to be legal
      --  as it came from spinning which is bound etc)
      model[datum] = number

      --update the control's text value
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

    --Function to override the standard OS textbox click functionality which
    --clears the selection after changing the focus
    function thisbox:button_cb(button, pressed)
      --if clicking in a non-focused text box
      if button == iup.BUTTON1 and pressed==1 and iup.GetFocus()~=self then
        --Set the focus manually
        iup.SetFocus(self)
        --do not forward the click to the OS
        return iup.IGNORE
      end
    end

    --Function called when losing keyboard focus
    function thisbox:killfocus_cb()
      --Convert this box's value to a number
      number=tonumber(self.value)

      --If the box contains a valid number (which it should unless it's blank)
      if number
        --and the number is in the valid range for this datum
        and is_legal[datum](number)
        --and it is different from what is currently reflected in the model
        and number ~= model[datum]
      then
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

--Module Function
--sets callbacks for all textboxes in the passed table, with updates to the relevant
--table in the model and calls to the passed function for updaing the heatmap
--where relevant.
return function(textboxes,model,updateheatmap)
  --For each set of lines
  for line=1, lines do
    --Make callbacks for this row
    make_line_callbacks(line,
      model.rows[line],
      textboxes.rows,textboxes.columns,
      updateheatmap)
    --Make callbacks for this column
    make_line_callbacks(line,
      model.columns[line],
      textboxes.columns,textboxes.rows,
      updateheatmap)
  end
end
