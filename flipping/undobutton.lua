-------------------------------------------------------------------------------
-- Game Corner modules
-------------------------------------------------------------------------------

--Sizes are required to know how big to make the button and where to put it,
--as well as for formatting the size
local sizes = require "settings.sizes"

-------------------------------------------------------------------------------
-- oh hey it's this guy again
-------------------------------------------------------------------------------

--the height of the canvas, for determining distances from the top.
local canvassize=(sizes.card+sizes.cardgap)*lines

-------------------------------------------------------------------------------
-- Module return
-------------------------------------------------------------------------------

local function makeundobutton(selection,updateheatmap)
  button=iup.button{active="NO",
    title="Undo Flip",rastersize=sizes.wxh(
      sizes.controls.width+sizes.cardgap,
      sizes.controls.height*2+sizes.controls.gap),
      cx=canvassize+sizes.margin+sizes.controls.gap-sizes.cardgap,
      cy=canvassize+sizes.margin+sizes.controls.gap}

  function button:action()
    selection.focus=selection.focus.last

    selection.revealed[selection.focus.row][selection.focus.column]=nil

    selection.focus.row=nil
    selection.focus.column=nil
    selection.focus.sector=nil

    updateheatmap()

    if not selection.focus.last then
      self.active="NO"
    end

  end
  return button
end

return makeundobutton
