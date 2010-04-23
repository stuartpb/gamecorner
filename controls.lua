-------------------------------------------------------------------------------
-- Sub-modules
-------------------------------------------------------------------------------

require "controls.construction"
require "controls.callbacks"

-------------------------------------------------------------------------------
-- Central table construction
-------------------------------------------------------------------------------

--The textboxes. Used by controls and layout.
local textboxes={rows={},columns={}}
--The labels. Referenced only before layout, at which point it is destroyed.
local labels={rows={},columns={}}

--never gets used?
local function update_controls()
  for line=1, lines do
    textboxes.rows[line].sum.value=rows[line].sum
    textboxes.rows[line].voltorb.value=rows[line].voltorb
    textboxes.columns[line].sum.value=columns[line].sum
    textboxes.columns[line].voltorb.value=columns[line].voltorb
  end
end

--Returns a string in the form of the first integer.."x"..the second.
--Used for specifying sizes in IUP.
function sizestr(width, height)
  return string.format("%ix%i",width,height)
end

local function place_controls(layout,textboxes,labels)

  local axes={"rows","columns"}
  local datatypes={"sum","voltorb"}
  local controlsets={labels,textboxes}

  --All this is done in a specific order because the order controls
  --are appended to the cbox is used for things like order when you
  --press "tab" - even though I'm overriding that functionality
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

-------------------------------------------------------------------------------
-- Main function
-------------------------------------------------------------------------------

function make_controls(layout, rows, columns, updateheatmap, defaults)
  construct_controls(textboxes,labels,defaults)
  make_callbacks(textboxes,rows,columns,updateheatmap)
  place_controls(layout,textboxes,labels)
end
