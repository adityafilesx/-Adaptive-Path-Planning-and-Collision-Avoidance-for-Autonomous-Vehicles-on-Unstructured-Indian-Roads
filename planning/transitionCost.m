function cost = transitionCost(state1, state2, defaultCost)
%TRANSITIONCOST Neutral transition cost for plannerHybridAStar.
%   This function is a pass-through placeholder for Phase 6+ integration
%   with the Adaptive Confidence-Aware Risk Governor (ACARG). It returns
%   the default cost unmodified, so the baseline Hybrid A* behaviour is
%   unchanged when this function is wired into TransitionCostFcn.
%
%   Phase 6 will replace this with risk-weighted cost that queries the
%   normalized risk grid, actor proximity, and confidence scores.
%
%   Inputs:
%       state1      — [x y theta] source pose
%       state2      — [x y theta] target pose
%       defaultCost — scalar default transition cost from the planner
%
%   Output:
%       cost        — scalar transition cost (identity: == defaultCost)

    cost = defaultCost;
end
