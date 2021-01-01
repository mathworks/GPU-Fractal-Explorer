function cmap = pinkbone(m)
% Combination of pink and bone colormaps

%   Copyright 2019 The Mathworks, Inc.

if nargin < 1
   f = get(groot,'CurrentFigure');
   if isempty(f)
      m = size(get(groot,'DefaultFigureColormap'),1);
   else
      m = size(f.Colormap,1);
   end
end
n = ceil(m/2);
cmap = [bone(n);flipud(pink(n))];
