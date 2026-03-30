Alpha Association node
~~~~~~~~~~~~~~~~~~~~~~

The **Alpha Association** node is variadic and converts the input images' alpha association
from straight to premultiplied and vice versa. The alpha channel remains untouched.

.. image:: images/node_filter_alpha_association.png
	:align: center

Inputs
++++++

The **Alpha Association** node requires an RGBA input texture.

Outputs
+++++++

The **Alpha Association** node provides a single RGBA texture.

Parameters
++++++++++

The **Alpha Association** node has a single **Mode** parameter to select between
converting from straight to premultiplied and from premultiplied to straight.
