function defs = defineFractals()
% Helper to create a struct defining the various parameters required for
% each fractal.

% Copyright 2019-2020 The MathWorks, Inc.

idx = 0;

% Burning Ship
idx = idx + 1;
defs(idx).Name = "Burning Ship";
defs(idx).MaxIterations = 5000;
defs(idx).ColormapFcn = @bone;
defs(idx).FixedMinimum = false;
defs(idx).StepsInAnimation = 1000;
defs(idx).CPUFunction = @computeBurningShipCPU;
defs(idx).GPUFunction = @computeBurningShipGPU;
defs(idx).LocationList = readLocationList("burningShipLocations.csv");

% Mandelbrot
idx = idx + 1;
defs(idx).Name = "Mandelbrot";
defs(idx).MaxIterations = 5000;
defs(idx).ColormapFcn = @colormap.jet2;
defs(idx).FixedMinimum = false;
defs(idx).StepsInAnimation = 1000;
defs(idx).CPUFunction = @computeMandelbrotCPU;
defs(idx).GPUFunction = @computeMandelbrotGPU;
defs(idx).LocationList = readLocationList("mandelbrotLocations.csv");

% Mandelar
idx = idx + 1;
defs(idx).Name = "Mandelbar";
defs(idx).MaxIterations = 5000;
defs(idx).ColormapFcn = @colormap.jet2;
defs(idx).FixedMinimum = false;
defs(idx).StepsInAnimation = 1000;
defs(idx).CPUFunction = @computeMandelbarCPU;
defs(idx).GPUFunction = @computeMandelbarGPU;
defs(idx).LocationList = readLocationList("mandelbarLocations.csv");

% Multibrot
idx = idx + 1;
defs(idx).Name = "Multibrot 11";
defs(idx).MaxIterations = 5000;
defs(idx).ColormapFcn = @colormap.jet2;
defs(idx).FixedMinimum = false;
defs(idx).StepsInAnimation = 1000;
defs(idx).CPUFunction = @computeMultibrotCPU;
defs(idx).GPUFunction = @computeMultibrotGPU;
defs(idx).LocationList = readLocationList("multibrot11Locations.csv");

% Newton's method on a cubic
idx = idx + 1;
defs(idx).Name = "Newton's Method (cubic)";
defs(idx).MaxIterations = 50;
defs(idx).ColormapFcn = @colormap.jet2;
defs(idx).FixedMinimum = true;
defs(idx).StepsInAnimation = 1000;
defs(idx).CPUFunction = @computeNewtonCubicCPU;
defs(idx).GPUFunction = @computeNewtonCubicGPU;
defs(idx).LocationList = readLocationList("newtonCubicLocations.csv");

% Newton's method on a trug function
idx = idx + 1;
defs(idx).Name = "Newton's Method (trig)";
defs(idx).MaxIterations = 50;
defs(idx).ColormapFcn = @colormap.jet2;
defs(idx).FlipAxes = false;
defs(idx).FixedMinimum = false;
defs(idx).StepsInAnimation = 1000;
defs(idx).CPUFunction = @computeNewtonTrigCPU;
defs(idx).GPUFunction = @computeNewtonTrigGPU;
defs(idx).LocationList = readLocationList("newtonTrigLocations.csv");

% The "tower of powers" function
idx = idx + 1;
defs(idx).Name = "Tower of Powers";
defs(idx).MaxIterations = 50;
defs(idx).ColormapFcn = @colormap.pinkbone;
defs(idx).FixedMinimum = true;
defs(idx).StepsInAnimation = 100;
defs(idx).CPUFunction = @computeTowerCPU;
defs(idx).GPUFunction = @computeTowerGPU;
defs(idx).LocationList = readLocationList("towerLocations.csv");
end

function locations = readLocationList(filename)
fid = fopen(fullfile('locations',filename), 'rt');
if fid<0
    error('fractalViewer:BadLocationRead', ...
        'Could not open location list "%s" for reading.', filename);
end

locData = textscan(fid, '%f,%f,%f');
N = size(locData{1}, 1);
if N<1
    close(gui.Window);
    error('fractalViewer:EmptyLocationFile', 'No locations found in "%s"', filename);
end
locations = struct( ...
    'XLim', cell(N, 1), ...
    'Y', cell(N, 1 ));
for ii=1:N
    locations(ii).XLim = [locData{1}(ii), locData{2}(ii)];
    locations(ii).Y = locData{3}(ii);
end

fclose( fid );
end % readLocationList