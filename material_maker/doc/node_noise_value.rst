Value noise node
~~~~~~~~~~~~~~~~~

The **Value** noise node outputs a texture generated as a sum of Value noise functions
with increasing frequencies and decreasing amplitudes. Value noise has a wide range of
applications, such as stains, wood, dust...

.. image:: images/node_noise_value.png
	:align: center

Inputs
++++++

The **Value** noise node does not accept any input.

Outputs
+++++++

The **Value** noise node provides a grayscale Value noise texture.

Parameters
++++++++++

The **Value** noise node accepts the following parameters:

* *Scale X* and *Scale Y* are the subdivisions of the first iteration

* *Iterations* is the number of iterations

* *Persistance* is the ratio between the amplitude of subsequent iterations. Lower values
  of persistance generate smoother textures.

Example images
++++++++++++++

.. image:: images/node_value_samples.png
	:align: center

Variations
++++++++++

* The **Color Value** node generates an RGB image made of 3 grayscale Value Noise images.

* The **Value Warp 1** and **Value Warp 2** nodes generate Value noise with domain warping.

.. image:: images/node_value_variations.png
	:align: center
