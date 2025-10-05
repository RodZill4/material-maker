# Material Maker 1.4

## Bug Fixes

- Fixed a problem when resizing the reroute node
- Fixed a problem when saving textures for dynamic materials export
- Fixed a missing icon in comment node in Classic theme
- Fixed support for bevel and mortar inputs in Custom Tile node

# Material Maker 1.4RC6

## General

- Updated X icon, added Bluesky and Mastodon in About dialog
- Updated contributors and patreons lists in About dialog

## Nodes

- Added support for #count in variadic nodes

## Bug Fixes

- Fixed recents not updating when loading from menu (contributed by williamchange)
- Fixed ExportMenu not shown on custom model drop (contributed by williamchange)
- Fixed redundant extension when exporting mesh map (contributed by williamchange)
- Fixed incorrect render index in counter (contributed by williamchange)
- Fixed reroute showing previous linked node on undo (contributed by williamchange)
- Fixed tooltip shown when mouse is away from slot (contributed by williamchange)
- Fixed reroute rect by hiding titlebar_hbox label (contributed by williamchange)
- Fixed hierarchy tree if MM started without panel (contributed by williamchange)
- Fixed $idx not working in export (contributed by williamchange)
- Fixed undo/redo for remote/ios nodes (contributed by williamchange)
- Fixed theme icon loading in editor (contributed by williamchange)
- Fixed 3D preview for dynamic materials
- Fixed shader generation in Debug node for texture uniforms

# Material Maker 1.4RC5

## Bug Fixes

- Fixed a bug that caused recents not to be added when a .ptex file is dropped (contributed by williamchange)
- Fixed lattice grid not updating when the slice count is updated (contributed by williamchange)
- Fixed SplinesView drawn area offset on start (contributed by williamchange)
- Fixed splines handle lines not drawing (contributed by williamchange)
- Fixed typo for transform node's mode tooltip (contributed by williamchange)
- Updated mode doc for transform node (contributed by williamchange)
- Fixed tones cursor outline not updating on undo (contributed by williamchange)
- Missing check for comment line in quick connection (contributed by williamchange)
- Fix reroute pos y offset when adding from port (contributed by williamchange)
- Fix filepath format not updating in 3d map export (contributed by williamchange)
- Fixed crash that occured when deleting an iterate buffer
- Relaxed render status condition when exporting materials
- Removed disable render option
- Documentation fixes (contributed by williamchange)

# Material Maker 1.4RC4

## General

- Don't show export menu for 3d preview on start (contributed by williamchange)

## Nodes

- Fixed dynamic pbr preview shader (contributed by williamchange)
- Fixed dynamic materials export for Godot 4 (contributed by Paulo Poiati)

## Bug Fixes

- Fix global menu translation for macOS (contributed by williamchange)
- Fix comment nodes not undoing position (contributed by williamchange)
- Fixed environment preview not showing reflection (contributed by williamchange)
- Fixed environment thumbnail generation (contributed by williamchange)
- Fixed window jump when maximizing from splash (contributed by williamchange)
- Fix connected signals errors when dragging panels (contributed by williamchange)
- Add null check in set_current_environment (contributed by williamchange)
- Fixed histogram with buffer inputs bug
- Fixed problem that caused the iterate buffer to stop updating

# Material Maker 1.4RC3

## General

- Improved idle FPS tooltip in preferences (contributed by williamchange)
- Removed library tree tooltips (contributed by williamchange)
- Removed www. from splashscreen URL (contributed by williamchange)
- Added hint for unload submenu when no custom library is loaded (contributed by williamchange)
- Made website spelling consistent in tooltips (contributed by williamchange)

## Nodes

- Added library icons for Decompose and Combine (contributed by williamchange)
- Added missing short/long desc. for material nodes (contributed by williamchange)
- Added icon for Mesh Map node (contributed by williamchange)
- Added several aliases (contributed by williamchange)
- Improved reroute ports drawing (contributed by williamchange)

## Bug Fixes

- Fixed duplicate with links shortcut (contributed by williamchange)
- Fixed duplicated "Help" menu for macOS (contributed by williamchange)
- Fixed comment node not dragging enclosed nodes (contributed by williamchange)
- Fixed environment upload (contributed by williamchange)
- Fixed saved preview mesh uv scale not applying (contributed by williamchange)
- Fixed center view not accounting for zoom level (contributed by williamchange)
- Fixed text/code edit white pixels corners when focused (contributed by williamchange)
- Fixed comment node not dragging comment line node (contributed by williamchange)
- Fixed create/web node not spawning at graph center (contributed by williamchange)
- Fixed crash when adding website nodes from library (contributed by williamchange)
- Fixed custom icon visibility on edited nodes (contributed by williamchange)
- Fixed restoring animation export size (contributed by williamchange)
- Fixed Preview3D material not updating (contributed by williamchange)
- Fixed node title color unchanged when edited (contributed by williamchange)
- Fixed for C key menu item shortcut for macOS (contributed by williamchange)
- Fixed simplex noise seed offset (contributed by williamchange)
- Fixed hidpi display panel undock position (contributed by williamchange)
- Fixed various non-critical errors and warnings (contributed by williamchange)

# Material Maker 1.4RC2

## General

- Preview3D mesh UV scale is now saved in settings (contributed by williamchange)
- Removed RZLogo TextureRect in about.tscn (contributed by williamchange)

## Nodes

- Fixed noise node banding artifacts

## Bug Fixes

- Fixed connections shown in front of nodes (contributed by williamchange)
- Fixed render counter context menu position (contributed by williamchange)
- Fixed missing top-level label in hierarchy panel (contributed by williamchange)
- Fixed small default window size on hidpi displays (contributed by williamchange)
- Fixed unlit material doc on inputs (contributed by williamchange)
- Fixed hierarchy panel previews (contributed by williamchange)
- Fixed reroute context menu (contributed by williamchange)
- Fixed a problem that caused buffers and materials not to updating correctly
- Fixed add node filter context pos on hidpi displays (contributed by williamchange)
- Fixed add node popup size not updating correctly (contributed by williamchange)
- Fixed preview3d that did not immediately apply 3D scale (contributed by williamchange)
- Fixed comment color popup scale and position on hidpi display (contributed by williamchange)
- Fixed propagating node changes (contributed by williamchange)
- Fixed CodeEditor errors (contributed by williamchange)
- Fixed crash that occurred when hovering param linked to minimized nodes (contributed by williamchange)
- Fixed ShowTree button size when entering subgraph (contributed by williamchange)
- Added missing parameter types in shader nodes documentation (contributed by williamchange)
- Added image check when exporting materials
- Fixed Font problem on Text node
- Fixed layout on multicolumn nodes
- Fixed comment node documentation and images (contributed by williamchange)
- Various code format and warning fixes (contributed by williamchange)
- Fixed scale factor for flexible layout subwindows
- Fixed growing export menu problem on Mac

# Material Maker 1.4RC1

## General

- Fixed shader exports for Unity and Unreal engines (HLSL generation for array uniforms)

## Nodes

- Fixed FBM noise and kaleidoscope nodes compatibility (contributed by williamchange)
- Fixed switch node input tooltips (contributed by williamchange)
- Fixed classic reroute (contributed by williamchange)

## Bug Fixes

- Fixed a problem that caused the menu to update repeatedly when moving a node
- Adjusted File Dialog minimum size (contributed by williamchange)
- Made load from website dialog exclusive (contributed by williamchange)
- Fixed comment line node min size not updating (contributed by williamchange)
- Fixed hdri download error dialog scale on hidpi displays (contributed by williamchange)
- Removed Ctrl+R shortcut for 2D/3D buttons (contributed by williamchange)
- Fixed SDF builder param size not updating (contributed by williamchange)
- Fixed and updated tip text mouse icons (contributed by williamchange)
- Fixed float edit drag focus bug (contributed by DevFika)
- Removed Show/Hide side panels menu item
- Small fixes in Splines editor

# Material Maker 1.4b3

## General

- Added Graph view preferences for connection styles (contributed by williamchange)
- Updated graph zoom level UI
- Added X shortcut to delete selected nodes (contributed by williamchange)
- Added duplicate with inputs (Control+Shift+D) command (contributed by williamchange)

## Nodes

- Added Comment Line node (contributed by williamchange)
- Made float edit control smaller (contributed by Jowan-Spooner)

## Bug Fixes

- Fixed comments behavior when moving through hierarchy
- Show webpage when clicking website url on splashscreen
- Fixed export node
- Fixed SDF editor problem with polygon parameters
- Fixed generated cylinder tangents
- Fixed generic node layout
- Many fixes in EasySDF editor (renaming, hide button, many 3D primitives)
- Fixed dialog placement under Linux (contributed by williamchange)
- Fixed scroll to item buttons in Library panel (contributed by williamchange)
- Fixed 2D preview reset tooltip (contributed by williamchange)
- Fixed environment list size (contributed by williamchange)
- Fixed camera controller reset (contributed by williamchange)
- Fixed crash that occurred when loading a mesh without UVs (contributed by williamchange)
- Fixes in Add Node popup (contributed by williamchange)
- Fixes in About dialog (contributed by williamchange)
- Made tip text translatable (contributed by williamchange)
- Fixes in light theme (contributed by williamchange)
- Miscellaneous UI fixes (contributed by williamchange)

# Material Maker 1.4b2

## General

- Animation export parameters are now saved (contributed by williamchange)
- Added a keyboard shortcut (H) to minimize nodes (contributed by williamchange)
- Updated gradient color picker to focus hex field when shown (contributed by williamchange)
- Added a shortcut (Control+,) for the Preferences dialog (contributed by williamchange)
- Added a limit of 5 custom models shown in the list in Preview 3D UI
- Improved DMG generation for macos (contributed by williamchange)

## Nodes

- Made RGBA transform nodes variadic (contributed by williamchange)
- Allow dragging curve parameter to tonality node (contributed by williamchange)
- Fixed artifacts in FBM nodes (contributed by williamchange)
- Fixes missing nodes descriptions (contributed by williamchange)
- Fixes typos in node labels (contributed by williamchange)
- Updated math aliases with new operators (contributed by williamchange)
- Improved Splines parameter editor (contributed by NotArme)
- Improved node labels alignment
- Added a Unity URP lit export target for static material types (contributed by williamchange)
- Fixed kaleidoscope variations (contributed by williamchange)
- Added axis parameters to Extrude/Revolution nodes (contributed by williamchange)
- Added more primitives to the EasySDF editor (contributed by williamchange)

## Bug Fixes

- Fixed tonemap/exposure fields not showing when environment is set (contributed by williamchange)
- Fixes in export editor
- Fixed EXR file format support
- Fixed documentation access from Material Maker (contributed by NotArme)
- Fixes in environment editor (contributed by wojtekpil)
- Fixes in the About dialog (contributed by williamchange)
- Fixed the curve preset icons (contributed by williamchange)
- Fixed aliasing problem in TEX3D preview (contributed by williamchange)
- Fixed division-by-zero errorrs in SDF3D preview (contributed by williamchange)
- Fixed Alt-drag on editors for fine-tuning float values (contributed by williamchange)
- Made the license uneditable in the About dialog (contributed by williamchange)
- Fixed weird presets of Shape node (contributed by williamchange)
- Documentation fixes and updates (contributed by NotArme and williamchange)
- Fixed graph screenshot feature
- Fixed Unity HDRP export target (contributed by williamchange)
- Fixed the scale of dialogs for hi-dpi displays (contributed by williamchange)
- Fixed the HDRI download dialog title (contributed by williamchange)
- Fixed environment panel minimum size (contributed by williamchange)

# Material Maker 1.4b1

## General

- Added AgX tonemapper and tonemap exposure and white parameters in the 3D preview (contributed by williamchange)

## Nodes

- Added a Custom Tiles node that can accepts the shape of a tile as SDF input
- Added a Fill Select node that can select a single area in a Fill result
- Fixed the smooth curvature node by increasing blur quality
- Fixed Japanese Glyphs nodes
- Updated the reroute node's color so it's more visible

## Bug Fixes

- Fixed single click edit of float parameter edit control (contributed by wojtekpil)
- Fixed icons problem in undocked panels
- Added missing file options in export editor
- Fixed shadertoy shader export for polygon/polyline parameters
- Fixed texture filtering and repeat problems
- Fixed status bar tip on 3D preview
- Fixed comment highlighting in code editor
- Fixed message when closing with unsaved projects (contributed by williamchange)
- Small fix for the meteor rain splash screen (contributed by williamchange)
- Fixed preview export for non-image types
- Fixed spline edit dialog
- Fixed Preference window, that vanished when trying to download languages
- Show locale as english if it's not found

## Miscellaneous

- Material Maker is now based on Godot 4.4.1
- Updated documentation to include Blender export (contributed by williamchange)

# Material Maker 1.4a3

## General

- The 3D preview panel has been completely redesigned (contributed by Jowan-Spooner)
- The Create Library dialog has been updated (contributed by NotArme)
- When uploading materials, it is now possible to select the preview
- Camera controls are now consistent in all 3D views

## Nodes

- The default nodes library now has more consistent node names (contributed by NotArme)
- The wavelet node now loops correctly (contributed by NotArme)
- The Pixelize node now has support for Bayer matrix dithering
- The Japanese Glyphs node now has a normalized bevel range (contributed by williamchange)

## Bug Fixes

- Fixed a few bugs in shader generation
- Fixed problems in the EasySDF node and editor
- Fixed greyscale images export
- Fixed export of images with transparency (contributed by karmaral)
- Fixed problem with saving environments
- When saving, errors will now be showed to the user in an alert window (contributed by NotArme)
- Messages in the status bar have been improved (contributed by NotArme)
- Fixed window scaling problems with high DPI screens
- Fixes in several Bricks nodes and Tones node
- Fixes in the Generalized Kuwahara node (contributed by williamchange)

## Miscellaneous

- Material Maker is now based on Godot 4.4
- The MacOS disk image background has been improved (contributed by williamchange)

# Material Maker 1.4a2

## General

- The Add Nodes popup has been improved (contributed by Jowan-Spooner)
- The 2D preview and References panels have been redesigned (contributed by Jowan-Spooner)
- Themes have been improved (contributed by Jowan-Spooner)
- Default layouts have been added for material authoring and painting
  modes (contributed by Jowan-Spooner)
- Added new splash screens (Crown Gambit, DroppedBeat)

## Nodes

- Updated the Roman Numerals node (now supports values upto 3999 and
  has an align parameter)
- Rewrote the comment node
- Added Reverse, Evenly Distribute and Simplify tools to the Gradient editor
  widget (contributed by Jowan-Spooner)

## Bug Fixes

- Started fixing material exports (Godot and static materials for Unreal)
- Fixed user libraries problem (contributed by NotArme)
- Fixed splashscreen position with multiple screens (contributed by NotArme)
- Fixed problems in environment editor
- Fixed popup menu locations

## Miscellaneous

- Material Maker is now based on Godot 4.4dev7

# Material Maker 1.4a1

## Known problems

- User settings are saved in a different directory (so using 1.4 alphas should not
  affect your 1.3 configuration)
- Subwindows are not scaled correctly if the UI scale is not 1

## General

- Added flexible UI layout: panels can be moved anywhere in the window or
  undocked (Material authoring and Painting have different layouts)
- Improved theme support (especially made many custom UI components themeable),
  added a new Modern theme and improved old themes (contributed by Jowan-Spooner)
- Added basic support for GLTF 3D models
- Dropping a .obj or .glb file into the 3D preview panel will use it as preview model
- In the 3D preview replaced the default cube mesh with a chamfered cube and the
  plane with a bent plane (chamfer and curvature can be modified in the mesh
  configuration popup)
- Improved the Add Node popup so it's themeable, more performant and has better search
  capabilities (contributed by Jowan-Spooner)
- Improved the Library panel's design (contributed by Jowan-Spooner)
- Added an editor for polygon parameters in the 2D preview
- Added a shader error diagnostic tool
- Added easy stylus pressure configuration in painting tool
- Added a Find/Replace tool to code editor
- Added an option to delete rescued unsaved projects at startup
- Added support for hover copy+paste on float, color and gradient editors

## Nodes

- Added a MeshMap node that automatically bakes maps (position, normal, tangent,
  curvature, occlusion or thickness) for the current custom mesh.
- Added many new 2D and 3D SDF nodes (contributed by Theaninova and williamchange)
- Added new operations to the Math and Vec3 Math nodes (contributed by williamchange)
- Added a Shard FBM noise node (contributed by williamchange)
- Added a Tex3D Uniform node (contributed by williamchange)
- Added Classic, Generalized and Anisotropic Kuwahara filter nodes (contributed by williamchange)
- Redesigned the Float and Gradient parameter editor widgets (contributed by Jowan-Spooner)
- Improved the image picker UI (contributed by Jowan-Spooner)
- Added a new Splines parameter type (that can be edited in the 2D preview directly)
  and a new Splines node
- Added a new Pixels parameter type, that can describe tiny images with 2, 4, 8 or 16 colors,
  and can be edited in the 2D preview directly. Added new Pixels and Smooth Pixels nodes
- Added a new Lattice parameter type and a new Distort node
- Added a new Webcam node that can output a Webcam feed (MacOS only)
- Added a density input to the Noise node
- The 2D and 3D SDF Boolean and Transform nodes, the 3D SDF Color node and the
  Tex3D Transform, Blend Select and Shape Select nodes are now variadic (contributed by williamchange)
- The Blend node now has Hue, Saturation, Color and Value blend modes (contributed
  by williamchange)
- The Spherize node has been improved (contributed by williamchange)
- Updated documentation for many nodes (contributed by williamchange)

## Bug Fixes

- Small fixes in the GLSL parser
- Optimized polygon/polyline parameter

## Miscellaneous

- Material Maker is now based on Godot 4.3. While porting to Godot 4, many features
  have been rewritten completely, including shader code generation and shader rendering
- The MacOS export has been modified so Material Maker can be installed
  easily (contributed by williamchange)

# Material Maker 1.3

## General

- Updated interface to the website to login and upload assets without the need
  of a web browser
- Added custom nodes sharing on the website (connect to the website and right
  click a custom node to share it)
- Added support for the $rndi (that returns a random integer value) parameter
  expression function (contributed by Arnklit)
- Added an option in the 2D Preview panel to export non square textures

## Nodes

- Added a Random Weave node (contributed by Arnklit)
- Added variations controls to all SDF repeat (2D and 3D, grid and circle)
  nodes (contributed by Arnklit)
- Updated the Normal Blend node to make it variadic (contributed by Arnklit)
- Added Cairo tiles node
- Added a Spherize node (contributed by williamchange)

## Bug Fixes

- Fixed an update problem in the Iterate Buffer node
- Fixed a NaN problem in the sdArc node (contributed by myaaaaaaaaa)
- Fixed a problem where the recovery file was not deleted when closing a tab
- Fixed an export problem in the Painting tool
- Fixed a problem with the Fill nodes where areas could leak though corners

## Miscellaneous

- Material Maker is now based on Godot 3.5.2

# Material Maker 1.2p1

## New features

- Added Unreal Engine 5 export targets that generate a Python script for UE5 to
  build automatically the generated material (it's necessary to setup a path for
  Python in UE, this is described in the documentation)

## Bug Fixes

- Fixed several small problems in the Export Editor window
- Fixed a problem that caused the 3D preview to update incorrectly
- Fixed a problem in the Tones Map node that could cause incorrect shader code generation
- Fixed a problem in the animation export tool that occurred when exporting graphs with buffers
- Fixed Histogram panel (not updating correctly) and improved histogram rendering
- Updated the Math nodes to improve parameters consistency (contributed by williamchange)
- Fixed a bug that caused Material Maker to crash when entering an expression as parameter in the Text node

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
