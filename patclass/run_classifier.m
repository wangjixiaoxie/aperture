function [class,err,posterior] = run_classifier(trainpat,trainreg,testpat,testreg,classifier,params)
%RUN_CLASSIFIER   Train and test a classifier using standard data formats.
% 
%  ******************
%  -DEPRECATED-
%   Used by the old version of classify_pat. Keeping it around for now
%   since it has interfaces with a number of different libraries and may
%   contain useful code.
%  ******************
%
%  [class, err, posterior] = run_classifier(trainpat, trainreg, testpat, testreg)
%
%  INPUTS:
%    trainpat:  [observations X variables] matrix to train on.
%
%    trainreg:  vector of condition labels for each observation in 
%               trainpat.
%
%     testpat:  [observations X variables] matrix to test.
%
%     testreg:  vector of condition labels for each observation in 
%               testpat.
%
%  classifier:  string indicating the type of classifier to use.
%
%      params:  structure giving options for running the classifier.
%
%  OUTPUTS:
%       class:  vector giving the classifier guess for each observation.
%
%         err:  an estimate of the misclassification error rate based on
%               the training data.
%
%   posterior:  [observations X conditions] matrix of classifier outputs
%               for each condition.

% input checks
if ~exist('classifier', 'var')
  classifier = 'bp_netlab';
end
if ~exist('params', 'var')
  params = struct;
end

class = [];
err = [];
posterior = [];

switch classifier
 case 'bp_netlab'
  params = structDefaults(params, 'nHidden', 10);

  trainreg = vec2mat(trainreg);
  testreg = vec2mat(testreg);

  sp1 = train_bp_netlab(trainpat', trainreg', params);
  [output, sp2] = test_bp_netlab(testpat', testreg', sp1);

 case 'logreg'
  params = structDefaults(params, 'penalty', .5);

  % adapt the inputs
  trainreg = vec2mat(trainreg);
  testreg = vec2mat(testreg);

  % run the classifier
  sp1 = train_logreg(trainpat', trainreg', params);
  [posterior,sp2] = test_logreg(testpat', testreg', sp1);

  % standardize the outputs
  err = sp2.logreg.trainError;
  [m,i] = max(posterior);
  class = i';
  class = class-1; % eeg_ana starts with 0 for categories
  posterior = posterior';

 case 'classify'
  params = structDefaults(params, 'type', 'linear');

  [class,err,posterior] = classify(testpat, trainpat, trainreg, params.type);

 case 'correlation'
  [class,posterior] = corr_class(testpat,trainpat,trainreg); 
  
 case 'svm'
  
  params = structDefaults(params);

  % adapt the inputs
  trainreg = vec2mat(trainreg);
  testreg = vec2mat(testreg);
  keyboard
  % run the classifier
  sp1 = train_svm(trainpat', trainreg', params);
  [posterior,sp2] = test_svm(testpat', testreg', sp1);

  % standardize the outputs
  err = sp2.logreg.trainError;
  [m,i] = max(posterior);
  class = i';
  class = class-1; % eeg_ana starts with 0 for categories
  posterior = posterior';
  
  %{
  % LIBSVM VERSION
  % standardize input
  trainreg = grp2idx(trainreg);
  testreg = grp2idx(testreg);
  keyboard
  % train
  model = svmtrain(trainreg,trainpat);
  
  % test; not sure what range of posterior is. Should we normalize so
  % it's between 0 and 1?
  [class,temp,posterior] = svmpredict(testreg,testpat,model);
  err = 1-(temp(1)/100);
  %}
  
  %{
  % MATLAB VERSION
  % function can't handle more than two groups, so iterate over groups,
  % train on group members versus everything else	
  uniq_reg_vals = unique(trainreg);
  for i=1:length(uniq_reg_vals)
    % separate into two groups
    this_trainreg = ismember(trainreg,uniq_reg_vals(i));
    
    % train the classifier
    svm_struct = svmtrain(trainpat,this_trainreg);
    
    % test
    groups = svmclassify(svm_struct,testpat);keyboard
  end
  %}
  
 otherwise
  error('Error:unknown classifier.')
end

function mat = vec2mat(vec)
  vals = unique(vec);
  for i=1:length(vals)
    mat(:,i) = vec==vals(i);
  end
%endfunction
