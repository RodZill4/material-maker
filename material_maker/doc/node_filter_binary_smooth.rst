Binary Smooth node
~~~~~~~~~~~~~~~~~~

The **Binary Smooth** node smoothes the shape of a mask.

.. image:: images/node_filter_binary_smooth.png
	:align: center

Inputs
++++++

The **Binary Smooth** node accepts a greyscale mask input to be smoothed.

Outputs
+++++++

The **Binary Smooth** node outputs the result of the smoothing operation.

Parameters
++++++++++

The **Binary Smooth** node has three parameters:

* The *resolution* defines the size of the output image.

* The *smooth* parameter defines how much the mask will be smoothed.

* The *offset* can be modified to expand or contract the smoothed shape.

Notes
+++++

This node outputs an image that has a fixed size.

Example images
++++++++++++++

.. image:: images/node_binary_smooth_samples.png
	:align: center
