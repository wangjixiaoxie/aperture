function exp = create_pow_pattern(exp, params, patname, resDir)
	%exp = create_pow_pattern(exp, params, patname, resDir)
	%
	% create a power pattern for each subject, time bin, saved in
	% resDir/data.  Filenames will be saved in exp.subj(s).pat
	% with the patname specified.
	%

	if ~exist('params', 'var')
		params = struct();
	end
	if ~exist('patname', 'var')
		patname = 'power_pattern';
	end
	if ~exist('resDir', 'var')
		resDir = fullfile(exp.resDir, patname);
	end

	% set the defaults for params
	params = structDefaults(params,  'evname', 'events',  'eventFilter', '',  'chanFilter', '',  'resampledRate', 500,  'downsample', 500,  'freqs', 2.^(1:(1/8):6),  'offsetMS', -200,  'durationMS', 1800,  'baseEventFilter', '',  'baseOffsetMS', -200,  'baseDurationMS', 100,  'filttype', 'stop',  'filtfreq', [58 62],  'filtorder', 4,  'bufferMS', 1000,  'width', 6,  'kthresh', 5,  'ztransform', 1,  'logtransform', 0,  'replace_eegFile', {},  'lock', 1,  'overwrite', 0,  'doBinning', 0);

	% get time bin information
	stepSize = fix(1000/params.downsample);
	MSvals = [params.offsetMS+stepSize/2:stepSize:(params.offsetMS+params.durationMS-stepSize/2)];
	time = init_time(MSvals);

	% initialize the frequency dimension
	freq = init_freq(params.freqs);

	fprintf('\nStarting create_pow_pattern. Parameters are:\n\n')
	disp(params);

	for s=1:length(exp.subj)
		% set where the pattern will be saved
		patfile = fullfile(resDir, 'patterns', sprintf('pattern_%s_%s.mat', patname, exp.subj(s).id));
		evfile = fullfile(resDir, 'events', sprintf('events_%s_%s.mat', patname, exp.subj(s).id));

		% check input files and prepare output files
		if prepFiles({}, {patfile, evfile}, params)~=0
			continue
		end

		% get the ev object to be used for this pattern
		ev = getobj(exp.subj(s), 'ev', params.evname);

		% get all events for this subject, w/filter that will be used to get voltage
		events = loadEvents(ev.file, params.replace_eegfile);
		events = filterStruct(events, '~strcmp(eegfile, '''')');
		base_events = filterStruct(events(:), params.baseEventFilter);
		events = filterStruct(events(:), params.eventFilter);
		
		% change the ev object
		ev.file = evfile;
		ev.len = length(events);

		% get chan, filter if desired
		chan = filterStruct(exp.subj(s).chan, params.chanFilter);

		% create a pat object to keep track of this pattern
		pat = init_pat(patname, patfile, params, ev, chan, time, freq);

		% initialize this subject's pattern
		patSize = [ev.len, length(chan), length(time), length(freq)];
		pattern = NaN(patSize);

		% initialize a boolean matrix to keep track of kurtosis
		kMask = false(patSize);

		% create a boolean matrix to keep track of artifacts
		mask = struct();
		if isfield(params, 'artWindow') && ~isempty(params.artWindow)
			artMask = false(patSize);
			timeArtMask = rmArtifacts(events, pat.dim.time, params.artWindow);
			for c=1:size(artMask,2)
				for f=1:size(artMask,4)
					artMask(:,c,:,f) = timeArtMask;
				end
			end
			mask = setobj(mask, struct('name', 'artifacts', 'mat', artMask));
		end

		% get a list of sessions in the filtered event struct
		sessions = unique(getStructField(events, 'session'));

		% get the patterns for each frequency and time bin
		start_e = 1;
		for n=1:length(sessions)
			fprintf('\nProcessing %s session %d:\n', exp.subj(s).id, sessions(n));
			sess_events = filterStruct(events, 'session==varargin{1}', sessions(n));
			sess_base_events = filterStruct(base_events, 'session==varargin{1}', sessions(n));

			for c=1:length(chan)
				fprintf('%d.', chan(c).number);

				% if z-transforming, get baseline stats for this sess, channel
				if params.ztransform
					base_pow = getphasepow(chan(c).number, sess_base_events, ...
					params.baseDurationMS, ...
					params.baseOffsetMS, params.bufferMS, ... 
					'freqs', params.freqs, ... 
					'filtfreq', params.filtfreq, ... 
					'filttype', params.filttype, ...
					'filtorder', params.filtorder, ... 
					'kthresh', params.kthresh, ...
					'width', params.width, ...
					'resampledRate', params.resampledRate, ...
					'powonly');

					% do log transform if desired
					if params.logtransform
						base_pow(base_pow<=0) = eps(0);
						base_pow = log10(base_pow);
					end

					for f=1:length(params.freqs)
						% if multiple samples given, use the first
						base_pow_vec = base_pow(:,f,1);

						% get separate baseline stats for each freq
						base_mean(f) = nanmean(base_pow_vec);
						base_std(f) = nanstd(base_pow_vec);
					end
				end % baseline

				% get power, z-transform, average each time bin
				e = start_e;
				for sess_e=1:length(sess_events)

					[this_pow, kInd] = getphasepow(chan(c).number, sess_events(sess_e), ...
					params.durationMS, ...
					params.offsetMS, params.bufferMS, ... 
					'freqs', params.freqs, ... 
					'filtfreq', params.filtfreq, ... 
					'filttype', params.filttype, ...
					'filtorder', params.filtorder, ... 
					'kthresh', params.kthresh, ...
					'width', params.width, ...
					'resampledRate', params.resampledRate, ...
					'downsample', params.downsample, ...
					'powonly', 'keepk');   

					% make it time X frequency
					this_pow = shiftdim(squeeze(this_pow),1);

					for f=1:length(params.freqs)
						% add kurtosis information to the mask
						kMask(e,c,:,f) = kInd;

						if params.ztransform
							if params.logtransform
								this_pow(this_pow<=0) = eps(0);
								this_pow = log10(this_pow);
							end

							% z-transform
							this_pow(:,f) = (this_pow(:,f) - base_mean(f))/base_std(f);
						end
					end

					pattern(e,c,:,:) = this_pow;
					e = e + 1;
				end % events

			end % channel
			start_e = start_e + length(sess_events);

		end % session
		fprintf('\n');

		% put the masks in one struct
		mask = setobj(mask, struct('name', 'kurtosis', 'mat', kMask));

		if params.doBinning
			% do binning if desired
			[pat, pattern, events] = patBins(pat, pattern, mask, events);
			mask = struct();
		end

		% save the pattern and corresponding events struct and masks
		save(pat.file, 'pattern', 'mask');
		closeFile(pat.file);
		save(pat.dim.ev.file, 'events');
		closeFile(pat.dim.ev.file);
		
		% update exp with the new pat object
		exp = update_exp(exp, 'subj', exp.subj(s).id, 'pat', pat);
	end % subj
