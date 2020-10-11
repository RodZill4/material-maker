Common properties of nodes
--------------------------

The nodes will always have outputs that will be connected to the inputs of other
nodes. They may also (and will probably) have parameters that can be modified
in the user interface, and inputs to receive data from other nodes.

.. image:: images/node_example.png
  :align: center

Outputs
^^^^^^^

Nodes can have several outputs that represent the images they provide. Each node output can be
connected to several node inputs. Each node output (and input) can be:

* a **greyscale image** (shown in grey) 

* a **color image** (shown in blue)

* an **RGBA image** (shown in semi-transparent green)

* a **2D signed distance function** (shown in orange)

* a **3D signed distance function** (shown in red), with or without a color index

* a **3D texture** (shown in fuchia), that can be associated to a color index, which makes
  it possible to associate several 3D textures in a single 3D scene

Greyscale, color and RGBA inputs and outputs can be connected to each other and will automatically be
converted when required.

2D signed distance functions have a specific preview that shows the associated signed distance
field. They can be converted into greyscale images using the `sdShow` node.

3D signed distance functions have a specific preview that shows the lit 3D scene. They can be
converted into a greyscale height map and a color normal map using the `Render` node.

Clicking on an output slot will show the corresponding preview at the bottom of the node.
When a node has several outputs, only one of them can be previewed at a time. The previewed
output slot will have a circle around it, and clicking it again will hide the preview.

Inputs
^^^^^^

Inputs are images the node will transform (if any). An input is always connected to at most
an output. Inputs generally have a default value that is used when it is not connected.

Parameters
^^^^^^^^^^

Parameters are used to configure nodes. The following types are supported:

* **float** parameters are used whenever a real number is needed. Float parameters have
  bounds, but it is possible to ignore them (at your own risk). To modify a float parameter,
  click in the text field and enter a new value, or click and drag left or right to decrease
  or decrease its value. When the lower or upper bound is reach, the value will stick to it,
  but dragging again from there makes it possible to go beyond the limit.
* **size** parameters are power of two values for the image size. They are used when
  actually storing data in a texture, or when performing resolution dependent calculations
  such as convolutions. They are shown as drop down list boxes.
* **enumerated** parameters are used when nodes have different named options and shown as
  drop down list boxes.
* **boolean** parameters are shown as check boxes.
* **color** parameters are shown as Color selectors.
* **gradient** parameters are edited in dedicated editor widgets. Cursors can be added by
  double-clicking in the lower part of the widget, dragged left and right using the left
  mouse button, and removed using the right mouse button.

  The drop down list box can be used to select one of the 4 interpolation options.
  
  Double clicking in the upper part of the gradient editor will open a larger version of the
  widget to move cursors mode precisely.

  Finally, it is possible to drag and drop from the upper part of a gradient editor widget to
  another to duplicate the gradient parameter, or from any **Colorize** node variant in the
  library to a gradient editor widget.

.. image:: images/gradient_editor.png
	:align: center

Randomness
^^^^^^^^^^

Nodes that provide random patterns have an implicit **seed** parameter. It is not possible
to edit it directly, but moving the node in the graph will change its value. It is possible
to freeze the seed value using the small dice button in the node's title bar in the graph.

.. image:: images/random_node.png
	:align: center

Subgraphs also have their seed and transmit it to their children unless not configured to
do so, or the children's seeds are frozen.

Modifying nodes
^^^^^^^^^^^^^^^

Most nodes in Material Maker can be modified, but they first have to be made editable.
To do this, select a node, and use the **Tools -> Make the selected nodes editable**
menu item or the **Control+W** keyboard shortcut.

.. image:: images/editable_node.png
	:align: center

When made editable, 3 buttons are shown at the bottom of the node:

* A pencil-shaped button to edit the node (the precise behavior of this button depends
  on the node type)
* A folder-like button to load an existing node template
* A floppy disk button to save the node as a template

To be reusable directly, templates must be saved in the **generators** directory in
the install dir (or the **addon/material_maker/nodes** directory when using Material
Maker as a Godot addon). All nodes templates saved in this directory are shown in
the **Tools -> Create** menu.

It is absolutely not necessary to save newly created nodes as templates, but this
makes them a lot easier to access and results in smaller material files (only
references to the templates are saved and not the whole node description).
Consequently, modifying a template without ensuring compatibility with the old
version (i.e. removing or renaming parameters, removing or swapping inputs or
outputs) may break existing materials, and should thus be avoided.
