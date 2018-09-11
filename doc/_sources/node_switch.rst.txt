Switch node
~~~~~~~~~~~

The Switch node can be used to select sources for 2 output textures
A and B from a choice of 2 pairs (A1, B1) and (A2, B2). It is useful
to create variations of a material and easily switch between them.

.. image:: images/node_switch.png

Inputs
++++++

The Switch node has 4 color inputs A1, B1, A2 and B2.

Outputs
+++++++

The Switch node has 2 outputs A and B.

Parameters
++++++++++

The Switch node has a single parameter whose value can be 1 or 2.
When the parameter is set to 1, A forwards A1 and B forwards B1.
When the parameter is set to 2, A forwards A2 and B forwards B2.

