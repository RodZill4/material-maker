sdSmoothBoolean node
....................

The **sdSmoothBoolean** node generates a signed distance image for the combination (union,
intersection or difference) of its inputs.

.. image:: images/node_simple_sdf_operators_sdsmoothboolean.png
	:align: center

Inputs
::::::

The **sdSmoothBoolean** node accepts 2 inputs in signed distance function format.

Outputs
:::::::

The **sdSmoothBoolean** node generates a signed distance function of the
combination of its inputs.

Parameters
::::::::::

The **sdSmoothBoolean** node accepts the following parameters:

* *the operator it applies (union, intersection or difference)*
* *the smoothness* of the operation

Example images
::::::::::::::

.. image:: images/node_sdsmoothboolean_sample.png
	:align: center
