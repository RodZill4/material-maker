Select node
~~~~~~~~~~~

The **Select** node assigns one or more 3D textures based on
samples whose color index match the color parameter.

.. image:: images/node_3d_texture_select.png
	:align: center

Inputs
......

The **Select** node accepts two or more 3D texture inputs:

* The default texture, used for all samples that don't match the color parameter.

* Selected texture that is assigned to all samples that match.

This node is variadic, and more inputs with associated color indicies can be added.

Outputs
.......

The **Select** node generates a merged 3D texture.

Parameters
..........

The **Select** node accepts 2 parameters:

* A color index that is compared with the color index of each sample

* A tolerance value used when comparing the color parameter with the sample's color index
