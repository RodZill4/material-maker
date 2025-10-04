Scale XY node
.............

The **Scale XY** node is variadic and generates signed distance images obtained by scaling its inputs in a non uniform way.
The result shapes are no longer correct signed distance functions, but can be used for many operations like ray marching.

.. image:: images/node_simple_sdf_transforms_scale_xy.png
	:align: center

Inputs
::::::

The **Scale XY** node accepts one or more inputs in signed distance function format.

Outputs
:::::::

The **Scale XY** node generates signed distance functions of the scaled shapes.

Parameters
::::::::::

The **Scale XY** node has three parameters:

* The *Scale* used as a uniform scale factor.

* The *Scale X* parameter defines the scale ratio along the X axis.

* The *Scale Y* parameter defines the scale ratio along the Y axis.
