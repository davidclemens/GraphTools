function varargout = tightFig(hfig,hsp,spi,PaperPos,MarginOuter,MarginInner,varargin)
% tightFig  removes dead space in figures
%   TIGHTFIG iteratively reformats an existing figure with a subplot matrix to 
%   minimize the dead space between subplots.
%
%   Syntax
%     TIGHTFIG(hfig,hsp,spi,PaperPos,MarginOuter,MarginInner)
%     TIGHTFIG(hfig,hsp,spi,PaperPos,MarginOuter,MarginInner,DPI)
%     hfig    = TIGHTFIG(__)
%
%   Description
%     TIGHTFIG(hfig,hsp,spi,PaperPos,MarginOuter,MarginInner)
%     TIGHTFIG(hfig,hsp,spi,PaperPos,MarginOuter,MarginInner,DPI)
%     hfig    = TIGHTFIG(__)
%
% 	Example(s)
%     hfig = TIGHTFIG(hfig,hsp,spi,[10,20],[1,2,1,2],0.5);
%     IGHTFIG(hfig,hsp,spi,[10,20],1,0.5);
%     hfig = TIGHTFIG(hfig,hsp,spi,[10,20],1,[0.5,2]);
%
% 	Input Arguments:
%     hfig - figure handle
%       figure handle       
%         Handle to the figure to which to apply the TightFig function.
%
%     hsp - array of subplot handles
%       axis handle array
%         Array of subplot handles, where size(hsp) = [# subplot rows,
%         # subplot columns].
%
%     spi - array of subplot indices
%       postive numeric integer array
%         Array of subplot indices, where size(spi) = [# subplot rows,
%         # subplot columns] and max(spi) = # subplots.
%
%     PaperPos - paper position array
%       1x2 numeric vector
%         Paper position array n the form of [width, height] in
%         centimeters.
%
%     MarginOuter - outer margin array
%       positive numeric scalar | 1x4 positive numeric vector
%         Outer margin array in the form of [left, bottom, right, top]
%         in centimeters.
%
%     MarginInner - inner margin array
%       positive numeric scalar | 1x2 positive numeric vector
%         Inner margin array in the form of [horizontal, vertical] in
%         centimeters.
%
%     DPI - dots per inch of disply
%       positive numeric scalar
%         Manually sets the dots per inch (dpi) of the display to account
%         for errors in the proper display dpi detection.
%
%
%   Name-Value Pair Arguments
%
%
%   See also SUBPLOT, FIGURE
%
%   Copyright (c) 2017-2022 David Clemens (dclemens@geomar.de)
%

    % Check inputs
    narginchk(6,7)
    nargoutchk(0,1)
    
    gr  = groot;
    if nargin == 6
        DPI     = gr.ScreenPixelsPerInch;
    elseif nargin == 7
        DPI     = varargin{1};
    end
    if ~isgraphics(hfig,'figure')
        error('hfig needs to be a figure handle.')
    end
    if any(floor(spi) ~= spi)
        error('spi needs to be matrix of integer values.')
    end
    if any(~isgraphics(hsp(:),'axes'))
        error('hsp needs to be a matrix of axes handles (subplots).')
    end
    if ~isnumeric(PaperPos) && ~all(size(PaperPos) == [1,2])
        error('PaperPos needs to be a numeric matrix of size [1,2]. Instead it was of size [%s].',strjoin(arrayfun(@(x) num2str(x,'%d'),size(PaperPos),'un',0),','))
    end
    if ~isnumeric(MarginOuter) && ~any(all([size(MarginOuter) == [1,4];size(MarginOuter) == [1,1]],2))
        error('MarginOuter needs to be a numeric matrix of size [1,4] or [1,1]. Instead it was of size [%s].',strjoin(arrayfun(@(x) num2str(x,'%d'),size(MarginOuter),'un',0),','))
    end
    if ~isnumeric(MarginInner) && ~any(all([size(MarginInner) == [1,2];size(MarginInner) == [1,1]],2))
        error('MarginOuter needs to be a numeric matrix of size [1,2] or [1,1]. Instead it was of size [%s].',strjoin(arrayfun(@(x) num2str(x,'%d'),size(MarginInner),'un',0),','))
    end
    if ~isnumeric(DPI) && numel(DPI) == 1 && DPI > 0
        error('The DPI input must be a positive numeric scalar.')
    end

    % expand MarginOuter if only one value was given
    if all(size(MarginOuter) == [1,1])
        MarginOuter     = repmat(MarginOuter,[1,4]);
    end
    % expand MarginInner if only one value was given
    if all(size(MarginInner) == [1,1])
        MarginInner     = repmat(MarginInner,[1,2]);
    end

    % Main function
    DPIratio            = DPI/gr.ScreenPixelsPerInch;
    PaperPos            = PaperPos.*DPIratio;               % apply DPI factor
    MarginOuter      	= MarginOuter.*DPIratio;        	% apply DPI factor
    MarginInner      	= MarginInner.*DPIratio;        	% apply DPI factor

    [spny,spnx]         = size(spi);        % get subplot matrix dimensions
    UnitsOldFig         = hfig.Units;       % store original figure units
    hfig.WindowStyle    = 'normal';         % make sure figure is not docked
    hfig.Visible        = 'off';

    hfig.Units          = 'centimeters';                  	% set figure units to centimeters
    hfig.Position       = [0 0 PaperPos(1) PaperPos(2)];	% set figure dimensions equal to paper size
    drawnow()

    % Initialize variables
    SubplotTightInsetOld  	= NaN(spny,spnx,4);     % left, bottom, right & top tight inset of subplots
    SubplotPositionOld      = NaN(spny,spnx,4);     % initialize
    SubplotTightInsetNew  	= NaN(spny,spnx,4);     % left, bottom, right & top tight inset of subplots
    SubplotPositionNew    	= NaN(spny,spnx,4);     % initialize

    % Get initial values for tight insets and positions of subplots
    for col = 1:spnx % loop over subplot columns
        for row = 1:spny % loop over subplot rows
            hsp(spi(row,col)).Units             = 'centimeters';                            % set subplot units to centimeters
            %set(hsp(spi(row,col)),'LooseInset',get(hsp(spi(row,col)),'TightInset'))
            SubplotTightInsetOld(row,col,:)     = hsp(spi(row,col)).TightInset.*DPIratio; 	% get left, bottom, right & top tight inset of subplot
            SubplotPositionOld(row,col,:)       = hsp(spi(row,col)).Position.*DPIratio;  	% get position of subplot
        end
    end

    % Iterate
    MaxIter     = 20;       % define
    Check       = true;     % initialize
    ii          = 1;        % initialize
    while Check
        if ii > MaxIter % if maximum number of iterations is surpassed
            warning('Maximum number of iterations (%s) reached.',num2str(MaxIter,'%d'))
            break
        end
        % total space left for subplots
        MaxTightInsetX      = max(sum(cat(3,[zeros(spny,1),SubplotTightInsetOld(:,:,3)],[SubplotTightInsetOld(:,:,1),zeros(spny,1)]),3),[],1);
        MaxTightInsetY      = max(sum(cat(3,[zeros(1,spnx);SubplotTightInsetOld(:,:,2)],[SubplotTightInsetOld(:,:,4);zeros(1,spnx)]),3),[],2);
        %                     Total paper width     - left & right margin       - inner margins             - max of all tight insets in X
        SubplotWidthTotal 	= PaperPos(1)           - sum(MarginOuter([1,3]))   - (spnx - 1)*MarginInner(1)	- sum(MaxTightInsetX);
        %                     Total paper height    - bottom & top margin       - inner margins             - max of all tight insets in Y
        SubplotHeightTotal  = PaperPos(2)           - sum(MarginOuter([2,4]))   - (spny - 1)*MarginInner(2)	- sum(MaxTightInsetY);

        % write width & height of subplots to new position
        SubplotPositionNew(:,:,3)	= repmat(SubplotWidthTotal/spnx,[spny,spnx]);
        SubplotPositionNew(:,:,4)	= repmat(SubplotHeightTotal/spny,[spny,spnx]);
        for col = 1:spnx % loop over subplot columns
            for row = 1:spny % loop over subplot rows
                % write X & Y coordinates of subplots to new position
                SubplotPositionNew(row,col,1)	= MarginOuter(1) + (col - 1)*MarginInner(1) + sum(MaxTightInsetX(1:col)) + (SubplotWidthTotal/spnx)*(col - 1);
                SubplotPositionNew(row,col,2)	= MarginOuter(2) + (spny - row)*MarginInner(2)  + sum(MaxTightInsetY((row + 1):(spny + 1))) + (SubplotHeightTotal/spny)*(spny - row);

                % apply new position
                try
                hsp(spi(row,col)).Position      = squeeze(SubplotPositionNew(row,col,:))';
                catch

                end
                % get new tight inset and position values
                SubplotTightInsetNew(row,col,:)	= hsp(spi(row,col)).TightInset.*DPIratio;	% get new left, bottom, right & top tight inset of subplot
                SubplotPositionNew(row,col,:)  	= hsp(spi(row,col)).Position.*DPIratio;  	% get new position of subplot
            end
        end
        % check progess
        CheckTolerance          = 4;
        CheckTightInset         = round(SubplotTightInsetNew,CheckTolerance,'significant') ~= round(SubplotTightInsetOld,CheckTolerance,'significant');     % true if old and new value differ in tight inset
        CheckPosition           = round(SubplotPositionNew,CheckTolerance,'significant') ~= round(SubplotPositionOld,CheckTolerance,'significant');         % true if old and new value differ in position
        Check                   = any(any([CheckTightInset(:),CheckPosition(:)])); % true if any value old and new value in position, tight inset or loose inset differ

        SubplotTightInsetOld    = SubplotTightInsetNew;	% set new old values
        SubplotPositionOld      = SubplotPositionNew; 	% set new old values
        ii                      = ii + 1;               % increment iteration counter
        drawnow()
    end

    % Reset units
    for col = 1:spnx
        for row = 1:spny
            hsp(spi(row,col)).Units     = 'normalized';
        end
    end
    hfig.Units      = UnitsOldFig;

    if nargout == 1
        varargout{1}	= hfig;
    end

    hfig.Visible    = 'on';
end
