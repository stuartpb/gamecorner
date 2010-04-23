--Required for both sizing and positioning
local sizes = require "minor.sizes"

--Gets used for stuff like where to position the column controls
--(below the bottom of the canvas)
local canvassize=(sizes.card+sizes.cardgap)*lines

local function construct_line_controls(position,axis,textboxes,labels,defaults)

  local linelabels=labels[axis][position]
  local lineboxes=textboxes[axis][position]

  local left, right, sumtop, voltorbtop
  if axis=="rows" then

    left= sizes.margin + canvassize + sizes.controls.gap
    spinleft = left + sizes.rspace
      - sizes.controls.textbox.width
    sumtop = sizes.margin + position*(sizes.card+sizes.cardgap)
      - sizes.card/2 - sizes.controls.gap
      - sizes.controls.textbox.height - sizes.cardgap
    voltorbtop = sumtop + sizes.controls.gap*2
      + sizes.controls.textbox.height

  elseif axis=="columns" then

    left= sizes.margin +
      (position-1)*(sizes.card+sizes.cardgap) + sizes.controls.gap
    spinleft= left + sizes.card
      - sizes.controls.textbox.width - sizes.controls.gap
    sumtop = sizes.margin
      + canvassize + sizes.controls.gap
    voltorbtop= sumtop
      + sizes.controls.textbox.height + sizes.controls.gap

  else error "line controls can only be for rows or columns"
  end

  linelabels.sum= iup.label{title="Sum:", cx=left,cy=sumtop}
  linelabels.voltorb= iup.label{title="VOLTORB:", cx=left,cy=voltorbtop}
  lineboxes.sum=iup.text{spin="YES", mask=iup.MASK_UINT,
    cx=spinleft,cy=sumtop, spinauto="NO",
    spinmax=3*lines, spinvalue=defaults.sum,
    value=string.format("%02i",defaults.sum),
    rastersize=sizes.wxh(sizes.controls.textbox.width,
      sizes.controls.textbox.height)}
  lineboxes.voltorb=iup.text{spin="YES", mask=iup.MASK_UINT,
    cx=spinleft,cy=voltorbtop, spinauto="NO",
    spinmax=lines, value=defaults.voltorb,
    value=string.format("%01i",defaults.voltorb),
    rastersize=sizes.wxh(sizes.controls.textbox.width,
      sizes.controls.textbox.height)}
end

return function (textboxes,labels,defaults)
  for _, axis in pairs{"rows","columns"} do
    for line=1, lines do
      textboxes[axis][line]={}
      labels[axis][line]={}
      construct_line_controls(line,axis,textboxes,labels,defaults)
    end
  end
end
