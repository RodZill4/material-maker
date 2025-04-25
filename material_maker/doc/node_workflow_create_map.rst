Create Map node
~~~~~~~~~~~~~~

The **Create Map** node creates a map holding height, orientation and offset information
used to combine simple materials.

.. image:: images/node_workflow_createmap.png
	:align: center

Inputs
++++++

The **Create Map** node accepts two inputs:

* the *height* component as a greyscale image.

* an optional offset map.

Outputs
+++++++

The **Create Map** node outputs the map in an RGB image where:

* the red component holds the height information

* the green component holds the orientation information

* the blue component holds the offset information

Parameters
++++++++++

The **Create Map** node has two parameters:

* *height* is the maximum height of the map

* *angle* is the orientation of the map
