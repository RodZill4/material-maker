Occlusion node
~~~~~~~~~~~~~~

The **Occlusion** node generates an ambient occlusion texture from its input.

.. image:: images/node_occlusion.png
	:align: center

Inputs
++++++

The **Occlusion** node accepts a single greyscale image as input, interpreted as a heightmap.

Outputs
+++++++

The **Occlusion** node outputs the generated normal map.

Parameters
++++++++++

The **Normal map** node has the following parameters:

* the *size* of the ambient occlusion map

* the *strength* of the ambient occlusion

Notes
+++++

This node outputs an image that has a fixed size.

Example images
++++++++++++++

.. image:: images/node_occlusion_samples.png
	:align: center
