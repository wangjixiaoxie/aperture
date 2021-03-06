function exp = init_iEEG(subj, res_dir, experiment, varargin)
%INIT_IEEG   Prepare an intracranial EEG experiment for analysis.
%
%  Create an experiment object and read in information about each subject's
%  electrodes. This information is stored in exp.subj.chan:
%    number - the number assigned to each channel
%    region - the region label used in the subject's jacksheet
%    label - a unique string for each channel; initialized as 
%            num2str(number).
%
%  If a good_leads_file exists, only the channels listed there will be
%  included in the subject's chan structure.
%
%  exp = init_iEEG(subj, res_dir, experiment, ...)
%
%  INPUTS:
%        subj:  subject structure. See get_sessdirs for details.
%
%     res_dir:  results directory; the exp structure will be saved 
%               in [res_dir]/exp.mat.
%
%  experiment:  optional string indicating the name of the experiment.
%
%      params:  structure specifying options. See below for details.
%
%  OUTPUTS:
%         exp:  experiment object. Contains the input subject structure,
%               with added information about each subject's channels.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   jacksheet       - path to the jacksheet file, relative to each subject's
%                     directory. ('docs/jacksheet.txt')
%   good_leads_file - path to a text file with one electrode number per
%                     row, indicating all electrodes that are "good".
%                     ('tal/good_leads.txt')
%   save_to_disk    - if true, experiment object will be saved on disk.
%                     (false)
%
%  See also init_exp, import_channels.

% input checks
if ~exist('params', 'var')
  params = struct;
end
if ~exist('experiment', 'var')
  experiment = '';
end
if ~exist('res_dir', 'var')
  res_dir = '.';
end
if ~exist('subj', 'var')
  error('You must pass a subj object.')
end

% options
defaults.jacksheet = fullfile('docs', 'jacksheet.txt');
defaults.good_leads_file = fullfile('tal', 'good_leads.txt');
defaults.save_to_disk = false;
params = propval(varargin, defaults);

% create the exp struct
exp = init_exp(subj, res_dir, experiment, 'iEEG');

for s = 1:length(exp.subj)
  % get the subject's main directory
  subj_dir = exp.subj(s).dir;
  if iscell(subj_dir)
    subj_dir = subj_dir{1};
  end
  
  % get channel numbers and labels from the jacksheet
  jacksheet = fullfile(subj_dir, params.jacksheet);
  if ~exist(jacksheet,'file')
    error('jacksheet not found: %s\n', jacksheet)
  end
  c = textscan(fopen(jacksheet,'r'), '%d%s%*[^\n]');
  [channels, regions] = deal(c{:});
  
  % get a list of "good" channel numbers
  good_chans_file = fullfile(subj_dir, params.good_leads_file);
  if exist(good_chans_file,'file')
    good_chans = read_chans_file(good_chans_file);
    [channels,gidx,cidx] = intersect(good_chans, channels);
  else
    fprintf('Warning: good leads file not found: %s\nIncluding all channels...', good_chans_file)
  end

  % get the good regions
  regions = regions(cidx);
  
  % create the chan struct for this subject
  chan = [];
  
  for c = 1:length(channels)
    chan(c).number = channels(c);
    chan(c).region = regions{c};
    
    % set the label for this channel
    if length(unique(regions)) == length(regions)
      % if the region labels are unique, use them
      chan(c).label = regions{c};
    else
      % use channel numbers
      chan(c).label = num2str(channels(c));
    end
  end
  exp.subj(s).chan = chan;
end

% update the exp object
if params.save_to_disk
  exp = update_exp(exp);
end
