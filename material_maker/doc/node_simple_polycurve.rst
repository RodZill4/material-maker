PolyCurve node
~~~~~~~~~~~~~~

The **PolyCurve** node outputs a simple RGBA image showing a curve defined by several control points.

.. image:: images/node_simple_polycurve.png
	:align: center

Inputs
++++++

The PolyCurve node accepts an optional image that is mapped along the curve,
and an optional profile that can be generated using a Tonality node.

Outputs
+++++++

The PolyCurve node generates an RGBA image showing the curve.

Parameters
++++++++++

The **PolyCurve** node has the following parameters:

* the control points that define the polycurve
* the *width* of the curve to be drawn
* the number of repetitions of the input pattern along the curve

Example images
++++++++++++++

.. image:: images/node_polycurve_samples.png
	:align: center
