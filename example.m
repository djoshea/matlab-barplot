bp = BarPlot('ylabel', 'Value');

cmap = parula(3);

g = bp.addGroup('Group 1');
g.addBar('Bar 1', 24, 'confInt', [20 28], 'FaceColor', cmap(1, :));
g.addBar('Bar 2', 18, 'error', 3, 'labelAbove', '*', 'FontSizeAbove', 12, 'FaceColor', cmap(2, :));
g.addBar('Bar 3', 18, 'errorLow', 3, 'errorHigh', 5, 'labelAbove', '*', 'FontSizeAbove', 12, 'FaceColor', cmap(3, :));

g = bp.addGroup('Group 2');
g.addBar('Bar 1', 24, 'confInt', [20 28], 'FaceColor', cmap(1, :));
g.addBar('Bar 2', 18, 'error', 3, 'labelAbove', '*', 'FontSizeAbove', 12, 'FaceColor', cmap(2, :));
b = g.addBar('Bar 3', 18, 'errorLow', 3, 'errorHigh', 5, 'labelAbove', '*', 'FontSizeAbove', 12, 'FaceColor', cmap(3, :));

b.FaceColor = 'r';

bp.render();