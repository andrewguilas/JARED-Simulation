local module = {}
module.__index = {}

function module.new(newRoom)
    local self = setmetatable({
        SpawnArea = newRoom.Floor.SpawnArea,
        DespawnArea = newRoom.Floor.DespawnArea,
        Seats = {},
        DisposalAreas = {
            {
                Start = newRoom.DisposalArea.DisposalA.Path.DisposalAreaStart, 
                End = newRoom.DisposalArea.DisposalA.Path.DisposalAreaEnd
            },
		    {
                Start = newRoom.DisposalArea.DisposalB.Path.DisposalAreaStart, 
                End = newRoom.DisposalArea.DisposalB.Path.DisposalAreaEnd}
            
        },
    }, module)

	for _, _table in ipairs(newRoom.Tables:GetChildren()) do
        for __, chair in ipairs(_table:GetChildren()) do
            local seat = chair:FindFirstChildWhichIsA("Seat")
            if seat then
                seat.Disabled = true
    
                local seatData = {
                    Seat = seat,
                    Owner = nil,
                }
    
                table.insert(self.Seats, seatData)
            end
        end
	end

    return self
end

return module