function pat_size = patsize_all_subj(subj, pat_name)
%PATSIZE_ALL_SUBJ   Get the size of a pattern for all subjects.
%
%  pat_size = patsize_all_subj(subj, pat_name)
%
%  INPUTS:
%      subj:  vector of subject objects.
%
%  pat_name:  name of a pattern defined for all subjects.
%
%  OUTPUTS:
%  pat_size:  [subjects X 4] vector giving the size of each subject's
%             pattern matrix.

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

n_subj = length(subj);
pat_size = NaN(n_subj, 4);
for i = 1:n_subj
  pat = getobj(subj(i), 'pat', pat_name);
  pat_size(i,:) = patsize(pat.dim);
end

