Iterate Variations node
~~~~~~~~~~~~~~~~~~~~~~~

The **Iterate Variations** node can be used to combine several variations of its input.
Variations differ by the value of a variable (defined in the **Variable** parameter),
that can is modified automatically according to the **From**, **To** and **Step**
parameters.

.. image:: images/node_miscellaneous_variations_iterate.png
	:align: center

Inputs
++++++

The **Iterate Variations** node has a single grayscale input whose variations will be generated and combined.

Outputs
+++++++

The **Iterate Variations** node has a single grayscale output that shows the combined variations.

Parameters
++++++++++

The **Iterate Variations** node accepts the following parameters:

* *From*, the initial value of the variable

* *To*, the maximum value of the variable

* the *Step* used to loop through all values

* *Combine*, the operator used to combine variations (**Add**, **Min**, **Max** or **Average**)

* the *Variable* that is controlled by the node (**$?1**, **$?2**, **$?3** or **$?4**)

* the *Randomize* option, that sets different seeds for different variations

Note
++++

To generate variations, the **Iterate Variations** node sets different values of the variations
variable.

The whole incoming branch is affected, until a buffer, text or image node is reached.
