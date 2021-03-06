function params = grid2params(search_params,grid)
%GRID2PARAMS   Get optimum parameters from the results of a grid search.
%
%  params = grid2params(search_params, grid)
%
%  Find the winning cell in the grid, and return a structure with the
%  corresponding parameters. It is assumed that the values in the grid
%  matrix are values like RMSD where smaller values indicate a better
%  fit. To select the largest value instead, change the sign of grid
%  before passing it.
%
%  INPUTS:
%  search_params:  structure containing the ranges of parameters used
%                  in the grid search. Each field should be a cell array
%                  giving the values that were searched over.
%
%           grid:  matrix of values corresponding to some measure of 
%                  fitness. Should have one dimension for each field of
%                  search_params.
%
%  OUTPUTS:
%         params:  structure with the optimum parameters. If there was
%                  a tie for the best set of parameters, params will
%                  have one element for each winning set.
%
%  See also grid_search.

% Copyright 2007-2011 Neal Morton, Sean Polyn, Zachary Cohen, Matthew Mollison.
%
% This file is part of EEG Analysis Toolbox.
%
% EEG Analysis Toolbox is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% EEG Analysis Toolbox is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License
% along with EEG Analysis Toolbox.  If not, see <http://www.gnu.org/licenses/>.

% input checks
if ~exist('search_params','var') || ~isstruct(search_params)
  error('You must pass a structure with the range of parameters in the search.')
elseif ~exist('grid','var') || ~isnumeric(grid)
  error('You must pass a matrix of fitness values.')
end

values = struct2cell(search_params);
names = fieldnames(search_params);

% find the winning spot in the grid
[ind{1:length(values)}] = ind2sub(size(grid), find(grid==min(grid(:))));

% create the winning parameters
for i=1:length(values)
  for j=1:length(ind{i})
    params(j).(names{i}) = values{i}{ind{i}(j)};
  end
end
