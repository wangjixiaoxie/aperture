function fig = create_fig(h, fig_name, res_dir, varargin)
%CREATE_FIG   Create a figure object.
%
%  fig = create_fig(h, fig_name, res_dir, ...)
%
%  INPUTS:
%         h:  handle or vector of handles to figure object(s).
%
%  fig_name:  string identifier of the fig object to be created.
%
%   res_dir:  path to the directory to save the figure(s). Default is
%             the current directory.
%
%  OUTPUTS:
%       fig:  new fig object, with references to the printed figures.
%
%  PARAMS:
%   source      - source of the figures (e.g., an object name). ('')
%   subject     - identifier of the subject that the figures correspond
%                 to. ('')
%   print_input - cell array of inputs to print, to be used when
%                 printing figures. ({'-depsc'})
%   file_ext    - desired file extension of the printed figures. ('eps')
%
%  NOTES:
%   create_fig only works well for individual figures and small groups
%   of figures. If you need to store many figures in one fig object,
%   call print and init_fig directly. 

% input checks
if ~exist('h', 'var') || isempty(h)
  h = gcf;
end
if ~exist('fig_name','var') || isempty(fig_name)
  fig_name = 'figure';
end
if ~exist('res_dir', 'var')
  res_dir = '.';
elseif ~ismember(res_dir(1), {'/', '.', '~'})
  res_dir = ['./' res_dir];
end
if ~exist(res_dir, 'dir')
  mkdir(res_dir)
end

% set params
defaults.source = '';
defaults.subject = '';
defaults.print_input = {'-depsc'};
defaults.file_ext = 'eps';

params = propval(varargin, defaults);

% define the basename of the figure files
inputs = {fig_name, params.source, params.subject};
inputs = inputs(~cellfun(@isempty, inputs));
switch length(inputs)
 case 1
  base_name = sprintf('%s', inputs{:});
 case 2
  base_name = sprintf('%s_%s', inputs{:});
 case 3
  base_name = sprintf('%s_%s_%s', inputs{:});
end

% print the figures
files = cell(1, length(h));
if isscalar(h)
  files{1} = fullfile(res_dir, sprintf('%s.%s', base_name, params.file_ext));
  print(h, files{1}, params.print_input{:});
else
  % each figure is identified by its position in h
  for i=1:length(files)
    files{i} = fullfile(res_dir, sprintf('%s-%d.%s', base_name, i, ...
                                         params.file_ext));
    print(h(i), files{i}, params.print_input{:});
  end
end

% create a new fig object
if isempty(params.source) && ~isempty(params.subject)
  source = params.subject;
else
  source = params.source;
end
fig = init_fig(fig_name, files, source);
