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

-- The number of rows and columns.
local lines = 5

--For error reporting
local posstrings={[0]="Voltorb",'1','2','3'}

--The possible combinations for each number for each number of
--non-voltorb cards.
local combosets={}

--Make a table for every possible sum containing the possible sets of cards
--that could yield that sum.
for open=1,lines do

  --Make a table for each possible sum for this number of non-zero cards.
  local sums={}; combosets[open]=sums
  for sum=open, open*3 do
    sums[sum]={}
  end

  --Calculate every possible set with these cards and place them
  --in the table for that sum.

  --For every possible number of cards with a 1 on them
  for onesend=0, open do
    --For every subsequently possible number of cards with a 2 on them
    for twosend=onesend, open do

      --running sum of all cards
      local sum=0

      --start with a zero count for 1, 2, and 3
      local set={0,0,0}

      --for each card
      for i=1,open do

        --determine the number on this card by the counts in this loop
        local thiscard= i>twosend and 3 or (i>onesend and 2 or 1)

        --add the number on this card to the sum
        sum=sum+thiscard

        --add to the number of this card in this set
        set[thiscard]=set[thiscard]+1

      end

      --add this set to the table for all possible card combinations
      --for this sum
      local thissumcombos = sums[sum]
      thissumcombos[#thissumcombos+1] = set
    end
  end
end

---- Functions --------------------------------------------

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

  local errs

  local function adderr(t)
    errs = errs or {}
    errs[#errs+1]=t
  end

  --Make adjusted row and column counts
  local adj={}
  for axis, t in pairs(model) do
    adj[axis]={}
    for i=1,lines do
      adj[axis][i]={}
      --initialize the card numbers to 5
      --(we're counting Voltorbs)
      adj[axis][i].cards = lines
      --we're also going to adjust Voltorb,
      --you know, in case Voltorb are getting revealed
      --(even though they really shouldn't)
      adj[axis][i].voltorb = t[i].voltorb
      adj[axis][i].sum = t[i].sum
    end
  end

  local definite={}
  local flips={}

  --For every row,
  for row=1,lines do
    definite[row]={}
    --for every card,
    for col=1, lines do
      --if this card has been revealed
      if revealed[row][col] then
        definite[row][col]=revealed[row][col]
        --add it to the definite numbers
        flips[#flips+1]={row=row,col=col,val=revealed[row][col]}
      end
    end
  end

  --recursive evaluation for all definite cards
  function calc_with_defs(defs)
    for i=1, #defs do
      local row=defs[i].row
      local col=defs[i].col
      local val=defs[i].val

      definite[row][col]=val

      --reduce the row and column adjustments accordingly
      adj.rows[row].sum=adj.rows[row].sum - val
      adj.columns[col].sum=adj.columns[col].sum - val

      adj.rows[row].cards=adj.rows[row].cards - 1
      adj.columns[col].cards=adj.columns[col].cards - 1

      if val == 0 then
        if adj.rows[row].voltorb <= 0 then
          adderr{row,"row","Too many Voltorb revealed"}
        else
          adj.rows[row].voltorb = adj.rows[row].voltorb - 1
        end
        if adj.columns[col].voltorb <= 0 then
          adderr{"column",col,"Too many Voltorb revealed"}
        else
          adj.columns[col].voltorb = adj.columns[col].voltorb - 1
        end
      end

      if adj.rows[row].cards < adj.rows[row].voltorb then
        adderr{row,"row","Too many non-Voltorb revealed"}
      end
      if adj.columns[col].cards < adj.columns[col].voltorb then
        adderr{"column",col,"Too many non-Voltorb revealed"}
      end
    end

    --get the card counts for each row and column
    local counts={}
    for axis,t in pairs(adj) do
      counts[axis]={}
      for line=1, lines do
        local nums = t[line].cards-t[line].voltorb
        if t[line].cards==0 --all the cards have been revealed
          or nums<0 --or there are too many Voltorbs
        then
          --just skip this case
        elseif nums==0 then
          counts[axis][line]={[0]=1,0,0,0}
        else
          local sumsets = combosets[nums][t[line].sum]
          if sumsets then
            counts[axis][line]={[0]=0,0,0,0}
            for _,set in pairs(sumsets) do
              for i = 1, 3 do
                counts[axis][line][i] = counts[axis][line][i] + set[i]/#sumsets
              end
            end
            counts[axis][line][0] = counts[axis][line][0] + t[line].voltorb
          else
            local errmsg =
              string.format("Can't reach %i with %i cards",t[line].sum,nums)
            if axis=="rows" then
              adderr{line,"row",errmsg}
            elseif axis=="columns" then
              adderr{"column",line,errmsg}
            end
          end
        end
      end
    end


    local discoveries

    local function discover(row,col,val)
      discoveries= discoveries or {}
      discoveries[#discoveries+1]={row=row,col=col,val=val}
    end

    --For every row,
    for row=1,lines do
      --for every card,
      for col=1, lines do
        do
          if definite[row][col] then
            local certainty=definite[row][col]
            for i=0,3 do
              probs[row][col][i] = i==certainty and 1 or 0
            end
          elseif counts.rows[row] and counts.columns[col] then
            local set={[0]=0,0,0,0}
            local sum=0
            local shonuff
            for i=0,3 do
              local odds=math.sqrt(counts.rows[row][i])
                *math.sqrt(counts.columns[col][i])

              --if this value is possible
              if odds~=0 then
                --save the first value added
                if sum==0 then shonuff=i
                --if a value has already been added, we're not certain
                else shonuff=false end
              end
              set[i]=odds
              sum=sum+odds
            end
            if sum==0 then
              adderr{row,col,"No possible card"}
            else
              for i=0,3 do
                probs[row][col][i]=set[i]/sum
              end
              if shonuff then discover(row,col,shonuff) end
            end
          end
        end
      end
    end

    if discoveries then return calc_with_defs(discoveries)
    else return errs end
  end

  return calc_with_defs(flips)
end
