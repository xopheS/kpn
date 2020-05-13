# Kahn Process Networks  (kpn)

:fire: **Implementations**
- Sequential (sequential.ml)
- Pipes (unix_pipes.ml)
- Network with thread (network.ml)

:fire: **Applications**
- Mandelbrot (mandelbrot.ml)
- k_Means (k_means.ml)
- Tic Tac Toe game (tictactoe.ml)

:fire: **Compile**

To compile a particular application run: 
  * `make mandelbrot`
  * `make k_means`
  * `make tictactoe`
  
To clean `make clean` or `make realclean`

## Mandelbrot:
The mandelbrot application can be run with arguments
(`arg default type`)

-   `-w 1300 int` Width of the window

-   `-h 1000 int` Height of the window

-   `-n 1000 int` Number of iterations

-   `-p 1 int` Number of processes for computation (must divide width)

-   `-xo -0.5 float` Real part of origin

-   `-yo 0. float` Imaginary part of origin

-   `-z 1. float` Zoom value (radius around origin)

-   `-r 4. float` Escape radius value

### Some views

-   `-xo -0.7463 -yo 0.1102 -z 0.005`

-   `-xo -0.7453 -yo 0.1127 -z 0.00065`

-   `-xo -0.16 -yo 1.0405 -z 0.026`

-   `-xo -0.925 -yo 0.266 -z 0.032`

-   `-xo -0.748 -yo 0.1 -z 0.0014`

-   `-xo -0.722 -yo 0.246 -z 0.019`

-   `-xo -0.235125 -yo 0.827215 -z 0.00004`

-   `-xo -0.81153120295763 -yo 0.20142958206181 -z 0.0003`

## K means:

`make k_means`

`./k_means.native 10` where 10 is the maximum number of processes used by the algorithm

## Tic tac Toe:
`make tictactoe`

`./tictactoe` (default window length,width = (1000,620) and board length,width = (600,600))

`./tictactoe -length_window x -width_window x -length x -width x` to change the default settings
