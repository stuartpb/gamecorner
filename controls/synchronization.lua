--Functions for synchronizing the controls with the model.

--For formatting the text values appropriately.
local formatters = require "controls.formatting"

return function (thisline,model)
  local frommodel={}
  for datum, formatter in pairs(formatters) do

    --Create table for holding these functions
    frommodel[datum]={}

    --Sets the control's textual value from the model.
    --This functionality is only seperated out of the main pull function
    --for use with spin_cb, because setting the spin value during the
    --spin callback results in issues coming from redundancy.
    --In normal circumstances the main pull function should be used.
    local function pulltext()
      thisline[datum].value=formatter(model[datum])
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
