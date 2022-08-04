classdef PointCIBar < BarPlot.Bar
% single point with a confidence interval around it

    properties
        value
        confHigh
        confLow
        
        MarkerSize
        MarkerLineWidth
        MarkerFaceColor
        MarkerEdgeColor
        
        ErrorLineWidth
        ErrorColor
    end
    
    methods(Access={?BarPlot,?BarPlot.BarGroup})
        function b = PointCIBar(varargin)
            p = inputParser();
            % redundant ways of specifying interval
            p.addRequired('group', @(g) isa(g, 'BarPlot.BarGroup'));
            p.addRequired('label', @(x) ischar(x) || iscellstr(x));
            p.addRequired('value', @isscalar);
            
            p.addParameter('confInt', [], @(x) isempty(x) || isvector(x));
            p.addParameter('confLow', [], @(x) isempty(x) || isscalar(x));
            p.addParameter('confHigh', [], @(x) isempty(x) || isscalar(x));
            
            % appearance
            p.addParameter('MarkerSize', 5, @isscalar); % in points
            p.addParameter('MarkerLineWidth', 0.5, @isscalar); % in points
            p.addParameter('MarkerFaceColor', [0.5 0.5 0.5], @(x) true);
            p.addParameter('MarkerEdgeColor', 'none', @(x) true);

            p.addParameter('ErrorLineWidth', 3, @isscalar); % in points
            
            p.addParameter('ErrorColor', [0.4 0.4 0.4], @(x) true);
            
            p.CaseSensitive = false;
            p.KeepUnmatched = true;
            p.parse(varargin{:});
            
            b@BarPlot.Bar(p.Results.group, p.Results.label, p.Unmatched);
            b.value = p.Results.value;
            b.MarkerSize = p.Results.MarkerSize;
            b.MarkerLineWidth = p.Results.MarkerLineWidth;
            b.MarkerFaceColor = p.Results.MarkerFaceColor;
            b.MarkerEdgeColor = p.Results.MarkerEdgeColor;
            b.ErrorColor = p.Results.ErrorColor;
            b.ErrorLineWidth = p.Results.ErrorLineWidth;
             
            if ~isempty(p.Results.confInt)
                b.confLow = min(p.Results.confInt);
                b.confHigh = max(p.Results.confInt);
            else
                b.confLow = p.Results.confLow;
                b.confHigh = p.Results.confHigh;
            end
        end
    end
        
    methods
        function name = getComponentsCollectionName(b)
            name = sprintf('BarPlot_pointCIComps_%s', b.guid);
        end
        
        function v = getHeightRelativeToBaseline(b)
            v = abs(b.value - b.baseline);
        end

        function tf = getIsAboveBaseline(b)
            tf = b.value > b.baseline;
        end

        function val = getMaxExtent(b)
            val = b.confHigh;
            if isempty(val)
                val = b.value;
            end
        end

        function val = getMinExtent(b)
            val = b.confLow;
            if isempty(val)
                val = b.value;
            end
        end
    end
    
    methods(Access={?BarPlot.Bar,?BarPlot.BarGroup})
        function [hStackBelowBaseline, hStackAboveBaseline] = renderInternal(b, axh, aa, xLeft)
            % determine actual error limits
            confHigh = b.maxExtent; %#ok<*PROPLC>
            confLow = b.minExtent;

            xc = xLeft;
            % collection to use for components of bars
            barCompsName = b.getComponentsCollectionName();
            
            % draw bar
            if isnan(b.value)
                warning('Skipping bar %s with NaN value', b.label);
                hMarker = gobjects(0, 1);
            elseif(b.value ~= b.group.baseline)
                hMarker = plot(xc, b.value, 'o', Parent=axh, ...
                    MarkerSize=b.MarkerSize, MarkerFaceColor=b.MarkerFaceColor, ...
                    MarkerEdgeColor=b.MarkerEdgeColor, LineWidth=b.MarkerLineWidth);
                aa.addHandlesToCollection(barCompsName, hMarker);
            else
                hMarker = gobjects(0, 1);
            end
            
            % draw error
            if confHigh ~= confLow
                hError = line([xc xc], [confLow confHigh], 'LineWidth', b.ErrorLineWidth, ...
                    'Parent', axh, 'Color', b.ErrorColor);
                hasbehavior(hError, 'legend', false);
                aa.addHandlesToCollection(barCompsName, hError);
            else
                hError = gobjects(0, 1);
            end
            
            hStackBelowBaseline = hMarker;
            hStackAboveBaseline = hError;
        end
    end
end

