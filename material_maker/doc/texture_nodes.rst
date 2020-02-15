Texture nodes
-------------

Texture nodes are nodes that actually hold and output an image (and as a consequence,
they are resolution dependant). There are two kinds of texture nodes: the image and
the buffer.

Image node
^^^^^^^^^^

The image node outputs a single image from a file. Its unique parameter is
the path of the image file.

Buffer node
^^^^^^^^^^^

The buffer node has a single input and two outputs. It renders its input into a buffer,
and its outputs will read from that buffer. The first output emits the buffer in full
resolution, and the second output will generate a given level of detail.

The buffer node has two parameters:

* the size of the buffer
* the detail level of the second output

Buffer nodes are generally used as input of shader nodes that sample their inputs multiple
times (such as convolution nodes).
