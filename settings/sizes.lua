local sizes = {
  --Width/height of a card
  card=120,
  --Width of gaps between cards
  cardgap=12,
  --Width of the colored bars behind the cards
  bars=16,
  --Margin between window edge and all controls
  margin=3,
  controls={
    --Gap between controls
    gap=2,
    --Width of textbox groups
    width=60,
    --Heights of textboxes
    height=20
  },
}

--Returns a string in the form of the first integer.."x"..the second.
--Used for specifying sizes in IUP.
function sizes.wxh(width, height)
  return string.format("%ix%i",width,height)
end

return sizes
