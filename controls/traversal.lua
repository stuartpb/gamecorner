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
