Boolean node
............

The **Boolean** node generates a 3D signed distance function for the combination (union,
intersection or difference) of its inputs. If the input shapes are associated to color indexes, the
boolean node applies them to the output.

.. image:: images/node_3d_sdf_operators_boolean.png
	:align: center

Inputs
::::::

The **Boolean** node accepts 2 inputs in 3D signed distance function format.

Outputs
:::::::

The **Boolean** node generates a signed distance function of the
combination of its inputs.

Parameters
::::::::::

The **Boolean** node accepts *the operator it applies (union, intersection or
difference)* as parameter.

Example images
::::::::::::::

.. image:: images/node_sdf3d_boolean_sample.png
	:align: center
