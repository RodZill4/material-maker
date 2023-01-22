Command line arguments
======================

When launched with no command line argument, Material Maker will start with an empty project.

When launched with the path of a .ptex file as command line argument, Material Maker will
start with this project file. Material Maker can thus be associated to files with .ptex
extension so double-clicking on them will directly open them.

Material Maker can also be used to export several .ptex file with the following command line:

 material_maker --export-material --target <engine> -o <output_path> <input_files>

Where:

* **engine** is the target engine (Godot, Unity or Unreal)
* **output_path** is the path where files will be generated
* **input_files** is the list of input files (wildcards are accepted)
