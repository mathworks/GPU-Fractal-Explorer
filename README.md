# GPU Fractal Explorer

*View and investigate various fractals using MATLAB and an NVIDIA GPU*

This application allows you to explore several different fractals in MATLAB with the help of a capable NVIDIA GPU. It was inspired by Cleve Moler's article <a href="https://www.mathworks.com/company/newsletters/articles/gpu-enables-obsession-with-fractals.html">GPU Enables Obsession with Fractals</a>, where each fractal has the common pattern that every location (i.e. pixel in the resulting image) can be calculated independently. This makes them trivially parallel and eminently suitable for acceleration on the GPU using the <a href="https://www.mathworks.com/help/parallel-computing/gpuarray.arrayfun.html">gpuArray/arrayfun</a> feature. 

The following fractals are included:

1. Burning Ship:  Mandelbrot-like iteration with update function (|Re(z)|+i|Im(z)|)^2
2. Mandelbrot:  The classic Mandelbrot set
3. Mandelbar:  A Mandelbrot variant using a conjugating update
4. Mandelbrot 11:  A Mandelbrot variant using ^11 instead of ^2.
5. Newton's Method (cubic):  Iterations to convergence of Newton's method for the function x.^3 - 2.*x - 5
6. Newton's Method (trig):  Iterations to convergence of Newton's method for the function tan(sin(x)) - sin(tan(x))
7. Tower of Powers:  Cycle count for y(k+1) = z^y(k)

This app is provided purely for your entertainment, but has the following features:

* Use the normal MATLAB zoom and pan to browse each fractal
* Quickly switch between fractals
* Sit back and watch the app pan and zoom between pre-stored locations for each fractal
* Add your own locations to the animation lists

You might also be interested in my other GPU fractal apps:

* <a href="https://www.mathworks.com/matlabcentral/fileexchange/30988-a-gpu-mandelbrot-set">A GPU Mandelbrot Set</a>
* <a href="https://www.mathworks.com/matlabcentral/fileexchange/33201-gpu-julia-set-explorer">GPU Julia Set Explorer</a>
