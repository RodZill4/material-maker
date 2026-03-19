FBM node
~~~~~~~~

The **FBM** node outputs a fractional Brownian motion texture.
FBM is obtained by repeating a noise pattern with smaller and smaller details.

.. image:: images/node_noise_fbm.png
	:align: center

Inputs
++++++

The **FBM** node accepts a single input, the **Offset Input** to optionally
drive the **Offset** value with an input.

Outputs
+++++++

The **FBM** node provides a grayscale noise texture.

Parameters
++++++++++

The FBM node accepts the following parameters:

* **Noise** type: value, perlin, simplex, cellular types or voronoise noise
* **X** and **Y** scale of the first octave noise
* Number of **Folds** (offsetting the noise negatively and taking the absolute value)
* Number of **Iterations**
* **Persistance**, i.e. the strength of each subsequent iteration
* **Lacunarity**, i.e. the scale of each subsequent iteration
* **Offset** of the points, can be used to animate the noise

Example images
++++++++++++++

.. image:: images/node_noise_fbm_sample.png
	:align: center
