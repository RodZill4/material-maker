Voronoi noise node
~~~~~~~~~~~~~~~~~~

The Voronoi noise node outputs Voronoi noise textures.

.. image:: images/node_voronoi.png

Inputs
++++++

The Voronoi noise node does not accept any input.

Outputs
+++++++

The Voronoi noise node provides three outputs:

* a greyscale Voronoi noise texture that shows the distance to the feature points.

* a greyscale texture that shows the distance to the closest segment bisector of all feature points pairs.

* a color Voronoi partition.

.. image:: images/voronoi.png

Parameters
++++++++++

The Voronoi noise node accepts the following parameters:

* *Scale X* and *Scale Y* define the number of feature points that define the noise

* *Intensity* is a factor applied to the first output of the node.

Notes
+++++

As with all random nodes, the seed is held by the node's position, so moving the node in the graph
will modify the texture, and the outputs will remain the same if its position and parameters
are not changed.
