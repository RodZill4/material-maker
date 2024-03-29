Normal convert node
~~~~~~~~~~~~~~~~~~~

The **Normal convert** node converts a normal map from its input. It can:

- either convert from DirectX or OpenGL format to Material Maker's internal
  format, which is useful when importing normal maps generated by other tools
- or convert from Material Maker's internal format to DirectX or OpenGL, which
  is useful to export normal maps without using Material nodes (note that
  Material nodes only accept "yellowish" internal format, and will generate
  incorrect normal maps when previewing or exporting if their input is a
  DirectX or OpenGL normal map)

.. image:: images/node_filter_normal_map_convert.png
	:align: center

Inputs
++++++

The **Normal convert** node accepts a single color normal map as input, either in
Material Maker's internal format or in OpenGL or DirectX format.

Outputs
+++++++

The **Normal convert** node outputs the normal map in another format.

Parameters
++++++++++

The **Normal convert** node accepts as parameter the format from/to
which the normal map must be converted.
