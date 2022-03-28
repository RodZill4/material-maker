Splatter node
~~~~~~~~~~~~~

The **Splatter** node splats several instances of its input with optional scale and rotation variations.
Overlapping instances are mixed with each other using a *lighten* filter.

The **Splatter** also has a color version whose input is in RGBA format.

.. image:: images/node_transform_splatter.png
	:align: center

Inputs
++++++

The **Splatter** node accepts two inputs:

* The *Source* inputs is the image to be splat into the output.

* The *Mask* input is a greyscale image that is used as a mask and affects each instance's value.

Outputs
+++++++

The **Splatter** node outputs the splat image.

The greyscale splatter has two additional outputs, one that assigns a random color to each splat instance and one that assigns a UV layout to each splat instance.

Parameters
++++++++++

The **Splatter** node accepts the following parameters:

* *Count*, the number of instances of the source image in the result, including those canceled by the mask.
* *Inputs* is the number of alternate shapes in the input (1, 4 or 16). Images containing several
  shapes can easily be created using the **Tile2x2** node.
* *Scale X and Scale Y* are the scale along X and Y axes applied to each instance.
* *RndRotate* is the maximum angle of the random rotation applied to each instance.
* *RndScale* is the amount of random scaling applied to each instance.
* *RndValue* is the amount of random value applied to each instance.
* *Variations*: if checked, the node will splat different variations of its input
  (i.e. roll a different seed for each instance)

Example images
++++++++++++++

.. image:: images/node_transform_splatter_samples.png
	:align: center
