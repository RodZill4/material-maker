Math node
~~~~~~~~~

The **Math** node performs various math operations between its inputs.

.. image:: images/node_filter_math.png
	:align: center

Inputs
++++++

The **Math** node accepts two greyscale inputs. Those inputs are optional, and when
left unconnected, the corresponding parameter value is used

Outputs
+++++++

The **Math** node generates a single greyscale texture that contains the result
of the math operation.

Parameters
++++++++++

The **Math** node accepts the following parameters:

* the *operation* to be performed
* *default values* to be used in place of the inputs when left unconnected
* a boolean that specifies if the result must be clamped between 0 and 1
