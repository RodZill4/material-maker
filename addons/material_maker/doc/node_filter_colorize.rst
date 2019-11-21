Colorize node
~~~~~~~~~~~~~

The **Colorize** node applies a user-defined gradient to a greyscale image: black pixels
will be colored with the leftmost color of the gradient and white pixels will take
the rightmost color.

.. image:: images/node_colorize.png
	:align: center

Inputs
++++++

The **Colorize** node requires a greyscale input texture.

Outputs
+++++++

The **Colorize** node provides a single color texture.

Parameters
++++++++++

The **Colorize** node has a single parameter that defines the gradient to be applied to
the input image.

Notes
+++++

The input will be considered (and implicitly converted to) greyscale if it is a color texture.

Example images
++++++++++++++

.. image:: images/node_colorize_samples.png
	:align: center
