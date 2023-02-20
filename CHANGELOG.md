# Material Maker 1.2p1

# New features

- Added Unreal Engine 5 export targets that generate a Python script for UE5 to
  build automatically the generated material

# Bug Fixes

- Fixed a problem that caused the 3D preview to update incorrectly
- Fixed a problem in the Tones Map node that could cause incorrect shader code generation

# Material Maker 1.2

## General

- Added a dependency manager that handles all parameter changes, buffers and previews to
  avoid useless renders (myaaaaaaaaa helped hunting and fixing memory leaks on this).
- Material export has been updated:
  - custom export targets can now be added to predefined **Material** nodes,
  - a new **Export again** menu item has been added to repeat the last export operation.
- Unsaved projects are now rescued when Material Maker crashes and automatically reopened
  at startup.

## Nodes

- Shader nodes can now be variadic, i.e. have a number of parameters, inputs and outputs that
  are repeated. A new icon in the node titlebar shows the variadic aspect and can be used to
  increase or decrease the number of occurences of those parameters and ports.
  A few nodes have been updated accordingly, so **Blend** now supports several layers,
  **Transform** can apply to several channels and workflow nodes can mix more raw materials.
- A new **Normal to Height** node has been added.
- Parameters have been added to the **Image** node to keep the image's aspect ratio (contributed
  by myaaaaaaaaa).
- New colorspace related nodes have been added, such as **Colorspace Roundtrip** that
  make it possible to perform computations in other colorspaces (contributed
  by myaaaaaaaaa).
- The **Fast Blur** node now has high pass and sharpened outputs (contributed
  by myaaaaaaaaa).
- A snap operation has been added to **Math** nodes (contributed by williamchange).
- The **Blend** node now has additional modes: Linear Light, Vivid Light, Pin Light, Hard Mix
  and Exclusion (contributed by paddy-exe).
- The interpolation code has been improved in the 3D FBM node (contributed by Arnklit).
- The random color output of the **Triangle Voronoi** node, that did not always tile, depending
  on the scale parameters, has been fixed (contributed by williamchange).
- The **Dilate** node can now create (optionally) a non-tileable result.

## Miscellaneous

- An [experimental HTML5](https://www.materialmaker.org/public/mm_web/) version has been added.
  Although it has a lot of limitations, it is a good way of trying Material Maker without
  installing it.
- Self-connections of subgraphs are now allowed if they don't form a loop, and loop
  detection has been optimized (contributed by myaaaaaaaaa).
- The .mmg format (used for predefined nodes) has been modified to be more Version Control
  System friendly (contributed by myaaaaaaaaa).

## Fixes, optimizations

- Files are now removed from the recent projects list when they fail to load (contributed by Arnklit).
- The **Comment** node now selects correctly its children, regardless of the current zoom level (contributed
  by Zhibade).
- The alignment of inputs in the Uneven Bricks 2 node has been fixed (contributed by Arnklit).
- Command line exporting has been fixed (contributed by myaaaaaaaaa).

# Material Maker 1.1

## General

- Updated renderer to limit the size of rendering viewports (big textures are rendered in chunks and reassembled).
  This can be used to avoid crashes on lower end GPU and/or when generating high resolution textures. The maximum
  render size can be configured in the progress counter context menu.
- Added GPU memory information near the progress counter, with a tooltip that shows the GPU interface name (this
  can be used to know if Material Maker runs on the integrated graphics on a laptop).
- In Graph views, added support for arrow keys to scroll in all directions (useful when connecting nodes that
  are far from each other).
- Buffer nodes and nodes that contain buffers are now shown with a specific icon. Right clicking that icon
  show a context menu that can pause and resume the buffers (making it possible to disable useless rendering
  of parts of the material).
- The FPS counter, the GPU memory counter and the rendering progress bar have been moved to a status bar at
  the bottom of the user interface.
- Added a small icon in the status bar that shows the status of the clipboard (and if it can be pasted into
  a graph view).
- Started adding tips to the status bar.
- Added an option for Tonemaps in the 3D Preview panel.
- Added an option to overwrite existing material files (.tres for Godot engine, .mat and .meta for
  Unity engine) when re-exporting materials.
- Added Godot 4 export targets to all material types (contributed by Arnklit).

## Nodes

- Updated the EasySDF node with support for coloring (of albedo, roughness, metallic and emission channels)
  and node parameters, and added more shapes and operators.
- Added additional modes to **Math** node (contributed by williamchange).
- Updated the **Iteration Buffer** with an autostop parameter. When set, the Iteration Buffer will stop iterating
  as soon as 2 consecutive results are identical.
- Added a Fill port type that is used as output of the **Fill** node (and nodes that generate fill information)
  and input of the Fill companion nodes.
- Removed the Iterations parameter from the **Fill** node, and added parameters to remove the edges and adjust
  the generated bounding box.
- Added a new **Fill from colors** node that generates fill information from the color islands in its input.
- Updated the **Beehive** and **Voronoi** nodes to output Fill information instead of a random color.
- Added **Spiral Gradient** node (contributed by Theaninova).
- Added **Diagonal Weave** node (contributed by williamchange).
- Added **Triangle Voronoi** node (contributed by williamchange).
- Added **Sixteen Segment Display** and **Roman Numerals** nodes (contributed by williamchange).
- Added **Japanese Glyphs** node (contributed by williamchange).
- Added **Uneven Bricks 3**, **Uneven Bricks 4** and **Uneven Bricks 5** nodes (contributed by Arnklit).
- Added **Swirl** node.

## Miscellaneous

- Material Maker is now based on Godot 3.5.

## Fixes, optimizations

- Fixed crash that occurred when **Material** node was fed incorrect Depth values.
- Optimized curve parameter editor

# Material Maker 1.0

## General

- Added an option to automatically size new comment nodes to current selection (contributed by Zhibade)
- In the Reference panel, it is now possible to scan an average color by dragging the mouse cursor around
- When creating a new painting project, MM now checks the model can be painted (i.e. has a single surface and correct UVs)
- The configuration of 2D preview and graph editor panels is now saved
- Added support for gestures in 2D and 3D preview as well as painting panels
- Added a new Download button for translations in the Preferences dialog
- Pasting a list of HTML colors (in hex format) into the graph editor now creates a new Colorize node

## Nodes

- Added 3D SDF shapes, primitives and transforms to *EasySDF* node and corresponding editor
- Added *Seven Segment Display* node with variable length/width (contributed by williamchange)
- Added *Smooth Mix* (a mix-by-height node with smooth transition between materials) Worflow node
- Updated *Dilate* node to improve precision in higher resolutions (contributed by Arnklit and wojtekpil)
- Added new *Morphology* node that provides dilation and erosion operations
- Added *White Noise*, *Clouds Noise* and *Directional Noise* nodes (contributed by Arnklit)
- Added new *Make Tileable Square* node (contributed by Arnklit)
- Added *Slope* node, that generates slopes from the highest areas of a heightmap
- Added *AlterHSV* node that can be used to modify the Hue, Saturation and Value of its input using
  input maps
- Added new *Mesh* node (contributed by Arnklit)
- Updated *Normal Map* node to improve precision when the buffer option is used
- Added new Additive and AddSub modes to the *Blend* node (contributed by Arnklit)
- Added new packing/unpacking nodes that can store 1 (or 2) values into 2 (or 4) when using buffers
  for better precision (contributed by Arnklit and wojtekpil)
- Added a flip parameter to the *Mirror* node:w

## Miscellaneous

- MacOS port is now signed and notarized
- Material Maker is now based on Godot 3.4.4

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
