function logCount = computeTowerGPU(xlim, numx, ylim, numy, maxIters)
% Compute Tower of Powers using a GPU.

% Copyright 2019-2020 The Mathworks, Inc.

% Create the input arrays
x = gpuArray.linspace(xlim(1),  xlim(2), numx);
y = gpuArray.linspace(ylim(1),  ylim(2), numy);
[x,y] = meshgrid(x, y);
z = complex(x, y);
tol = 1e-4;

% Process
count = cycle_arrayfun(z(:), tol, maxIters);
count = reshape(count, size(z));
logCount = gather(log(count+1));
end

function c = cycle_arrayfun(z, tol, maxIters)
% CYCLE  Cycle length of iterated power
% c = cycle(z)
M = numel(z);
H = 40;   % Height of stack
S = NaN(M,H,"like",z);   % Stack
y = ones(size(z),"like",z);
k = 0;
c = NaN(M,1,"like",real(z([])));
threadID = colon(1,M)';
while k<maxIters
    k = k+1;
    stackPos = mod(k-1, H)+1;
    [y,c] = arrayfun(@iIterate, threadID, z, y, c, maxIters, stackPos, tol, H);
    % Add to stack
    S(:,stackPos) = y;
end


    function [yy, cc] = iIterate(threadID, zz, yy, cc, maxIters, stackPos, tol, H)
        % Nested function to loop over uplevel variable S finding any matches.
        
        if cc < maxIters || ~isfinite(yy)
            % Already found a loop or Y has gone to infinity
            return;
        end
        % This element is still processing
        yy = zz.^yy;
        % Check for a cycle, working backwards from the current sample
        for hh=1:H
            thisIdx = mod(stackPos-hh-1, H)+1;
            thisDiff = abs(yy-S(threadID,thisIdx));
            if thisDiff < tol
                cc = hh;
                break;
            end
        end
    end

end