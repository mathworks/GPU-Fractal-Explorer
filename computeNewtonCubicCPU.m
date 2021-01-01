function logCount = computeNewtonCubicCPU(xlim, numx, ylim, numy, maxIters)
% Compute the Newton's Method cubic fractal using GPU arrayfun.

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
z = x.^3 - 2.*x - 5;

function z = df(x)
z = 3.*x.^2 - 2;