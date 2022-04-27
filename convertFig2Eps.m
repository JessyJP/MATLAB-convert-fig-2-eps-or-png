function convertFig2Eps(figPathOrFileNms,varargin)
% function convertFig2Eps(figPathOrFileNms,varargin)
% 
% Description: Automatically(with minimal effort) converts figure(s) to EPS
% format (by default). The format is aimed for publishing. The function has multiple
% options for the convenience of the user.
%
% INPUT(s) : all iinputs are optional
% Main input: 'figPathOrFileNms' = > figure file, folder path that contains
% multiple figures and folders, or list(cell) of figure file paths and folder paths.
%     Extra options for paths: 'subdir' => includes all subdirectories for
%     (any) of the input(s) in 'figPathOrFileNms' is a directory path(s)
%
%     Extra options for fig: 'png' 'expand' 'normalize'  'wait' 'save' 
%           Option: 'png'    => specifies alternative output image format 
%           Option: 'expand' => exapnds(maximizes) the axes within the figure window 
%           Option: 'normalize' => normalizes the window to the screen size (fullscreen)
%           Option: 'wait'      => waits before any for keypress "ENTER" after execution of all fomating(before 'save' and 'eval') 
%           Option: 'save'      => saves the changes made to the figure file in addition to the image output
%           Option: 'debug'     => show which files were skiped over the conversion (i.e. are not *.fig files)
%           Option: 'errorContinue' => if file open error is encountered, continue execution
%           Option: 'expGraph'  => use exportgraphics() instead of the default print()
%                   
%
%     Extra options for fontsize using flags: 'fontsize1'/'fontsize2'/'fontsize3'/ ... /'fontsize100'
%     
%     Extra options for fig: eval string format:  ['eval:','---string to evaluate----']
%           This option can evaluate any command/function/script to additionally
%           process the figure before saving. For reference use the following
%           internal handles
%     
%     Internal Figure File Full Path & Name: "inputFileName" => [pathstr,name,~] = fileparts(inputFileName); 
%     Internal Figure Handle Name: "fig" => the current figure handle
%     Internal axes Handle/Variable Placeholder: "ax" => empty variable, can be used for any purpose
%     Internal Resolution DPI variable: "ResolutionDPI" (Default DPI = 150;) 
%     Internal Output format: "outputFormat" (Default: outputFormat = '-depsc') % Used for print()
%     Internal Output extention: "outputExt" (Default: outputExt = '.eps')
%     Internal Output objec handle: "objOutH" (Default: objOutH = fig)
%
%     
% OUTPUT: the output is the converted to image from the converted figure in
% the specified format
%     
%     EXAMPLE:
%     example 1: "convertFig2Eps"  /or/  "convertFig2Eps()" /or/ "convertFig2Eps('.')"
%     example 2: "convertFig2Eps('C:','subdir','png','expand','normalize','fontsize100','save','eval:disp(fig.Number);')" 
%
% Author: Yasen Polihronov (yp1504@bristol.ac.uk) 
% Version: 1.6, 24/03/2020 
% Changelog: 
% 1.0 - First publication 
% 1.1 - Bugfix & error handling option "errorContinue" added 
% 1.2 - Update add the use of exportgraphics() instead of the default print()
% 1.3 - Add default resolution DPI that can be altered via "eval:..." 
% 1.4 - Add Comments for more internal variables
% 1.5 - Fix misspelling of "outputExt"
% 1.6 - Add object print/output handle "objOutH" which could be [fig] or [ax]
% 1.7 - add "function expandAxesToFillFigure(fig)" as a subfunction

% Reset
% clear all;
% close all force hidden;
% clc;
%% Function Start

% CheckCMD is is used for swichting ON optional parameters
checkCMD = @(str) ~(isempty(strfind(lower(cell2mat(varargin)),lower(str))));
% FindCMD is used for finding the optional input for internal evaluation
    function [cmdID] = findCMD(searchStr)
        for cmdID = 1:length(varargin)
           cmdStr = varargin{cmdID};
           if ~isempty(strfind(lower(cmdStr),lower(searchStr)))
               return;
           end
       end
    end
%% Inputs & Switches
% Convert all 
inputExt= '.fig';
% in directory [or filenames]
if ~exist('figPathOrFileNms','var') || isempty(figPathOrFileNms)
    figPathOrFileNms = '.';% current 
end
if ~iscell(figPathOrFileNms)
    Dtb = struct2table(dir(figPathOrFileNms));
    
    % Find and remove current and previous folder
    indRm = strcmp(Dtb.name,{'.'}) | strcmp(Dtb.name,{'..'});
    Dtb(indRm,:) = [];% Remove the current and previous folder
    
    % Check if the structure is empty and return 
    if isempty(Dtb)
        debugON = checkCMD('debug');% Pre check
        if debugON
            disp(['   Empty Folder Path :[',figPathOrFileNms,']']);
        end
        return;
    end
    
    % Construct full absolute file/dir paths
    Dtb = fullfile(figPathOrFileNms,Dtb.name);
%         Dtb = fullfile(Dtb.folder,Dtb.name);
    
    % If still non-cell(string or char) is found, convert to cell array
    if ~iscell(Dtb)
        Dtb = {Dtb};
    end
else
    Dtb = figPathOrFileNms;
end
subdirON = checkCMD('subdir');
% Convert to new format
outputFormat        = '-depsc';
outputExt           = '.eps';
pngON               = checkCMD('.png')||checkCMD('png');
normalizeON         = checkCMD('normalize');
expandON            = checkCMD('expand');
evalON              = checkCMD('eval');
waitON              = checkCMD('wait');% Pause on each fig file  to make changes
saveON              = checkCMD('save');
debugON             = checkCMD('debug');
errorContinueON     = checkCMD('errorContinue');
expGraph            = checkCMD('expGraph');

% Default fontsize
defaultFontSize = 20;
for FS = 1:100
if checkCMD(['fontsize',num2str(FS)]) 
    defaultFontSize = FS;
end
end

% Default DPI
ResolutionDPI = 150;

% Format for print()
if pngON 
    outputFormat = '-dpng';
    outputExt = '.png';
end
    
%% Convert
% Loop
for i = 1:numel(Dtb)
    % Select Input Stream
    if isfolder(Dtb{i})
        if debugON
            disp(['Not Converted Folder Path: [',Dtb{i},']']);
        end
        % If subdir on
        if subdirON
            if debugON
                disp(['   Recursive call with Folder Path in:[',Dtb{i},'] ...']);
            end
            convertFig2Eps(Dtb{i},varargin{:})
        end
        continue;
    end

    % Get input name 
    inputFileName = Dtb{i};
    
    % Get name for output
    [pathstr,name,inFileExt] = fileparts(inputFileName);
    % If the file is a fig file
    if (strfind(inFileExt,inputExt))
       % Open figure       
       try
           fig = openfig(inputFileName);
       catch theError
           % If continue option is on
           if ~errorContinueON
                rethrow(theError);
           else
                fprintf(2,'File [%s] not converted due to Error!!!\n',inputFileName);
                if debugON
                    fprintf(2,'   Error Identifier:   %s\n',theError.identifier);
                    fprintf(2,'   Error Message:      %s\n',theError.message);
                end
                continue;
           end
       end
       %% Inset other adjustments here
       % Normalize Figure Window
       if normalizeON
%            set(fig,'units','normalized','position',[0 0 1 1]);
           set(fig,'WindowStyle','normal','WindowState','fullscreen');
       end
%        try
%            for c = 1:length(fig.Children)
%                Child = fig.Children(c);
%                Child.FontSize = defaultFontSize;
%            end
%        end
       set(findall(fig,'-property','FontSize'),'FontSize',defaultFontSize);
       
       % Expand figure
       if expandON
           expandAxesToFillFigure(fig);
       end      
       
       % Default output handle for export
       objOutH = fig;% This could be changed to a specific subplot
       
       % EvalON option
       if evalON
           ax = [];% Axes placeholder
           evalStr = varargin{findCMD('eval')};
           bb = strfind(evalStr,':');%Find Begining of statement
           bb = bb(1) +1;% Begining of statement char
           evalStr = evalStr(bb:end);
           if strcmpi(evalStr(1),'(') && strcmpi(evalStr(end),')')
               evalStr(1) = []; evalStr(end) = [];
           end
           eval(evalStr);
       end
       
       % Wait before saving
       if waitON
           disp('Wating for changes... [Press Enter] when done.');
           pause;
       end 
       
       % Save figure
       if saveON
           savefig(fig,inputFileName);
           disp('Figure Resaved');
       end
       
       % Make Output file name
       outputName = fullfile(pathstr,[name,outputExt]);
       % Check if the file already exists
       if exist(outputName,'file') && pngON
           delete(outputName);
       end
       %% Export with new fomat
       if expGraph
            exportgraphics(objOutH,outputName,'Resolution',ResolutionDPI);
       else            
            print(objOutH,outputName,outputFormat,num2str(ResolutionDPI,'-r%i'));
       end
       disp([inputExt,' => ',outputExt,':[',name,']']);
       try 
           close(fig,'force');
       catch
           close all force hidden;
       end
    else
        if debugON
            disp(['Not Converted: [',[name,inFileExt],'] in dir [',pathstr,']']);
        end
    end
end

end

function expandAxesToFillFigure(fig)
% function expandAxesToFillFigure(fig)

    style = hgexport('factorystyle');
    style.Bounds = 'tight';
    hgexport(fig,'-clipboard',style,'applystyle', true);
    drawnow;
end