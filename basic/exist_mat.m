function bool = exist_mat(obj)
%EXIST_MAT   Check if an object has an associated mat.
%
%  bool = exist_mat(obj)
%
%  INPUTS:
%      obj:  an object.
%
%  OUTPUTS:
%     bool:  boolean that is true if the object has an associated
%            matrix, either in the workspace or on disk.

% input checks
if ~isstruct(obj)
  error('obj must be a structure.')
end

ws = false;
hd = false;

if isfield(obj, 'file') && ~isempty(obj.file)
  % check if the mat is saved on disk
  obj_type = get_obj_type(obj);
  
  if ~exist(obj.file, 'file')
    if ~obj.modified
      % if modified, don't worry about broken references; we're probably
      % about to save to a new file
      warning('Broken file reference in %s object ''%s''.', obj_type, ...
              get_obj_name(obj))
    end
  elseif strcmp(who('-file', obj.file, obj_type), obj_type)
    % make sure the variable is in the file
    hd = true;
  end
end

% anything in the .mat field counts
if isfield(obj, 'mat') && ~isempty(obj.mat)
  ws = true;
end

bool = hd || ws;
