classdef ViolinBar < BarPlot.Bar
% function to plot bar plots with error bars

    properties
        values
        
        style
        
        % for histogram
        useStairs
        binEdges
        binWidth
        
        % for ksdensity
        bandwidth
        support
        trimQuantiles
        trimQuantileMultiplier
        
        % for histogram style=
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
            
            p.addParameter('style', 'ksdensity', @(s) any(validatestring(s, {'ksdensity','histogram'},'ViolinBar','style'))); % ksdensity or histogram
            
            % for histogram
            p.addParameter('binEdges', [], @isvector);
            p.addParameter('useStairs', true, @islogical); % draw histogram
            p.addParameter('binWidth', [], @(x) isempty(x) || isscalar(x));
            
            % for ksdensity
            p.addParameter('bandwidth', [], @(x) isempty(x) || isscalar(x));
            p.addParameter('support', 'unbounded', @(x) isvector(x) || ischar(x));
            p.addParameter('trimQuantiles', [], @(x) isempty(x) || isvector(x) || isscalar(x)); % trim the original data to the central X% by quantile to eliminate long tails in the ks density
            p.addParameter('trimQuantileMultiplier', 1, @isscalar); 
            
            % appearance
            p.addParameter('FaceColor', [0.5 0.5 0.5], @(x) true);
            p.addParameter('EdgeColor', 'none', @(x) true);
            
            p.addParameter('locationType', 'median', @(x) ischar(x) || iscell(x));
            p.addParameter('LocationLineWidth', 1, @isvector); % in points
            p.addParameter('LocationLineColor', 'k', @(x) true);
            p.addParameter('LocationLineStyle', '-', @isvector);
            
            p.CaseSensitive = false;
            p.KeepUnmatched = true;
            p.parse(varargin{:});
            
            b@BarPlot.Bar(p.Results.group, p.Results.label, p.Unmatched);
            
            b.values = p.Results.values;
            
            b.style = p.Results.style;
            b.bandwidth = p.Results.bandwidth;
            b.support = p.Results.support;
            
            trimQuantiles = p.Results.trimQuantiles;
            if isscalar(trimQuantiles)
                % cover this fraction of the central range
                alpha = (1 - trimQuantiles)/2;
                b.trimQuantiles = [alpha, 1 - alpha];
            elseif numel(trimQuantiles) == 2
                b.trimQuantiles = trimQuantiles(:)';
            else
                b.trimQuantiles = [];
            end
            b.trimQuantileMultiplier = p.Results.trimQuantileMultiplier;
            
            b.binEdges = p.Results.binEdges;
            if isempty(b.binEdges)
                b.binWidth = p.Results.binWidth;
            end
            b.useStairs = p.Results.useStairs;
            
            b.locationType = p.Results.locationType;
            b.LocationLineWidth = p.Results.LocationLineWidth;
            b.LocationLineColor = p.Results.LocationLineColor;
            b.LocationLineStyle = p.Results.LocationLineStyle;
            
            b.FaceColor = p.Results.FaceColor;
            b.EdgeColor = p.Results.EdgeColor;
        end
    end
        
    methods
        function name = getComponentsCollectionName(b)
            name = sprintf('BarPlot_barComps_%s', b.guid);
        end

        function tf = getIsAboveBaseline(b)
            tf = median(b.values, 'omitnan') > b.baseline;
        end

        function val = getMaxExtent(b)
            valmax = max(b.values, [], 'omitnan');
            if ~isempty(b.trimQuantiles)
                val = min(quantile(b.values, b.trimQuantiles(2)) * b.trimQuantileMultiplier, valmax);
            else
                val = valmax;
            end
        end

        function val = getMinExtent(b)
            valmin = min(b.values, [], 'omitnan');
            if ~isempty(b.trimQuantiles)
                val = max(quantile(b.values, b.trimQuantiles(1)) * b.trimQuantileMultiplier, valmin);
            else
                val = valmin;
            end
        end
        
        function v = getHeightRelativeToBaseline(b)
            if b.above
                v = b.getMaxExtent() - b.baseline;
            else
                v = -(b.getMinExtent() - b.baseline);
            end
        end
    end
    
    methods(Access={?BarPlot.Bar,?BarPlot.BarGroup})
        function [hStackBelowBaseline, hStackAboveBaseline] = renderInternal(b, axh, aa, xLeft) %#ok<INUSL>
            % collection to use for components of bars
            barCompsName = b.getComponentsCollectionName();
            
            % draw bar
            V = b.values;
            minV = min(V, [], 'omitnan');
            maxV = max(V, [], 'omitnan');
            
            xCenter = xLeft + b.Width/2;
            
            if strcmp(b.style, 'ksdensity')
                if strcmp(b.support, 'minmax')
                    support = [minV - eps(minV), maxV + eps(maxV)]; %#ok<*PROPLC>
                else
                    support = b.support;
                end
                if ~isempty(b.bandwidth)
                    [f, xi]=ksdensity(V,'bandwidth', b.bandwidth, 'support', support);
                else
                    [f, xi]=ksdensity(V, 'support', support);
                end
                
                if ~isempty(b.trimQuantiles)
                    med = median(V, 'omitnan');
                    vals = quantile(V, b.trimQuantiles);
                    % expand the quantiles away from the median if requested (trimQuantileMultiplier > 1)
                    vals(1) = (vals(1) - med) * b.trimQuantileMultiplier + med;
                    vals(2) = (vals(2) - med) * b.trimQuantileMultiplier + med;
                    mask = xi < vals(1) | xi > vals(2);
                    f(mask) = [];
                    xi(mask) = [];
                end
                
                f = f';
                xi = xi';
                
                f=f/max(f)*b.Width/2; %normalize
                XX = [f+xCenter; flipud(xCenter-f)];
                YY = [xi; flipud(xi)];
                
            elseif strcmp(b.style, 'histogram')
                if isempty(b.binEdges)
                    if isempty(b.binWidth)
                        [f, edges] = histcounts(Y);
                    else
                        [f, edges] = histcounts(Y, 'BinWidth', b.binWidth);
                    end
                else
                    [f, edges] = histcounts(Y, b.binEdges);
                end
                
                f = f';
                edges = edges';
                f=f/max(f)*b.Width/2; %normalize
                
                % strip 0s from above and below so that the histograms only
                % extend as far as the distribution's support
                idx1 = find(f > 0, 1, 'first');
                if idx1 > 0
                    f = f(idx1:end);
                    edges = edges(idx1:end);
                end
                nTrail = numel(f) - find(f > 0, 1, 'last');
                if nTrail > 0
                    f = f(1:end-nTrail);
                    edges = edges(1:end-nTrail);
                end
                
                if ~isempty(f)
                    if b.useStairs
                        [yo, xo] = stairs(edges, [f; f(end)]);
                        XX = [xo+xCenter; flipud(xCenter-xo)];
                        YY = [yo; flipud(yo)];
                    else
                        xi = mean([edges(1:end-1) edges(2:end)], 2);
                        XX = [f+xCenter; flipud(xCenter-f)];
                        YY = [xi; flipud(xi)];
                    end
                end
            end

            if ~isempty(f)
                hViolin = fill(XX, YY, b.FaceColor, ...
                    'EdgeColor', b.FaceColor);
                aa.addHandlesToCollection(barCompsName, hViolin);

                hStackBelowBaseline = hViolin;
            else
                hStackBelowBaseline = gobjects(0, 1);
            end
            
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
                            v = median(V, 'omitnan');
                        case 'mean'
                            v = mean(V, 'omitnan');
                        case 'none'
                            v = NaN;
                        otherwise
                            error('Unknown locationType %s', types{iM});
                    end
                else
                    v = quantile(Y, types{iM});
                end
                if ~isnan(v)
                    h(iM) = line(xLeft +  [0 b.Width], [v v], 'LineStyle', ls{iM}, ...
                        'LineWidth', lw(iM), 'Color', fc(iM, :));
                end
            end
            
            aa.addHandlesToCollection(barCompsName, hViolin);
            hStackAboveBaseline = h;
        end
    end
end

