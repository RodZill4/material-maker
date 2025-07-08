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

* a grayscale Voronoi noise texture that shows the distance to the feature points.

* a grayscale texture that shows the distance to the closest segment bisector of all feature points pairs.

* Fill information for each cell that must be connected to a Fill companion node

The third output can be used in conjunction with **Fill To** nodes to generate random colors,
custom UVs etc. to create complex materials that show for example bricks of different colors.


Parameters
++++++++++

The **Voronoi** noise node accepts the following parameters:

* *Scale X* and *Scale Y* define the number of feature points that define the noise.

* *Stretch X* and *Stretch Y* are applied to the distance functions.

* *Intensity* is a factor applied to the first output of the node.

* *Randomness* defines the location of feature points.

Example images
++++++++++++++

.. image:: images/node_voronoi_samples.png
	:align: center
