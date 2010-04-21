local heatrgb; do
  local probabilityheats={
    [0]={255,0,0},
    [1]={255,224,0},
    [2]={0,128,255},
    [3]={0,0,255},
  }

  function heatrgb(card)
    local colors, max, avg = {}, 0, 0
    for rgbi=1,3 do
      colors[rgbi]=0
      for num=0,3 do
        colors[rgbi]=colors[rgbi]+
          card[num]*probabilityheats[num][rgbi]
      end
      max=math.max(max,colors[rgbi])
      avg=avg+colors[rgbi]
    end
    avg=avg/3
    local multiplier=math.max(1,1-((max-164)/164))
    --scale up color
    for rgbi=1,3 do
      colors[rgbi]=math.min(255,colors[rgbi]*multiplier)
    end

    return unpack(colors)
  end
end

local function lin(position, zero, one)
  return zero * (1-position) + one * position
end


return function (probs,cardcolors,encodergb)
  for rownum=1, lines do
    local row=cardcolors[rownum]
    for colnum=1, lines do
      local cell=row[colnum]

      local cardprobs=probs[rownum][colnum]

      local r,g,b = heatrgb(cardprobs)
      cell.overall = encodergb(r,g,b)

      local function brightrgb(heat)
        return lin(heat,r,255), lin(heat,g,255), lin(heat,b,255)
      end

      local function darkrgb(heat)
        return lin(heat,0,r), lin(heat,0,g), lin(heat,0,b)
      end

      local darkr, darkg, darkb=darkrgb(.8)
      local function dbrgb(heat)
        return lin(heat,darkr,255), lin(heat,darkg,255), lin(heat,darkb,255)
      end

      for i=0,4 do
        cell.subsquares[i]=encodergb(darkrgb(.8))
      end

      for num=0, 3 do
        cell[num]=encodergb(dbrgb(cardprobs[num]))
      end
    end
  end
end
