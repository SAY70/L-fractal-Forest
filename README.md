# L-fractal-Forest

MATLAB code for building 3-D fractal (recursively branching) tree stands and finding which branch elements fall inside the field of view of an upward-looking receiver placed below the canopy.

## Files

| File | What it does |
|------|--------------|
| `tree_obj.m` | Class for a single cylindrical branch: tail/head position, length, orientation angles and trunk/branch dielectric values. `gen_branches` recursively grows four child branches per node (each shortened by the persistence factor and rotated about x or y) until branch length falls below the threshold. `shinozaki_pipe` assigns branch diameters using the Shinozaki pipe model. |
| `Rand_fract_forest.m` | Main script. Places a 10 × 7 set of trees at random positions, plots the stand, highlights branch centres inside a 40° view cone of a receiver at (1.5, 0.5, 0.1) m, plots a branch-length histogram and computes branch azimuth and elevation angles. |
| `test_for_more_branch.m` | Test script on a regular 3 × 3 grid of trees that sorts branches into primary, secondary and unused classes by length relative to the threshold. |
| `Moving_Antenna.m` | Standalone test: a receiver moving in the x–y plane over randomly placed particles, counting the particles inside its 30° view cone at each time step. |

## Getting started

Requires MATLAB R2017b or newer (the code uses `classdef`, `vecnorm` and `rescale`).

1. Clone or download this repository and open the folder in MATLAB, so that `tree_obj.m` is on the path.
2. Run the main script:

   ```matlab
   Rand_fract_forest
   ```

3. Change the growth parameters (`pers`, `thrsh`, `ang`), the stand size (`n_rows`, `n_cols`, `x_range`, `y_range`) or the receiver position and view angle near the top of the script.

Tree positions and branch angles are drawn with `rand`, so each run gives a different stand; call `rng(seed)` first if you need repeatable results.
