function map = getConservativeOccupancyMap(riskMap)
%GETCONSERVATIVEOCCUPANCYMAP Return the union map for a planner interface.
    map = riskMap.staticConservativeMap;
end
