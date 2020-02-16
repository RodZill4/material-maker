Scratches node
~~~~~~~~~~~~~~

The **Scratches** node outputs a fibers pattern, that can be used for
scratches on any material or messy fibers.

It is inspired from a the *Fuzzy scratches* shadertoy from
Daedalus (https://www.shadertoy.com/view/4syXRD).

.. image:: images/node_pattern_scratches.png
	:align: center

Inputs
++++++

The **Scratches** node does not accept any input.

Outputs
+++++++

The **Scratches** node generates a single greyscale output texture.

Parameters
++++++++++

The **Scratches** node accepts the following parameters:

* the *Length* parameter defines the length of a fiber in the output texture. The number of
  scratches grows exponentially with the inverse of this length.

* the *Width* parameter defines the width of each fiber.

* *Layers* is the number of layers of the effect. The number of scratches grows
  linearly with the number of layers.

* *Waviness* can be tweaked to draw straight or curved scratches.

* *Angle* is the average angle of the scratches.

* *Randomness* is applied to the scratches angles.

Example images
++++++++++++++

.. image:: images/node_scratches_samples.png
	:align: center
