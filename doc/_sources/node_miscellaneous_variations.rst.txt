Variations node
~~~~~~~~~~~~~~~

The **Variations** node can be used to generate several variations of its input.
Variations differ by the seeds used for all random aspects of the input. 

.. image:: images/node_miscellaneous_variations.png
	:align: center

Inputs
++++++

The **Variations** node has a single input whose variations will be generated.

Outputs
+++++++

The **Variations** node has several outputs that generate different variations.

Note
++++

To generate variations, the **Variations** node rolls it input with different seeds.

The whole incoming branch is affected, until a buffer, text or image node is reached.
