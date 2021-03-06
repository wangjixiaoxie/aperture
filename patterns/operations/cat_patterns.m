function pat = cat_patterns(pats, dimension, varargin)
%CAT_PATTERNS   Concatenate a set of patterns.
%
%  pat = cat_patterns(pats, dimension, ...)
%
%  INPUTS:
%       pats:  a vector of pat objects.
%
%  dimension:  dimension along which to concatenate the patterns. Can be
%              either a string specifying the name of the dimension (can
%              be: 'ev', 'chan', 'time', 'freq'), or an integer
%              corresponding to the dimension in the pattern matrix.
%
%  OUTPUTS:
%        pat:  pat object with metadata for the new concatenated
%              pattern.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   save_mats - if true, mats associated with the new pattern will
%               be saved to disk. If false, modified mats will be stored
%               in the workspace, and can subsequently be moved to disk
%               using move_obj_to_hd. (true)
%   save_as   - name of the concatenated pattern. If all patterns have
%               the same name, defaults to that name; otherwise, the
%               default name is 'cat_pattern'.
%   res_dir   - path to the directory in which to save the new pattern.
%               Default is the same directory as the first pattern in
%               pats.

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

% use the first pattern to set defaults
def_pat = pats(1);
pats_name = unique({pats.name});
if length(pats_name) == 1
  default_pat_name = pats_name{:};
else
  default_pat_name = 'cat_pattern';
end

% get a source identifier to set filenames
source = unique({pats.source});
if length(source) > 1
  source = 'multiple';
else
  source = source{:};
end

% options
defaults.save_mats = true;
defaults.save_as = default_pat_name;
defaults.res_dir = gen_pat_dir(def_pat);
defaults.verbose = true;
defaults.source = source;
params = propval(varargin, defaults);
pat_name = params.save_as;

% input checks
if ~exist('pats', 'var')
  error('You must pass a vector of pat objects.')
end
if ~exist('dimension', 'var')
  dimension = 2;
end

% parse the dimension input
try
  [dim_name, dim_number, dim_long_name, dim_dir_name] = ...
      read_dim_input(dimension);
catch
  if isnumeric(dimension)
    % non-standard dimension; cannot track metadata, but can still
    % concatenate the matrix
    dim_name = '';
    dim_number = dimension;
  else
    error('Invalid dimension.')
  end
end

% print status
if params.verbose
  if length(pats_name) == 1
    fprintf('concatenating "%s" patterns along %s dimension...\n', ...
            pats_name{:}, dim_name)
  else
    fprintf('concatenating patterns along %s dimension...\n', dim_name)
  end
end

% make sure the non-cat dimensions match
pat_sizes = cell(1, length(pats));
for i=1:length(pats)
  full_size = patsize(pats(i).dim);
  pat_sizes{i} = full_size(~ismember(1:length(full_size), dim_number));
end
if ~isequal(pat_sizes{:})
  error('pattern dimensions do not match.')
end

if params.save_mats
  loc = 'hd';
else
  loc = 'ws';
end

% print names if they are unique; otherwise, print sources
if params.verbose
  sources = {pats.name};
  if ~isunique(sources)
    sources = {pats.source};
  end
end

% concatenate the dim structure
dim = def_pat.dim;
if ~isempty(dim_name)
  if params.verbose
    fprintf('%s...', lower(dim_long_name))
  end
  
  % concatenate the dimension for each pattern
  cat_dim = [];
  for i = 1:length(pats)
    if params.verbose
      fprintf('%s ', sources{i})
    end
    pat_dim = get_dim(pats(i).dim, dim_name);
    cat_dim = cat_structs(cat_dim, pat_dim);
  end
  
  % save the concatenated dimension
  dim_dir = fullfile(params.res_dir, dim_dir_name);
  if ~exist(dim_dir)
    mkdir(dim_dir);
  end
  dim.(dim_name).file = fullfile(dim_dir, ...
      objfilename(dim_dir_name, pat_name, params.source));
  dim = set_dim(dim, dim_name, cat_dim, loc);
end

% set the directory to save the pattern
pat_dir = fullfile(params.res_dir, 'patterns');
if ~exist(pat_dir)
  mkdir(pat_dir)
end

% concatenate the pattern
if params.verbose
  fprintf('patterns...')
end
pattern = [];
for i=1:length(pats)
  if params.verbose
    fprintf('%s ', sources{i})
  end
  pattern = cat(dim_number, pattern, get_mat(pats(i)));
end
if params.verbose
  fprintf('\n')
end

% create the new pat object
pat_file = fullfile(pat_dir, ...
                    objfilename('pattern', pat_name, params.source));
pat = init_pat(pat_name, pat_file, params.source, def_pat.params, dim);
if params.verbose
  fprintf('pattern "%s" created.\n', pat_name)
end

% save the new pattern
pat = set_mat(pat, pattern, loc);
if strcmp(loc, 'ws')
  pat.modified = true;
end

