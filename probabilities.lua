--[[---------------------------------------------------------------------------
The probability calculation algorithm.

  This file specifies the function that defines the probabilities of each
  possible value for each card. It recieves the sums and Voltorb counts
  for each row and column, as well as the table to put the results it
  calculates into. The specific interface is defined in the beginning of the
  "Interface function" section.

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

---- Variables --------------------------------------------

-- To be clear, this is where we start the implementation-specific stuff for
-- my naive algorithm. A smart algorithm would have a much smarter approach.

--The data for the average card's probability for each row and column.
local lineprobs={rows={},columns={}}

---- Functions --------------------------------------------

--Calculate the probabilities for all card in each row and column.
local function calculate_rcprobs(model, reveals)

  --For both rows and columns
  for _, axis in pairs{"rows","columns"} do
    local data=model[axis]
    local rcprobs=lineprobs[axis]

    --For each row/column
    for line=1, lines do

      local flipped={[0]=0,0,0,0}
      local fliptotal=0
      for i=1, lines do
        local card
        if axis=="rows" then
          card=reveals[line][i]
        else
          card=reveals[i][line]
        end
        if card then flipped[card]=flipped[card]+1 fliptotal=fliptotal+1 end
      end

      --The number of cards with a number on them
      local nonzero = lines-data[line].voltorb
      local hidden= nonzero-fliptotal+flipped[0]

      --The average number on each card with a number on it
      local average = (data[line].sum
        -flipped[1]-flipped[2]*2
        -flipped[3]*3)/(hidden)

      --Function to calculate how close the average is to the parameter
      --(bottoming out at 0)
      local function oneoff(num)
        return 1-math.min(1,math.abs(average-num))
      end

      --Each number's odds, by this calculation
      local oneodds = oneoff(1)
      local twoodds = oneoff(2)
      local threeodds = oneoff(3)

      local open=lines-fliptotal

      --if every card in this line has been flipped,
      --set this line's probabilities exactly
      if open==0 then
        rcprobs[line]={}
        for i=0,3 do
          rcprobs[line][i]=flipped[i]/lines
        end

      else
        --The probability for each row/column:
        rcprobs[line]={

          --The probability of a Voltorb is as simple as the number of Voltorbs
          --in the row or column out of the number of cards in a row/column
          [0]=data[line].voltorb/open,

          --The probability of each number is the probability of that number
          --within the probability of the card being a number at all
          [1]=oneodds*(nonzero/lines),
          [2]=twoodds*(nonzero/lines),
          [3]=threeodds*(nonzero/lines),
        }
      end
    end
  end
end

-------------------------------------------------------------------------------
-- Interface function
-------------------------------------------------------------------------------
return function (

  model, -- Parameter 1: Table of input.
          -- A table containing two tables, one at the index 'rows',
          -- and the other at the index 'columns', which each have five tables
          -- (one for each row / column, numbered from top to bottom (for rows)
          -- and left to right (for columns)). Each row / column's table contains
          -- two values: the sum of all that row / column's cards, found at the
          -- index 'sum', and the number of Voltorb in that row / column, found
          -- at the index 'voltorb'.

          -- (So, to get the number of Voltorb in the second row from the top,
          -- you would check "model.rows[2].voltorb".)

  revealed, --Parameter 2: Table of input.
          -- A table containing 5 tables (one for each row from top to
          -- bottom), with any revealed cards being at the index of their
          -- column in this row. The revealed value on the card is represented
          -- as a number, with 0 meaning Voltorb. If an index is nil, it means
          -- that that card has not been flipped.

          -- For example, if the card at row 2, column 4 had been revealed
          -- as a Voltorb, it would be represented as revealed[2][4] = 0.

  probs -- Parameter 3: Table for output.
          -- A table containing 5 tables (one for each row from top to
          -- bottom), each containing 5 further tables (one for each
          -- column's card in that row). The tables for the cards contain 4
          -- values, at indices 0 (representing the probability that the card
          -- is a Voltorb) through 3 (with 1, 2 and 3 representing the
          -- probability of the card being each of those numbers).

          -- For example, if the card in the bottom-left corner has an equal
          -- probability of being either a Voltorb or a 3, then both
          -- probs[5][1][0] and probs[5][1][3] would be set to 0.5:
          --  - probs[5] represents the cards in the fifth (bottom) row,
          --  - probs[5][1] represents the leftmost card in this row
          --    (the card in the first column from left to right),
          --  - probs[5][1][3] represents the probability that this card
          --    is a "3" card (where, with 1 out of 2 odds, the value is
          --    1/2, or 0.5), and
          --  - probs[5][1][0] represents the probability that this card
          --    is a Voltorb card.

          -- Remember: even though Lua arrays start at 1, zero is still a
          -- valid table index (as are fractions, negatives, strings,
          -- and all other values but nil).
          -- The reason that the Voltorb probability is at the index of 0
          -- instead of an index of "voltorb" or some other arbitrary
          -- identifier is that 0 is Voltorb's numeric yield when totaling
          -- the sum. If your algorithm determines the value for each
          -- possibility by the result from a formula from the row's sum,
          -- you don't have to make Voltorb a special case; If you're
          -- iterating through them, you can do it with a for loop from
          -- 0 to 3; if you're treating them as a seperate case, it's not
          -- too much of a jump to see it as the Voltorb index. Indeed, they
          -- rather look alike: they're both circles, and depending on your
          -- choice of font, they may even have a line through the middle.
  )

  --Implementation for the naive algorithm:

  --calculate the probabilities for these rows and columns
  calculate_rcprobs(model,revealed)

  --For every row,
  for row=1,lines do
    --for every card,
    for col=1, lines do
      --for every possibility,
      for num=0,3 do
        --the probability is the average of the row and column's probability
        probs[row][col][num]=
          lineprobs.rows[row][num]*.5
          + lineprobs.columns[col][num]*.5
      end
    end
  end
end
