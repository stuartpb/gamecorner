--File for confirming that values are within the legal range.
local legal_value={}

function legal_value.sum(num)
  return 0 <= num and num <= lines*3
end

function legal_value.voltorb(num)
  return 0 <= num and num <= lines
end

return legal_value
