--Functions for formatting numbers for text.
--Used during initial control creation
--and in callbacks when pulling values from the model.

--The number of digits for both textboxes.
local digits={sum=2,voltorb=1}

--The format parameters to string.format to fill with zeroes
--for that many digits.
local formatters={}
for k, digits in pairs(digits) do
  local zeropad=string.format("%%0%ii",digits)
  formatters[k]=function(value)
    return string.format(zeropad,value)
  end
end

return formatters
