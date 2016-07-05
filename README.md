# matlab-barplot
Automatic bar plots with groups, whiskers, bridges

Requires http://github.com/djoshea/matlab-auto-axis/ for automatic constraint satisfaction which places the bridges and labels automatically.

Bar plots are built by construct objects one by one, rather than creating a giant array of all the required data, confidence intervals, etc., which becomes tedious. Instead, you create one  `BarPlot` object and create groups and bars one at a time. At the end, call `.render()` on the `BarPlot` object. See below for a brief example and look at advanced usage in `BarPlot.demo` for an idea of how to use this.

Rectangular bar plots with whiskers / confidence intervals, as well as violin plots are supported. Significance bridges can connect any two bars to indicate a comparison.

# Brief example

From `example.m`:

```matlab
bp = BarPlot('ylabel', 'Value');

cmap = parula(8);

% create the first group of 2 bars
g = bp.addGroup('Group 1');
b1 = g.addBar('Bar 1', 24, 'confInt', [20 28], 'FaceColor', cmap(1, :));
b2 = g.addBar('Bar 2', 18, 'error', 3, 'labelAbove', '*', 'FontSizeAbove', 12, 'FaceColor', cmap(2, :));

% add the bridge connecting bar 1 and bar 2
g.addBridge('*', b1, b2, 'FontSize', 12);

% create the second group of bars, using violin bars
g = bp.addGroup('Group 2');
g.addBar('Bar 1', 24, 'confInt', [20 28], 'FaceColor', cmap(1, :));
g.addBar('Bar 2', 18, 'error', 3, 'labelAbove', '*', 'FontSizeAbove', 12, 'FaceColor', cmap(2, :));

% make a third bar, hold onto the BarPlot.Bar object returned, and change
% its properties
b3 = g.addBar('Bar 3', 18, 'errorLow', 3, 'errorHigh', 5, 'labelAbove', '*', 'FontSizeAbove', 12, 'FaceColor', cmap(3, :));
b3.FaceColor = 'r';

% make a violin bar that shows the distribution
vals = 25 + 4*randn(30, 1);
b4 = g.addViolinBar('Bar 4', vals, 'FaceColor', cmap(4, :), 'locationType', 'median');

% add the bridge connecting bar 3 and bar 4
g.addBridge('*', b3, b4, 'FontSize', 12);

% add the bridge connecting bar 1 and bar 4, spanning groups
% here we call addBridge on the root bar plot instead
bp.addBridge('**', b1, b4, 'FontSize', 12);

bp.render();
```

<img width="70%" src="/testExample.png?raw=true">

# Demo gallery

Figure export was via http://github.com/djoshea/matlab-save-figure/

```
BarPlot.demo();
```
![Demo](/testBarPlot.png?raw=true =300x200 "Demo" )

```
BarPlot.demo('bridgesExtendToBars', true);
```
![Demo](/testBarPlotExtendedBridges.png?raw=true "Demo")

```
BarPlot.demo('labelRotation', 45, 'labelAlignment', 'right');
```
![Demo](/testBarPlotLabelRot.png?raw=true "Demo")

```
BarPlot.demo('style', 'violin');
```
![Demo](/testBarPlotViolin.png?raw=true "Demo")
