Uneven Bricks 3 node
~~~~~~~~~~~~~~~~~~~~

The **Uneven Bricks 3** node outputs an uneven brick pattern texture that can be used for walls
or pavement. It generates an uneven pattern by randomly offsetting brick intersections.

.. image:: images/node_pattern_uneven_bricks_3.png
	:align: center

Inputs
++++++

The **Uneven Bricks 3** node accepts 3 optional grayscale input maps for the shape mortar,
bevel and round parameters (the corresponding parameter is multiplied by the map value).

Outputs
+++++++

The **Uneven Bricks 3** node provides the following textures:

* The first is a grayscale image where bricks are shown in white and mortar in black.

* The second is Fill information for each brick and must be connected to a Fill companion node.

* The third is Fill information for each brick corner and must be connected to a Fill companion node.

The second and third outputs can be used in conjunction with **Fill To** nodes to generate random colors,
custom UVs etc. to create complex materials that show for example bricks of different colors.

Parameters
++++++++++

The **Uneven Bricks 3** node accepts the following parameters:

* the *Rows* parameter defines the number of brick rows in a single pattern of the texture.

* the *Columns* parameter defines the number of brick rows in a single pattern of the texture.

* the *Randomness* parameter defines the randomness introduced when generating the pattern.

* the *Mortar* parameter defines the relative thickness of mortar in patterns.

* the *Bevel* parameter defines the relative thickness of brick bevel in patterns.

* the *Round* parameter defines the radius of each round corner.

* the *Corner* parameter defines the size of each corner (for the 3rd output texture).

Example images
++++++++++++++

.. image:: images/node_unevenbricks3_samples.png
	:align: center
