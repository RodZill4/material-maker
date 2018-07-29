This is an addon for the Godot game engine that can be used to create texture procedurally.

Its user interface is based on Godot's GraphEditor: textures are described as interconnected texture generators and operators.

![Screenshot](doc/screenshot.png)

## Generators

### Image

This operator reads a bitmap from disk

### Sine

This generator creates sine wave based vertical bars.
It will soon be replaced with a more flexible generator (similar to the PatternFunction in NeoTextureEdit)

Its parameters are the number of bars and a multiplier applied to the sine wave (higher values will make the bars sharper).

![Sine pattern](doc/sine.png)

### Bricks

This generator creates bricks greyscale patterns.

The Bricks generator has 5 parameters:
* the number of brick rows
* the number of bricks per row
* the offset between even and odd rows
* the mortar space between bricks
* the bevel at the edge of the bricks

![Bricks pattern](doc/bricks.png)

### Perlin Noise

The Perlin Noise generator creates a greyscale pattern and has 4 parameters:
* the horizontal and vertical scale of the first iteration
* the number of iteration
* the persistence (the weight ratio between 2 iterations)

![Perlin Noise](doc/perlin.png)

### Voronoi Noise

The Voronoi Noise generator creates greyscale patterns based on Voronoi diagrams and has 3 parameters:
* the horizontal and vertical scale (the number of feature points)
* the "intensity" of the noise (used to adjust the generated color)

![Voronoi Noise](doc/voronoi.png)
