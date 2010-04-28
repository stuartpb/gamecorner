--[[---------------------------------------------------------------------------
The card coloring algorithm.

  This file specifies the function that defines the colors of each card and
  every section of each card (the numbers/circle, the background, and all
  5 squares). It recieves the probabilities of each number for each card,
  as well as the table to put the colors it calculates into and the function
  to use to group the red, blue, and green values. The specific interface is
  defined in the beginning of the "Interface function" section.

  This file can be as complex as desired and structured however you please,
  so long as it returns a function with the defined interface, which takes
  the data in the format described, and returns it in the format described.
  (Also, it's a good idea to stick to locals.)

  The "Algorithm structure" section makes more sense coming from the
  "Interface function" section, which describes the structure of the data
  in full detail.
--]]---------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Algorithm structure
-------------------------------------------------------------------------------

---- Constants --------------------------------------------

-- "lines" is a global representing the number of rows and columns
-- defined as 5 in the main script.

---- Functions --------------------------------------------

--Function to calculate the base color of a passed-in card.
local heatrgb; do

  --The color for each possibility.
  local probabilityheats={
    [0]={255,0,0},
    [1]={255,224,0},
    [2]={0,128,255},
    [3]={0,0,255},
  }

  function heatrgb(card)

    --Table holding the red, green, and blue values.
    local colors = {}
    --Variables holding the maximum color (red, green, or blue)
    --and the average of the colors (not used).
    local max, avg = 0, 0

    --For red, green, and blue
    for rgbi=1,3 do

      --Start the color off at 0
      colors[rgbi]=0

      --For Voltorb through 3
      for num=0,3 do

        --Increase this color by the amount of this color for this number
        --for how likely this color is (ie. if the current color is red
        --and this number is Voltorb, which has a probability on this
        --card of 0.5, increase it by 128 (Voltorb's red value (255) * 0.5)
        colors[rgbi]=colors[rgbi]+
          card[num]*probabilityheats[num][rgbi]

      end

      --If this color is greater than the previous max, make it the new max
      max=math.max(max,colors[rgbi])

      --Add this to the total of colors to average out after the fact
      avg=avg+colors[rgbi]
    end

    --Average the 3 colors that have been summed
    avg=avg/3

    --Determine the multiplier needed to bring the highest color up to
    --at least 164
    local multiplier=math.max(1,1-((max-164)/164))

    --scale up colors by that value
    for rgbi=1,3 do
      colors[rgbi]=math.min(255,colors[rgbi]*multiplier)
    end

    --return red, green, blue
    return unpack(colors)
  end
end

--Function to scale a value linearly between two other values.
local function lin(position, zero, one)
  return zero * (1-position) + one * position
end

--Function to set the indices in a table.
local function setrgb(t,r,g,b)
  t[1]=r; t[2]=g; t[3]=b
end

-------------------------------------------------------------------------------
-- Interface function
-------------------------------------------------------------------------------
return function (
  probs, -- Parameter 1: Table of input.
          -- A table containing 5 tables (one for each row from top to
          -- bottom), each containing 5 further tables (one for each
          -- column's card in that row). The tables for the cards contain 4
          -- values, at indices 0 (representing the probability that the card
          -- is a Voltorb) through 3 (with 1, 2 and 3 representing the
          -- probability of the card being each of those numbers).
          -- Further information can be found in probabilities.lua.
  cardcolors -- Parameter 2: Table for output.
          -- A table containing 5 tables (one for each row from top to
          -- bottom), each containing 5 further tables (one for each
          -- column's card in that row). The tables for the cards contain
          -- tables for the colors for several parts of the card, with the
          -- value at "overall" being the overall color of the card (the
          -- background), the values at indices 0 through 3 being the colors
          -- for the circle, 1, 2, and 3 (representing the numbers and Voltorb
          -- probabilities), and a table at "subsquares" with 5 indices from
          -- 0 through 4, with 0 through 3 representing the background
          -- sections behind their respective numbers and 4 representing
          -- the middle of the card.
  )

  --For each row
  for rownum=1, lines do

    --localize this row
    local row=cardcolors[rownum]

    --For each column
    for colnum=1, lines do

      --Localize this card's table (as 'cell')
      local cell=row[colnum]

      --Localize this card's probabilities table
      local cardprobs=probs[rownum][colnum]

      --Get the overall background color for this card
      local r,g,b = heatrgb(cardprobs)
      setrgb(cell.overall,r,g,b)

      --Function returning the r, g, and b between the card's background
      --color and white based on the fraction taken in.
      local function brightrgb(heat)
        return lin(heat,r,255), lin(heat,g,255), lin(heat,b,255)
      end

      --Function returning the r, g, and b between black and the card's
      --background color based on the fraction taken in.
      local function darkrgb(heat)
        return lin(heat,0,r), lin(heat,0,g), lin(heat,0,b)
      end

      --r, g, and b for the subsquares.
      local darkr, darkg, darkb=darkrgb(.8)

      --Function returning the r, g, and b between the card's subsquares'
      --color and white based on the fraction taken in.
      local function dbrgb(heat)
        return lin(heat,darkr,255), lin(heat,darkg,255), lin(heat,darkb,255)
      end

      --Set the colors for all subsquares
      for i=0,4 do
        setrgb(cell.subsquares[i],darkrgb(.8))
      end

      --Set the colors for all possibilities
      for num=0, 3 do
        setrgb(cell[num],dbrgb(cardprobs[num]))
      end
    end
  end
end
