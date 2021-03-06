function model=setParam(model, paramType, rxnList, params, var)
% setParam
%   Sets parameters for reactions
%
%   model       a model structure
%   paramType   the type of parameter to set:
%               'lb'    Lower bound
%               'ub'    Upper bound
%               'eq'    Both upper and lower bound (equality
%                       constraint)
%               'obj'   Objective coefficient
%               'rev'   Reversibility
%               'var'   Variance around measured bound
%   rxnList     a cell array of reaction IDs or a vector with their
%               corresponding indexes
%   params      a vector of the corresponding values
%   var         percentage of variance around measured value, if 'var' is
%               set as paramType. Defining 'var' as 5 results in lb and ub
%               at 97.5% and 102.5% of the provide params value (if params
%               value is negative, then lb and ub are 102.5% and 97.5%).
%
%   model       an updated model structure
%
%   Usage: model=setParam(model, paramType, rxnList, params)
%
%   Eduard Kerkhoven, 2019-05-03
%

if ~isempty(setdiff(paramType,{'lb';'ub';'eq';'obj';'rev';'var'}))
    EM=['Incorrect parameter type: "' paramType '"'];
    dispEM(EM);
end

%Allow to set several parameters to the same value
if numel(rxnList)~=numel(params) && numel(params)~=1
    EM='The number of parameter values and the number of reactions must be the same';
    dispEM(EM);
end

if isnumeric(rxnList) || islogical(rxnList)
    rxnList=model.rxns(rxnList);
end

%If it's a char array
rxnList=cellstr(rxnList);

%Find the indexes for the reactions in rxnList I do not use getIndexes
%since I don't want to throw errors if you don't get matches
indexes=zeros(numel(rxnList),1);

for i=1:numel(rxnList)
    index=find(strcmp(rxnList{i},model.rxns),1);
    if ~isempty(index)
        indexes(i)=index;
    else
        indexes(i)=-1;
        EM=['Reaction ' rxnList{i} ' is not present in the reaction list'];
        dispEM(EM,false);
    end
end

%Remove the reactions that weren't found
params(indexes==-1)=[];
indexes(indexes==-1)=[];

%Change the parameters
if ~isempty(indexes)
    if strcmpi(paramType,'eq')
        model.lb(indexes)=params;
        model.ub(indexes)=params;
    end
    if strcmpi(paramType,'lb')
        model.lb(indexes)=params;
    end
    if strcmpi(paramType,'ub')
        model.ub(indexes)=params;
    end
    if strcmpi(paramType,'obj')
        %NOTE: The objective is changed to the new parameters, they are not
        %added
        model.c=zeros(numel(model.c),1);
        model.c(indexes)=params;
    end
    if strcmpi(paramType,'rev')
        %Non-zero values are interpreted as reversible
        model.rev(indexes)=params~=0;
    end
    if strcmpi(paramType,'var')
        for i=1:numel(params)
            if params(i) < 0
                model.lb(indexes(i)) = params(i) * (1+var/200);
                model.ub(indexes(i)) = params(i) * (1-var/200);
            else
                model.lb(indexes(i)) = params(i) * (1-var/200);
                model.ub(indexes(i)) = params(i) * (1+var/200);
            end
        end
    end
end
end