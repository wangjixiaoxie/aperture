function pat = pat_statistics(pat,event_bins,fcn_handle,fcn_inputs,stat_name,res_dir)
%PAT_STATISTICS   Run a statistical test on a pattern.
%
%  pat = pat_statistics(pat, event_bins, fcn_handle, fcn_inputs, stat_name, res_dir)
%
%  Use this function to run a test of significance on a pattern. You specify the
%  factors of the test in reference to the events structure corresponding to the
%  pat. The statistical test can be run by any function with a standard signature
%  outlined below.
%
%  INPUTS:
%         pat:  a pat object.
%
%  event_bins:  cell array where each cell specifies one factor to create from
%               each pat's event structure. See make_event_bins for options.
%
%  fcn_handle:  handle to a function that runs a statistical test of the form:
%                [p, statistic] = fcn_handle(chan_vec, group, ...)
%                INPUTS:
%                  chan_vec:  vector of data for one channel concatenated across 
%                             every pattern in pats.
%
%                     group:  cell array of labels with one cell per factor; each
%                             cell can contain an array or a cell array of strings.
%                             group{1} has a unique label for each pattern.
%
%                OUTPUTS:
%                         p:  scalar p-value of the significance test.
%
%                 statistic:  scalar containing the statistic (e.g. t or F) from
%                             which the p-value is derived.
%               Default fcn_handle is @run_sig_test, a which runs a
%               number of common significance tests with standard I/O.
%               
%  fcn_inputs:  cell array of additional inputs to fcn_handle.
%
%   stat_name:  string identifier for the statistic.
%
%     res_dir:  path to directory to save results; if not specified, the pattern's
%               default stats directory is used.
%
%  OUTPUTS:
%        stat:  stat object.
%
%  EXAMPLES:
%   % test for a significant subsequent memory effect
%   pat = pat_statistics(pat, {'recalled'}, @run_sig_test, {'anovan'});

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
  error('You must pass a pat object.')
elseif ~exist('event_bins', 'var')
  error('You must pass a cell array of event bins.')
elseif ~exist('fcn_handle', 'var')
  fcn_handle = @run_sig_test;
end
if ~iscell(event_bins)
  event_bins = {event_bins};
end
if ~exist('fcn_inputs', 'var')
  fcn_inputs = {};
end
if ~exist('stat_name', 'var')
  stat_name = 'stat';
end
if ~exist('res_dir', 'var')
  res_dir = get_pat_dir(pat, 'stats');
elseif ~exist(res_dir, 'dir')
  mkdir(res_dir);
end

fprintf('creating regressors...')
nfact = length(event_bins);
group = cell(1,nfact);

% load the events for this pattern
events = get_mat(pat.dim.ev);

% make the regressors
for i=1:length(event_bins)
  group{i} = make_event_bins(events, event_bins{i})';
end

% set the path to the MAT-file that will hold the results
stat_file = fullfile(res_dir, objfilename('stat', stat_name, pat.source));

% initialize the stat object
params.event_bins = event_bins;
stat = init_stat(stat_name, stat_file, pat.source, params);

fprintf('running %s on %s...\n', func2str(fcn_handle), pat.name)

% set the size of the output variables
psize = patsize(pat.dim);
%p = NaN(nfact,psize(2),psize(3),psize(4));
%statistic = NaN(nfact,psize(2),psize(3),psize(4));

if ~isfield(pat.dim,'splitdim') || isempty(pat.dim.splitdim) || pat.dim.splitdim~=2
  % load the whole pattern
  full_pattern = load_pattern(pat);
else
  full_pattern = [];
end

fprintf('channel: ');
step = floor(psize(3)/4);
p = [];
statistic = [];
for c=1:psize(2)
  fprintf('%s ', pat.dim.chan(c).label);
  
  if ~isempty(full_pattern)
    % grab this slice
    pattern = full_pattern(:,c,:,:);
  else
    % nothing loaded yet; load just this channel
    pattern = load_pattern(pat, struct('patnum', c));
  end
  
  p_chan = NaN(nfact, 1, psize(3), psize(4));
  statistic_chan = NaN(nfact, 1, psize(3), psize(4));

  % run the statistic
  for t=1:size(pattern,3)
    if t~=size(pattern,3) && ~mod(t,step)
      fprintf('.')
    end
    for f=1:size(pattern,4)
      X = squeeze(pattern(:,1,t,f));
      [samp_p, samp_statistic] = fcn_handle(X, group, fcn_inputs{:});

      % check if we can determine the sign of the effect
      if ~any(samp_p < 0)
        temp = fix_regressors(group);
        for i=1:length(temp)
          reg = temp{i}(~isnan(temp{i}));
          vals = unique(reg);
          if length(vals)==2
            samp_p(i) = samp_p(i)*sign(nanmean(X(reg==vals(2))) - nanmean(X(reg==vals(1))));
          end
        end
      end
      
      % add to the larger matrices
      %p(:,c,t,f) = samp_p;
      %statistic(:,c,t,f) = samp_statistic;
      p_chan(:,1,t,f) = samp_p;
      statistic_chan(:,1,t,f) = samp_statistic;

    end
  end
  
  p = [p p_chan];
  statistic = [statistic statistic_chan];
end
fprintf('\n')

if all(isnan(p(:)))
  warning('Problem with sig test; p values are all NaNs.')
end

save(stat.file, 'p', 'statistic');
pat = setobj(pat, 'stat', stat);
