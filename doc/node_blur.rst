Blur node
~~~~~~~~~

The blur node applies a Gaussian blur algorithm to its inputs.

.. image:: images/node_blur.png

Inputs
++++++

The blur node has a single input.

Outputs
+++++++

The blur node outputs the result of the blur operation.

Parameters
++++++++++

The blur node has three parameters:

* The grid size defines the size of the output image. 

* The direction specifies if the blur algorithm is applied horizontally, vertically or both.

* The sigma parameter defines how smooth the output will be.

Notes
+++++

This node outputs an image that has a fixed size.