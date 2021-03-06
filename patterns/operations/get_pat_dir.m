function pat_dir = get_pat_dir(pat, varargin)
%GET_PAT_DIR   Get the path to a pattern's standard directory.
%
%  pat_dir = get_pat_dir(pat, s1, s2, ... sN)
%
%  It is assumed that the pattern's files are saved in
%  [pat_dir]/patterns.
%
%  INPUTS:
%      pat:  a pattern object.
%
%        s:  additional arguments indicate subdirectories of the main
%            pattern directory.
%
%  OUTPUTS:
%  pat_dir:  path to the requested pattern directory.
%
%  EXAMPLE:
%   % get the path to the standard directory for a pattern's
%   % figures
%   report_dir = get_pat_dir(pat, 'reports', 'figs');

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

main_dir = check_dir(gen_pat_dir(pat));
if ~isempty(varargin)
  pat_dir = check_dir(gen_pat_dir(pat, varargin{:}));
else
  pat_dir = main_dir;
end

