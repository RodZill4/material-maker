Bricks node
~~~~~~~~~~~

The bricks node outputs two related bricks pattern textures.

.. image:: images/node_bricks.png

Inputs
++++++

The bricks node does not accept any input.

Outputs
+++++++

The bricks node provides the following textures:

* The first one is a greyscale image where bricks are shown in white and mortar in black.

* The second one is a color image where all bricks are drawn using a random uniform color.

Both images can be used together to create complex materials that show for example bricks
of different colors.

.. image:: images/bricks.png

Parameters
++++++++++

The Bricks node accepts the following parameters:

* the "Pattern" parameter defines the bricks pattern that will be generated.

* the "Repeat" parameter defines the number of patterns on the horizontal and vertical
  axes of the texture.

* the "Rows" parameter defines the number of brick rows in a single pattern of the texture.

* the "Columns" parameter defines the number of brick rows in a single pattern of the texture.

* the "Offset" parameter defines the offset of odd rows of the pattern. This parameter
  only applies to the "Running bond" patterns.

* the "Mortar" parameter defines the relative thickness of mortar in patterns.

* the "Bevel" parameter defines the relative thickness of brick bevel in patterns.

Notes
+++++

As with all random nodes, the seed is held by the node's position, so moving the node in the graph
will modify the texture, and the outputs will remain the same if its position and parameters
are not changed.
