Fast Blur node
~~~~~~~~~

The **Fast Blur** node applies an approximated Gaussian blur algorithm to its input.

.. image:: images/node_filter_blur_fast.png
	:align: center

Inputs
++++++

The **Fast Blur** node accepts an RGBA input to be blurred and an optional blur mask
that defines the intensity of the blur effect.

Outputs
+++++++

The **Fast Blur** node outputs the result of the blur operation.

Parameters
++++++++++

The **Fast Blur** node has three parameters:

* The *resolution* defines the size of the output image.

* The *sigma* parameter defines how smooth the output will be.

* The *quality* can be modified to choose between nicer result and rendering time.

Notes
+++++

This node outputs an image that has a fixed size.

Example images
++++++++++++++

.. image:: images/node_blur_samples.png
	:align: center
