Tonality node
~~~~~~~~~~~~~

The **Tonality** node is variadic and applies a user-defined curve to greyscale images.

.. image:: images/node_filter_tonality.png
	:align: center

Inputs
++++++

The **Tonality** node accepts one or more greyscale input textures.

Outputs
+++++++

The **Tonality** node outputs greyscale textures.

Parameters
++++++++++

The **Tonality** node has a single parameter that defines the tonality curve to be applied to
the input image.

Notes
+++++

The input will be considered (and implicitly converted to) greyscale if it is a color texture.
