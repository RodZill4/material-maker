Supersample node
~~~~~~~~~~~~~~~~

The **Supersample** node samples sub-pixel details several times to make them visible.

.. image:: images/node_filter_supersample.png
	:align: center

Inputs
++++++

The **Supersample** node accepts an RGBA input.

Outputs
+++++++

The **Supersample** node generates a single RGBA texture that contains the result
of the operation.

Parameters
++++++++++

The **Supersample** node accepts the following parameters:

* *Size* is the target resolution
* *Count* is the number of samples per axis (high values may affect performances very badly)
* *Width* is the size (in pixels) of the sampled area. Values greater than 1 may help antialias the result 
