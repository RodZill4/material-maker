Blur node
~~~~~~~~~

The **Blur** node applies a Gaussian blur algorithm to its input.

.. image:: images/node_filter_blur.png
	:align: center

Inputs
++++++

The **Blur** node accepts a RGBA input to be blurred and an optional blur mask
that defines the intensity of the blur effect.

Outputs
+++++++

The **Blur** node outputs the result of the blur operation.

Parameters
++++++++++

The **Blur** node has three parameters:

* The *grid size* defines the size of the output image.

* The *direction* specifies if the blur algorithm is applied horizontally, vertically or both.

* The *sigma* parameter defines how smooth the output will be.

Notes
+++++

This node outputs an image that has a fixed size.

Example images
++++++++++++++

.. image:: images/node_blur_samples.png
	:align: center
