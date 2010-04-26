-------------------------------------------------------------------------------
-- Game Corner modules
-------------------------------------------------------------------------------

--Sizes are required to know where the cursor is.
local sizes = require "settings.sizes"

local scard = sizes.card
local sgap = sizes.controls.gap
local half = scard/2
local cardgap = scard+sgap

-------------------------------------------------------------------------------
-- Module definition
-------------------------------------------------------------------------------

--Sets callbacks for the canvas.
return function(canvas,revealstack, revealarray)
  local scol, srow, sector
  local selected = false

  function canvas:motion_cb(x,y,status)
    local lmb=tonumber(iup.isbutton1(status))==1
    if not lmb or not scol then
      scol = math.floor(x/cardgap)+1
      srow = math.floor(y/cardgap)+1
    end

    local sright=srow*cardgap-sgap
    local sbottom=scol*cardgap-sgap

    if x<=sright and y<=sbottom then
      if lmb and sector then
        if (sector%2==1)==(x>sright-half)
          and (sector>2)==(y>sbottom-half)
        then
          --draw.cardfocus(srow,scol,sector,true)
        end
      else
        if revealarray[srow][scol] then
          srow, scol,sector = nil, nil, nil
        else
          --in case it didn't get unset
          selected=false

          sector = x > sright-half and 1 or 0
          if y>sbottom-half then
            sector=sector+2
          end

          --draw.cardfocus(srow,scol,sector)
        end
      end
    end
  end

  function canvas:button_cb(_,_,x,y,status)
    local lmb=tonumber(iup.isbutton1(status))==1
    local sright=srow*cardgap-sgap
    local sbottom=scol*cardgap-sgap

    if selected then
      if not lmb then
        selected=false
        if x<=sright and y<=sbottom
          and (sector%2==1)==(x>sright-half)
          and (sector>2)==(y>sbottom-half)
        then
          reveals[#reveals+1]={
            column=scol,row=srow,
            card=sector}
          revealarray[srow][scol]=sector
        end
      end
    else
      scol = math.floor(x/cardgap)+1
      srow = math.floor(y/cardgap)+1
      if revealarray[srow][scol] then
        srow,scol,sector=nil,nil,nil
      else
        sector = x > sright-half and 1 or 0
        if y>sbottom-half then
          sector=sector+2
        end

        if lmb then
          selected=true
          --draw.cardfocus(srow,scol,sector,true)
        end
      end
    end
  end

end
