Voronoi noise node
~~~~~~~~~~~~~~~~~~

The **Voronoi** noise node outputs Voronoi noise textures that can be used for irregular
tiles, animal skin or scales, cracks...

.. image:: images/node_noise_voronoi.png
	:align: center

Inputs
++++++

The **Voronoi** noise node does not accept any input.

Outputs
+++++++

The **Voronoi** noise node provides three outputs:

* a greyscale Voronoi noise texture that shows the distance to the feature points.

* a greyscale texture that shows the distance to the closest segment bisector of all feature points pairs.

* a color Voronoi partition.

Parameters
++++++++++

The **Voronoi** noise node accepts the following parameters:

* *Scale X* and *Scale Y* define the number of feature points that define the noise.

* *Stretch X* and *Stretch Y* are applied to the distance functions.

* *Intensity* is a factor applied to the first output of the node.

* *Randomness* defines the location of feature points.

Notes
+++++

As with all random nodes, the seed is held by the node's position, so moving the node in the graph
will modify the texture, and the outputs will remain the same if its position and parameters
are not changed.

Example images
++++++++++++++

.. image:: images/node_voronoi_samples.png
	:align: center
