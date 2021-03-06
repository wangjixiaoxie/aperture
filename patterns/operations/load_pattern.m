function pattern = load_pattern(pat, params)
%LOAD_PATTERN   Load a pattern from a pat object.
%
%  pattern = load_pattern(pat, params)
%
%  If pat.file is a cell array, the pattern is assumed to be saved in 
%  slices, and will be reconstituted by loading up all the files in 
%  pat.file and concatenating along pat.dim.splitdim.
%
%  INPUTS:
%      pat:  a pat object.
%
%   params:  structure with fields that specify options for loading
%            the pattern.
%
%  OUTPUTS:
%  pattern:  an [events X channels X time X frequency] matrix.
%
%  PARAMS:
%   patnum - specifies a "slice" of the pattern to load. 
%   pat.file{params.patnum} will be loaded.
%
%  See also create_pattern, split_pattern.

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
if ~exist('pat','var')
  error('You must pass a pat object.')
elseif isempty(pat)
  error('The input pat object is empty.')
end
if ~exist('params', 'var')
  params = struct;
end

% set default parameters
params = structDefaults(params, 'patnum', []);

% load the pattern
if iscell(pat.file) % pattern is split
  if ~isempty(params.patnum)
    % load just one slice of the pattern
    load(pat.file{params.patnum});
  elseif isfield(pat.dim,'splitdim') && ~isempty(pat.dim.splitdim)
    % concatenate along the split dimension to reform the pattern
    pattern = NaN(patsize(pat.dim));
    allDim = repmat({':'}, 1, ndims(pattern));
    for i=1:length(pat.file)
      % load this slice
      s = load(pat.file{i});
      
      % add it to the matrix
      ind = allDim;
      ind{pat.dim.splitdim} = i;
      pattern(ind{:}) = s.pattern;
    end    
  else
    % if pat.file is a cell array and there's no information about 
    % which dimension to concatenate along, give up
    error('pat.dim must have a ''splitdim'' field.')
  end
elseif isfield(pat, 'mat') && ~isempty(pat.mat)
  % the pattern is already in the workspace; just return it
  pattern = pat.mat;
else % there is just one file; load it up
  load(pat.file);
end
