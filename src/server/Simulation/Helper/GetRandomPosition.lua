return function(part, buffer)
	local offsetX = math.random(-(part.Size.X / 2 - buffer), (part.Size.X / 2 - buffer))
	local offsetZ = math.random(-(part.Size.Z / 2 - buffer), (part.Size.Z / 2 - buffer))
	local spawnPosition = part.Position + Vector3.new(offsetX, buffer, offsetZ)
    
    return spawnPosition
end