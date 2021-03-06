% Presents food images to participant, accepts rating from them in the form
% of a joystick movement forward or back.
% Original code modified by Charles Theobald, May 2016, to accommodate
% joystick interface.
function SimpleExposure_Food_ED(varargin)

global KEYS COLORS w wRect XCENTER YCENTER PICS STIM SimpExp trial rects mids

% This is for food & or model exposure!

prompt={'SUBJECT ID' 'fMRI: 1 = Yes; 0 = No'};
defAns={'4444' '0'};

answer=inputdlg(prompt,'Please input subject info',1,defAns);

ID=str2double(answer{1});
fmri = str2double(answer{2});
% COND = str2double(answer{2});
% SESS = str2double(answer{3});
% prac = str2double(answer{4});


rng(ID); %Seed random number generator with subject ID
d = clock;

KEYS = struct;
if fmri == 1;
    KEYS.ONE= KbName('0)');
    KEYS.TWO= KbName('1!');
    KEYS.THREE= KbName('2@');
    KEYS.FOUR= KbName('3#');
    KEYS.FIVE= KbName('4$');
    KEYS.SIX= KbName('5%');
    KEYS.SEVEN= KbName('6^');
    KEYS.EIGHT= KbName('7&');
    KEYS.NINE= KbName('8*');
%     KEYS.TEN= KbName('9(');
else
    KEYS.ONE= KbName('1!');
    KEYS.TWO= KbName('2@');
    KEYS.THREE= KbName('3#');
    KEYS.FOUR= KbName('4$');
    KEYS.FIVE= KbName('5%');
    KEYS.SIX= KbName('6^');
    KEYS.SEVEN= KbName('7&');
    KEYS.EIGHT= KbName('8*');
    KEYS.NINE= KbName('9(');
%     KEYS.TEN= KbName('0)');
end

rangetest = cell2mat(struct2cell(KEYS));
% KEYS.all = min(rangetest):max(rangetest);
KEYS.all = rangetest;
% KEYS.trigger = KbName('''"');
KEYS.trigger = KbName('''');


COLORS = struct;
COLORS.BLACK = [0 0 0];
COLORS.WHITE = [255 255 255];
COLORS.RED = [255 0 0];
COLORS.BLUE = [0 0 255];
COLORS.GREEN = [0 255 0];
COLORS.YELLOW = [255 255 0];
COLORS.rect = COLORS.GREEN;

n_images = 20;

STIM = struct;
STIM.blocks = 1;
STIM.trials = n_images *2; %n healthy images and n unhealthy images
STIM.totes = STIM.blocks * STIM.trials;
STIM.trialdur = 3.5;
STIM.rate_dur = 2;
STIM.jitter = [2 3 4];

%% Keyboard stuff for fMRI...

%list devices
[keyboardIndices, productNames] = GetKeyboardIndices;

isxkeys=strcmp(productNames,'Xkeys');

xkeys=keyboardIndices(isxkeys);
macbook = keyboardIndices(strcmp(productNames,'Apple Internal Keyboard / Trackpad'));

%in case something goes wrong or the keyboard name isn?t exactly right
if isempty(macbook)
    macbook=-1;
end

%in case you?re not hooked up to the scanner, then just work off the keyboard
if isempty(xkeys)
    xkeys=macbook;
end

% Prepare to use joystick. 20160509cdt
LoadPsychHID
xkeys = 0;


%% Find & load in pics
%find the image directory by figuring out where the .m is kept
[mdir,~,~] = fileparts(which('SimpleExposure_Food_ED.m'));

% [ratedir,~,~] = fileparts(which('SimpleExposure.m'));
picratefolder = fullfile(mdir,'Ratings');   %XXX: Double check this is correct folder.
imgdir = fullfile(mdir,'Pics');

try
    cd(picratefolder)
catch
    error('Could not find and/or open the folder that contains the image ratings.');
end



filen = sprintf('PicRate_Food%d.mat',ID);
try
    p = open(filen);
catch
        warning('Attemped to open file called "%s" for Subject #%d. Could not find and/or open this training rating file. Double check that you have typed in the subject number appropriately.',filen,ID);
    commandwindow;
    randopics = input('Would you like to continue with a random selection of images? [1 = Yes, 0 = No]');
    if randopics == 1
        cd(imgdir)
        p = struct;
        p.PicRating_Food.H = dir('He*');
        p.PicRating_Food.U = dir('Binge*');

    else
        error('Task cannot proceed without images. Contact Erik (elk@uoregon.edu) if you have continued problems.')
    end
    
end

cd(imgdir);
 


PICS =struct;

PICS.in.hi = struct('name',{p.PicRating_Food.H(1:n_images).name}');
PICS.in.lo = struct('name',{p.PicRating_Food.U(1:n_images).name}');
% neutpics = dir('water*');

%Check if pictures are present. If not, throw error.
%Could be updated to search computer to look for pics...
if isempty(PICS.in.hi) || isempty(PICS.in.lo)
    error('Could not find pics. Please ensure pictures are found in a folder names IMAGES within the folder containing the .m task file.');
end

%% Fill in rest of pertinent info
SimpExp = struct;

%1 = Healthy, 0 = Unhealthy
pictype = [ones(n_images,1); zeros(n_images,1)];

%Make long list of randomized #s to represent each pic
piclist = [randperm(n_images)'; randperm(n_images)'];


%Concatenate these into a long list of trial types.
trial_types = [pictype piclist];
shuffled = trial_types(randperm(size(trial_types,1)),:);

jitter = BalanceTrials(STIM.totes,1,STIM.jitter);

 for x = 1:STIM.blocks
     for y = 1:STIM.trials;
         tc = (x-1)*STIM.trials + y;
         SimpExp.data(tc).pictype = shuffled(tc,1);
         
         if shuffled(tc,1) == 1
            SimpExp.data(tc).picname = PICS.in.hi(shuffled(tc,2)).name;
         elseif shuffled(tc,1) == 0
             SimpExp.data(tc).picname = PICS.in.lo(shuffled(tc,2)).name;
         end
         
         SimpExp.data(tc).jitter = jitter(tc);
         SimpExp.data(tc).fix_onset = NaN;
         SimpExp.data(tc).pic_onset = NaN;
         SimpExp.data(tc).rate_onset = NaN;
         SimpExp.data(tc).rate_RT = NaN;
         SimpExp.data(tc).rating = 5;
     end
 end

    SimpExp.info.ID = ID;
    SimpExp.info.date = sprintf('%s %2.0f:%02.0f',date,d(4),d(5));
    


commandwindow;


%%
%change this to 0 to fill whole screen
DEBUG=0;

%set up the screen and dimensions

%list all the screens, then just pick the last one in the list (if you have
%only 1 monitor, then it just chooses that one)
Screen('Preference', 'SkipSyncTests', 1);

screenNumber=max(Screen('Screens'));

if DEBUG==1;
    %create a rect for the screen
    winRect=[0 0 640 480];
    %establish the center points
    XCENTER=320;
    YCENTER=240;
else
    %change screen resolution
%     Screen('Resolution',0,1024,768,[],32);
    
    %this gives the x and y dimensions of our screen, in pixels.
    [swidth, sheight] = Screen('WindowSize', screenNumber);
    XCENTER=fix(swidth/2);
    YCENTER=fix(sheight/2);
    %when you leave winRect blank, it just fills the whole screen
    winRect=[];
end

%open a window on that monitor. 32 refers to 32 bit color depth (millions of
%colors), winRect will either be a 1024x768 box, or the whole screen. The
%function returns a window "w", and a rect that represents the whole
%screen. 
[w, wRect]=Screen('OpenWindow', screenNumber, 0,winRect,32,2);

%%
%you can set the font sizes and styles here
Screen('TextFont', w, 'Arial');
%Screen('TextStyle', w, 1);
Screen('TextSize',w,30);

KbName('UnifyKeyNames');

%% Where should pics go
% Images of food have been normalized to 600x450 pixels.
% Change rect matrices to correct dimensions, remove semi-colons. 20160509cdt
im_width = 600;
im_height = 450;
x_offset = 0;
y_offset = 0;
im_x_center = XCENTER + x_offset;
im_y_center = YCENTER + y_offset;
im_center = [im_x_center im_y_center im_x_center im_y_center];
near_scale = 1.5;
far_scale = 0.5;
im_rect = [-im_width/2 -im_height/2 im_width/2 im_height/2];
STIM.framerect = im_center + im_rect;
STIM.framerectfar = im_center + im_rect * far_scale;
STIM.framerectnear = im_center + im_rect * near_scale;

%% Dat Grid
[rects,mids] = DrawRectsGrid();
% verbage = 'How appetizing is this food?';

%% fMRI Synch

if fmri == 1;
    DrawFormattedText(w,'Synching with fMRI: Waiting for trigger','center','center',COLORS.WHITE);
    Screen('Flip',w);
    
    scan_sec = KbTriggerWait(KEYS.trigger,xkeys);
else
    scan_sec = GetSecs();
end

%% Initial screend
DrawFormattedText(w,'We are going to show you some pictures of food. \n\n Press any # key to continue.','center','center',COLORS.WHITE,50,[],[],1.5);
Screen('Flip',w);
FlushEvents();
while 1
    [pracDown, ~, pracCode] = KbCheck(); %waits for R or L index button to be pressed
    if pracDown == 1 && any(pracCode(KEYS.all))
        break
    end
end
Screen('Flip',w);
WaitSecs(1);

DrawFormattedText(w,'A green border appears around the image, you will have one second to react with the joystick.\n\nPress any key to continue.','center','center',COLORS.WHITE,50,[],[],1.5);
Screen('Flip',w);
FlushEvents();
while 1
    [pracDown, ~, pracCode] = KbCheck(); %waits for R or L index button to be pressed
    if pracDown == 1 && any(pracCode(KEYS.all))
        break
    end
end
Screen('Flip',w);
WaitSecs(1);



DrawFormattedText(w,'A green border appears around the image, you will have one second to react with the joystick.\n\nPress any # key to continue.','center','center',COLORS.WHITE,50,[],[],1.5);
Screen('Flip',w);
FlushEvents();
while 1
    [pracDown, ~, pracCode] = KbCheck(); %waits for R or L index button to be pressed
    if pracDown == 1 && any(pracCode(KEYS.all))
        break
    end
end
Screen('Flip',w);
WaitSecs(1);
DrawFormattedText(w,'Pull the joystick toward you for foods that you do like and pull the joystick away from you for foods you dislike.\n\nPress any # key to continue.','center','center',COLORS.WHITE,50,[],[],1.5);
Screen('Flip',w);
% KbWait([],3);
FlushEvents();
while 1
    [pracDown, ~, pracCode] = KbCheck(); %waits for R or L index button to be pressed
    if pracDown == 1 && any(pracCode(KEYS.all))
        break
    end
end
Screen('Flip',w);
WaitSecs(1);

%% Trials
% 20160509cdt
usingKeyboard = 0;
% Width of border around images.
BORDERSIZE = 15;
joystickCenter = 32767;
joystickSensitivity = 6000;

for block = 1:STIM.blocks
    for trial = 1:STIM.trials
        tcounter = (block-1)*STIM.trials + trial;
        tpx = imread(getfield(SimpExp,'data',{tcounter},'picname'));
        texture = Screen('MakeTexture',w,tpx);
        
        % Fixation. 20160509cdt
        DrawFormattedText(w,'+','center','center',COLORS.WHITE);
        fixon = Screen('Flip',w);
        SimpExp.data(tcounter).fix_onset = fixon - scan_sec;
        WaitSecs(SimpExp.data(tcounter).jitter);
        
        % Intial display of food and instructions. 20160509cdt
        Screen('DrawTexture',w,texture,[],STIM.framerect);
%         DrawFormattedText(w,verbage,'center',(wRect(4)*.75),COLORS.WHITE);
        if (usingKeyboard)
            drawRatings([],w);
        end
        picon = Screen('Flip',w);
        SimpExp.data(tcounter).pic_onset = picon - scan_sec;
        WaitSecs(STIM.trialdur - STIM.rate_dur);
        
        % Time to rate the food. 20160509cdt
        Screen('FillRect', w, COLORS.GREEN, STIM.framerect + [-BORDERSIZE -BORDERSIZE BORDERSIZE BORDERSIZE]);
        Screen('DrawTexture',w,texture,[],STIM.framerect);
%         DrawFormattedText(w,verbage,'center',(wRect(4)*.75),COLORS.GREEN);
        if (usingKeyboard)
            drawRatings([],w,1); %The 1 here turns everything green.
        end
        rateon = Screen('Flip',w);
        SimpExp.data(tcounter).rate_onset = rateon - scan_sec;
        
        FlushEvents();
        telap = 0;
        while telap < STIM.rate_dur
            telap = GetSecs() - rateon;
            
            if (usingKeyboard)
                [keyisdown, rt, keycode] = KbCheck();
                if (keyisdown==1 && any(keycode(KEYS.all)))
                    SimpExp.data(tcounter).rate_RT = rt - rateon;

                    rating = KbName(find(keycode));
                    rating = str2double(rating(1));

                    Screen('DrawTexture',w,texture,[],STIM.framerect);
                    drawRatings(keycode,w,1);
%                     DrawFormattedText(w,verbage,'center',(wRect(4)*.75),COLORS.GREEN);
                    Screen('Flip',w);
                    WaitSecs(.25);
                    if fmri == 1;
                        rating = rating + 1;
                    elseif fmri == 0 && rating == 0
                        rating = 10;
                    end

                    SimpExp.data(tcounter).rating = rating;
                    break;
                end
            else % using joystick 20160509cdt
                n = 0;
                [x, y, z, buttons] = WinJoystickMex(n);
                if (y < joystickCenter - joystickSensitivity)
                    if isnan(SimpExp.data(tcounter).rate_RT)
                        SimpExp.data(tcounter).rate_RT = GetSecs() - rateon;
                    end
                    Screen('FillRect', w, COLORS.GREEN, STIM.framerectfar + [-BORDERSIZE -BORDERSIZE BORDERSIZE BORDERSIZE]);
                    Screen('DrawTexture',w,texture,[],STIM.framerectfar);
%                     DrawFormattedText(w,verbage,'center',(wRect(4)*.75),COLORS.GREEN);
                    Screen('Flip',w);
                    SimpExp.data(tcounter).rating = 1;
                    WaitSecs(.25);
                    fprintf('%d %d %d - %d %d %d %d \n', x, y, z, buttons(1), buttons(2), buttons(3), buttons(4));
                elseif (y > joystickCenter + joystickSensitivity)
                    if isnan(SimpExp.data(tcounter).rate_RT)
                        SimpExp.data(tcounter).rate_RT = GetSecs() - rateon;
                    end
                    Screen('FillRect', w, COLORS.GREEN, STIM.framerectnear + [-BORDERSIZE -BORDERSIZE BORDERSIZE BORDERSIZE]);
                    Screen('DrawTexture',w,texture,[],STIM.framerectnear);
%                     DrawFormattedText(w,verbage,'center',(wRect(4)*.75),COLORS.GREEN);
                    Screen('Flip',w);
                    SimpExp.data(tcounter).rating = 9;
                    WaitSecs(.25);
                    fprintf('%d %d %d - %d %d %d %d \n', x, y, z, buttons(1), buttons(2), buttons(3), buttons(4));
                end

            end
        end        
    end
    
    
%     DrawFormattedText(w,'Press any key to continue','center',wRect(4)*9/10,COLORS.WHITE);
%     Screen('Flip',w);
%     KbWait();
    
end

%% Save all the data

%Export GNG to text and save with subject number.
%find the mfilesdir by figuring out where show_faces.m is kept

%get the parent directory, which is one level up from mfilesdir
savedir = [mdir filesep 'Results' filesep];

% 20160509cdt
if ~exist(savedir, 'dir')
    mkdir(savedir);
end

% cd(savedir)
savename = ['SimpExp_Food_' num2str(ID)];

if exist(savename,'file')==2;
    savename = ['SimpExp_Food_' num2str(ID) '_' sprintf('%s_%2.0f%02.0f',date,d(4),d(5))];
end

% 20160510cdt save names for .mat and .xls files.
mat_savename = [savename '.mat'];
xls_savename = [savename '.xls'];

try
    save([savedir mat_savename],'SimpExp');
    % Prepare data for xls output format. 20160510cdt
    fields = transpose(fieldnames(SimpExp.data));
    out_data = transpose(struct2cell(transpose(SimpExp.data)));
    %xlswrite([savedir xls_savename], fields)
    xlswrite([savedir xls_savename], out_data);
    print('saved xlswrite file');
catch
    warning('Something is amiss with this save. Retrying to save in a more general location...');
    warning( [savedir xls_savename] );
    try
        save([mdir filesep mat_savename],'BRC');
    catch
        warning('STILL problems saving....Try right-clicking on ''SimpExp'' and Save as...');
        SimpExp.data
    end
end

DrawFormattedText(w,'That concludes this task.','center','center',COLORS.WHITE);
Screen('Flip', w);
WaitSecs(5);

sca

end


function [ rects,mids ] = DrawRectsGrid(varargin)
%DrawRectGrid:  Builds a grid of squares with gaps in between.

global wRect XCENTER

%Size of image will depend on screen size. First, an area approximately 80%
%of screen is determined. Then, images are 1/4th the side of that square
%(minus the 3 x the gap between images.

num_rects = 9;                 %How many rects?
xlen = wRect(3)*.9;           %Make area covering about 90% of vertical dimension of screen.
gap = 10;                       %Gap size between each rect
square_side = fix((xlen - (num_rects-1)*gap)/num_rects); %Size of rect depends on size of screen.

squart_x = XCENTER-(xlen/2);
squart_y = wRect(4)*.8;         %Rects start @~80% down screen.

rects = zeros(4,9);

% for row = 1:DIMS.grid_row;
    for col = 1:9;
%         currr = ((row-1)*DIMS.grid_col)+col;
        rects(1,col)= squart_x + (col-1)*(square_side+gap);
        rects(2,col)= squart_y;
        rects(3,col)= squart_x + (col-1)*(square_side+gap)+square_side;
        rects(4,col)= squart_y + square_side;
    end
% end
mids = [rects(1,:)+square_side/2; rects(2,:)+square_side/2+5];

end

%%
function drawRatings(varargin)

global w KEYS COLORS rects mids

if nargin >= 3
    ccc = varargin{3};
    if ccc == 1;
        colors=repmat(COLORS.GREEN',1,9);
        wordcol = COLORS.GREEN;
    end
else
    colors=repmat(COLORS.WHITE',1,9);
    wordcol = COLORS.WHITE;
end

% rects=horzcat(allRects.rate1rect',allRects.rate2rect',allRects.rate3rect',allRects.rate4rect');

%Needs to feed in "code" from KbCheck, to show which key was chosen.
if nargin >= 1 && ~isempty(varargin{1})
    response=varargin{1};
    
    key=find(response);
    if length(key)>1
        key=key(1);
    end;
    
    switch key
        
        case {KEYS.ONE}
            choice=1;
        case {KEYS.TWO}
            choice=2;
        case {KEYS.THREE}
            choice=3;
        case {KEYS.FOUR}
            choice=4;
        case {KEYS.FIVE}
            choice=5;
        case {KEYS.SIX}
            choice=6;
        case {KEYS.SEVEN}
            choice=7;
        case {KEYS.EIGHT}
            choice=8;
        case {KEYS.NINE}
            choice=9;
%         case {KEYS.TEN}
%             choice = 10;
    end
    
    if exist('choice','var')
        
        
        colors(:,choice)=COLORS.BLUE';
        
    end
end

if nargin>=2
    
    window=varargin{2};
    
else
    
    window=w;
    
end
   

Screen('TextFont', window, 'Arial');
Screen('TextStyle', window, 1);
oldSize = Screen('TextSize',window,35);

%draw all the squares
Screen('FrameRect',window,colors,rects,1);


% Screen('FrameRect',w2,colors,rects,1);


%draw the text (1-10)
for n = 1:9;
    numnum = sprintf('%d',n);
    CenterTextOnPoint(window,numnum,mids(1,n),mids(2,n),wordcol);
end


Screen('TextSize',window,oldSize);

end


%%
function [nx, ny, textbounds] = CenterTextOnPoint(win, tstring, sx, sy,color)
% [nx, ny, textbounds] = DrawFormattedText(win, tstring [, sx][, sy][, color][, wrapat][, flipHorizontal][, flipVertical][, vSpacing][, righttoleft])
%
% 

numlines=1;

if nargin < 1 || isempty(win)
    error('CenterTextOnPoint: Windowhandle missing!');
end

if nargin < 2 || isempty(tstring)
    % Empty text string -> Nothing to do.
    return;
end

% Store data class of input string for later use in re-cast ops:
stringclass = class(tstring);

% Default x start position is left border of window:
if isempty(sx)
    sx=0;
end

% if ischar(sx) && strcmpi(sx, 'center')
%     xcenter=1;
%     sx=0;
% else
%     xcenter=0;
% end

xcenter=0;

% No text wrapping by default:
% if nargin < 6 || isempty(wrapat)
    wrapat = 0;
% end

% No horizontal mirroring by default:
% if nargin < 7 || isempty(flipHorizontal)
    flipHorizontal = 0;
% end

% No vertical mirroring by default:
% if nargin < 8 || isempty(flipVertical)
    flipVertical = 0;
% end

% No vertical mirroring by default:
% if nargin < 9 || isempty(vSpacing)
    vSpacing = 1.5;
% end

% if nargin < 10 || isempty(righttoleft)
    righttoleft = 0;
% end

% Convert all conventional linefeeds into C-style newlines:
newlinepos = strfind(char(tstring), '\n');

% If '\n' is already encoded as a char(10) as in Octave, then
% there's no need for replacemet.
if char(10) == '\n' %#ok<STCMP>
   newlinepos = [];
end

% Need different encoding for repchar that matches class of input tstring:
if isa(tstring, 'double')
    repchar = 10;
elseif isa(tstring, 'uint8')
    repchar = uint8(10);    
else
    repchar = char(10);
end

while ~isempty(newlinepos)
    % Replace first occurence of '\n' by ASCII or double code 10 aka 'repchar':
    tstring = [ tstring(1:min(newlinepos)-1) repchar tstring(min(newlinepos)+2:end)];
    % Search next occurence of linefeed (if any) in new expanded string:
    newlinepos = strfind(char(tstring), '\n');
end

% % Text wrapping requested?
% if wrapat > 0
%     % Call WrapString to create a broken up version of the input string
%     % that is wrapped around column 'wrapat'
%     tstring = WrapString(tstring, wrapat);
% end

% Query textsize for implementation of linefeeds:
theight = Screen('TextSize', win) * vSpacing;

% Default y start position is top of window:
if isempty(sy)
    sy=0;
end

winRect = Screen('Rect', win);
winHeight = RectHeight(winRect);

% if ischar(sy) && strcmpi(sy, 'center')
    % Compute vertical centering:
    
    % Compute height of text box:
%     numlines = length(strfind(char(tstring), char(10))) + 1;
    %bbox = SetRect(0,0,1,numlines * theight);
    bbox = SetRect(0,0,1,theight);
    
    
    textRect=CenterRectOnPoint(bbox,sx,sy);
    % Center box in window:
    [rect,dh,dv] = CenterRect(bbox, textRect);

    % Initialize vertical start position sy with vertical offset of
    % centered text box:
    sy = dv;
% end

% Keep current text color if noone provided:
if nargin < 5 || isempty(color)
    color = [];
end

% Init cursor position:
xp = sx;
yp = sy;

minx = inf;
miny = inf;
maxx = 0;
maxy = 0;

% Is the OpenGL userspace context for this 'windowPtr' active, as required?
[previouswin, IsOpenGLRendering] = Screen('GetOpenGLDrawMode');

% OpenGL rendering for this window active?
if IsOpenGLRendering
    % Yes. We need to disable OpenGL mode for that other window and
    % switch to our window:
    Screen('EndOpenGL', win);
end

% Disable culling/clipping if bounding box is requested as 3rd return
% % argument, or if forcefully disabled. Unless clipping is forcefully
% % enabled.
% disableClip = (ptb_drawformattedtext_disableClipping ~= -1) && ...
%               ((ptb_drawformattedtext_disableClipping > 0) || (nargout >= 3));
% 

disableClip=1;

% Parse string, break it into substrings at line-feeds:
while ~isempty(tstring)
    % Find next substring to process:
    crpositions = strfind(char(tstring), char(10));
    if ~isempty(crpositions)
        curstring = tstring(1:min(crpositions)-1);
        tstring = tstring(min(crpositions)+1:end);
        dolinefeed = 1;
    else
        curstring = tstring;
        tstring =[];
        dolinefeed = 0;
    end

    if IsOSX
        % On OS/X, we enforce a line-break if the unwrapped/unbroken text
        % would exceed 250 characters. The ATSU text renderer of OS/X can't
        % handle more than 250 characters.
        if size(curstring, 2) > 250
            tstring = [curstring(251:end) tstring]; %#ok<AGROW>
            curstring = curstring(1:250);
            dolinefeed = 1;
        end
    end
    
    if IsWin
        % On Windows, a single ampersand & is translated into a control
        % character to enable underlined text. To avoid this and actually
        % draw & symbols in text as & symbols in text, we need to store
        % them as two && symbols. -> Replace all single & by &&.
        if isa(curstring, 'char')
            % Only works with char-acters, not doubles, so we can't do this
            % when string is represented as double-encoded Unicode:
            curstring = strrep(curstring, '&', '&&');
        end
    end
    
    % tstring contains the remainder of the input string to process in next
    % iteration, curstring is the string we need to draw now.

    % Perform crude clipping against upper and lower window borders for
    % this text snippet. If it is clearly outside the window and would get
    % clipped away by the renderer anyway, we can safe ourselves the
    % trouble of processing it:
    if disableClip || ((yp + theight >= 0) && (yp - theight <= winHeight))
        % Inside crude clipping area. Need to draw.
        noclip = 1;
    else
        % Skip this text line draw call, as it would be clipped away
        % anyway.
        noclip = 0;
        dolinefeed = 1;
    end
    
    % Any string to draw?
    if ~isempty(curstring) && noclip
        % Cast curstring back to the class of the original input string, to
        % make sure special unicode encoding (e.g., double()'s) does not
        % get lost for actual drawing:
        curstring = cast(curstring, stringclass);
        
        % Need bounding box?
%         if xcenter || flipHorizontal || flipVertical
            % Compute text bounding box for this substring:
            bbox=Screen('TextBounds', win, curstring, [], [], [], righttoleft);
%         end
        
        % Horizontally centered output required?
%         if xcenter
            % Yes. Compute dh, dv position offsets to center it in the center of window.
%             [rect,dh] = CenterRect(bbox, winRect);
            [rect,dh] = CenterRect(bbox, textRect);
            % Set drawing cursor to horizontal x offset:
            xp = dh;
%         end
            
%         if flipHorizontal || flipVertical
%             textbox = OffsetRect(bbox, xp, yp);
%             [xc, yc] = RectCenter(textbox);
% 
%             % Make a backup copy of the current transformation matrix for later
%             % use/restoration of default state:
%             Screen('glPushMatrix', win);
% 
%             % Translate origin into the geometric center of text:
%             Screen('glTranslate', win, xc, yc, 0);
% 
%             % Apple a scaling transform which flips the direction of x-Axis,
%             % thereby mirroring the drawn text horizontally:
%             if flipVertical
%                 Screen('glScale', win, 1, -1, 1);
%             end
%             
%             if flipHorizontal
%                 Screen('glScale', win, -1, 1, 1);
%             end
% 
%             % We need to undo the translations...
%             Screen('glTranslate', win, -xc, -yc, 0);
%             [nx ny] = Screen('DrawText', win, curstring, xp, yp, color, [], [], righttoleft);
%             Screen('glPopMatrix', win);
%         else
            [nx ny] = Screen('DrawText', win, curstring, xp, yp, color, [], [], righttoleft);
%         end
    else
        % This is an empty substring (pure linefeed). Just update cursor
        % position:
        nx = xp;
        ny = yp;
    end

    % Update bounding box:
    minx = min([minx , xp, nx]);
    maxx = max([maxx , xp, nx]);
    miny = min([miny , yp, ny]);
    maxy = max([maxy , yp, ny]);

    % Linefeed to do?
    if dolinefeed
        % Update text drawing cursor to perform carriage return:
        if xcenter==0
            xp = sx;
        end
        yp = ny + theight;
    else
        % Keep drawing cursor where it is supposed to be:
        xp = nx;
        yp = ny;
    end
    % Done with substring, parse next substring.
end

% Add one line height:
maxy = maxy + theight;

% Create final bounding box:
textbounds = SetRect(minx, miny, maxx, maxy);

% Create new cursor position. The cursor is positioned to allow
% to continue to print text directly after the drawn text.
% Basically behaves like printf or fprintf formatting.
nx = xp;
ny = yp;

% Our work is done. If a different window than our target window was
% active, we'll switch back to that window and its state:
if previouswin > 0
    if previouswin ~= win
        % Different window was active before our invocation:

        % Was that window in 3D mode, i.e., OpenGL rendering for that window was active?
        if IsOpenGLRendering
            % Yes. We need to switch that window back into 3D OpenGL mode:
            Screen('BeginOpenGL', previouswin);
        else
            % No. We just perform a dummy call that will switch back to that
            % window:
            Screen('GetWindowInfo', previouswin);
        end
    else
        % Our window was active beforehand.
        if IsOpenGLRendering
            % Was in 3D mode. We need to switch back to 3D:
            Screen('BeginOpenGL', previouswin);
        end
    end
end

return;
end
