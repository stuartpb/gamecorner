-------------------------------------------------------------------------------
-- Required C Libraries
-------------------------------------------------------------------------------

--This module uses constructors directly from IUPLua.
require "iuplua"

-------------------------------------------------------------------------------
-- Game Corner modules
-------------------------------------------------------------------------------

--Required for both sizing and positioning
local sizes = require "settings.sizes"
--Required for background colors
local colors = require "settings.colors"
--Required for initializing the default text values.
local formatters = require "controls.formatting"
--Required for Voltorb label.
local voltorb = require "images.voltorb"

-------------------------------------------------------------------------------
-- "Constant" value definitions
-------------------------------------------------------------------------------

--Gets used for stuff like where to position the column controls
--(below the bottom of the canvas)
local canvassize=(sizes.card+sizes.cardgap)*lines
local voltwidth=voltorb.width

-------------------------------------------------------------------------------
-- Module functionality
-------------------------------------------------------------------------------

--Constructs the controls for a row or column.
local function construct_line_controls(
  axis, --The axis to create on ("rows" or "columns").
  position, --The row/column to create controls for.
  lineboxes, --The table containing this line's table
             --for storing the sum and Voltorb controls.
  axislabels, --The table containing the labels of all this axis's lines.
  defaults --The default numbers for the sum and voltorb textboxes.
  )

  --Positions for controls:
  local left  --left side of the labels
  local tops={} --tops of the Voltorb and Sum controls

  --If controls are for a row
  if axis=="rows" then

    left = -- The left of the labels is
      sizes.margin -- the left margin of the window
      + canvassize -- plus the width of the canvas
      + sizes.controls.gap -- plus the gap between the labels and the canvas

    tops.sum = -- The top of the Sum controls is
      sizes.margin -- the top margin of the window
      + (sizes.card + sizes.cardgap) -- plus the cumulative
                                     -- card heights and gaps
        * position -- of every row up to this one
      - sizes.cardgap -- minus this row's gap
      - sizes.card/2 -- and half of its card height to center it
      - sizes.controls.gap/2 -- minus half of the gap between controls
                             -- to center the gap between sum and voltorb
      - sizes.controls.height -- minus the height of the Sum box
                                      -- to place it above the middle

    tops.voltorb = -- The top of the Voltorb controls is
      tops.sum -- the top of the Sum controls
      + sizes.controls.height -- plus the height of the Sum textbox
      + sizes.controls.gap -- plus the gap between the controls

  --Otherwise if controls are for a column
  elseif axis=="columns" then

    left = -- The left of the labels is
      sizes.margin -- the left margin of the window
      + (sizes.card + sizes.cardgap) -- plus the cumulative
                                     -- card widths and gaps
        * (position-1) -- of every row before this one
      + sizes.card/2
      - sizes.controls.width/2

    tops.sum = -- The top of the Sum controls is
      sizes.margin -- the top margin of the window
      + canvassize -- plus the height of the canvas
      + sizes.controls.gap -- plus the gap between the canvas and the controls

    tops.voltorb = -- The top of the Voltorb controls is
      tops.sum -- the top of the Sum controls
      + sizes.controls.height -- plus the height of the Sum textbox
      + sizes.controls.gap -- plus the gap between the textboxes

  -- if it's not rows or columns then there's a mistake somewhere
  else error "line controls can only be for rows or columns"
  end

  --Create this line's labels

  axislabels[position]= iup.label{image=voltorb, cx=left,
  cy=tops.voltorb+(sizes.controls.height-voltorb.height)/2}

  local bg=string.format("%i %i %i", unpack(colors.lines[position]))

  --Function for creating both textboxes.
  local function maketextbox (box, max, indent)
    lineboxes[box] = iup.text{
      bgcolor=bg,
      mask = iup.MASK_UINT, -- allow only digits
      alignment = "ARIGHT", --just like in the games
      spin = "YES", -- give us those incrementing arrows on the side and all
      spinauto = "NO", -- since we format the text value ourselves
                       -- we turn off the automatic update of the text value
      spinmax = max, -- set the upper limit for spinning
      spinvalue = defaults[box], -- start at the default for this box
      value = -- start the text with the formatted default
        formatters[box](defaults[box]),
      rastersize = sizes.wxh(sizes.controls.width-indent,
        sizes.controls.height),
      cx = left+indent, --position the left at the left for textboxes
      cy = tops[box] --position the top at the top for this textbox
    }
  end

  --Make the textboxes
  maketextbox('sum', 3*lines, 0)
  maketextbox('voltorb', lines,voltwidth+sizes.controls.gap)
end

--Module Function
--Constructs all controls and places them in tables in the tables at
--the "rows" and "columns" indices in the passed tables.
--Sum and Voltorb textboxes are initialized with the default values
--specified in the third table.
return function (textboxes,labels,defaults)
  --For both rows and columns
  for _, axis in pairs{"rows","columns"} do
    --For each line
    for line=1, lines do
      --Create the table to store this line's textboxes in
      local lineboxes={}
      --Construct this line's labels and textboxes.
      construct_line_controls(axis,line,lineboxes,labels[axis],defaults)
      --Store this line's controls in the greater table
      textboxes[axis][line]=lineboxes
    end
  end
end
