function [pat,status] = pat_anovan(pat, params, statname, resDir)
%PAT_ANOVAN   Run anovan on a pattern.
%
%   *** deprecated ***
%   NWM: phasing out this function, implementing similar functionality
%   in pat_statistics.
%
%   PAT = PAT_ANOVAN(PAT,PARAMS,STATNAME,RESDIR) runs anovan on
%   the pattern corresponding to PAT, using options specified in
%   the PARAMS struct.  The results are saved in a "stat" substruct 
%   of PAT named STATNAME (default: 'anovan').  p-values are saved in
%   RESDIR/stats (default is PAT's resDir)
%
%   Params:
%     'fields'    REQUIRED - Specifies how to create the regressors.  
%                 See make_event_bins for possible values
%     'optinput'  Cell array of optional inputs to anovan
%     'lock'      If true, stat.file will be locked during operation
%                 (default is false)
%     'overwrite' If false (default) and stat.file already exists, 
%                 output will be empty
%
%   Example:
%    To test for significance between recalled and not recalled items:
%    pat = pat_anovan(pat,struct('fields','recalled'),'sme');
%

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

if ~exist('resDir', 'var')
  resDir = fileparts(fileparts(pat.file));
end
if ~exist('statname', 'var')
  statname = 'anovan';
end
if isstr(params.fields)
  params.fields = {params.fields};
end

params = structDefaults(params, 'optinput', {},  'factorlabels', {},  'lock', 0,  'overwrite', 0);

status = 0;

% set where the stats will be saved
filename = sprintf('%s_%s_%s.mat', pat.name, statname, pat.source);
statfile = fullfile(resDir, 'stats', filename);

% check input files and prepare output files
err = prepFiles(pat.file, statfile, params);
if err
  return
end

fprintf('\nStarting ANOVAN...');

% initialize the stat object
stat = init_stat(statname, statfile, params);

% load pattern and events
pattern = load_pattern(pat, params);
events = get_mat(pat.dim.ev);

% make the regressors
group = cell(1, length(params.fields));
for i=1:length(params.fields)
  vec = make_event_bins(events, params.fields{i});
  group{i} = vec';
  if ~isempty(params.factorlabels)
    stat.factor(i).name = params.factorlabels{i};
    elseif isstr(params.fields{i})
    stat.factor(i).name = params.fields{i};
    else
    stat.factor(i).name = sprintf('factor%d', i);
  end
  stat.factor(i).field = params.fields{i};
  stat.factor(i).vals = unique(vec);
end

if ismember('interaction', params.optinput)
  numev = length(params.fields)+1;
  else
  numev = length(params.fields);
end

p = NaN(numev, size(pattern,2), size(pattern,3), size(pattern,4));
tab = cell(numev, size(pattern,2), size(pattern,3), size(pattern,4));
stats = cell(numev, size(pattern,2), size(pattern,3), size(pattern,4));
terms = cell(numev, size(pattern,2), size(pattern,3), size(pattern,4));
% do the anova
fprintf('Channel: ');
for c=1:size(pattern,2)
  fprintf('%s ', pat.dim.chan(c).label);
  for t=1:size(pattern,3)
    for f=1:size(pattern,4)
      [p(:,c,t,f) tab{1,c,t,f} stats{1,c,t,f}] = anovan(squeeze(pattern(:,c,t,f)), group, 'display', 'off', params.optinput{:});
    end
  end
end
fprintf('\n');

save(stat.file, 'p', 'tab', 'stats');
closeFile(stat.file);

pat = setobj(pat,'stat',stat);
