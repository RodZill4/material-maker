Directional Blur node
~~~~~~~~~~~~~~~~~~~~~

The **Directional Blur** node applies a Gaussian blur algorithm to its input in a given direction.

.. image:: images/node_filter_blur_directional.png
	:align: center

Inputs
++++++

The **Directional Blur** node accepts an RGBA input to be blurred and an optional blur mask
that defines the intensity of the blur effect.

Outputs
+++++++

The **Directional Blur** node outputs the result of the blur operation.

Parameters
++++++++++

The **Directional Blur** node has three parameters:

* The *grid size* defines the size of the output image.

* The *sigma* parameter defines how smooth the output will be.

* The *angle* specifies the angle of the blur algorithm.

Notes
+++++

This node outputs an image that has a fixed size.

Example images
++++++++++++++

.. image:: images/node_directional_blur_samples.png
	:align: center
