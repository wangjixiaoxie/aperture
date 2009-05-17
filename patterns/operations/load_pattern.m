function pattern = load_pattern(pat,params)
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
%   'loadSingles' If true (default is false), the pattern will
%                 be loaded as an array of singles.
%
%  NOTES: This function no longer load events. Use load_events(pat.dim.ev)
%  to load the events corresponding to the pattern.
%
%  See also create_pattern, split_pattern.

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
params = structDefaults(params, 'loadSingles',0, 'patnum', []);

% load the pattern
if iscell(pat.file) % pattern is split
  if ~isempty(params.patnum)
    % load just one slice of the pattern
    load(pat.file{params.patnum});
  
  elseif isfield(pat.dim,'splitdim') && ~isempty(pat.dim.splitdim)
    % concatenate along the split dimension to reform the pattern
    pattern = NaN(patsize(pat.dim));
    allDim = {':',':',':',':'};
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

% sanity check the loaded pattern
psize = patsize(pat.dim);
if isempty(pattern)
  error('pattern %s is empty.', pat.name)
elseif any(psize(1:ndims(pattern))~=size(pattern))
  warning('eeg_ana:load_pattern:badPatSize', ...
          'size of pattern %s does not match the dim structure.', pat.name)
end

% change to lower precision if desired
if params.loadSingles
	pattern = single(pattern);
end
