classdef Bridge < handle
    properties(SetAccess=protected)
        bar1
        bar2
        parent % group I belong to or BarPlot if spans groups
    end

    properties
        label
        extendToBars
        tickLength
        above
        avoidAdjacentBridges
        offset
        labelOffset
        
        Color
        LineWidth
        FontName
        FontWeight
        FontSize
        FontColor
    end
    
    properties(SetAccess=protected)
        guid
    end
    
    methods(Access={?BarPlot,?BarPlot.BarGroup})
        function br = Bridge(varargin)
            ff = get(0, 'DefaultAxesFontName');
            sz = get(0, 'DefaultAxesFontSize');
            tc = get(0, 'DefaultTextColor');
            
            p = inputParser();
            p.addRequired('label', @isstringlike);
            p.addRequired('bar1', @(x) isa(x, 'BarPlot.Bar'));
            p.addRequired('bar2', @(x) isa(x, 'BarPlot.Bar'));
            p.addRequired('parent', @(x) isa(x, 'BarPlot.BarGroup') || isa(x, 'BarPlot'));
            p.addParameter('FontName', ff, @ischar);
            p.addParameter('FontWeight', 'normal', @ischar);
            p.addParameter('FontSize', sz, @(x) isempty(x) || isscalar(x));
            p.addParameter('FontColor', tc, @(x) true);
            p.addParameter('Color', 'k', @(x)true);
            p.addParameter('LineWidth', 1, @isscalar);
            p.addParameter('baseline', 0, @isscalar);
            p.addParameter('offset', 0.1, @isscalar);
            p.addParameter('labelOffset', 0.05, @isscalar);
            p.addParameter('tickLength', 0.1, @(x) ischar(x) || isscalar(x)); % points
            p.addParameter('extendToBars', false, @islogical);
            p.addParameter('avoidAdjacentBridges', true, @islogical);
            p.parse(varargin{:});
            
            br.label = string(p.Results.label);
            br.labelOffset = p.Results.labelOffset;
            br.bar1 = p.Results.bar1;
            br.bar2 = p.Results.bar2;
            br.Color = p.Results.Color;
            br.LineWidth = p.Results.LineWidth;
            br.tickLength = p.Results.tickLength;
            br.avoidAdjacentBridges = p.Results.avoidAdjacentBridges;
            br.extendToBars = p.Results.extendToBars;
            br.offset = p.Results.offset;
            
            br.FontName = p.Results.FontName;
            br.FontWeight = p.Results.FontWeight;
            br.FontSize = p.Results.FontSize;
            br.FontColor = p.Results.FontColor;
            
            % above or below
            br.parent = p.Results.parent;
            [~, br.guid] = fileparts(tempname);
        end
    end
      
    methods
        function name = getComponentsCollectionName(br)
             name = sprintf('BarPlot_bridgeComps_%s', br.guid);
        end

        function tf = get.above(br)
            % pick to be the same as the larger of the two bars in abs height
            h1 = br.bar1.heightRelativeToBaseline;
            h2 = br.bar2.heightRelativeToBaseline;
            [~, bigger] = max([h1 h2]);
            above = [br.bar1.above br.bar2.above]; %#ok<PROP>
            tf = above(bigger); %#ok<PROP>
        end
    end
    
    methods(Access={?BarPlot,?BarPlot.BarGroup})
        function [hLine, hText] = render(br, ax, aa, x1, x2) %#ok<INUSL>
            width1 = br.bar1.Width;
            width2 = br.bar2.Width;
            
            % add a 10% offset so that adjacent bridges don't touch
            if x1 < x2
                x1 = x1 + width1/10;
                x2 = x2  - width2/10;
            else
                x1 = x1 - width1/10;
                x2 = x2 + width2/10;
            end
            
            % here we decide whether to use 4 points or 2 if tickLength == 0
            if br.tickLength > 0 || br.extendToBars
                x = [x1 x1 x2 x2];
                if br.above
                    y = [0 1 1 0];
                else
                    y = [0 -1 -1 0];
                end
            else
                x = [x1 x2];
                y = [0 0];
            end
            
            xc = mean([x1 x2]);
            hLine = line(x, y, 'Color', br.Color, 'LineWidth', br.LineWidth);
            hText = text(xc, 0, br.label, 'Color', br.Color, 'HorizontalAlignment', 'center', ...
                'Background', 'none', 'YLimInclude', 'on', 'Color', br.FontColor, ...
                'FontName', br.FontName, 'FontWeight', br.FontWeight, 'FontSize', br.FontSize, 'Margin', 0.001);      
            
            import AutoAxis.PositionType;
            if br.extendToBars
                % position the vertical edge lines at a literal offset from the min(y1 y2) bars' component collections 
                ref1 = br.bar1.getComponentsCollectionName();
                ref2 = br.bar2.getComponentsCollectionName();
                if br.above
                    a = AutoAxis.AnchorInfo(hLine, PositionType.Bottom, ref1, PositionType.Top, br.offset, ...
                        'BarPlot: anchor bridge extends just above left bar');
                    a.applyToPointsWithinLine = 1;
                    aa.addAnchor(a);
                    
                    a = AutoAxis.AnchorInfo(hLine, PositionType.Bottom, ref2, PositionType.Top, br.offset, ...
                        'BarPlot: anchor bridge extends just above right bar');
                    a.applyToPointsWithinLine = 4;
                    aa.addAnchor(a);
                else
                    a = AutoAxis.AnchorInfo(hLine, PositionType.Top, ref1, PositionType.Bottom, br.offset, ...
                        'BarPlot: anchor bridge extends just below left bar');
                    a.applyToPointsWithinLine = 1;
                    aa.addAnchor(a);
                    
                    a = AutoAxis.AnchorInfo(hLine, PositionType.Top, ref2, PositionType.Bottom, br.offset, ...
                        'BarPlot: anchor bridge extends just below right bar');
                    a.applyToPointsWithinLine = 4;
                    aa.addAnchor(a);
                end

                % the top of the line will be positioned by the container

            elseif br.tickLength > 0
                % set height of bridges
                a = AutoAxis.AnchorInfo(hLine, PositionType.Height, [], br.tickLength, 0, ...
                    'BarPlot: anchor bridge tick length via height');
                aa.addAnchor(a);
            end

            if br.above
                hText.VerticalAlignment = 'Baseline';
                a = AutoAxis.AnchorInfo(hText, PositionType.Bottom, hLine, ...
                    PositionType.Top, br.labelOffset, ...
                    'BarPlot: anchor bridge label to top of bridge line');
                aa.addAnchor(a);
            else
                hText.VerticalAlignment = 'Cap';
                a = AutoAxis.AnchorInfo(hText, PositionType.Top, hLine, ...
                    PositionType.Bottom, br.labelOffset, ...
                    'BarPlot: anchor bridge label to bottom of bridge line');
                aa.addAnchor(a);
            end
            
            aa.addHandlesToCollection(br.getComponentsCollectionName(), [hLine; hText]);
        end
    end
end
