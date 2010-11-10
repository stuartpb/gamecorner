--Defines various colors as used in the games.
--The colors for each card by probability are defined by the routines
--in coloring.lua - these are used by drawing.lua for drawing elements
--such as the background and flipped cards.

return {
  --The colors for the lines and controls.
  lines={ --left to right/top to bottom
    {224,112,80},
    {64,168,64},
    {232,160,56},
    {48,144,248},
    {192,96,224}
  },
  rust={184,136,128},
  darkrust={160,88,80},
  grey={160,176,168},
  darkgrey={128,128,128},
  white={248,248,248},
  black={64,64,64},
  gold={232,201,56},
  darkgreen={24,128,96},
  lightgreen={40,160,104}
}
