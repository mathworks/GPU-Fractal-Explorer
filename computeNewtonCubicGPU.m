function logCount = computeNewtonCubicGPU(xlim, numx, ylim, numy, maxIters)
% Compute the Newton's Method cubic fractal using GPU arrayfun.

% Copyright 2019-2020 The Mathworks, Inc.

% Create the input arrays
x = gpuArray.linspace(xlim(1),  xlim(2), numx);
y = gpuArray.linspace(ylim(1),  ylim(2), numy);
[x,y] = meshgrid(x, y);
tolerance = sqrt(eps("double"));

% Calculate
logCount = arrayfun(@processElement, x, y, tolerance, maxIters);

% Gather the result back to the CPU
logCount = gather(logCount);


function logCount = processElement(x0, y0, tolerance, maxIterations)
% Evaluate the Burning Ship function for a single element
z = complex(x0, y0);
w = complex(Inf,0);
count = 0;
while (count < maxIterations) && (abs(z-w) > tolerance)
    w = z;
    z = z - f(z) ./ df(z);
    count = count + 1;
end
logCount = log(count + 1);

function z = f(x)
z = x.^3 - 2.*x - 5;

function z = df(x)
z = 3.*x.^2 - 2;