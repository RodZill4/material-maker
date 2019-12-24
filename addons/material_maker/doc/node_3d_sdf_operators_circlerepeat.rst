CircleRepeat node
...........

The **CircleRepeat** node generates a 3D signed distance image of a circular repetition of its
input. The source object must be offset in the positive Y direction from the center.

.. image:: images/node_sdf3d_circlerepeat.png
	:align: center

Inputs
::::::

The **CircleRepeat** node accepts an input in 3D signed distance function format.

Outputs
:::::::

The **CircleRepeat** node generates a signed distance function of the
repeated version of the input shape.

Parameters
::::::::::

The **CircleRepeat** node accepts *the number of repetitions* as parameter.

Example images
::::::::::::::

.. image:: images/node_sdf3d_circlerepeat_sample.png
	:align: center
