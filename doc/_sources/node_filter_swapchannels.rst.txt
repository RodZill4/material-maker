Swap Channels node
~~~~~~~~~~~~~~~~~

The **Swap Channels** node can be used to replace each channel (R, G, B and A) of
an with 0, 1 or a channel of its input (inverted or not).

.. image:: images/node_filter_swapchannels.png
	:align: center

Inputs
++++++

The **Swap Channels** node has a single RGBA input.

Outputs
+++++++

The **Swap Channels** node outputs an RGBA image whose channels are defined by its parameters.

Parameters
++++++++++

The **Swap Channels** node has a parameter for each channel that defines its value (0 or 1)
or source (a channel of the input image, inverted or not).
