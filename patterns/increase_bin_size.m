function exp = increase_bin_size(exp, params, patname, resDir)
%
%INCREASE_BIN_SIZE - average over adjacent time or frequency bins
%to decrease the size of patterns, or average over channels for ROI
%analyses; new patterns will be saved in a new directory
%
% FUNCTION: exp = increase_bin_size(exp, params, patname, resDir)
%
% INPUT: exp - struct created by init_iEEG or init_scalp
%        params - required fields: patname (specifies the name of
%                 which pattern in the exp struct to use)
%
%                 optional fields: eventFilter (specify subset of
%                 events to use), masks (cell array containing
%                 names of masks to apply to pattern)
%        resDir - 'pattern' files are saved in resDir/data
%        patname - name of new pattern to save under in the exp struct
%
% OUTPUT: new exp struct with ana object added, which contains file
% info and parameters of the analysis
%

%exp = increase_bin_size(exp, params, resDir, patname)
%
%EXAMPLES: params.binChan = {'LF', 'RF'} OR {{'LF', 'LFp'}, {'RF',
%'RFp'}} OR {[1 2 125], [45 35 76 17 18]}
%          params.MSbins = [0 100; 100 200]
%          params.freqbins = [2 4; 4 8]
%

if ~isfield(params, 'patname')
  error('You must specify which pattern to use');
end
if ~exist('patname', 'var')
  patname = [params.patname '_mod'];
end
if ~exist('resDir', 'var')
  resDir = fullfile(exp.resDir, patname);
end

params = structDefaults(params, 'eventFilter', '',  'masks', {});

% create the new pattern for each subject
for s=1:length(exp.subj)
  fprintf('%s\n', exp.subj(s).id);
  
  % set where the pattern will be saved
  patfile = fullfile(resDir, 'data', [exp.subj(s).id '_' patname '.mat']);
  
  % get the pat obj for the original pattern
  pat1 = getobj(exp.subj(s), 'pat', params.patname);  
  
  % check input files and prepare output files
  if prepFiles(pat1.file, patfile, params)~=0
    continue
  end
  
  % load the original pattern with filters and masks
  [pattern1, events] = loadPat(pat1, params, 1);
  
  % do the binning
  [pat, pattern, events] = patBins(pat1, params, pattern1
  
  if pat.dim.ev.length<pat1.dim.ev.length 
    % we need to save a new events struct
    pat.dim.ev.file = fullfile(resDir, 'data', [exp.subj(s).id '_' patname '_events.mat']);
    save(pat.dim.ev.file, 'events');
  end

  % update exp with the new pat object
  exp = update_exp(exp, 'subj', exp.subj(s).id, 'pat', pat);
  
  % save the new pattern
  closeFile(pat.file, 'pattern');
end % subj