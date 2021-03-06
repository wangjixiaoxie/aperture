function [table, header] = create_pat_report(pat, dim, fig_names, ...
                                             fig_labels, varargin)
%CREATE_PAT_REPORT   Create a PDF report of figures derived from a pattern.
%
%  [table, header] = create_pat_report(pat, dim, fig_names, fig_labels, ...)
%
%  Use this function to prepare a report with one fig object per column,
%  and a dimension label in the first column.
%
%  INPUTS:
%         pat:  a pattern object with fig objects stored in the 'fig'
%               field.
%
%         dim:  dimension to use for labeling each row of the report.
%
%   fig_names:  cell array giving the names of figure objects to
%               include. The order of columns will follow the order that
%               fig names are specified here. If omitted or empty, all 
%               figure objects attached to pat will be used.
%
%  fig_labels:  cell array of strings giving a label for each column of
%               the report. If omitted, the labels of the second non-
%               singleton dimension will be used; if there is only
%               one non-singleton dimension, the fig_name will be used.
%
%  OUTPUTS:
%       table:  cell array of LaTeX code that can be passed into
%               longtable (or similar) to create a PDF report.
%
%      header:  cell array of strings giving the header for the
%               report.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   row_labels_width
%   row_dim_field
%   row_dim_sort

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
if ~exist('pat', 'var')
  error('You must pass a pattern object.')
elseif ~exist('dim', 'var')
  error('You must specify a dimension to use as row labels.')
end
if ~exist('fig_names', 'var') || isempty(fig_names)
  fig_names = {pat.fig.name};
elseif ~iscellstr(fig_names)
  error('fig_names must be a cell array of strings.')
end
if ~exist('fig_labels', 'var')
  fig_labels = {};
elseif ~iscellstr(fig_labels)
  error('fig_labels must be a cell array of strings.')
end

% options
defaults.row_labels_width = [];
defaults.row_dim_field = '';
defaults.row_dim_sort = {};
params = propval(varargin, defaults);

% read the input dimension
[dim_name, dim_number, dim_long_name] = read_dim_input(dim);
pat_size = patsize(pat.dim);

% get a cell array of figure filenames
fig_files = {};
header = {dim_long_name};
for i = 1:length(fig_names)
  fig = getobj(pat, 'fig', fig_names{i});

  % check the dimensions on the filename cell array
  if size(fig.file, dim_number) ~= pat_size(dim_number)
    error('The files on fig object "%s" do not match the %s dimension of pattern "%s".', ...
          fig.name, dim_name, pat.name)
  end
  
  % put the rows dimension first, then any non-singleton dims
  [files, dim_order] = fix_dim(fig.file, dim_number, 2);
  
  % add these column(s)
  fig_files = cat(2, fig_files, files);

  % set the header for these column(s)
  if ~isempty(fig_labels)
    % use user-defined labels
    cols_added = size(files, 2);
    tot_cols = size(fig_files, 2);
    ind = tot_cols - cols_added + 1:tot_cols;
    header(ind + 1) = fig_labels(ind);
  %elseif length(find(size(files)>1))==2
  elseif size(files, 2) > 1
    % the second dimension is non-singleton
    % blank out the header for the first column
    header{1} = '';
    
    % use the labels for this dimension
    dim2_name = read_dim_input(dim_order(2));
    col_labels = get_dim_labels(pat.dim, dim2_name);
    header = [header col_labels];
  else
    % the second dimension is singleton; use the fig_name
    % remove underscores; i'm assuming that people don't mean to use
    % subscripts in their fig_names
    header{end+1} = strrep(fig.name, '_', ' ');
  end
end

% labels for the report
if isempty(params.row_dim_field)
  % use the standard labels
  row_labels = get_dim_labels(pat.dim, dim_name);
else
  this_dim = get_dim(pat.dim, dim_name);
  
  if ischar(params.row_dim_field)
    % get labels directly from a field
    row_labels = getStructField(this_dim, params.row_dim_field);
    if ~iscellstr(row_labels)
      error('%s field %s does not contain strings; cannot use as labels.', ...
            dim_name, params.row_dim_field)
    end
  elseif iscellstr(params.row_dim_field)
    % get all labels
    dim_labels = cell(length(this_dim), length(params.row_dim_field));
    for i = 1:length(params.row_dim_field)
      dim_labels(:,i) = getStructField(this_dim, params.row_dim_field{i});
    end
    
    % create row labels
    row_labels = cell(1, length(this_dim));
    for i = 1:length(this_dim)
      row_labels{i} = strtrim(sprintf('%s ', dim_labels{i,:}));
    end
  end
end

row_labels = cellfun(@(x) strrep(x, '_', ' '), row_labels, ...
                     'UniformOutput', false);

% create the table
table = create_report(fig_files, row_labels, ...
                      'row_labels_width', params.row_labels_width);

% check our outputs
if length(row_labels) ~= size(table,1)
  error('row_labels does not match the number of rows in table.')
elseif length(header) ~= size(table,2)
  error('header does not match the number of columns in table.')
end

% sort the rows
if ~isempty(params.row_dim_sort)
  n_sort = length(params.row_dim_sort);
  n_rows = size(table, 1);
  this_dim = get_dim(pat.dim, dim_name);
  sort_labels = NaN(n_rows, n_sort);
  for i = 1:n_sort
    sort_labels(:,i) = make_event_index(this_dim, params.row_dim_sort{i});
  end
  [y, sort_ind] = sortrows(sort_labels);
  table = table(sort_ind,:);
end


function [y, dim_order] = fix_dim(x, dim1, n_dims)
  %FIX_DIM   Put a specified dimension first, then non-singleton,
  %          then singleton.
  %
  %  y = fix_dim(x, dim1, n_dims)
  
  % input checks
  if ~exist('n_dims', 'var')
    n_dims = ndims(x);
  end
  
  % find non-singleton dimensions
  s = size(x);
  d = find(s > 1);

  if length(d) > n_dims
    error('Too many non-singleton dimensions.')
  end

  % if the first dim is there, remove it from the list
  d = d(d ~= dim1);
  sing = find(s == 1);
  sing = sing(sing ~= dim1);

  % place the first dimension at the beginning, then
  % non-singleton dimensions, then singleton
  dim_order = [dim1 d sing];

  if max(dim_order) > length(dim_order)
    all_dim = 1:max(dim_order);
    to_add = all_dim(~ismember(all_dim, dim_order));
    dim_order = [dim_order to_add];
  end
  
  y = permute(x, dim_order);

