--The number of rows and columns.
local lines = 5

--Returns a table of functions that return which
--textboxes to switch focus to for advancing (tab)
--and retracting (shift+tab).
return function(position, thisaxis, otheraxis)
  local thisline=thisaxis[position]

  return {
    sum={
      advance= thisline.voltorb,
      retract= position > 1 and thisaxis[position-1].voltorb
        or otheraxis[lines].voltorb
      },
    voltorb={
      advance= position < lines and thisaxis[position+1].sum
        or otheraxis[1].sum,
      retract= thisline.sum
    }
  }
end
