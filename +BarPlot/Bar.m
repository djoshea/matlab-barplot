classdef Bar < handle
% function to plot bar plots with error bars

    properties
        label
        value
        labelAbove
        
        error
        errorLow
        errorHigh
        confHigh
        confLow
        
        FontName
        FontWeight
        FontSize
        FontColor
        HorizontalAlignment
        LabelRotation
        
        FontNameAbove
        FontWeightAbove
        FontSizeAbove
        FontColorAbove
        HorizontalAlignmentAbove
        LabelRotationAbove
        
        FaceColor
        EdgeColor
        
        Width
        ErrorLineWidth
        ErrorColor
    end

    properties(Dependent,SetAccess=private)
        baseline
        heightRelativeToBaseline
        above

        highErrorLimit
        lowErrorLimit
    end
    
    properties(SetAccess=protected)
        group
        guid
    end

    methods(Access={?BarPlot,?BarPlot.BarGroup})
        function b = Bar(label, value, varargin)
            ff = get(0, 'DefaultAxesFontName');
            sz = get(0, 'DefaultAxesFontSize');
            tc = get(0, 'DefaultTextColor');
            
            p = inputParser();
            p.addRequired('group', @(g) isa(g, 'BarPlot.BarGroup'));
            p.addParameter('labelAbove', '', @(x) ischar(x) || iscellstr(x));
            p.addParameter('FontName', ff, @ischar);
            p.addParameter('FontWeight', 'normal', @ischar);
            p.addParameter('FontSize', sz, @(x) isempty(x) || isscalar(x));
            p.addParameter('FontColor', tc, @(x) true);
            p.addParameter('HorizontalAlignment', 'center', @ischar);
            p.addParameter('LabelRotation', 0, @isscalar);
            
            p.addParameter('FontNameAbove', ff, @ischar);
            p.addParameter('FontWeightAbove', 'normal', @ischar);
            p.addParameter('FontSizeAbove', sz, @(x) isempty(x) || isscalar(x));
            p.addParameter('FontColorAbove', tc, @(x) true);
            p.addParameter('HorizontalAlignmentAbove', 'center', @ischar);
            p.addParameter('LabelRotationAbove', 0, @isscalar);
            
            p.addParameter('Width', 0.8, @isscalar);
            p.addParameter('ErrorLineWidth', 3, @isscalar); % in points
            
            % redundant ways of specifying interval
            p.addParameter('confInt', [], @(x) isempty(x) || isvector(x));
            p.addParameter('confLow', [], @(x) isempty(x) || isscalar(x));
            p.addParameter('confHigh', [], @(x) isempty(x) || isscalar(x));
            p.addParameter('errorLow', [], @(x) isempty(x) || isscalar(x));
            p.addParameter('errorHigh', [], @(x) isempty(x) || isscalar(x));
            p.addParameter('error', [], @(x) isempty(x) || isscalar(x));
            
            p.addParameter('FaceColor', [0.5 0.5 0.5], @(x) true);
            p.addParameter('EdgeColor', 'none', @(x) true);
            p.addParameter('ErrorColor', [0.4 0.4 0.4], @(x) true);
            
            p.CaseSensitive = false;
            p.parse(varargin{:});
            
            b.label = label;
            b.value = value;
            b.group = p.Results.group;
            b.labelAbove = p.Results.labelAbove;
            
            b.FontName = p.Results.FontName;
            b.FontWeight = p.Results.FontWeight;
            b.FontSize = p.Results.FontSize;
            b.FontColor = p.Results.FontColor;
            b.HorizontalAlignment = p.Results.HorizontalAlignment;
            b.LabelRotation = p.Results.LabelRotation;
            
            b.FontNameAbove = p.Results.FontNameAbove;
            b.FontWeightAbove = p.Results.FontWeightAbove;
            b.FontSizeAbove = p.Results.FontSizeAbove;
            b.FontColorAbove = p.Results.FontColorAbove;
            b.HorizontalAlignmentAbove = p.Results.HorizontalAlignmentAbove;
            b.LabelRotationAbove = p.Results.LabelRotationAbove;
            
            b.Width = p.Results.Width;
            b.FaceColor = p.Results.FaceColor;
            b.EdgeColor = p.Results.EdgeColor;
            b.ErrorColor = p.Results.ErrorColor;
            b.ErrorLineWidth = p.Results.ErrorLineWidth;
             
            if ~isempty(p.Results.confInt)
                b.confLow = min(p.Results.confInt);
                b.confHigh = max(p.Results.confInt);
            else
                b.confLow = p.Results.confLow;
                b.confHigh = p.Results.confHigh;
            end
            b.errorLow = p.Results.errorLow;
            b.errorHigh = p.Results.errorHigh;
            b.error = p.Results.error;
            
            b.guid = num2str(matlab.internal.timing.timing('cpucount'));
        end
    end
        
    methods
        function name = getComponentsCollectionName(b)
            name = sprintf('BarPlot_barComps_%s', b.guid);
        end

        function v = get.baseline(b)
            v = b.group.baseline;
        end

        function v = get.heightRelativeToBaseline(b)
            v = abs(b.value - b.baseline);
        end

        function tf = get.above(b)
            tf = b.value > b.baseline;
        end

        function val = get.highErrorLimit(b)
            if ~isempty(b.error)
                % just show on one side
                if b.above
                    val = b.value + b.error;
                else
                    val = b.value;
                end
            else
                if ~isempty(b.errorHigh)
                    val= b.value + b.errorHigh;
                else
                    val = b.confHigh;
                end
            end
            if isempty(val)
                val = b.value;
            end
        end

        function val = get.lowErrorLimit(b)
            if ~isempty(b.error)
                % just show on one side
                if b.above
                    val = b.value;
                else
                    val = b.value - b.error;
                end
            else
                if ~isempty(b.errorLow)
                    val= b.value - b.errorLow;
                else
                    val = b.confLow;
                end
            end
            if isempty(val)
                val = b.value;
            end
        end
    end
    
    methods(Access=?BarPlot.BarGroup)
        function [xRight, xCenter, hBar, hError, hLabelAbove] = render(b, axh, aa, xLeft)
            % determine actual error limits
            confHigh = b.highErrorLimit; %#ok<*PROPLC>
            confLow = b.lowErrorLimit;

            xc = xLeft;
            % collection to use for components of bars
            barCompsName = b.getComponentsCollectionName();
            
            aboveBaseline = b.above;
            
            % draw bar
            if(b.value ~= b.group.baseline)
                hBar = rectangle('Position', [xc, min(b.group.baseline, b.value), b.Width, abs(b.value-b.group.baseline)], ...
                    'Parent', axh, 'FaceColor', b.FaceColor, 'EdgeColor', b.EdgeColor);
                aa.addHandlesToCollection(barCompsName, hBar);
            else
                hBar = gobjects(0, 1);
            end
            
            % draw error
            if confHigh ~= confLow
                hError = line([xc xc]+b.Width/2, [confLow confHigh], 'LineWidth', b.ErrorLineWidth, ...
                    'Parent', axh, 'Color', b.ErrorColor);
%                 hLine = rectangle('Position', ...
%                     [xc+b.Width/2-b.ErrorWidth/2, confLow, b.ErrorWidth, confHigh-confLow], ...
%                     'Parent', axh, 'FaceColor', b.ErrorColor, 'EdgeColor', 'none');
                hasbehavior(hError, 'legend', false);
                aa.addHandlesToCollection(barCompsName, hError);
            else
                hError = gobjects(0, 1);
            end
            
            % add label above
            if ~isempty(b.labelAbove)
                if aboveBaseline
                    vertAlign = 'Bottom';
                    y = confHigh;
                else
                    vertAlign = 'top';
                    y = confLow;
                end
                hLabelAbove = text(xc+b.Width/2, y, b.labelAbove, 'VerticalAlignment', vertAlign, ...
                    'Color', b.FontColorAbove, 'FontName', b.FontNameAbove, 'FontWeight', b.FontWeightAbove, 'FontSize', b.FontSizeAbove, ...
                    'HorizontalAlignment', b.HorizontalAlignmentAbove, 'Rotation', b.LabelRotationAbove, ...
                    'Background', 'none', 'YLimInclude', 'on');
                aa.addHandlesToCollection(barCompsName, hLabelAbove);
            else
                hLabelAbove = gobjects(0, 1);
            end
            
            % add label underneath axis
            hLabel = text(xc + b.Width/2, 0, b.label, ...
                'Color', b.FontColor, 'FontName', b.FontName, 'FontWeight', b.FontWeight, ...
                'FontSize', b.FontSize, 'Parent', axh, ...
                'VerticalAlignment', 'top', 'HorizontalAlignment', b.HorizontalAlignment, ...
                'Rotation', b.LabelRotation, 'Background', 'none');
            
            import AutoAxis.PositionType;
            a = AutoAxis.AnchorInfo(hLabel, PositionType.Top, axh, PositionType.Bottom, ...
                    'tickLabelOffset', 'BarPlot: anchor bar label below axis');
            aa.addAnchor(a);
            
            % add label to global collection and collection just for this
            % group
            aa.addHandlesToCollection('BarPlot_barLabels', hLabel);
           % aa.addHandlesToCollection(b.group.getBarLabelsCollectionName(), hLabel);
            xRight = xc + b.Width;
            xCenter = xc + b.Width/2;
        end
    end
end

