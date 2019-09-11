
curse = require 'curse'

function love.load()
  rhombGrid = curse.createRhomboidalGrid(7, 7, 64, 50, 50)
  -- rectGrid = curse.createRectangularGrid(7, 7, 32, 50, 350)
  -- hexGrid = curse.createHexagonalGrid(7, 32, 450, 50)
end

function love.update()
  mx, my = love.mouse.getPosition()
  highlighted = rhombGrid:containingHex(mx, my) -- or rectGrid:containingHex(mx, my) or hexGrid:containingHex(mx, my)
end

function love.draw()
  love.graphics.line(300, 500, 364, 500)
  love.graphics.setColor(0,200,255,200)
  -- love.graphics.line(0,50,1000,50)
  -- love.graphics.line(0,350,1000,350)
  -- love.graphics.line(50,0,50,1000)
  -- love.graphics.line(450,0,450,1000)

  love.graphics.setColor(255,255,255,255)
  for hex in rhombGrid:hexIterator() do
    drawHexagon(hex)
  end

  -- for hex in rectGrid:hexIterator() do
  --   drawHexagon(hex)
  -- end

  -- for hex in hexGrid:hexIterator() do
  --   drawHexagon(hex)
  -- end

  if (highlighted) then
    -- Redraw highlighted so it gets drawn on top of white lines
    drawHexagon(highlighted)
    neighbors = highlighted:directedNeighbors()
    text = ''
    for dir, neighbor in pairs(neighbors) do
      text = text .. ('%s: %s, %s\n'):format(dir, neighbor.q, neighbor.r)
    end
    center = highlighted.grid:hex(4, 4)
    dirToCenter = highlighted:direction(center)
    if dirToCenter ~= nil then
      text = text .. ('\n%s towards (4, 4)\n'):format(dirToCenter)
      for _, linecell in ipairs(highlighted:line(dirToCenter, highlighted:distance(center)+1)) do
        text = text .. ('(%d, %d)\n'):format(linecell.q, linecell.r)
      end
    end
    love.graphics.print(text, 100, 350)
  end
end

function drawHexagon(hex)
  local c = {love.graphics.getColor()}
  if hex == highlighted then
    love.graphics.setColor(0, 200, 255, 200)
  end
  love.graphics.polygon(
    'line',
    hex.vertices[1].x, hex.vertices[1].y,
    hex.vertices[2].x, hex.vertices[2].y,
    hex.vertices[3].x, hex.vertices[3].y,
    hex.vertices[4].x, hex.vertices[4].y,
    hex.vertices[5].x, hex.vertices[5].y,
    hex.vertices[6].x, hex.vertices[6].y
  )

  love.graphics.print(('(%d, %d)'):format(hex.q, hex.r), hex.center.x - 17, hex.center.y - 7)
  love.graphics.setColor(c)
end
