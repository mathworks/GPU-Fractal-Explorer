function window = fractalExplorer()
%fractalViewer  view and explore a few different fractals using a GPU
%
%   fractalViewer() opens a MATLAB figure window shows one of several
%   simple fractals. Use the usual zoom and pan controls from the figure
%   window toolbar to navigate around and explore, or click "animate" to
%   see a pre-defined path through the set. You can move back to the
%   initial view at any time by clicking the "reset" button or add the
%   current view to the animation list using "add".
%
%   The control panel can be hidden using the right-hand toolbar button.
%
%   A selector allows a choice of factals:
%   1. Burning Ship:  Mandelbrot-like iteration with update function (|Re(z)|+i|Im(z)|)^2
%   2. Mandelbrot:  The classic Mandelbrot set
%   3. Mandelbar:  A Mandelbrot variant using a conjugating update
%   4. Mandelbrot 11:  A Mandelbrot variant using ^11 instead of ^2.
%   5. Newton's Method (cubic):  Iterations to convergence of Newton's
%         method for the function x.^3 - 2.*x - 5
%   6. Newton's Method (trig):  Iterations to convergence of Newton's
%         method for the function tan(sin(x)) - sin(tan(x))
%   7. Tower of Powers:  Cycle count for y(k+1) = z^y(k)
%
%   Note that you can also switch between CPU and GPU execution.
%
%   See also:  gpuArray.

%   Copyright 2019-2021 The Mathworks, Inc.

% Check that we are running in R2011a or above and have a GPU
matlabVersionCheck();
gpuCheck();

% Define some global (to this file) data structures so that they can be
% used by all the helper functions.
versionStr = '1.0';
data = createData();
gui = createGUI(versionStr);
% Copy the window limits into the data
data.WindowPixelSize = gui.Window.Position(1,3:4);

% Make sure the image is updated now that the window is onscreen
reset();

% Return the window handle if requested
if nargout
    window = gui.Window;
end

    function out = createData()
        out = struct( ...
            'XLim', [-2 1], ...
            'Y', 0, ...
            'Fractals', defineFractals(), ...
            'SelectedFractal', "Mandelbrot", ...
            'IsAnimating', false, ...
            'NextLocation', 1, ...
            'LastFrameTime', now(), ...
            'WindowPixelSize', [100 100], ...
            'CalculationMethods', ["CPU","GPU"], ...
            'SelectedCalculationMethod', "CPU", ...
            'ControlsVisible', true, ...
            'WriteVideo', false, ...
            'VideoWriter',  [] );
    end % createData

    function out = createGUI(versionStr)
        % Create the GUI, storing handles in the global GUI structure
        out.Window = figure( ...
            'Name', ['Fractal Explorer v', versionStr], ...
            'NumberTitle', 'off', ...
            'HandleVisibility', 'off', ...
            'MenuBar', 'none', ...
            'ToolBar', 'figure', ...
            'Renderer', 'ZBuffer' ); % Can't use painters as colormaps are broken for >256 colors!
        out.MainAxes = axes( ...
            'Parent', out.Window, ...
            'Position', [0 0 1 1], ...
            'XLim', data.XLim, ...
            'YLim', [-1 1], ...
            'CLim', log([1 1000]), ...
            'XTick', [], 'YTick', [], ...
            'DataAspectRatio', [1 1 1] );
        out.Image = image( ...
            'XData', [0 1], ...
            'YData', [0 1], ...
            'XLimInclude', 'off', ...
            'YLimInclude', 'off', ...
            'CData', nan, ...
            'CDataMapping', 'Scaled', ...
            'HandleVisibility', 'off', ...
            'Parent', out.MainAxes );
        % Add a line so that zooming works. Strange but true.
        line( 'Parent', out.MainAxes, 'XData', [-2 2], 'YData', [-2 2], ...
            'Visible', 'off', ...
            'HitTest', 'off' );
        set( out.MainAxes, 'XLimMode', 'manual', 'YLimMode', 'manual', ...
            'CLim', [0 1] );
        colormap( out.MainAxes, colormap.jet2(1000) );
        
        out.ControlPanel = uipanel( ...
            'Parent', out.Window, ...
            'BackgroundColor', 'k', ...
            'Units', 'Pixels', ...
            'Position', [10 10 155 102] );
        
        % Some text for showing compute time
        out.ComputeText = uicontrol( ...
            'Style', 'Text', ...
            'String', 'Computed in 0ms', ...
            'BackgroundColor', 'k', ...
            'ForegroundColor', 'g', ...
            'FontSize', 7, ...
            'Parent', out.ControlPanel, ...
            'Position', [5 16 145 14] );
        out.FrameRateText = uicontrol( ...
            'Style', 'Text', ...
            'String', 'Displaying at 0fps', ...
            'BackgroundColor', 'k', ...
            'ForegroundColor', 'g', ...
            'FontSize', 7, ...
            'Parent', out.ControlPanel, ...
            'Position', [5 2 145 14] );
        
        % Create a drop-down for selecting the calculation method
        out.MethodSelector = uicontrol( ...
            'Style', 'PopupMenu', ...
            'String', data.CalculationMethods, ...
            'Value', 2, ...
            'FontSize', 7, ...
            'Parent', out.ControlPanel, ...
            'BackgroundColor', 0.8*[1 1 1], ...
            'Position', [5 78 145 16], ...
            'Callback', @onCalculationMethodChanged );
        out.FractalSelector = uicontrol( ...
            'Style', 'PopupMenu', ...
            'String', [data.Fractals.Name], ...
            'Value', 2, ...
            'FontSize', 7, ...
            'Parent', out.ControlPanel, ...
            'BackgroundColor', 0.8*[1 1 1], ...
            'Position', [5 54 145 16], ...
            'Callback', @onFractalChanged );
        out.ResetButton = uicontrol( ...
            'Style', 'ToggleButton', ...
            'String', 'Reset', ...
            'FontSize', 7, ...
            'Parent', out.ControlPanel, ...
            'BackgroundColor', 0.6*[1 1 1], ...
            'Position', [5 30 70 16], ...
            'TooltipString', 'Reset the view to the top', ...
            'Callback', @onResetPressed );
        out.AnimateButton = uicontrol( ...
            'Style', 'ToggleButton', ...
            'String', 'Animate', ...
            'FontSize', 7, ...
            'Parent', out.ControlPanel, ...
            'BackgroundColor', 0.6*[1 1 1], ...
            'Position', [80 30 70 16], ...
            'TooltipString', 'Start/stop animating between stored locations', ...
            'Callback', @onPlayPressed );
        
        % Remove some things we don't want from the toolbar and add a
        % toggle to the toolbar to hide the controls
        tb = findall( out.Window, 'Type', 'uitoolbar' );
        delete( findall( tb, 'Tag', 'Standard.FileOpen' ) );
        delete( findall( tb, 'Tag', 'Standard.NewFigure' ) );
        delete( findall( tb, 'Tag', 'Standard.EditPlot' ) );
        delete( findall( tb, 'Tag', 'Exploration.Brushing' ) );
        delete( findall( tb, 'Tag', 'Exploration.DataCursor' ) );
        delete( findall( tb, 'Tag', 'Exploration.Rotate' ) );
        delete( findall( tb, 'Tag', 'DataManager.Linking' ) );
        delete( findall( tb, 'Tag', 'Plottools.PlottoolsOn' ) );
        delete( findall( tb, 'Tag', 'Plottools.PlottoolsOff' ) );
        out.AnimateToggle = uitoggletool( ...
            'Parent', tb, ...
            'CData', readIcon( 'icon_play.png' ), ...
            'TooltipString', 'Start/stop animating between stored locations', ...
            'State', 'off', ...
            'Separator', 'on', ...
            'ClickedCallback', @onPlayToolbarPressed );
        out.ShowControlsToggle = uitoggletool( ...
            'Parent', tb, ...
            'CData', readIcon( 'icon_mandelControls.png' ), ...
            'TooltipString', 'Show/hide the control panel', ...
            'State', 'on', ...
            'ClickedCallback', @onControlsTogglePressed );
        
        
        % Add listeners so that we can redraw when the axes are moved
        addlistener( out.MainAxes, 'YLim', 'PostSet', @onLimitsChanged );
        % Also redraw if resized
        set( out.Window, 'ResizeFcn', @onFigureResize, ...
            'CloseRequestFcn', @onFigureClose );
    end % createGUI

    function onFractalChanged( ~, ~ )
        %Stop animating
        data.IsAnimating = false;
        updateAnimationControls( false );
        % Select the new fractal
        idx = get( gui.FractalSelector, 'Value' );
        data.SelectedFractal = data.Fractals(idx).Name;
        % Now call the reset callback to get us to the starting state
        onResetPressed();
    end % onFractalChanged

    function onLimitsChanged( ~, ~ )
        redraw();
    end % onLimitsChanged

    function onFigureResize( ~, ~ )
        % Change the axes limits to exactly fit the figure
        pos = get( gui.Window, 'Position' );
        xlim = get( gui.MainAxes, 'XLim' );
        ylim = get( gui.MainAxes, 'YLim' );
        delta_ylim = ( diff( xlim )*pos(4)/pos(3) - diff( ylim ) ) / 2;
        data.WindowPixelSize = pos(3:4);
        % Set the YLim to give the correct aspect. This will trigger a
        % redraw
        set( gui.MainAxes, 'YLim', ylim + delta_ylim*[-1 1] );
    end % onFigureResize

    function onFigureClose( ~, ~ )
        % Clear up
        data.IsAnimating = false;
        if data.WriteVideo
            close( data.VideoWriter );
        end
        delete( gui.Window );
    end % onFigureClose

    function onCalculationMethodChanged( ~, ~ )
        idx = get( gui.MethodSelector, 'Value' );
        data.SelectedCalculationMethod = data.CalculationMethods{idx};
        redraw();
    end % onCalculationMethodChanged

    function onResetPressed( ~, ~ )
        fprintf( 'Leaving location [%1.15f, %1.15f], %1.15f\n', ...
            data.XLim, data.Y );
        reset();
    end

    function reset()
        fract = iGetSelectedFractalDefinition(data);
        origXLim = fract.LocationList(1).XLim;
        origY = fract.LocationList(1).Y;
        
        pos = get( gui.Window, 'Position' );
        aspect = pos(4)/pos(3);
        ylim = diff(origXLim) * aspect / 2 * [-1 1];
        set( gui.MainAxes, 'XLim', origXLim, 'YLim', origY + ylim );
        set( gui.ResetButton, 'Value', 0 );
        set( gui.MainAxes, 'XDir', 'normal', 'YDir', 'normal' );
        
        % Also reset the colormap in case we changed fractal
        colormap( gui.MainAxes, fract.ColormapFcn(1000) );
        data.NextLocation = 1;
        redraw();
    end % onResetPressed

    function onPlayPressed( ~, ~ )
        disp('Play')
        if get( gui.AnimateButton, 'Value' )==1
            updateAnimationControls(true);
            while ishandle(gui.AnimateButton) && (get( gui.AnimateButton, 'Value' )==1)
                fract = iGetSelectedFractalDefinition(data);
                locationList = fract.LocationList;
                newXLim = locationList(data.NextLocation).XLim;
                newY    = locationList(data.NextLocation).Y;
                animatedMove( newXLim, newY );
                if numel(locationList)>1
                    % Choose a random location
                    thisLocation = data.NextLocation;
                    while data.NextLocation == thisLocation
                        data.NextLocation = randi( numel(locationList), 1 );
                    end
                    fprintf( 'Next location: %d\n', data.NextLocation )
                else
                    % Only one location, so stop
                    data.IsAnimating = false;
                    updateAnimationControls( false );
                end
            end
        else
            data.IsAnimating = false;
            updateAnimationControls( false );
        end
    end % onPlayPressed

    function onPlayToolbarPressed( ~, evt )
        ison = strcmpi(get( gui.AnimateToggle, 'State' ), 'on');
        updateAnimationControls( ison );
        onPlayPressed(gui.AnimateButton, evt);
    end % onPlayToolbarPressed

    function updateAnimationControls( isAnimating )
        if isAnimating
            set( gui.AnimateButton, 'Value', 1 );
            set( gui.AnimateToggle, 'State', 'on' );
        else
            set( gui.AnimateButton, 'Value', 0 );
            set( gui.AnimateToggle, 'State', 'off' );
        end
        drawnow();
    end % updateAnimationControls

    function onControlsTogglePressed( ~, ~ )
        % Toggle the control panel on and off
        disp('Toggle controls')
        pos = get( gui.ControlPanel, 'Position' );
        if strcmpi( get( gui.ShowControlsToggle, 'State' ), 'off' )
            % Turn it off (move offscreen)
            pos(1) = -pos(3)-10;
        else
            % Turn it on (move onscreen)
            pos(1) = 10;
        end
        set( gui.ControlPanel, 'Position', pos );
        
    end

    function animatedMove( targetXLim, targetY )
        % Form a zoom path between the two
        data.IsAnimating = true;
        if isequal( data.XLim, targetXLim ) && isequal( data.Y, targetY )
            data.IsAnimating = false;
            return;
        end
        
        % Perform a zoom and translate arc
        fract = iGetSelectedFractalDefinition(data);
        maxNumSteps = fract.StepsInAnimation;
        distTravelled = sqrt( (mean( data.XLim ) - mean( targetXLim )).^2 ...
            + (data.Y - targetY).^2 );
        adjustRatio = exp( -10*linspace(-3,3,maxNumSteps).^2 );
        adjustRatio = adjustRatio - min(adjustRatio);
        ratio = cumsum( adjustRatio ); ratio = ratio / ratio(end);
        minXPath = interp1( [0,1], [data.XLim(1),targetXLim(1)], ratio );
        maxXPath = interp1( [0,1], [data.XLim(2),targetXLim(2)], ratio );
        maxXRange = max( maxXPath - maxXPath );
        xlimAdjust = max(0, 0.3*distTravelled - maxXRange);
        minXPath = minXPath - xlimAdjust*adjustRatio;
        maxXPath = maxXPath + xlimAdjust*adjustRatio;
        
        % Cull the ends if there's negligable motion. This helps to keep
        % things smooth but without long periods of no apparant motion.
        tolerance = 0.001;
        xRange = maxXPath - minXPath;
        firstGood = find( (xRange > (1+tolerance)*xRange(1)) | (xRange < (1-tolerance)*xRange(1)), 1, 'first' );
        if ~isempty( firstGood ) && firstGood > 2
            toCull = 2:firstGood-1;
        else
            toCull = [];
        end
        lastGood = find( (xRange > (1+tolerance)*xRange(end)) | (xRange < (1-tolerance)*xRange(end)), 1, 'last' );
        if ~isempty( lastGood ) && lastGood < numel(xRange)-1
            toCull = [toCull, lastGood:numel(xRange)-1];
        end
        ratio(toCull) = [];
        minXPath(toCull) = [];
        maxXPath(toCull) = [];
        xRange(toCull) = [];
        
        if ~isempty( ratio )
            % Work out the aspect ratio
            pos = get( gui.Window, 'Position' );
            aspect = pos(4)/pos(3);
            
            YPath = interp1( [0,1], [data.Y,targetY], ratio );
            heightPath = aspect*xRange;
            minYPath = YPath - 0.5*heightPath;
            maxYPath = YPath + 0.5*heightPath;
            for ii=1:numel(ratio)
                % Setting the limits will cause a redraw
                set( gui.MainAxes, ...
                    'XLim', [minXPath(ii),maxXPath(ii)], ...
                    'YLim', [minYPath(ii),maxYPath(ii)] );
                if data.IsAnimating == false
                    break;
                end
            end
        end
        data.IsAnimating = false;
        % Do a final redraw at full res
        redraw();
    end % animatedMove

    function redraw()
        % Protect against the window closing
        if ~ishandle(gui.MainAxes)
            return;
        end
        % To work out what to draw and at what resolution we need the axis
        % limits and pixel counts.
        xlim = get(gui.MainAxes,'XLim');
        ylim = get(gui.MainAxes,'YLim');
        data.XLim = xlim;
        data.Y = mean( ylim );
        imWidth = data.WindowPixelSize(1);
        imHeight = data.WindowPixelSize(2);
        
        fractalDef = iGetSelectedFractalDefinition(data);
        
        zoomLevel = imWidth / diff( xlim );
        maxIterations = min( fractalDef.MaxIterations, 200 + 0.1*sqrt(zoomLevel) );
        
        if data.SelectedCalculationMethod == "GPU"
            calcFcn = fractalDef.GPUFunction;
        else
            calcFcn = fractalDef.CPUFunction;
        end
        
        t = tic;
        logCount = computeFractal(calcFcn, ...
            xlim, imWidth, ...
            ylim, imHeight, ...
            maxIterations);
        computeTime = toc(t);
        
        if ~isempty(logCount)
            if fractalDef.FixedMinimum
                % Leave minimum alone but scale by maxit
                logCount = logCount ./ log(maxIterations+1);
            else
                % Adjust minimum so that colors scale
                minCount = min( logCount(:) );
                logCount = (logCount - minCount) ./ (log(maxIterations+1)-minCount);
            end
        end
        
        % Guard against a closed window
        if ~ishandle( gui.Image )
            return;
        end
        set( gui.Image, ...
            'XData', xlim, ...
            'YData', ylim, ...
            'CData', logCount );
        if data.ControlsVisible
            set( gui.ComputeText, 'String', sprintf( 'Computed in %dms', round(1000*computeTime) ) )
            
            % Capture the current time for frame-rate calculations
            thisFrameTime = now();
            framerate = 1 / (86400*(thisFrameTime - data.LastFrameTime)); % convert days to seconds
            set( gui.FrameRateText, 'String', sprintf( 'Displaying at %dfps', round(framerate) ) )
            data.LastFrameTime = thisFrameTime;
            
            % Force a redraw
            drawnow();
        end
        
        % Capture!
        if data.WriteVideo
            t0 = now();
            currFrame = getframe( gui.Window );
            writeVideo( data.VideoWriter, currFrame );
            % Also reset the frame time to exclude the video writing
            delta_t = now() - t0;
            data.LastFrameTime = data.LastFrameTime + delta_t;
        end
        
        
    end % redraw

    function fractalDef = iGetSelectedFractalDefinition(data)
        % Get the definitions for the selected fractal
        selectedName = data.SelectedFractal;
        allNames = [data.Fractals.Name];
        fractalDef = data.Fractals(strcmp(allNames, selectedName));
    end

    function logCount = computeFractal(calculationFcn, ...
            xlim, numx, ...
            ylim, numy, ...
            maxIterations)
        % Perform the calculation using the selected method.
        
        % Guard against fractional sizes
        numx = round(numx);
        numy = round(numy);
        
        % Guard against empty (zero sized window?)
        if numx<=0 || numy<=0
            logCount = ones(max(0,numy), max(0,numx));
            return;
        end
        
        % Call the computation
        logCount = calculationFcn( xlim, numx, ...
            ylim, numy, ...
            maxIterations );
    end

    function cdata = readIcon( filename )
        [cdata,~,alpha] = imread( fullfile('icons', filename) );
        idx = find( ~alpha );
        page = size(cdata,1)*size(cdata,2);
        cdata = double( cdata ) / 255;
        cdata(idx) = nan;
        cdata(idx+page) = nan;
        cdata(idx+2*page) = nan;
    end % readIcon

    function matlabVersionCheck()
        % R2011a is v7.12
        majorMinor = sscanf( version, '%d.%d' );
        if (majorMinor(1)<7) || (majorMinor(1)==7 && majorMinor(2)<13)
            error( 'fractalViewer:MATLABTooOld', 'fractalViewer requires MATLAB R2011b or above.' );
        end
    end % matlabVersionCheck

    function gpuCheck()
        try
            d = gpuDevice();
        catch err
            error( 'fractalViewer:NoGPU', 'fractalViewer requires a GPU and none appear to be availble. Type "gpuDevice" for more information.' );
        end
        if ~d.DeviceSupported
            error( 'fractalViewer:GPUNotSupported', 'The selected GPU is not supported. Type "gpuDevice" for more information.' );
        end
    end % matlabVersionCheck

end % fractalViewer