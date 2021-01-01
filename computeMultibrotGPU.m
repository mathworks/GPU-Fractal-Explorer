function logCount = computeMultibrotGPU(xlim, numx, ylim, numy, maxIters)
% Compute the Multibrot set using GPU arrayfun.

% Copyright 2019-2020 The Mathworks, Inc.

% Create the input arrays
x = gpuArray.linspace(xlim(1),  xlim(2), numx);
y = gpuArray.linspace(ylim(1),  ylim(2), numy);
[x,y] = meshgrid(x, y);
escapeRadius = 20;
exponent = 11;

% Calculate
logCount = arrayfun(@processElement, ...
    x, y, exponent, escapeRadius.^2, maxIters);

% Gather the result back to the CPU
logCount = gather(logCount);


function logCount = processElement(x0, y0, exponent, escapeRadius2, maxIterations)
% Evaluate the Multibrot function for a single element

z0 = complex( x0, y0 );
z = z0;
count = 0;
while (count <= maxIterations) && (z*conj(z) <= escapeRadius2)
    z = z.^exponent + z0;
    count = count + 1;
end
magZ2 = max(real(z).^2 + imag(z).^2, escapeRadius2);
logCount = log(count + 1 - log(log( magZ2 ) / exponent ) / log(exponent));

