--Functions for determining if a given string represents the final value.
--These functions are called after the given string has been determined
--to be a valid number within the limits for the given datum.

local finished={}

function finished.sum(value)
  local number=tonumber(value)

  return
    --If there is more than one digit or
    #value > 1 or
    --the number is greater than 1
    --(since the only valid 2-digit numbers for the sum start with
    --either 1 or 0, it can only continue if the current digit
    --comes to a number that is less than 1)
    number > 1
end

function finished.voltorb(value)
  --Any number entered for Voltorb is finished, since they're all 1 digit
  return true
end

return finished
