--Functions to do with the interrelationships between
--sums and Voltorb counts.
local inter={}

--Creates functions to constrain the other value on a line
--so that it is valid with a new value for the other datum.
--Requires the model (so it can be updated) and the functions
--for updating controls from the model (so they can be used
--after updating the model).
function inter.constraint(model,frommodel)

  local constrain_to={}

  --Binds the Voltorb count to be within the realm of possibility
  --for the passed sum.
  function constrain_to.sum(number)
    local lowest= lines-model.voltorb
    local highest= lowest*3

    --if sum is impossible with current Voltorb count,
    --tweak Voltorb count to permit sum spun to
    while number > highest do
      model.voltorb= model.voltorb-1
      highest = (lines-model.voltorb)*3
    end

    while number < lowest do
      model.voltorb= model.voltorb+1
      lowest = lines-model.voltorb
    end

    --update the Voltorb count displayed
    frommodel.voltorb.pull()
  end

  --Updates the sum value to be within the realm of possibility with
  --the passed number of voltorb.
  function constrain_to.voltorb(number)
    local lowest= lines-number
    local highest= lowest*3

    model.sum=math.max(math.min(model.sum,highest),lowest)

    --update the sum count displayed
    frommodel.sum.pull()
  end

  return constrain_to
end

function inter.validation(model)
  local is_valid={}

  function is_valid.sum(num)
    local lowest= lines-model.voltorb
    local highest= lowest*3

    return lowest <= num and num <= highest
  end

  return is_valid
end

return inter
