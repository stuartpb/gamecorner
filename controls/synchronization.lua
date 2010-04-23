--Functions for synchronizing the controls with the model.

--The number of digits for both textboxes.
local digits={sum=2,voltorb=1}

--The format parameters to string.format to fill with zeroes
--for that many digits.
local formats={}
for k, digits in pairs(digits) do
  formats[k]=string.format("%%0%ii",digits)
end

return function (thisline,model)
  local frommodel={}
  for datum, formatstring in pairs(formats) do

    --Create table for holding these functions
    frommodel[datum]={}

    --Sets the control's textual value from the model.
    --This functionality is only seperated out of the main pull function
    --for use with spin_cb, because setting the spin value during the
    --spin callback results in issues coming from redundancy.
    --In normal circumstances the main pull function should be used.
    local function pulltext()
      thisline[datum].value=string.format(formats[datum],model[datum])
    end

    --Pulls the control's state from the model.
    local function pull()
      --Set the spin value
      thisline[datum].spinvalue=model[datum]
      --Set the text value
      pulltext()
    end

    frommodel[datum].pulltext=pulltext
    frommodel[datum].pull=pull
  end

  return frommodel
end
