function cmap = jet2(m)
% Jet colormap with added fade to black

%   Copyright 2010-2019 The Mathworks, Inc.

if nargin < 1
   f = get(groot,'CurrentFigure');
   if isempty(f)
      m = size(get(groot,'DefaultFigureColormap'),1);
   else
      m = size(f.Colormap,1);
   end
end


% A list of break-point colors
colors = [
    0.0  0.0  0.5
    0.0  0.0  1.0
    0.0  0.5  1.0
    0.0  1.0  1.0
    0.5  1.0  0.5
    1.0  1.0  0.0
    1.0  0.5  0.0
    1.0  0.0  0.0
    0.5  0.0  0.0    
    0.5  0.0  0.0
    1.0  0.0  0.0
    1.0  0.5  0.0
    1.0  1.0  0.0
    0.5  1.0  0.5
    0.0  1.0  1.0
    0.0  0.5  1.0
    0.0  0.0  1.0
    0.0  0.0  0.5
    0.0  0.0  0.0
    ];

% Now work out the indices into the map
N = size( colors, 1 );
idxIn = 1:N;
idxOut = linspace( 1, N, m );
cmap = [
    interp1( idxIn, colors(:,1), idxOut )
    interp1( idxIn, colors(:,2), idxOut )
    interp1( idxIn, colors(:,3), idxOut )
    ]';