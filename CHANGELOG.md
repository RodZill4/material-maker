# Material Maker 1.0

## General

- Added an option to automatically size new comment nodes to current selection (contributed by Zhibade)
- In the Reference panel, it is now possible to scan an average color by dragging the mouse cursor around

## Nodes
- Added *Seven Segment Display* node with variable length/width (contributed by williamchange)
- Added *Smooth Mix* (a mix-by-height node with smooth transition between materials) Worflow node
- Updated *Dilate* node to improve precision in higher resolutions (contributed by Arnklit and wojtekpil)
- Added new *Morphology* node that provides dilation and erosion operations
- Added *Clouds Noise* and *Directional Noise* nodes (contributed by Arnklit)
- Added new *Make Tileable Square* node (contributed by Arnklit)
- Added *Slope* node, that generates slopes from the highest areas of a heightmap
- Added *AlterHSV* node that can be used to modify the Hue, Saturation and Value of its input using
  input maps 
- Updated *Normal Map* node to improve precision when the buffer option is used
- Added new packing/unpacking nodes that can store 1 (or 2) values into 2 (or 4) when using buffers
  for better precision (contributed by Arnklit and wojtekpil)

# Material Maker 0.99

## General

- The 3D preview had several improvements including better parallax mapping quality,
  debanding applied by default and better control of scale factor to avoid decreased
  rendering quality (contributed by Calinou)
- Environments can now be downloaded from and uploaded to the website

## 3D model painting

- Brushes now have default jitter parameters (position, angle, size and opacity)
- Painting on seams has been improved

## Nodes

- Added an EasySDF node that can be used to describe complex SDF shapes with a dedicated editor
- The Tesselated Material type has been fixed and renamed to Static PBR Displacement (contributed by Arnklit)
- Tiler and Splatter nodes now have a new custom UV output (contributed by Arnklit)
- Non uniform scale nodes have been added for 2D and 3D SDF (contributed by Paulo Falcao)
- Circle splatter nodes now have support for variations (contributed by Arnklit)
- A new Fill to Gradient node has been added (contributed by Arnklit)
- A new color conversion node (that between linear and sRBG) has been added (contributed by Arnklit)
- A new 3D SDF FBM node that adds FBM noise on top of an existing SDF shape has been added (contributed by Arnklit, based on an article by Inigo Quilez)

# Material Maker 0.98

## General

- Undo/Redo has been implemented in Material graph projects, and stroke Undo/Redo is available in Painting projects
- In the *2D preview* panel, 4 display modes are available: tile, extend, clamp and temporal antialiasing
- The *2D preview* panel now has postprocessing filters for pixel art generation (that show the generated texture in low res size)
- Holding the *Control* key while dragging parameter controls in the 2D preview will now snap them to the grid (if any)

## Material creation

- Nodes are now colored based on their category in the library (contributed by Arnklit)
- The *Add Node* menu now has configurable buttons to quickly add frequently used nodes
- New *Reroute* nodes can now be used for long connections or to organize graphs (contributed by Arnklit)
- Double clicking a subgraph node when editing a material graph will now enter it
- Many UI problems including bad widget alignmentd have been fixed (contributed by Arnklit)
- When adding materials to the website, Material Maker now generates better looking previews
- Directionality problems have been fixed in Ambient Occlusion and Thickness maps baking (contributed by wojtekpil)
- Pasting an HTML color code into a graph will create a *Uniform* node (contributed by vreon)

## 3D model painting

- A new texture space painting engine has been added
- The painting tool has a new *color picker* button that can be used to get colors and values from all channels of the painted object. The values are assigned to the current brush if it has parameters for those channels.
- Normal maps can now be painted directly or generated from painted depth or both
- A new a *Paint Project Settings* dialog has been added. It replaces the huge submenu in the Tools menu
- A new *Stamp* tool has been added. To use it, press the mouse button to place the center of the stamp, then drag around to define the size and angle
- An implicit mask has been added to painting and it can be configured from an ID map using the new *Mask Selector* tool 
- The brush parameters panel has been updated to show channel filter parameters in a more intuitive way
- Parameters expressions can now use new *tilt* (stylus angle), and *stroke_seed* (a random number that is rerolled for each stroke) predefined variables
- The base brush library has been reorganized, many brushes have been improved and a few brushes have been added

## Nodes

- A new *Colormap* node, that colors a greyscale image from a colormap image has been added (contributed by vreon)
- New *Bevel*, *Binary smooth*, *Crystal*, *Dirt noise*, *Randomize*, *Smooth min/max*, *Uneven Bricks 2* nodes have been added (contributed by Arnklit)
- A New *HBAO* node has been added (contributed by wojtekpil)
- New *Wavelet noise*, *Palettize* nodes have been added
- A new *Tesselation* material type is available where the depath channel is used as displacement. Please make sure to enable tesselation in the 3D preview panel when using it (contributed by Arnklit)
- The *Warp Dilation* node has been updated and now accepts an angle parameter instead of the mode
- The *Bricks* node has been updated with new patterns and *Fill* compatible outputs (contributed by Arnklit)
- The *FBM* node has been updated with a new *Voronoise* mode and a new *Offset* parameter (contributed by Arnklit)
- The *Directional Blur* node has a new mode selector (contributed by Arnklit)
- The *Custom UV* and *Kaleidoscope* nodes now support variations (contributed by vreon)
- The *Math* node now has a new smoothstep operation (contributed by Arnklit)
- The *Variations* nodes now have seed parameters for all outputs
- *Comment* nodes have been redesigned (contributed by Arnklit)
- The *Iterate buffer* node now supports expressions for its *iterations* parameter

## Miscellaneous

- Material Maker is now based on Godot 3.4
