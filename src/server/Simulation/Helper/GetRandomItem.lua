return function(tbl, comparator)
    local trueValues = {}
    for _, value in ipairs(tbl) do
        if comparator(value) then
          table.insert(trueValues, value)  
        end
    end
    return trueValues[math.random(1, #trueValues)]
end