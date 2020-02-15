sdRoundedShape node
...................

The **sdRoundedShape** node generates a signed distance image of a rounded shape
based on its input, by substracting a constant from its distance function (i.e.
"growing" it towards the outside).

.. image:: images/node_sdroundedshape.png
	:align: center

Inputs
::::::

The **sdRoundedShape** node accepts an input in signed distance function format.

Outputs
:::::::

The **sdRoundedShape** node generates a signed distance function of the
rounded version of the input shape.

Parameters
::::::::::

The **sdRoundedShape** node accepts the following parameters:

* *the distance* to be substracted from the function

Example images
::::::::::::::

.. image:: images/node_sdroundedshape_sample.png
	:align: center
