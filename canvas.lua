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
-- Helper functions
-------------------------------------------------------------------------------

--Returns the sector on the card of the cursor position, followed by the row
--and column, or nil if the cursor is not on a card.
local function oncard(x,y)
    local left = x-x%cardgap
    local top = y-y%cardgap
    local right=left+scard
    local bottom=top+scard

    if x>=left and x<=right and y>=bottom and y<=top
    then
      local sector=x > left+half and 1 or 0

      if y>top+half then
        sector=sector+2
      end

      return sector, math.ceil(y/cardgap), math.ceil(x/cardgap)
    else return nil end
end

-------------------------------------------------------------------------------
-- Module definition
-------------------------------------------------------------------------------

--Sets callbacks for the canvas.
return function(iupcanvas,cdcan,selection,probs)

  function iupcanvas:motion_cb(x,y,status)
    local lmb_pressed=tonumber(iup.isbutton1(status))==1

    local current=selection.focus
    local revealed=selection.revealed

    local sector, row, column = oncard(x,y)

    local swapbuffers

    --if the mouse button is currently pressed
    if lmb_pressed then
      --if it's in a selection action (ie. the hold
      --didn't start inside a gap)
      if current.selected then
        if sector==current.sector
        and row==current.row and column==current.column
        then
          --draw.cardfocus(srow,scol,sector,true)
        else
          --draw the card like nothing was on it
          draw.card(cdcan,current.row,current.column,
            probs[current.row][current.column])
        end

        swapbuffers=true
      end
    else --if the mouse button is not currently considered held down
      current.selected=false --reaffirm that nothing is selected

      --if the cursor was previously within a card that it is not
      if current.sector and (
        current.row~=row
          or current.column~=column
          or current.sector~=sector)
      then
        --replace the card
        draw.card(cdcan,current.row,current.column,
          probs[current.row][current.column])
        swapbuffers=true
      end

      if sector and revealed[row][column] then
        current.sector=nil
        current.row=nil
        current.column=nil
      else
        if sector then
          --draw.cardfocus(srow,scol,sector)
        end
        current.sector=sector
        current.row=row
        current.column=column
      end
    end

    if swapbuffers then cdcan:Flush() end
  end

  function iupcanvas:button_cb(_,_,x,y,status)
    local current=selection.focus
    local revealed=selection.revealed

    local lmb_pressed=tonumber(iup.isbutton1(status))==1

    local sector, row, column = oncard(x,y)

    --if the mouse button was held before this
    if current.selected then
      --if the left mouse button is being released
      if not lmb_pressed then
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

          --mark this card as
          revealed[row][column]=sector
          --draw.flippedcard(cdcan,row,column,sector)
          --swapbuffers=true
        end
      end

    else --if the left mouse button was not already down
      --if the cursor was on a valid card
      if sector and not revealed[row][column] then
        current.row = row
        current.column = column
        current.sector =  sector

        if lmb_pressed then
          current.selected=true
          --draw.cardfocus(srow,scol,sector,true)
        end
      end
    end
  end

  function iupcanvas:leavewindow_cb()
    local focus=selection.focus

    if focus.sector then
      draw.card(cdcan,focus.row,focus.column,
        probs[focus.row][focus.column])
      cdcan:Flush()
    end

    if not focus.selected then
      focus.sector=nil
      focus.row=nil
      focus.column=nil
    end

  end

end
