classdef ViolinBar < BarPlot.Bar
% function to plot bar plots with error bars

    properties
        values
        bandwidth
        support
        
        FaceColor
        EdgeColor
        
        locationType = 'median' % can be cell array of multiples, scalar quantile values, 'mean', or 'median'
        LocationLineWidth
        LocationLineColor
        LocationLineStyle
    end

    methods(Access={?BarPlot,?BarPlot.BarGroup})
        function b = ViolinBar(varargin)
            p = inputParser();
            % redundant ways of specifying interval
            p.addRequired('group', @(g) isa(g, 'BarPlot.BarGroup'));
            p.addRequired('label', @ischar);
            p.addRequired('values', @isvector);
            
            p.addParameter('bandwidth', [], @(x) isempty(x) || isscalar(x));
            p.addParameter('support', 'unbounded', @(x) isvector(x) || ischar(x));
            
            % appearance
            p.addParameter('FaceColor', [0.5 0.5 0.5], @(x) true);
            p.addParameter('EdgeColor', 'none', @(x) true);
            
            p.addParameter('locationType', 'mean', @(x) ischar(x) || iscell(x));
            p.addParameter('LocationLineWidth', 1, @isvector); % in points
            p.addParameter('LocationLineColor', 'k', @(x) true);
            p.addParameter('LocationLineStyle', '-', @isvector);
            
            p.CaseSensitive = false;
            p.KeepUnmatched = true;
            p.parse(varargin{:});
            
            b@BarPlot.Bar(p.Results.group, p.Results.label, p.Unmatched);
            
            b.values = p.Results.values;
            b.locationType = p.Results.locationType;
            b.LocationLineWidth = p.Results.LocationLineWidth;
            b.LocationLineColor = p.Results.LocationLineColor;
            b.LocationLineStyle = p.Results.LocationLineStyle;
            
            b.bandwidth = p.Results.bandwidth;
            b.support = p.Results.support;
            
            b.FaceColor = p.Results.FaceColor;
            b.EdgeColor = p.Results.EdgeColor;
        end
    end
        
    methods
        function name = getComponentsCollectionName(b)
            name = sprintf('BarPlot_barComps_%s', b.guid);
        end

        function tf = getIsAboveBaseline(b)
            tf = nanmedian(b.values) > b.baseline;
        end

        function val = getMaxExtent(b)
            val = nanmax(b.values);
        end

        function val = getMinExtent(b)
            val = nanmin(b.values);
        end
        
        function v = getHeightRelativeToBaseline(b)
            if b.above
                v = max(b.values - b.baseline);
            else
                v = -min(b.values - b.baseline);
            end
        end
    end
    
    methods(Access={?BarPlot.Bar,?BarPlot.BarGroup})
        function [hStackBelowBaseline, hStackAboveBaseline] = renderInternal(b, axh, aa, xLeft)
            % collection to use for components of bars
            barCompsName = b.getComponentsCollectionName();
            
            % draw bar
            Y = b.values;
            
            if strcmp(b.support, 'minmax')
                support = [nanmin(Y) - eps(nanmin(Y)), nanmax(Y) + eps(nanmax(Y))]; %#ok<*PROPLC>
            else
                support = b.support;
            end
            if ~isempty(b.bandwidth)
                [f, xi]=ksdensity(Y,'bandwidth', b.bandwidth, 'support', support);
            else
                [f, xi]=ksdensity(Y, 'support', support);
            end

            xCenter = xLeft + b.Width/2;
            f=f/max(f)*b.Width/2; %normalize
      
            f = f';
            xi = xi';
            hViolin = fill([f+xCenter; flipud(xCenter-f)], [xi; flipud(xi)], b.FaceColor, ...
                'EdgeColor', b.FaceColor);
            aa.addHandlesToCollection(barCompsName, hViolin);
            
            hStackBelowBaseline = hViolin;
            
            if ischar(b.locationType)
                types = {b.locationType};
            elseif isscalar(b.locationType) && isnumeric(b.locationType)
                types = num2cell(b.locationType);
            else
                types = b.locationType;
            end
            
            % draw horizontal location lines
            nTypes = numel(types);
            fc = BarPlot.Utilities.expandWrapColormap(b.LocationLineColor, nTypes);
            lw = BarPlot.Utilities.expandWrap(b.LocationLineWidth, nTypes);
            ls = BarPlot.Utilities.expandWrap(b.LocationLineStyle, nTypes);
            
            h = gobjects(nTypes, 1);
            for iM = 1:nTypes
                if ischar(types{iM}) 
                    switch types{iM}
                        case 'median'
                            v = nanmedian(Y);
                        case 'mean'
                            v = nanmean(Y);
                        otherwise
                            error('Unknown locationType %s', types{iM});
                    end
                else
                    v = quantile(Y, types{iM});
                end
                h(iM) = line(xLeft +  [0 b.Width], [v v], 'LineStyle', ls{iM}, ...
                    'LineWidth', lw(iM), 'Color', fc(iM, :));
            end
            
            aa.addHandlesToCollection(barCompsName, hViolin);
            hStackAboveBaseline = h;
        end
    end
end

