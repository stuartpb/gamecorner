-------------------------------------------------------------------------------
-- Sub-modules
-------------------------------------------------------------------------------

local construct_controls=require "controls.construction"
--Function that gives all controls their callbacks.
local make_callbacks=require "controls.callbacks"

-------------------------------------------------------------------------------
-- Main function
-------------------------------------------------------------------------------

function make_controls(layout, rows, columns, updateheatmap, defaults)
  --The textboxes. Used by controls and layout.
  local textboxes={rows={},columns={}}
  --The labels. Not used after layout.
  local labels={rows={},columns={}}

  --Construct controls inside of these tables
  construct_controls(textboxes,labels,defaults)
  --Add callbacks to these controls
  make_callbacks(textboxes,rows,columns,updateheatmap)

  local axes={"rows","columns"}
  local datatypes={"sum","voltorb"}
  local controlsets={labels,textboxes}

  --All this is done in a specific order because the order controls
  --are appended to the cbox is used for things like order when you
  --press "tab" - even though I'm overriding that functionality,
  --who's to say what else could use that ordering

  for _, axis in ipairs(axes) do
    for line=1, lines do
      for _, datum in ipairs(datatypes) do
        for _, controls in ipairs(controlsets) do
          iup.Append(layout,controls[axis][line][datum])
        end
      end
    end
  end
end
