Color Conversion node
~~~~~~~~~~~~~~~~~~~~~

The **Color Conversion** node converts the input image from linear color space to sRGB or from sRGB to liear, depending on the mode, the alpha channel remains untouched.

.. image:: images/node_filter_color_conversion.png
	:align: center

Inputs
++++++

The **Color Conversion** node requires an RGBA input texture.

Outputs
+++++++

The **Color Conversion** node provides a single RGBA texture.

Parameters
++++++++++

The **Color Conversion** has a single **Mode** parameter to select between converting from linear to sRGB and from sRGB to linear.

Example images
++++++++++++++

.. image:: images/node_color_conversion_samples.png
	:align: center
