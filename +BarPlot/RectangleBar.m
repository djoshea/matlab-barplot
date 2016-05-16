classdef RectangleBar < BarPlot.Bar
% function to plot bar plots with error bars

    properties
        value
        
        error
        errorLow
        errorHigh
        confHigh
        confLow
        
        FaceColor
        EdgeColor
        
        ErrorLineWidth
        ErrorColor
    end
    
    methods(Access={?BarPlot,?BarPlot.BarGroup})
        function b = RectangleBar(varargin)
            p = inputParser();
            % redundant ways of specifying interval
            p.addRequired('group', @(g) isa(g, 'BarPlot.BarGroup'));
            p.addRequired('label', @ischar);
            p.addRequired('value', @isscalar);
            
            p.addParameter('confInt', [], @(x) isempty(x) || isvector(x));
            p.addParameter('confLow', [], @(x) isempty(x) || isscalar(x));
            p.addParameter('confHigh', [], @(x) isempty(x) || isscalar(x));
            p.addParameter('errorLow', [], @(x) isempty(x) || isscalar(x));
            p.addParameter('errorHigh', [], @(x) isempty(x) || isscalar(x));
            p.addParameter('error', [], @(x) isempty(x) || isscalar(x));
            
            % appearance
            p.addParameter('ErrorLineWidth', 3, @isscalar); % in points
            p.addParameter('FaceColor', [0.5 0.5 0.5], @(x) true);
            p.addParameter('EdgeColor', 'none', @(x) true);
            p.addParameter('ErrorColor', [0.4 0.4 0.4], @(x) true);
            
            p.CaseSensitive = false;
            p.KeepUnmatched = true;
            p.parse(varargin{:});
            
            b@BarPlot.Bar(p.Results.group, p.Results.label, p.Unmatched);
            b.value = p.Results.value;
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
        end
    end
        
    methods
        function name = getComponentsCollectionName(b)
            name = sprintf('BarPlot_barComps_%s', b.guid);
        end
        
        function v = getHeightRelativeToBaseline(b)
            v = abs(b.value - b.baseline);
        end

        function tf = getIsAboveBaseline(b)
            tf = b.value > b.baseline;
        end

        function val = getMaxExtent(b)
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

        function val = getMinExtent(b)
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
    
    methods(Access={?BarPlot.Bar,?BarPlot.BarGroup})
        function [hStackBelowBaseline, hStackAboveBaseline] = renderInternal(b, axh, aa, xLeft)
            % determine actual error limits
            confHigh = b.maxExtent; %#ok<*PROPLC>
            confLow = b.minExtent;

            xc = xLeft;
            % collection to use for components of bars
            barCompsName = b.getComponentsCollectionName();
            
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
                hasbehavior(hError, 'legend', false);
                aa.addHandlesToCollection(barCompsName, hError);
            else
                hError = gobjects(0, 1);
            end
            
            hStackBelowBaseline = hBar;
            hStackAboveBaseline = hError;
        end
    end
end

