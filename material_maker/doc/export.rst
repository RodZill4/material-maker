.. _export-section:

Exporting Materials
===================

When exporting a material, using either the Export submenu or the command line arguments,
Material Maker generates PNG image files for all elements of the material as well as
specific files for the target game engine.

In all cases, the generated PNG files (and especially the normal map) is generated in the
correct format.

Godot game engine
-----------------

When exporting for the Godot game engine, Material Maker will generate a .tres file that
describes a fully configured SpatialMaterial.

Note that exporting for Godot is not necessary if you use the Material maker addon, that
provides an import plugin. This import plugin can either generate a precomputed material,
or a material that will be rendered at runtime.

Unity game engine
-----------------

When exporting for the Unity game engine, Material Maker will generate a .mat file that
describes a fully configured material. It is thus possible to export materials directly
into one of your project assets directory, and Unity will automatically detect the newly
exported materials.

Unreal game engine
------------------

When exporting for the Unreal game engine, Material Maker will only generate PNG image
files, and it is necessary to create the material in Unreal.

To create a minimal material:

* import all PNG files into unreal
* create a new material using the **Add new -> Material** menu
* open the new material to edit it
* drag and drop all textures into the material graph to create a Texture Sample node
  for each texture
* connect the RGB output of the albedo *Texture Sample* node to the *Base Color* input
  of the material node
* connect the R output of the ORM *Texture Sample* node to the *Ambient Occlusion* input
  of the material node
* connect the G output of the ORM *Texture Sample* node to the *Roughness* input
  of the material node
* connect the B output of the ORM *Texture Sample* node to the *Metallic* input
  of the material node
* connect the RGB output of the normal *Texture Sample* node to the *Normal* input
  of the material node

More complex materials with support for emission textures, depth maps, texture
coordinate scaling...

.. image:: images/unreal_export.png
  :align: center
