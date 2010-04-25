--Required for both sizing and positioning
local sizes = require "sizes"
--Required for initializing the default text values.
local formatters = require "controls.formatting"

--Gets used for stuff like where to position the column controls
--(below the bottom of the canvas)
local canvassize=(sizes.card+sizes.cardgap)*lines

--Constructs the controls for a row or column.
local function construct_line_controls(
  axis, --The axis to create on ("rows" or "columns").
  position, --The row/column to create controls for.
  textboxes, --The table containing the textboxes for rows and columns.
  labels, --The table containing the labels for rows and columns.
  defaults --The default numbers for the sum and voltorb textboxes.
  )

  --Localize this line's label and textbox tables.
  local linelabels=labels[axis][position]
  local lineboxes=textboxes[axis][position]

  --Positions for controls:
  local left  --left side of the labels
  local textleft  --left side of the textboxes
  local tops={} --tops of the Voltorb and Sum controls

  --If controls are for a row
  if axis=="rows" then

    left = -- The left of the labels is
      sizes.margin -- the left margin of the window
      + canvassize -- plus the width of the canvas
      + sizes.controls.gap -- plus the gap between the labels and the canvas

    textleft = -- The left of the textboxes is
      left -- the left of the labels
      + sizes.rspace -- plus the width of the entire right
      - sizes.controls.textbox.width -- minus the width of the textboxes
      - sizes.margin -- minus the right margin

    tops.sum = -- The top of the Sum controls is
      sizes.margin -- the top margin of the window
      + (sizes.card + sizes.cardgap) -- plus the cumulative
                                     -- card heights and gaps
        * position -- of every row up to this one
      - sizes.cardgap -- minus this row's gap
      - sizes.card/2 -- and half of its card height to center it
      - sizes.controls.gap/2 -- minus half of the gap between controls
                             -- to center the gap between sum and voltorb
      - sizes.controls.textbox.height -- minus the height of the Sum box
                                      -- to place it above the middle

    tops.voltorb = -- The top of the Voltorb controls is
      tops.sum -- the top of the Sum controls
      + sizes.controls.textbox.height -- plus the height of the Sum textbox
      + sizes.controls.gap -- plus the gap between the controls

  --Otherwise if controls are for a column
  elseif axis=="columns" then

    left = -- The left of the labels is
      sizes.margin -- the left margin of the window
      + (sizes.card + sizes.cardgap) -- plus the cumulative
                                     -- card widths and gaps
        * (position-1) -- of every row before this one

    textleft = -- The left of the textboxes is
      left -- the left of the labels
      + sizes.card -- plus the width of the card
      - sizes.controls.textbox.width -- minus the width of the textboxes

    tops.sum = -- The top of the Sum controls is
      sizes.margin -- the top margin of the window
      + canvassize -- plus the height of the canvas
      + sizes.controls.gap -- plus the gap between the canvas and the controls

    tops.voltorb = -- The top of the Voltorb controls is
      tops.sum -- the top of the Sum controls
      + sizes.controls.textbox.height -- plus the height of the Sum textbox
      + sizes.controls.gap -- plus the gap between the textboxes

  -- if it's not rows or columns then there's a mistake somewhere
  else error "line controls can only be for rows or columns"
  end

  --Create this line's labels
  linelabels.sum= iup.label{title="Sum:", cx=left,cy=tops.sum}
  linelabels.voltorb= iup.label{title="VOLTORB:", cx=left,cy=tops.voltorb}

  --save the string for the size for textboxes
  local textboxsize = sizes.wxh(sizes.controls.textbox.width,
    sizes.controls.textbox.height)

  --Function for creating both textboxes.
  local function maketextbox (box, max)
    lineboxes[box] = iup.text{
      mask = iup.MASK_UINT, -- allow only digits
      alignment = "ARIGHT", --just like in the games
      spin = "YES", -- give us those incrementing arrows on the side and all
      spinauto = "NO", -- since we format the text value ourselves
                       -- we turn off the automatic update of the text value
      spinmax = max, -- set the upper limit for spinning
      spinvalue = defaults[box], -- start at the default for this box
      value = -- start the text with the formatted default
        formatters[box](defaults[box]),
      rastersize = textboxsize, -- use the size specified for textboxes
      cx = textleft, --position the left at the left for textboxes
      cy = tops[box] --position the top at the top for this textbox
    }
  end

  --Make the textboxes
  maketextbox('sum', 3*lines)
  maketextbox('voltorb', lines)
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
      --Create tables for this line in both control tables
      textboxes[axis][line]={}
      labels[axis][line]={}
      --Construct this line's labels and textboxes.
      construct_line_controls(axis,line,textboxes,labels,defaults)
    end
  end
end
