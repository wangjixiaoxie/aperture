function pat = baseline_pattern(pat, baselineMS);
%BASELINE_PATTERN   Re-baseline a pattern.
%
%  pat = baseline_pattern(pat, baselineMS)
%
%  INPUTS:
%      pat:         input pattern object.
%      baselineMS:  [2 X 1] array of MS values for baseline
%                   period.
%
%  OUTPUTS:
%      pat:         pattern object that has been re-baselined.


%identify baseline period
times = get_dim_vals(pat.dim, 'time');
base = baselineMS(1) <= times & times < baselineMS(2);

% events X channels X 1 X freq
base_mean = nanmean(pat.mat(:,:,base,:), 3);
pat.mat = pat.mat - repmat(base_mean, [1 1 patsize(pat.dim, 3) 1]);
