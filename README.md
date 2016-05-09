# matlab-barplot
Automatic bar plots with groups, whiskers, bridges

Requires http://github.com/djoshea/matlab-auto-axis/ for automatic constraint satisfaction which places the bridges and labels automatically.

Bar plots are built by feeding data into a `BarPlot` object one group, one bar at a time. At the end, call `.render()`. See the usage in `BarPlot.demo` for an idea of how to do this.

# Examples

Figure export was via http://github.com/djoshea/matlab-save-figure/

```
BarPlot.demo();
```
![Demo](/testBarPlot.png?raw=true "Demo")

```
BarPlot.demo('bridgesExtendToBars', true);
```
![Demo](/testBarPlotExtendedBridges.png?raw=true "Demo")

```
BarPlot.demo('labelRotation', 45, 'labelAlignment', 'right');
```
![Demo](/testBarPlotLabelRot.png?raw=true "Demo")
