local json = require("dkjson")

Queue = class(function(q)
    q.first = 0
    q.last  = -1
  end)

function Queue:push(value)
  local last = self.last + 1
  self.last = last
  self[last] = value
end

function Queue:pop()
  local first = self.first
  if first > self.last then
    error("q is empty")
  end
  local ret = self[first]
  self[first] = nil
  if self.first == self.last then
    self.first = 0
    self.last = -1
  else
    self.first = first + 1
  end
  return ret
end

function Queue:len()
  return self.last - self.first + 1
end

function Queue:clear()
  for i=self.first,self.last do
    self[i]=nil
  end
  self.first = 0
  self.last = -1
end

function Queue:__tojson()
  local ret = {}
  local n = 1
  for i=self.first, self.last do
    ret[n] = self[i]
    n = n+1
  end
  return json.encode(ret)
end
