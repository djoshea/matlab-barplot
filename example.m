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