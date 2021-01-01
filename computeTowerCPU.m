function logCount = computeTowerCPU(xlim, numx, ylim, numy, maxIters)
% Compute Tower of Powers using a CPU.

% Copyright 2019-2020 The Mathworks, Inc.

% Create the input arrays
x = linspace(xlim(1),  xlim(2), numx);
y = linspace(ylim(1),  ylim(2), numy);
[x,y] = meshgrid(x, y);
z = complex(x, y);
tol = 1e-4;

% Process the whole array at once
count = reshape(cycle(z(:), tol, maxIters), size(z));
logCount = log(count+1);
end

function c = cycle(z, tol, maxIters)
% CYCLE  Cycle length of iterated power
% c = cycle(z)
M = numel(z);
H = 40;   % Height of stack
S = NaN(M,H,"like",z);   % Stack
y = ones(M,1,"like",z);
k = 0;
c = NaN(M,1);
stillRunning = true(size(c));
while k<maxIters
    y = z.^y;
    k = k+1;
    minDiff = min(abs(y-S), [], 2);
    % For each newly discovered loop we need to find the minimum cycle
    % length
    newLoops = find(stillRunning & (minDiff < tol));
    for ll = 1:numel(newLoops)
        row = newLoops(ll);
        c(row) = find(abs(y(row)-S(row,:)) < tol, 1, "first");
    end
    stillRunning(newLoops) = false;
    % Add to stack
    S(:,2:end) = S(:,1:end-1);
    S(:,1) = y;
end
end