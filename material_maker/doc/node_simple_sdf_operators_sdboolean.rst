sdBoolean node
..............

The **sdBoolean** node generates a signed distance image for the combination (union,
intersection or difference) of its inputs.

.. image:: images/node_simple_sdf_operators_sdboolean.png
	:align: center

Inputs
::::::

The **sdBoolean** node accepts two or more inputs in signed distance function format.

This node is variadic, and more shapes can be added.

Outputs
:::::::

The **sdBoolean** node generates a signed distance function of the
combination of its inputs.

Parameters
::::::::::

The **sdBoolean** node accepts *the operator it applies (union, intersection or
difference)* as parameter.

Example images
::::::::::::::

.. image:: images/node_sdboolean_sample.png
	:align: center
