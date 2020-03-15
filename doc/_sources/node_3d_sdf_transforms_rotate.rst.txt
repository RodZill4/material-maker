Rotate node
...........

The **Rotate** node generates a 3D signed distance function of a rotated scene
based on its input. If the input shapes are associated to color indexes, the
rotate node applies them to the output.

.. image:: images/node_3d_sdf_transforms_rotate.png
	:align: center

Inputs
::::::

The **Rotate** node accepts an input in 3D signed distance function format.

Outputs
:::::::

The **Rotate** node generates a signed distance function of the
rotated input shape.

Parameters
::::::::::

The **Rotate** node accepts *the angles of the rotations around the X, Y and Z axes* as parameters.
