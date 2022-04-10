SDF FBM node
............

The **SDF FBM** node adds layers of noise to a base 3D SDF shape.

.. image:: images/node_3d_sdf_operators_sdf_fbm.png
	:align: center

Inputs
::::::

The **SDF FBM** node accepts a single input in 3D signed distance function format.

Outputs
:::::::

The **SDF FBM** node generates a signed distance field of the base shape with the noise applied to it.

Parameters
::::::::::

The **SDF FBM** node accepts the following parameters.

* The *Mode* of the operation, either additive of subtractive.

* The amount of *Iterations* performed.

* The *Smoothness* of the boolean operation performed at each iteration.

* A *Scaling* control to adjust how much the size of the noise is adjusted at each iteration.

Example images
::::::::::::::

.. image:: images/node_sdf3d_sdf_fbm_sample.png
	:align: center
