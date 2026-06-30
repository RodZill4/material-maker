Tonality node
~~~~~~~~~~~~~

The **Tonality** node is variadic and applies a user-defined curve to grayscale 3D textures.

.. image:: images/node_3d_texture_tonality.png
	:align: center

Inputs
++++++

The **Tonality** node accepts one or more grayscale 3D textures.

Outputs
+++++++

The **Tonality** node outputs grayscale 3D textures.

Parameters
++++++++++

The **Tonality** node has a single parameter that defines the tonality curve to be applied to
the input 3D texture.

Notes
+++++

The input will be considered (and implicitly converted to) grayscale 3D texture if it is a 3D texture.
