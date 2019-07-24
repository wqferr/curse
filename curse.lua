local curse = {
  _VERSION     = 'curse 0.2.2',
  _DESCRIPTION = 'A hexagonal grid library for LÖVE',
  _URL         = 'https://github.com/wqferr/curse',
  _LICENSE     = [[
    MIT LICENSE

    Copyright (c) 2011 Enrique García Cota
    Copyright (c) 2019 William Quelho Ferreira

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
}

local grid = {}
local gridMt = {__index = grid}

local cell = {}
local cellMt = {__index = cell}

local abs, min, max = math.abs, math.min, math.max
local ceil, floor = math.ceil, math.floor
local cos, sin = math.cos, math.sin
local sqrt, pi = math.sqrt, math.pi

curse.directions = {
  NE = { 1,-1},
  E  = { 1, 0},
  SE = { 0, 1},
  SW = {-1, 1},
  W  = {-1, 0},
  NW = { 0,-1}
}

curse.direction_names = {
  'NE', 'E', 'SE', 'SW', 'W', 'NW'
}

local function round(num)
  return floor(num+.5)
end

local function roundToNearestHex(q, r)
  -- convert to cube coordinates and round
  local x, y, z = q, r, -q - r
  local rx, ry, rz = round(q), round(r), round(z)

  -- pick the largest difference and 'reset' it so that x + y + z = 0
  local dx, dy, dz = abs(rx - x), abs(ry - y), abs(rz - z)
  if dx > dy and dx > dz then
    rx = -ry - rz
  elseif dy > dz then
    ry = -rx - rz
  else
    rz = -rx - ry
  end

  return rx, ry
end

local function createHex(grid, q, r)
  hex = {q=q, r=r, grid=grid}
  hex.cubecoords = {x=q, y=-q-r, z=r}
  setmetatable(hex, cellMt)
  return hex
end

function curse.createRhomboidalGrid(width, height, hexSize, originX, originY)
  local g = grid:new(hexSize, originX, originY)

  for q = 1, width do
    for r = 1, height do
      g:addHex(q, r)
    end
  end

  return g
end

function curse.createRectangularGrid(width, height, hexSize, originX, originY)
  -- move the origin to the left, so that the top-left hex can be spill,1
  -- this means the bottom-left hex will be 1,height
  local spill = ceil(height/2) - 1
  local ox = (originX or 0) - (hexSize * sqrt(3) * spill)
  local oy = originY or 0

  local g = grid:new(hexSize, ox, oy)

  for r = 1, height do
    local rspill = ceil(r/2) - 1
    local qmin = spill - rspill + 1
    local qmax = qmin + width - 1

    for q = qmin, qmax do
      g:addHex(q, r)
    end
  end

  return g
end

function curse.createHexagonalGrid(diameter, hexSize, originX, originY)
  assert(diameter % 2 == 1, "Hexagonal grid diameter must be odd!")

  local spill = floor(diameter/2)
  local ox = (originX or 0) - (hexSize * sqrt(3) * spill / 2)
  local oy = originY or 0

  local g = grid:new(hexSize, ox, oy)

  for r = 1, diameter do
    local qmin = max(spill - (r - 1), 0) + 1
    local qmax = diameter - max(-spill + (r - 1), 0)

    for q = qmin, qmax do
      g:addHex(q, r)
    end
  end

  return g
end

function grid:new(hexSize, originX, originY)
  local g = {d=hexSize, originX=(originX or 0), originY=(originY or 0), maxQ=0, maxR=0}
  return setmetatable(g, gridMt)
end

function grid:addHex(q, r)
  local d = self.d
  local coordq, coordr = (q - 1), (r - 1) -- pixels are 0-based
  local hex = createHex(self, q, r)

  local w = d * sqrt(3)
  local h = d * 3/2
  hex.x = (w * (coordq + coordr/2)) + self.originX
  hex.y = (h * coordr) + self.originY
  hex.vertices = {}

  for i = 0, 6 do
    local angle = 2 * pi / 6 * (i + 0.5)
    local x = hex.x + (d * cos(angle))
    local y = hex.y + (d * sin(angle))
    hex.vertices[i] = {x=x, y=y}
  end

  self[q] = self[q] or {}
  self[q][r] = hex
  self.maxQ = max(self.maxQ, q)
  self.maxR = max(self.maxR, r)

  return hex
end

function grid:hex(q, r)
  local row = self[q]
  if (row ~= nil) then
    return row[r]
  else
    return nil
  end
end

function grid:hexIterator()
  local q = 1
  local r = 1

  return function()
    for iq = q, self.maxQ do
      if self[iq] ~= nil then
        q = iq

        for ir = r, self.maxR do
          if self[iq][ir] ~= nil then
            r = ir + 1
            return self[iq][ir]
          end
        end

        q = q + 1
        r = 1
      end
    end

    return nil
  end
end

function grid:containingHex(x, y)
  local x, y = x - self.originX, y - self.originY
  local q = 1 + (((1/3 * sqrt(3) * x) - (1/3 * y)) / self.d)
  local r = 1 + (2/3 * y / self.d)
  q, r = roundToNearestHex(q, r)

  return self:hex(q, r)
end

function cell:directedNeighbors()
  neighbors = {}
  for _, dir in ipairs(curse.direction_names) do
    neighbor = self:neighbor(dir)
    if neighbor ~= nil then
      neighbors[dir] = neighbor
    end
  end
  return neighbors
end

function cell:neighbors()
  neighbors = {}
  for _, dir in ipairs(curse.direction_names) do
    neighbor = self:neighbor(dir)
    if neighbor ~= nil then
      table.insert(neighbors, neighbor)
    end
  end
  return neighbors
end

function cell:neighbor(dir)
  displacement = curse.directions[dir]
  assert(displacement ~= nil, 'Illegal direction: '..tostring(dir))
  dq, dr = unpack(displacement)
  return self.grid:hex(self.q + dq, self.r + dr)
end

function cell:direction(other)
  if other.q == self.q and other.r == self.r then
    return nil, 'cells are the same'
  elseif other.cubecoords.x == self.cubecoords.x then
    if other.cubecoords.z > self.cubecoords.z then
      return 'SE'
    else
      return 'NW'
    end
  elseif other.cubecoords.y == self.cubecoords.y then
    if other.x > self.x then
      return 'NE'
    else
      return 'SW'
    end
  elseif other.cubecoords.z == self.cubecoords.z then
    if other.cubecoords.x > self.cubecoords.x then
      return 'E'
    else
      return 'W'
    end
  else
    return nil, 'cells are not aligned along any axis'
  end
end

function cell:line(dir, maxlen)
  maxlen = maxlen or math.huge
  assert(curse.directions[dir] ~= nil, ('illegal direction: %s'):format(dir))
  last = self
  line = {}
  repeat
    table.insert(line, last)
    last = last:neighbor(dir)
  until last == nil or #line >= maxlen
  return line
end

function cell:distance(other)
  return math.max(
    abs(self.cubecoords.x - other.cubecoords.x),
    abs(self.cubecoords.y - other.cubecoords.y),
    abs(self.cubecoords.z - other.cubecoords.z)
  )
end

return curse
