Scale XYZ node
..............

The **Scale XYZ** node generates a 3D signed distance function of a scaled shape
based on its input in a non uniform way. 
The result shape is no longer a correct signed distance function, but can be used for many operations like ray marching.

.. image:: images/node_3d_sdf_transforms_scale_xyz.png
	:align: center

Inputs
::::::

The **Scale XYZ** node accepts an input in 3D signed distance function format.

Outputs
:::::::

The **Scale XYZ** node generates a signed distance function of the
scaled input shape.

Parameters
::::::::::

The **Scale XYZ** node has four parameters:

* The *Scale* used as a uniform scale factor.

* The *Scale X* parameter defines the scale ratio along the X axis.

* The *Scale Y* parameter defines the scale ratio along the Y axis.

* The *Scale Z* parameter defines the scale ratio along the Z axis.