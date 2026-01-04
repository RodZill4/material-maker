Skewed Bricks node
~~~~~~~~~~~~~~~~~~

The **Skewed Bricks** node outputs several related bricks pattern textures that can be used for walls
or pavement.

.. image:: images/node_pattern_skewed_bricks.png
	:align: center

Inputs
++++++

The **Skewed Bricks** node accepts 3 optional grayscale input maps for the shape mortar,
bevel and round parameters (the corresponding parameter is multiplied by the map value).

Outputs
+++++++

The **Skewed Bricks** node provides the following textures:

* The first is a grayscale image where bricks are shown in white and mortar in black.

* The second is an RGB output of the skewed uv islands of each brick.

* The third is an RGB output of the skewed uv islands of the four corners of each brick.

* The fourth is Fill information for each brick and must be connected to a Fill companion node.

* The fifth is Fill information for each brick corner and must be connected to a Fill companion node.

The second and third outputs can be used in conjunction with **Fill To** nodes to generate random colors,
custom UVs etc. to create complex materials that show for example bricks of different colors.

Parameters
++++++++++

The **Skewed Bricks** node accepts the following parameters:

* the *Rows* parameter defines the number of brick rows in a single pattern of the texture.

* the *Columns* parameter defines the number of brick rows in a single pattern of the texture.

* the *Offset* parameter defines the offset of odd rows of the pattern. This parameter
  only applies to the *Running bond* patterns.

* the *Randomness* parameter defines how much the bricks get randomly skewed.

* the *Mortar* parameter defines the relative thickness of mortar in patterns.

* the *Bevel* parameter defines the relative thickness of brick bevel in patterns.

* the *Round* parameter defines the radius of each round corner.

* the *Corner* parameter defines the size of each corner (for the 3rd and 5th output textures).

Example images
++++++++++++++

.. image:: images/node_skewed_bricks_samples.png
	:align: center
