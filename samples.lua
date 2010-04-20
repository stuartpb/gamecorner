--sample real-use boards for testing

--example usage:
--in the main file, right before calculating initial probabilities:

--  require "samples"
--  fromsample.set_data(samples.original, rows, columns)
--  update_controls()

samples={
  original={
    {1,0,1,1,1},
    {1,0,0,1,1},
    {2,0,1,1,1},
    {0,1,1,1,2},
    {3,1,2,1,0}
  },
  uno={
    {0,2,1,3,1},
    {0,1,1,1,0},
    {1,0,1,0,1},
    {0,1,1,3,3},
    {0,1,1,1,1}
  },
  dos={
    {1,0,1,0,1},
    {2,0,0,1,2},
    {2,0,1,1,2},
    {0,2,1,1,1},
    {1,0,2,2,0}
  },
  tres={
    {1,1,0,1,1},
    {0,0,1,1,3},
    {0,1,3,0,0},
    {1,1,0,3,3},
    {1,1,1,0,2}
  },
  catorce={
    {2,1,0,1,1},
    {1,3,0,1,1},
    {1,1,1,0,2},
    {1,0,2,1,0},
    {1,0,1,1,2}
  },
  easymode={-- this one's pretty easy
    {1,3,0,1,1},
    {1,1,1,0,3},
    {0,1,1,1,1},
    {0,0,1,1,1},
    {1,3,0,1,1}
  },
  safecol5={-- I hit [5][4] first because it looked safest- D'OH
    {1,1,0,3,1},
    {1,1,0,1,1},
    {0,0,1,3,1},
    {0,1,0,1,1},
    {2,1,1,0,3}
  },
  cascade={-- another easy one if you hit the first column, then go down the fifth
    {1,2,0,1,2},
    {2,0,1,1,2},
    {1,0,1,1,2},
    {1,1,1,0,1},
    {1,1,0,1,0}
  },
  bland={-- BLANDEST. BOARD. EVER. (On Level 2, even!)
    {1,1,1,0,2},
    {0,2,1,2,2},
    {2,0,2,1,1},
    {2,1,1,0,0},
    {0,1,0,1,1}
  },
  dangerzone={-- Don't they know that top row is the... DAAANGAAA ZOONE?
    {0,1,3,0,0},
    {1,0,0,1,1},
    {2,0,2,1,1},
    {2,1,1,0,0},
    {0,1,0,1,1}
  },
  threeclear={-- 3 clear lines? A 1:4 5th column?! This was pretty crazy logical
    {1,1,0,1,0},
    {1,3,1,1,1},
    {1,0,2,1,0},
    {0,1,1,1,0},
    {2,1,1,2,0}
  },
  logic2={-- similarly (72 COINS OH YEAH)
    {0,2,1,1,3},
    {0,2,1,2,1},
    {0,1,3,1,1},
    {0,1,1,0,1},
    {1,0,1,1,0}
  },
  alevel3={-- OH NUTS ROW 4 ([3][2] killed me)
    {2,2,1,1,1},
    {1,1,2,0,0},
    {1,0,1,2,2},
    {0,2,0,0,0},
    {0,1,1,1,2}
  },
  levolt3={-- without dynamic solving or an offseeting algorithm I had to resort to memos to deduce 0 & 1 exclusive rows
    {1,1,2,0,0},
    {1,1,0,1,1},
    {1,0,0,1,1},
    {0,3,1,0,3},
    {0,2,3,1,1}
  },
  level4={-- hot diggity daffodil, that last row on level 4 (216 coins!)
    {2,0,1,0,0},
    {2,1,1,0,3},
    {0,2,1,1,0},
    {1,1,0,0,1},
    {3,1,3,1,1}
  },
  level5={-- I got [2][1] then [2][2] killed me
    {2,0,2,1,0},
    {2,0,2,3,0},
    {2,0,0,1,2},
    {0,2,1,1,1},
    {0,1,0,0,1}
  },
}

--replicated in this file because, hey, why not
local lines=5

fromsample={}
function fromsample.singular_probs(sample)

  local exact_probs={}

  for row=1,lines do
    exact_probs[row]={}
    for col=1, lines do
        exact_probs[row][col]={}
        for i=0, 3 do
          exact_probs[row][col][i]=0
        end
        exact_probs[row][col][sample[row][col]]=1
    end
  end

  return exact_probs
end

function fromsample.set_data(sample, rows, columns)
  for major=1,lines do
    columns[major].sum=0
    columns[major].voltorb=0
    rows[major].sum=0
    rows[major].voltorb=0
    for minor=1, lines do
      columns[major].sum=columns[major].sum + sample[minor][major]
      if sample[minor][major]==0 then columns[major].voltorb = columns[major].voltorb+1 end
      rows[major].sum=rows[major].sum + sample[major][minor]
      if sample[major][minor]==0 then rows[major].voltorb = rows[major].voltorb+1 end
    end
  end
end
