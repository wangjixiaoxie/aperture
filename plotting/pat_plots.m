function exp = pat_plots(exp, params, figname, title, resDir)
%
%PAT_PLOTS - manages event-related potential/power figures, plus
%topo plots of both voltage and power
%
% FUNCTION: exp = pat_plots(exp, params, figname, resDir)
%
% INPUT: exp - struct created by init_iEEG or init_scalp
%        params - required fields: patname (specifies the name of
%                 which pattern in the exp struct to use)
%
%                 optional fields: eventFilter (specify subset of
%                 events to use), masks (cell array containing
%                 names of masks to apply to pattern), subjects
%                 (cell array of ids of subjects to include) diff
%                 (set to 1 to plot difference of eventypes)
%                 across_subj (set to 1 to plot patterns saved in exp.pat)
%
%        resDir - plots saved in resDir/figs
%
% OUTPUT: new exp struct with filenames of all figures created
% saved in pat.figs
%

if ~exist('resDir', 'var')
  resDir = fullfile(exp.resDir, 'eeg', params.patname);
end
if ~exist('figname', 'var')
  figname = 'plots';
end
if ~exist('title', 'var')
  title = 'plots';
end

params = structDefaults(params, 'diff', 0,  'across_subj', 0,  'sym', {'-r', '-b'}, 'plotsig', 1);

if ~isfield(params, 'subjects')
  params.subjects = getStructField(exp.subj, 'id');
end
if params.across_subj
  params.subjects = [params.subjects 'across_subj'];
end

if ~exist(fullfile(resDir, 'figs'), 'dir')
  mkdir(fullfile(resDir, 'figs'));
end

clf reset

for i=1:length(params.subjects)
  
  % get the pat object, load pattern
  if strcmp(params.subjects{i}, 'across_subj')
    id = 'across_subj';
    pat = getobj(exp, 'pat', params.patname);
  else
    s = find(inStruct(exp.subj, 'strcmp(id, varargin{1})', params.subjects{i}));
    id = exp.subj(s).id;
    pat = getobj(exp.subj(s), 'pat', params.patname);
  end

  timeMS = [pat.dim.time.avg];
  
  % check input files
  if prepFiles(pat.file, {}, params)~=0
    continue
  end
  
  pattern = loadPat(pat, params, 0);
  
  if ~isfield(pat, 'stat') || isempty(pat.stat)
    params.plotsig = 0;
  end
  
  if params.plotsig
    load(pat.stat.file);
  end
  
  if params.diff & size(pattern,1)==2
    pattern = pattern(2,:,:,:)-pattern(1,:,:,:);
  end
  
  if length(pat.dim.freq)==1 % plotting voltage values

    fig = init_fig(figname, 'erp', {}, params);
    
    for c=1:size(pattern,2)
      if params.plotsig
	h = plot_erp(timeMS, squeeze(pattern(1,c,:))', squeeze(pattern(2,c,:))', squeeze(p(1,c,:))');
      else
	h = plot_erp(timeMS, squeeze(pattern(1,c,:))', squeeze(pattern(2,c,:)));
      end
      
      if 1%sum(~isnan(get(h, 'YData')))>0
	fig.file{c} = fullfile(resDir, 'figs', [params.patname '_erp_' id 'e1c' num2str(c) '.eps']);
	print(gcf, '-depsc', fig.file{c});
      end
    end
    
  else % plotting power values
    
    fig = init_fig(figname, 'power', {}, params);
    
    for e=1:size(pattern,1)
      if params.plotsig
	h = plot_pow(squeeze(p(e,c,:,:))', pat.dim);
	fig.file{c} = fullfile(resDir, 'figs', [params.patname '_erpow_sig_' id '_e' num2str(e) 'c' num2str(c) '.eps']);
      else
	h = plot_pow(squeeze(pattern(e,c,:,:))', pat.dim);
	fig.file{c} = fullfile(resDir, 'figs', [params.patname '_erpow_' id '_e' num2str(e) 'c' num2str(c) '.eps']);
      end
            
      print(gcf, '-depsc', fig.file{c});
      
    end
  end

  pat = setobj(pat, 'fig', fig);
  
  % update exp with filenames of the new figures
  if strcmp(id, 'across_subj')
    exp = update_exp(exp, 'pat', pat);
  else
    exp = update_exp(exp, 'subj', exp.subj(s).id, 'pat', pat);
  end
  
end % subjects
