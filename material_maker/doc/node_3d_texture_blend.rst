Blend node
~~~~~~~~~~

The **Blend** node blends two or more 3D textures using an optional opacity. It performs a blend operation
defined by the blend mode between the inputs, and mixes the result with the background input
using the opacity (defines by the *opacity* parameter, or the optional greyscale input).

.. image:: images/node_3d_texture_blend.png
	:align: center

Inputs
......

The **Blend** node accepts three inputs:

* The first input is the background layer.

* The second input is the first layer.

* The third input is an optional mask that will be used instead of the opacity parameter.

This node is variadic, and more layers and associated masks can be added.

Outputs
.......

The **Blend** node outputs the result of the blend operation.

Parameters
..........

The **Blend** node has two or more parameters:

* The *blend mode*, that can be one of the following: *Normal*, *Multiply*, *Screen*,
  *Overlay*, *Hard Light*, *Soft Light*, *Burn*, *Dodge*, *Lighten*, *Darken*, *Difference*.

* The *opacity* used when mixing the result of the blend operation with the bottom input
  when the corresponding input is not connected. When connected, the opacity channel is
  converted to greyscale and multiplied with that parameter.

Both parameters are repeated for each additional layer.

Example images
..............

.. image:: images/node_3d_texture_blend_sample.png
	:align: center
