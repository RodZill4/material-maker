Edge detect node
~~~~~~~~~~~~~~~~

There are 4 different **Edge detect** nodes that apply an edge detect
filter to their input. Them main edge detect node has more parameters,
the 3 others are simplified (and faster) filters.

.. image:: images/node_filter_edge_detect.png
	:align: center

Inputs
++++++

The **Edge detect** node has a single input.

Outputs
+++++++

The **Edge detect** node outputs the result of the edge detect operation.

Parameters
++++++++++

The **Edge detect** node accepts the following parameters:

* The *size* at which the input is sampled

* the *width* of the edge detection area for each pixel

* the value difference *threshold* used when comparing pixel colors

Example images
++++++++++++++

.. image:: images/node_edge_detect_samples.png
	:align: center
