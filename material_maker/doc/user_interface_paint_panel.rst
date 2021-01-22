Paint panel
-----------

Creating a paint project
^^^^^^^^^^^^^^^^^^^^^^^^

To start painting in Material Maker, just use the *File -> New paint project* menu.
This will show a dialog where a model file and a texture size can be specified.

.. image:: images/new_paint_project.png
  :align: center

A project file name will be automatically selected, but it is possible to modify
it before creating the paint project.

The paint panel consists of two sub panels. The top subpanel shows the model to be painted,
and the bottom subpanel shows the graph where the current brush is described.

Painting a 3D model
^^^^^^^^^^^^^^^^^^^

The paint subpanel is where the model is actually painted. It shows the model with its material
in its current state, and a dynamic preview of the current brush.

.. image:: images/paint_subpanel.png
  :align: center

In the paint subpanel, the model can be rotated by holding the middle mouse button
and translated by holding the middle mouse button and the Shift key.

The mouse wheel can be used to modify the zoom level. If the Control key is held,
the mouse wheel will adjust the camera's field of view angle.

The left mouse button (with no modifier) can be used to paint. Holding the Shift key and
the left mouse button will modify the brush size (left - right) and hardness (up - down).
Holding the Control key and the left mouse button will modify the pattern size and
orientation (more about brushes and brush types below). Holding the Control key will
also show the patten on the whole view (which can be useful with Pattern and UV pattern
brushes).

In the top left corner of the paint subpanel, buttons can be used to select a painting tool.
The available tools are:

* A freehand painting tool, that directly applies the brush

* A freehand line tool, that draws line following the mouse cursors movement

* A line tool, that draws straight lines

* A fill tool (pressing this button fill dircetly fill the current layer using
  the current brush)

* An eraser mode, that applies to all aforementionned tools

In the top right corner, common brush parameters such as size, hardness, opacity and spacing
can be modified.

Note that before painting, it is necessary to select a brush (by double-clicking it in the
Brushes panel) and a layer.



