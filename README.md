Scripts for GIMP

# turing-pattern.scm

[Turing pattern](https://en.wikipedia.org/wiki/Turing_pattern) generator script for GIMP based on the following recipe by [Nobu Design](https://www.youtube.com/watch?v=NZNl6N7PnF4).

**NOTE**: this script relies on Rob Antonishen's high-pass script (cf [this post on his blog](https://www.silent9.com/blog/archives/152-High-Pass-Filter-Plugin.html) and [this entry on gimper.net](https://gimper.net/resources/high-pass-filter.352/)). This script must then be installed for the turing pattern script to work.

## controls

- repeats: number of iterations (the patterns emerge from a cyclic process).
  Normally, the default value (10) should be fine and doing more iterations
  won't change things much. This control is still given in the case some future
  modifications of the script may make it relevant.

- diffusion: the radius of the blur used in the cyclic process giving rise the
  patterns. This parameter is called diffusion because it plays the same role
  diffusion in the chemical models where Turing patterns usually arise.
