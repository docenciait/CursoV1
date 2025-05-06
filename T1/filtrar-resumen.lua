-- filtrar-resumen.lua
local utils = require 'pandoc.utils'

function Para(el)
  local txt = utils.stringify(el)
  if #txt > 200 then
    local bullets = {}
    for s in string.gmatch(txt, "([^%.]+%.)") do
      table.insert(bullets, pandoc.Plain { pandoc.Str(s) })
      if #bullets == 2 then break end
    end
    return pandoc.BulletList(bullets)
  end
end
