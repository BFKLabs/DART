% --- initialises the plotting data structure --- %
function pData = initPlotDataStruct(mFcn,cFcn,pFcn,oFcn)

% ------------------------------- %
% --- PLOT DATA STRUCT FIELDS --- %
% ------------------------------- %

% Func - name of the analysis function file
% Name - the description name of the analysis function
% Type - function plot type (either 'Individual', 'Single', or 'Combined')
% fType - set the function type. first value is the function index, the
%         second value is function type described as follows:
%     = 1, 'Classic' - the classical metrics that can be calculated by 
%                      tri-kinetics or other established methods
%     = 2, 'Stimuli Response' - stimuli-response experiment dependent functions 
%     = 3, 'Multi Metric' - functions that rely on the calculation of other,
%                           multiple functions
%     = 4, 'Special' - functions that are for special experiment types
%                      (i.e., Sleep Deprivation, Arousal Threshold etc)

% hasTime - boolean flag indicating whether plots have a time axis
% hasSP - boolean flag indicating whether subplots are fixed or not
% hasSR - boolean flag indicating whether the stimuli response table is required
% canComb - boolean flag indicating is subplots can be combined into a
%              single figure (must have hasSP = true)
% hasRC - boolean flag indicating if the subplot table has the rows/columns
%         selection fields (must have hasSP = true)
% hasRS - boolean flag indicating if the subplots are reset

% pFcn - plotting function handle name
% cFcn - calculation function handle name

% pP - plotting parameter struct
% cP - calculation parameter struct
% oP - data output parameter struct
% sP - special parameter struct
% pF - plot format parameter struct

% data struct initialisation
Func = sprintf('@%s',mFcn);
pData = struct('Func',Func,'Name',[],'Type',[],'fType',[],'dcFunc',[],...
               'hasSP',false,'hasTime',false,'hasSR',false,'hasRS',true',...
               'canComb',false,'hasRC',true,'useAll',false,...
               'cFcn',cFcn,'pFcn',pFcn,'oFcn',oFcn,...
               'cP',[],'pP',[],'sP',[],'oP',[],'pF',[]);