function logCount = computeMultibrotCPU(xlim, numx, ylim, numy, maxIters)
% Create a view of the Multibrot set using only the CPU.

% Copyright 2019-2020 The MathWorks, Inc.

% Create the input arrays
x = linspace(xlim(1), xlim(2), numx);
y = linspace(ylim(1), ylim(2), numy);
[x0,y0] = meshgrid(x, y);
z0 = complex(x0, y0);
escapeRadius = 20; % Square of escape radius
exponent = 11;

logCount = process(z0, exponent, escapeRadius.^2, maxIters);
end

function logCount = process(z0, exponent, escapeRadius2, maxIters)
% Calculate
z = z0;
count = zeros(size(z0));

for n = 0:maxIters
    inside = ((real(z).^2 + imag(z).^2) <= escapeRadius2);
    count = count + inside;
    z = inside.*(z.^exponent + z0) + (1-inside).*z;
end
magZ2 = max(real(z).^2 + imag(z).^2, escapeRadius2);
logCount = log(count + 1 - log(log( magZ2 ) / exponent ) / log(exponent));

end