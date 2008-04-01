function s = loadStruct(structFile, repStr)
%
%LOADSTRUCT - load a structure from file, and recursively 
%replace a string found anywhere in the struct 
%with a new string.  Useful for bringing a struct with file
%references from a remote machine to a local machine.
%
% FUNCTION: s = loadStruct(structFile, repStr)
%
% Examples:
% structFile = '/Volumes/mortonne/EXPERIMENTS/catFR/pow_pattern3/eeg.mat';
% repStr = {'/data1' '/Volumes/hippo/data1'; '~/' '/Volumes/mortonne/'};
% eeg = loadStruct(structFile,repStr);
%

struct = load(structFile);
struct_name = fieldnames(struct);
s = getfield(struct, struct_name{1});

% do a strrep on any string in the struct
if exist('repStr', 'var') && ~isempty(repStr)
  s = recursive_strrep(s, repStr);
end

if isfield(s, 'file')
  save(s.file, 's');
end