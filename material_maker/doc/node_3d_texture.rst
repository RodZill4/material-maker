3D textures
~~~~~~~~~~~

3D textures can be applied to objects defined by a heightmap, that can be generated
either as a regular greyscale image, or from a 3D scene defined using signed distance
functions.

In both cases, the **Apply** node is used to define 3D coordinates to query 3D textures,
and the **Select** node can be used to apply different 3D textures depending on a color
index.

.. toctree::
	:maxdepth: 1

	node_3d_texture_apply
	node_3d_texture_select
	node_3d_texture_from2d
	node_3d_texture_pattern
	node_3d_texture_fbm
	node_3d_texture_blend
	node_3d_texture_colorize
	node_3d_texture_rotate
	node_3d_texture_distort
