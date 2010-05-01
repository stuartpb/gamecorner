-------------------------------------------------------------------------------
-- Required C Libraries
-------------------------------------------------------------------------------

--on top of defining several callbacks for an IUP canvas, this module calls
--iup.isbutton1 directly.
require "iuplua"

--despite calling the Flush function of a CD canvas directly, this module
--uses no functions from CanvasDraw itself.

-------------------------------------------------------------------------------
-- Game Corner modules
-------------------------------------------------------------------------------

--Sizes are required to know where the cursor is.
local sizes = require "settings.sizes"
--These callbacks initiate per-card drawing.
local draw = require "drawing"

-------------------------------------------------------------------------------
-- Local constants
-------------------------------------------------------------------------------

local scard = sizes.card
local sgap = sizes.cardgap
local half = scard/2
local cardgap = scard+sgap

-------------------------------------------------------------------------------
-- Objects passed on module function call
-------------------------------------------------------------------------------

local iupcanvas, cdcan, selection, colors,
  updateheatmap, undobutton, suppress

-------------------------------------------------------------------------------
-- Helper functions
-------------------------------------------------------------------------------

--Returns the sector on the card of the cursor position, followed by the row
--and column, or nil if the cursor is not on a card.
local function oncard(x,y)
    local left = x-x%cardgap
    local top = y-y%cardgap
    local right=left+scard
    local bottom=top+scard

    if x>=left and x<right and y<bottom and y>=top
    then
      local sector=x > left+half and 1 or 0

      if y>top+half then
        sector=sector+2
      end

      return sector, math.floor(y/cardgap)+1, math.floor(x/cardgap)+1
    else return nil end
end

local function motion(mousedown,sector,row,column)
  local current=selection.focus
  local revealed=selection.revealed

  local swapbuffers

  --if the mouse button is currently pressed
  if mousedown then
    --if it's in a selection action (ie. the hold
    --didn't start inside a gap)
    if current.selected then
      if sector==current.sector
      and row==current.row and column==current.column
      then
        draw.cardfocus(cdcan,row,column,sector,true)
      else
        --draw the card like nothing was on it
        draw.card(cdcan,current.row,current.column,
          colors[current.row][current.column])
      end

      swapbuffers=true
    end
  else --if the mouse button is not currently considered held down
    current.selected=false --reaffirm that nothing is selected

    --if the cursor was previously within a card that it is not
    if current.sector and (
      current.row~=row
        or current.column~=column)
    then
      --replace the card
      draw.card(cdcan,current.row,current.column,
        colors[current.row][current.column])
      swapbuffers=true
    end

    if sector and revealed[row][column] then
      current.sector=nil
      current.row=nil
      current.column=nil
    else
      --if entering a new sector/card
      if sector and (
        current.row~=row
          or current.column~=column
          or current.sector~=sector)
      then
        draw.cardfocus(cdcan,row,column,sector)
        swapbuffers=true
      end
      current.sector=sector
      current.row=row
      current.column=column
    end
  end

  if swapbuffers then cdcan:Flush() end
end

local function button(mousedown,sector,row,column)
  local current=selection.focus
  local revealed=selection.revealed

  --if the mouse button was held before this
  if current.selected then
    --if the left mouse button is being released
    if not mousedown then
      --state that we are no longer holding the button down
      current.selected=false
      --if we're within the selected card and sector
      if current.row==row and current.column == column
        and current.sector == sector
      then
        --push a clear (as that's what all cursors over a flipped card are)
        --focus onto the stack
        selection.focus={
          row=nil,
          column=nil,
          sector=nil,
          last=current
        }

        --set this card's flipped value
        revealed[row][column]=sector
        --recalculate the odds with this change
        --and display them
        updateheatmap()
        undobutton.active="YES"
      end
    end

  else --if the left mouse button was not already down
    --if the cursor was on a valid card
    if sector and not revealed[row][column] then
      current.row = row
      current.column = column
      current.sector =  sector

      if mousedown then
        current.selected=true
        draw.cardfocus(cdcan,row,column,sector,true)
        cdcan:Flush()
      end
    end
  end
end

-------------------------------------------------------------------------------
-- Module definition
-------------------------------------------------------------------------------

--Sets callbacks for the canvas.
return function(...)
  iupcanvas, cdcan, selection, colors,
  updateheatmap, undobutton, suppress = ...

  function iupcanvas:motion_cb(x,y,status)
    if not suppress() then
      motion(iup.isbutton1(status),oncard(x,y))
    end
  end

  function iupcanvas:button_cb(mousebutton,pressed,x,y,status)
    if not suppress() then
      local lmb_pressed
      if mousebutton==iup.BUTTON1 then
        lmb_pressed = pressed==1
      else
        lmb_pressed = iup.isbutton1(status)
      end

      button(lmb_pressed,oncard(x,y))
    end
  end

  function iupcanvas:leavewindow_cb()
    local focus=selection.focus

    if focus.sector then
      draw.card(cdcan,focus.row,focus.column,
        colors[focus.row][focus.column])
      cdcan:Flush()
    end

    if not focus.selected then
      focus.sector=nil
      focus.row=nil
      focus.column=nil
    end

  end

end
