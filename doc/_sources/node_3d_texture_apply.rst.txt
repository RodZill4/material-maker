Apply node
~~~~~~~~~~

The **Apply** node applies a 3D texture on a surface defined by a heightmap. It can be used
to apply several different 3D textures accoding to a color index map.

.. image:: images/node_3d_texture_apply.png
	:align: center

Inputs
......

The **Apply** node accepts 3 inputs:

* the height map defined by a greyscale texture that defines the 3D surface
* the color index map defined by a greyscale texture that can be used to define which 3D texture should be applied for each pixel of the result
* the 3D texture (or several 3D textures using the **Select** node)

Outputs
.......

The **Apply** node generates a color image where the 3D textures are applied to the surface.

Parameters
..........

The **Apply** node does not accept parameters
