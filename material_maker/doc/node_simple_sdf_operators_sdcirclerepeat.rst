sdCircleRepeat node
...................

The **sdCircleRepeat** node generates a signed distance image obtained by repeating
the input on a circle.

.. image:: images/node_simple_sdf_operators_sdcirclerepeat.png
	:align: center

Inputs
::::::

The **sdCircleRepeat** node accepts a single input in signed distance function format.

Outputs
:::::::

The **sdCircleRepeat** node generates a signed distance function of the
repeated pattern.

Parameters
::::::::::

The **sdCircleRepeat** node accepts the following parameters:

* The **Count** controls the number of repetitions of the input.
* The **Variations** control enables variation sampling on the input

Example images
::::::::::::::

.. image:: images/node_sdcirclerepeat_sample.png
	:align: center
