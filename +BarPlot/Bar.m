classdef Bar < handle & matlab.mixin.Heterogeneous
% function to plot bar plots with error bars

    properties
        label
        labelAbove
        
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
        
        Width
        
        gapExtraLeft
        gapExtraRight
    end

    properties(Dependent,SetAccess=private)
        baseline
        above
        heightRelativeToBaseline

        maxExtent
        minExtent
        
    end
    
    properties(SetAccess=protected)
        group
        guid
    end

    methods(Access={?BarPlot,?BarPlot.BarGroup,?BarPlot.Bar})
        function b = Bar(varargin)
            ff = get(0, 'DefaultAxesFontName');
            sz = get(0, 'DefaultAxesFontSize');
            tc = get(0, 'DefaultTextColor');
            
            p = inputParser();
            p.addRequired('group', @(g) isa(g, 'BarPlot.BarGroup'));
            p.addRequired('label', @(x) ischar(x) || iscellstr(x));
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
            
            % in addition to the default bar gap set by this bar's group
            p.addParameter('gapExtraLeft', 0, @isscalar);
            p.addParameter('gapExtraRight', 0, @isscalar);
            
            p.CaseSensitive = false;
            p.parse(varargin{:});
            
            b.label = p.Results.label;
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
            
            b.gapExtraLeft = p.Results.gapExtraLeft;
            b.gapExtraRight = p.Results.gapExtraRight;
            
            b.guid = num2str(matlab.internal.timing.timing('unixtimeofday'));
        end
    end
    
    methods(Abstract)
        tf = getIsAboveBaseline(b);
        v = getHeightRelativeToBaseline(b);
        val = getMaxExtent(b);
        val = getMinExtent(b);
    end
    
    methods(Abstract, Access={?BarPlot.Bar,?BarPlot.BarGroup})
        [hStackBelowBaseline, hStackAboveBaseline] = renderInternal(axh, aa, xLeft);
    end
    
    methods(Sealed)
        function tf = eq(a, b)
            tf = arrayfun(@(b_) isequal(a, b_), b);
        end
    end
        
    methods
        function name = getComponentsCollectionName(b)
            name = sprintf('BarPlot_barComps_%s', b.guid);
        end

        function v = get.baseline(b)
            v = b.group.baseline;
        end

        function tf = get.above(b)
            tf = b.getIsAboveBaseline();
        end
        
        function v = get.heightRelativeToBaseline(b)
            v = b.getHeightRelativeToBaseline();
        end
        
        function v = get.maxExtent(b)
            v = b.getMaxExtent();
        end
        
        function v = get.minExtent(b)
            v = b.getMinExtent();
        end
 
    end
    
    methods(Access=?BarPlot.BarGroup)
        function [hStackBelowBaseline, hStackAboveBaseline] = render(b, axh, aa, xLeft)
            % collection to use for components of bars
            barCompsName = b.getComponentsCollectionName();
            
            aboveBaseline = b.above;
            
            % add label above
            if ~isempty(b.labelAbove)
                if aboveBaseline
                    vertAlign = 'Bottom';
                    y = b.maxExtent;
                else
                    vertAlign = 'top';
                    y = b.minExtent;
                end
                hLabelAbove = text(xLeft+b.Width/2, y, b.labelAbove, 'VerticalAlignment', vertAlign, ...
                    'Color', b.FontColorAbove, 'FontName', b.FontNameAbove, 'FontWeight', b.FontWeightAbove, 'FontSize', b.FontSizeAbove, ...
                    'HorizontalAlignment', b.HorizontalAlignmentAbove, 'Rotation', b.LabelRotationAbove, ...
                    'Background', 'none', 'YLimInclude', 'on', 'Margin', 0.1);
                aa.addHandlesToCollection(barCompsName, hLabelAbove);
            end
            
            % defer to the bar implementation to render itself
            [hStackBelowBaseline, hStackAboveBaseline] = b.renderInternal(axh, aa, xLeft);
            
            % add label underneath axis
            hLabel = text(xLeft + b.Width/2, 0, b.label, ...
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
        end
    end
end

