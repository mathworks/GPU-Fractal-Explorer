function logCount = computeNewtonTrigCPU(xlim, numx, ylim, numy, maxIters)
% Compute the Newton's Method trig fractal using GPU arrayfun.

% Copyright 2019-2020 The Mathworks, Inc.

% Create the input arrays
x = linspace(xlim(1),  xlim(2), numx);
y = linspace(ylim(1),  ylim(2), numy);
[x,y] = meshgrid(x, y);
tolerance = sqrt(eps("double"));

z = complex(x, y);
w = complex(Inf, 0);

% Calculate
count = zeros(size(x));
for n = 0:maxIters
    notDone = (abs(z-w) > tolerance);
    count = count + notDone;
    w = z;
    z(notDone) = z(notDone) - f(z(notDone)) ./ df(z(notDone));
end
logCount = log(count+1);


function z = f(x)
z = tan(sin(x)) - sin(tan(x));

function z = df(x)
z = cos(x).*(tan(sin(x)).^2 + 1) - cos(tan(x)).*(tan(x).^2 + 1);