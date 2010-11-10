-------------------------------------------------------------------------------
-- Required C Libraries
-------------------------------------------------------------------------------

--This module uses the Append function directly from IUPLua.
local iup = require "iuplua"

-------------------------------------------------------------------------------
-- Sub-modules
-------------------------------------------------------------------------------

--Function that constructs controls and stores them in provided tables.
local construct_controls = require "controls.construction"
--Function that gives all controls in provided tables their callbacks.
local make_callbacks = require "controls.callbacks"

-------------------------------------------------------------------------------
-- Constant value definitions
-------------------------------------------------------------------------------

--The number of rows and columns.
--Used to append each textbox into the main
local lines = 5

-------------------------------------------------------------------------------
-- Main function
-------------------------------------------------------------------------------

return function (layout, model, updateheatmap)
  --The textboxes. Used by controls and layout.
  local textboxes={rows={},columns={}}
  --The labels. Not used after layout.
  local labels={rows={},columns={}}

  --Construct controls inside of these tables
  construct_controls(textboxes,labels,model)
  --Add callbacks to these controls
  make_callbacks(textboxes,model,updateheatmap)

  local axes={"rows","columns"}
  local datatypes={"sum","voltorb"}

  --All this is done in a specific order because the order controls
  --are appended to the cbox is used for things like order when you
  --press "tab" - even though I'm overriding that functionality,
  --who's to say what else could use that ordering

  for i_axis=1,2 do
    local axis=axes[i_axis]
    for line=1, lines do
      iup.Append(layout,labels[axis][line])
      for i_datum=1,2 do
        local datum=datatypes[i_datum]
        iup.Append(layout,textboxes[axis][line][datum])
      end
    end
  end

  --Return textboxes so the main script can set initial focus
  --and can update all of them when the model changes independently
  return textboxes
end
