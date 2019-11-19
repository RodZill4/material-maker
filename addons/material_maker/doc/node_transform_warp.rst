Warp node
~~~~~~~~~

The **Warp** node deforms an input image according to the derivative of the second input image.

.. image:: images/node_warp.png

Inputs
++++++

The **Warp** node accepts two inputs:

* The *Source* inputs is the image to be deformed.

* The *Displace* input is a greyscale image whose derivative will be used to deform the source.

Outputs
+++++++

The **Warp** node outputs the deformed image.

Parameters
++++++++++

The **Warp** node has two parameters:

* *strength* to scale the warp effect.

* *epsilon* is used to evaluate the second input's derivative

Example images
++++++++++++++

.. image:: images/node_warp_samples.png
	:align: center
