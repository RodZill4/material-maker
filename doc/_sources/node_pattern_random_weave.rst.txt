Random Weave node
~~~~~~~~~~~~~~~~~

The **Random Weave** node outputs a randomizable weave pattern, that can be used for cloth.

.. image:: images/node_pattern_random_weave.png
	:align: center

Inputs
++++++

The **Random Weave** node accepts an optional greyscale input map for the width parameter
(whose value is multiplied by the map value).

Outputs
+++++++

The **Random Weave** generates a greyscale heightmap for the pattern as well as masks
for the horizontal and vertical stripes.

Parameters
++++++++++

The **Weave** node accepts the following parameters:

* the *Size X* and *Size Y* parameters define the number of patterns that will be generated.

* the *Width X* and *Width Y* parameters define the width of stitches. 

* the *Stitch* parameter sets the length of the stitch.

* the *Random* parameter controls how much the stitches get randomized.

Example images
++++++++++++++

.. image:: images/node_random_weave_samples.png
	:align: center
