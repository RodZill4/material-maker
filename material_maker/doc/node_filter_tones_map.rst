Tones Map node
~~~~~~~~~~~~~~

The **Tones Map** node remaps the image, given input and output tone intervals.
This node will not affect the alpha channel of the image. If necessary, the remap
operation is extrapolated linearly beyond the specified intervals.

.. image:: images/node_filter_tones_map.png
	:align: center

Inputs
++++++

The **Tones Map** node requires an RGBA input texture.

Outputs
+++++++

The **Tones Map** node provides a single RGBA texture.

Parameters
++++++++++

The **Tones Map** node accepts 4 parameters:

* the minimum and maximum input tones

* the minimum and maximum output tones