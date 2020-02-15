Buffer node
~~~~~~~~~~~

The **Buffer** node samples its input into a texture of a given resolution and
outputs the result.

Buffers can be used either as inputs of convolution nodes (to limit the combined
shader's complexity), or to create a cheap blur/pixelization effect (by using the
LOD output). Note that convolution transforms that are provided in the nodes library
already include buffers where necessary.

.. image:: images/node_buffer.png
	:align: center

Inputs
++++++

The **Buffer** node has an input that will be saved when exporting the project.

Outputs
+++++++

The **Buffer** node has 2 outputs:

* the first output provides the image

* the second output generates a given mipmap of the image

Parameters
++++++++++

The **Buffer** node has two parameters:

* the *texture resolution*

* the *mipmap level* of its second output
