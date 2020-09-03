local utils = {}

utils.preferred_screen = function(id)
	if screen:count() >= id then
		return id
	end

	return 1
end


return utils

