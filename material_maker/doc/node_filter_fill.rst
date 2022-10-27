Fill node
~~~~~~~~~

The **Fill** node fills all areas surrounded by white pixels, and generates
a specific input for the fill companion (generally named "Fill to ...") nodes.

That fill information is an axis aligned bounding box of each filled area.

.. image:: images/node_filter_fill.png
	:align: center

Inputs
++++++

The **Fill** node accepts:

* a mask greyscale input whose light parts surround areas that must be filled

Outputs
+++++++

The **Fill** node generates a single RGBA texture that contains the bounding
box of each filled area.

Parameters
++++++++++

The **Fill** node accepts the following parameters:

* *resolution* is the resolution of the effect and only influences how details
  of the mask (and not the source if any) is captured. It is advised to be careful
  with using high values here, as the computation time may become very long and high
  resolutions can cause precision issues.
  Setting it higher than the input's resolution will not yield any benefit - only
  increase the computation time.
* *Remove edges* is an option to grow filled areas to remove edges.
* *Adjust* is useful when removing edges and is used to grow the areas bounding boxes.
  It is useful when using for example the **Fill to UV** or the **Fill to Gradient** node. 
