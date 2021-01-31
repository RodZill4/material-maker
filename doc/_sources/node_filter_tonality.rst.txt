Tonality node
~~~~~~~~~~~~~

The **Tonality** node applies a user-defined curve to a greyscale image.

.. image:: images/node_filter_tonality.png
	:align: center

Inputs
++++++

The **Tonality** node requires a greyscale input texture.

Outputs
+++++++

The **Tonality** node provides a single greyscale texture.

Parameters
++++++++++

The **Tonality** node has a single parameter that defines the tonality curve to be applied to
the input image.

Notes
+++++

The input will be considered (and implicitly converted to) greyscale if it is a color texture.
