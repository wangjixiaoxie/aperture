function [chanbins,chanbinlabels] = chan_groups1()
%[chanbins,chanbinlabels] = chan_groups1()

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

chanbins = {[1 2 3 9 121 122 123 124], [18 16 10 19 11 4 20 12 5 118], [32 26 22 23 38 33 27 24 34 28], [111 110 105 104 103 87 93 98], [13 6 112 7 106 31 55 80], [35 24 41 36 30 47 72 37], [109 115 120 119 102 108 114 101 113 108 107 99], [48 43 39 44 40 49 45 46 56 50 57 63], [86 92 97 85 91 96 84 90 95], [54 62 79 61 78 67 72 77], [51 52 53 58 59 60 64 65 66], [83 89 94 88], [71 76 75 74 82 81], [68 69 70 73]};
chanbinlabels = {'RF', 'F', 'LF', 'RC', 'C', 'LC', 'RT', 'LT', 'RP', 'P', 'LP', 'RO', 'O', 'LO'};
