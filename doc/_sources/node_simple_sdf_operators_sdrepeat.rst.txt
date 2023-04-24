sdRepeat node
.............

The **sdRepeat** node generates a signed distance image obtained by repeating
the input on a grid.

.. image:: images/node_simple_sdf_operators_sdrepeat.png
	:align: center

Inputs
::::::

The **sdRepeat** node accepts a single input in signed distance function format.

Outputs
:::::::

The **sdRepeat** node generates a signed distance function of the
repeated pattern.

Parameters
::::::::::

The **sdRepeat** node accepts the following parameters:

* The **X** and **Y** controls the rows and columns amount to repeat the input
* The **R** controls the random rotation of the repeated shape
* The **Variations** control enables variation sampling on the input

Example images
::::::::::::::

.. image:: images/node_sdrepeat_sample.png
	:align: center
