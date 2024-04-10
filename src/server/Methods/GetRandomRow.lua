return function(array)
	-- Calculate cumulative probabilities
	local cumulativeProbability = {}
	local totalProbability = 0
	for _, row in ipairs(array) do
		totalProbability += row.PROBABILITY
		cumulativeProbability[#cumulativeProbability + 1] = totalProbability
	end

	-- Generate a random number between 0 and totalProbability
	local rand = math.random() * totalProbability

	-- Find the corresponding row size based on the random number
	for i, prob in ipairs(cumulativeProbability) do
		if rand <= prob then
			return array[i]
		end
	end
end