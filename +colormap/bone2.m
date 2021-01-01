function cmap = bone2(m)
% Bone colormap with added fade to black

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
cmap = (7*gray(n) + fliplr(hot(n)))/8;
% Now flip and add
cmap = [cmap;flipud(cmap)];
