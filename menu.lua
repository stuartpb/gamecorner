-------------------------------------------------------------------------------
-- Required C Libraries
-------------------------------------------------------------------------------

--This module uses menu constructors directly from IUPLua.
local iup = require "iuplua"

-------------------------------------------------------------------------------
-- Mudule functionality
-------------------------------------------------------------------------------

--A function for making actions that visit URLs.
local function goto(url)
  return function() iup.Help(url) end
end

--The function to quit.
local function quit()
  return iup.CLOSE
end

return iup.menu{
  iup.submenu{title="File",
    iup.menu{
      iup.item{title="Quit";action=quit}
    }
  },
  iup.submenu{title="About",
    iup.menu{
      iup.item{title="Wiki page";action=goto "http://www.testtrack4.com/wiki/Game_Corner"},
      iup.item{title="Project page";action=goto "http://launchpad.net/gamecorner"},
    }
  }
}
