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

--For error reporting
local posstrings={[0]="Voltorb",'1','2','3'}

--The possible combinations for each number for each number of
--non-voltorb cards.
local combosets={}

--Make a table for every possible sum containing the possible sets of cards
--that could yield that sum.
for open=1,lines do
  local sums={}

  --Make a table for each possible sum for this number of non-zero cards.
  for sum=open, open*3 do
    sums[sum]={}
  end

  --Calculate every possible set with these cards and place them
  --in the table for that sum.
  for onesend=0,open do
    for twosend=onesend,open do
      local sum=0
      local set={}
      for i=1,open do
        local thiscard= i>twosend and 3 or (i>onesend and 2 or 1)
        sum=sum+thiscard
        set[i]=thiscard
      end
      local thissum=sums[sum]
      thissum[#thissum+1]=set
    end
  end

  combosets[open]=sums
end

--Calculate the exact probability for each card for each sum with
--each number of non-zero cards.
local cardprobs={}
for open,sums in pairs(combosets) do

  --The table of sums for this number of non-zero cards.
  local countprobs={}

  for sum,sets in pairs(sums) do

    --The probability of each card for this sum.
    local sumprobs={[0]=0,[1]=0,[2]=0,[3]=0}

    --Total all cards that can contribute to this sum.
    for _,set in pairs(sets) do
      for _, card in pairs(set) do
        sumprobs[card]=sumprobs[card]+1
      end
    end

    --turn the totals into averages
    for i=0,3 do
      sumprobs[i]=sumprobs[i]/(open * #sets)
    end

    countprobs[sum]=sumprobs
  end

  cardprobs[open]=countprobs
end

---- Variables --------------------------------------------

-- To be clear, this is where we start the implementation-specific stuff for
-- this algorithm.

--The average probability for each unflipped card in a row/column.
local lineprobs={rows={},columns={}}

--The distributions of probabilities among possiblities for each row/column.
local dists={rows={},columns={}}

---- Functions --------------------------------------------

local function calc_sureness(axis,line)
  local thisline=lineprobs[axis][line]
  local sureness=1
  for num=0,3 do
    local numsure=math.abs(.25-thisline[num])
    if thisline[num] < .25 then
      numsure=numsure/.25
    else
      numsure=numsure/.75
    end
    sureness=sureness-.25*(1-numsure)
  end
  dists[axis][line]=sureness
end

--Calculate the probabilities for all card in each row and column.
local function calculate_rcprobs(model, reveals)

  --For both rows and columns
  for axis, rcprobs in pairs(lineprobs) do
    local data=model[axis]

    --For each row/column
    for line=1, lines do

    --function for reporting errors for this line
    local function errtable(...)
      local errrow, errcol
      if axis == 'rows' then
        errrow = line
        errcol = 'row'
      elseif axis == 'columns' then
        errcol = line
        errrow = 'column'
      end
      return {{errrow,errcol,string.format(...)}}
    end

      local linesum=data[line].sum
      local voltorbcount=data[line].voltorb

      --The number of cards with a number on them
      local nonzero=lines-voltorbcount
      local open=nonzero

      local flipped={[0]=0,[1]=0,[2]=0,[3]=0}

      for i=1, lines do
        local card
        if axis=="rows" then
          card=reveals[line][i]
        else
          card=reveals[i][line]
        end
        if card then
          flipped[card]=flipped[card]+1
          if card==0 then
            voltorbcount=voltorbcount-1
          else
            linesum=linesum-card
            open=open-1
          end
        end
      end

      --if there were more flipped cards than possible
      if open<0 then
        return errtable(
          "Cannot have %i non-zero flipped cards with %i Voltorb",
          open, voltorbcount)
      --also this one
      elseif flipped[0] > data[line].voltorb then
        return errtable(
          "%i too many Voltorb flipped",
          flipped[0]-data[line].voltorb)

      elseif open==0 then
        if voltorbcount==0 then
          --if every card in this line has been flipped,
          --set this line's probabilities exactly
          rcprobs[line]={}
          for i=0,3 do
            rcprobs[line][i]=flipped[i]/lines
          end
        else
          rcprobs[line]={[0]=1,0,0,0}
        end
      else
        if not cardprobs[open][linesum] then
          return errtable("%i cards can not add up to %i",
            open,linesum)
        else
        --The probability for each row/column:
        rcprobs[line]={

          --The probability of a Voltorb is as simple as the number of Voltorb
          --in the row or column out of the number of cards in a row/column
          [0]=voltorbcount/lines,

          --The probability of each number is the probability of that number
          --within the probability of the card being a number at all
          [1]=cardprobs[open][linesum][1]*(nonzero/lines),
          [2]=cardprobs[open][linesum][2]*(nonzero/lines),
          [3]=cardprobs[open][linesum][3]*(nonzero/lines),
        }
        end
      end
      --calculate this line's distribution
      calc_sureness(axis,line)
    end
  end
end

--Function dictating how much to scale depending on distributions
local function scaleby(self, other)
  if self > other then
    return .5 + .5 * self
  elseif self < other then
    return .5 - .5 * other
  else
    return .5
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

  --Implementation for this algorithm:

  --calculate the probabilities for these rows and columns
  local calcerr = calculate_rcprobs(model,revealed)

  if calcerr then return calcerr end

  --For every row,
  for row=1,lines do
    --for every card,
    for col=1, lines do
      --for every possibility,
      local errs
      for num=0,3 do
        local rowprob = lineprobs.rows[row][num]
        local colprob = lineprobs.columns[col][num]
        if rowprob==1 then
          if colprob==0 then
            errs=errs or {}
            errs[#errs+1]=string.format(
              "Row definite %s\ncolumn has no possibility for it",
              posstrings[num])
          else
            probs[row][col][num]=1
          end
        elseif colprob==1 then
          if rowprob==0 then
            errs=errs or {}
            errs[#errs+1]=string.format(
              "Column definite %s\nrow has no possibility for it",
              posstrings[num])
          else
            probs[row][col][num]=1
          end
        else
          --the probability is the average of the row and column's probability
          probs[row][col][num]=rowprob*scaleby(dists.rows[row],dists.columns[col])
            + colprob*scaleby(dists.columns[col],dists.rows[row])
        end
        if errs then return {{row,col, table.concat(errs,'\n')}} end
      end
    end
  end
end
