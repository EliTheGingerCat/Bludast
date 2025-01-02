local gAstRttiIndex = 0
return function(): number
	gAstRttiIndex += 1
	return gAstRttiIndex
end
