local List = {}
function List.new (tick)

  local tick = tick or 0;
  
  return {first = tick, last = tick-1}
end

function List.pushleft (list, value)
  local first = list.first - 1
  list.first = first
  list[first] = value
end

function List.pushright (list, value)
  local last = list.last + 1
  list.last = last
  list[last] = value
end

function List.popleft (list)
  local first = list.first
  if first > list.last then error("list is empty") end
  local value = list[first]
  list[first] = nil        -- to allow garbage collection
  list.first = first + 1
  return value
end

function List.popright (list)
  local last = list.last
  if list.first > last then error("list is empty") end
  local value = list[last]
  list[last] = nil         -- to allow garbage collection
  list.last = last - 1
  return value
end

function List.length(list)
  return (list.last - list.first) + 1;
end

function List.each(list, fn)
  for i = list.first, list.last do
    fn(list[i]);
  end
end

return List;