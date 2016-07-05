classdef BarGroup < handle
    properties
        FontName
        FontWeight
        FontSize
        FontColor
        
        baseline
        baselineColor 
        baselineLineWidth
        
        baselineOverhang
        barGap
        name
    end
    
    properties(SetAccess=protected)
        barPlot
        bars
        bridges
    end
    
    properties(SetAccess=protected)
        guid
    end
    
    methods
        function g = BarGroup(name, varargin)
            ff = get(0, 'DefaultAxesFontName');
            sz = get(0, 'DefaultAxesFontSize');
            tc = get(0, 'DefaultTextColor');
            
            p = inputParser();
            p.addRequired('barPlot', @(bp) isa(bp, 'BarPlot'));
            p.addParameter('FontName', ff, @ischar);
            p.addParameter('FontWeight', 'bold', @ischar);
            p.addParameter('FontSize', sz, @isscalar);
            p.addParameter('FontColor', tc, @(x) true);
            p.addParameter('baseline', 0, @(x) isempty(x) || isscalar(x));
            p.addParameter('baselineColor', [0.2 0.2 0.2], @(x) true);
            p.addParameter('baselineLineWidth', 0.5, @isscalar);
            p.addParameter('baselineOverhang', 0.15, @isscalar);
            p.addParameter('barGap', 0.2, @isscalar);
            p.CaseSensitive = false;
            p.parse(varargin{:});
            
            g.name = name;
            g.barPlot = p.Results.barPlot;
            
            g.FontName = p.Results.FontName;
            g.FontWeight = p.Results.FontWeight;
            g.FontSize = p.Results.FontSize;
            g.FontColor = p.Results.FontColor;
           
            g.baseline = p.Results.baseline;
            g.baselineLineWidth = p.Results.baselineLineWidth;
            g.baselineColor = p.Results.baselineColor;
            g.baselineOverhang = p.Results.baselineOverhang;
            g.barGap = p.Results.barGap;
            
            b.guid = num2str(matlab.internal.timing.timing('cpucount'));
        end
        
        function b = addBar(g, label, value, varargin)
            b = BarPlot.RectangleBar(g, label, value, varargin{:});
            if isempty(g.bars)
                g.bars = b;
            else
                g.bars(end+1, 1) = b;
            end
        end
        
        function b = addViolinBar(g, label, values, varargin)
            b = BarPlot.ViolinBar(g, label, values, varargin{:});
            if isempty(g.bars)
                g.bars = b;
            else
                g.bars(end+1, 1) = b;
            end
        end
        
        function br = addBridge(g, label, bar1, bar2, varargin)
            assert(ismember(bar1, g.bars), 'Bar 1 not found within group, call addBridge on BarPlot root instead');
            assert(ismember(bar2, g.bars), 'Bar 2 not found within group, call addBridge on BarPlot root instead');
            
            br = BarPlot.Bridge(label, bar1, bar2, g, varargin{:});
            if isempty(g.bridges)
                g.bridges = br;
            else
                g.bridges(end+1, 1) = br;
            end
        end  
    end
       
    methods(Access=?BarPlot)
        function [xRight, barCenters] = render(g, axh, aa, xLeft)
            import AutoAxis.PositionType;
            xc = xLeft + g.baselineOverhang;
            barCenters = nan(numel(g.bars), 1);
            
            % render bars
            [hStackBelowBaseline, hStackAboveBaseline] = deal(cell(numel(g.bars)));
            for i = 1:numel(g.bars)
                [hStackBelowBaseline{i}, hStackAboveBaseline{i}] = g.bars(i).render(axh, aa, xc);
                barCenters(i) = xc + g.bars(i).Width / 2;
                xc = xc + g.bars(i).Width;
                xc = xc + g.barGap;
            end
            hStackBelowBaseline = cat(1, hStackBelowBaseline{:});
            hStackAboveBaseline = cat(1, hStackAboveBaseline{:});
            xRight = xc + g.baselineOverhang;
            xCenter = mean([xLeft, xRight]);
            
             % add baseline
            if ~isempty(g.baseline) && ~isnan(g.baseline)
                hBaseline = line([xLeft xRight], [g.baseline g.baseline], ...
                'LineWidth', g.baselineLineWidth, 'Parent', axh, ...
                'Color', g.baselineColor);
                
                % place baseline below error interval but above bars
                if ~isempty(hStackAboveBaseline)
                    uistack(hStackAboveBaseline, 'bottom');
                end
                uistack(hBaseline, 'bottom');
                if ~isempty(hStackBelowBaseline)
                    uistack(hStackBelowBaseline, 'bottom')
                end
            end
            
            % add group label
            if ~isempty(g.name)
                hText = text(xCenter, 0, ...
                    g.name, 'Parent', axh, ...
                    'Color', g.FontColor, 'FontWeight', g.FontWeight, ...
                    'FontSize', g.FontSize, 'FontName', g.FontName, ...
                    'VerticalAlignment', 'top', 'HorizontalAlignment', 'center', 'Background', 'none');
   
                a = AutoAxis.AnchorInfo(hText, PositionType.Top, 'BarPlot_barLabels', PositionType.Bottom, ...
                    'tickLabelOffset', 'BarPlot: anchor group label below all bar labels');
                aa.addAnchor(a);
                
                aa.addHandlesToCollection('BarPlot_groupLabels', hText); 
            end
            
            % draw bridges
            if numel(g.bridges) > 0
                % sort them in order such that smaller bridges come first
                % and bridges that span them come later
                [belowBr, aboveBr] = g.sortBridges();
                
                for dir = 1:2
                    above = dir == 1;
                    if above
                        list = aboveBr;
                    else
                        list = belowBr;
                    end
                        
                    for i = 1:numel(list)
                        prev = list(1:i-1);
                        br = list(i);
                        % find bridges that this bridge should avoid
                        bridgesAvoid = g.findBridgesToAvoid(br, prev);
                        bridgeCollections = arrayfun(@(br) br.getComponentsCollectionName(), bridgesAvoid, 'UniformOutput', false);

                        % find bars whose components this bridge should avoid
                        [barsSpanned, id1, id2] = g.findBarsInBridgeSpan(br);
                        barCollections = arrayfun(@(bar) bar.getComponentsCollectionName(), barsSpanned, 'UniformOutput', false);

                        % render the bridge
                        hLine = br.render(axh, aa, barCenters(id1), barCenters(id2));

                        collections = cat(1, bridgeCollections, barCollections);
                        if above
                            a = AutoAxis.AnchorInfo(hLine, PositionType.Bottom, collections, ...
                                PositionType.Top, br.offset, ...
                                'BarPlot: anchor bridge line to top of spanned bars');
                        else
                            a = AutoAxis.AnchorInfo(hLine, PositionType.Top, collections, ...
                                PositionType.Bottom, br.offset, ...
                                'BarPlot: anchor bridge line to bottom of spanned bars');
                        end
                        if br.extendToBars
                            a.applyToPointsWithinLine = [2 3];
                            a.margin = 0.05+br.tickLength;
                        end;
                        
                        aa.addAnchor(a);
                    end
                end
            end
        end
        
        function str = getBarLabelsCollectionName(g)
            str = sprintf('BarPlot_groupBarLabels_%s', g.guid);
        end
        
        function idx = findBarInGroup(g, bar)
            idx = find(bar == g.bars);
        end
    end

    methods(Access=protected)
        function [idLeft, idRight, id1, id2] = getBridgeBarSpanIdx(g, bridges)
            findBar = @(b) find(b == g.bars);
            id1 = arrayfun(findBar, cat(1, bridges.bar1));
            id2 = arrayfun(findBar, cat(1, bridges.bar2));
            idLeft = min(id1, id2);
            idRight = max(id1, id2);
        end

        function [belowBr, aboveBr] = sortBridges(g)
            [idLeft, idRight] = g.getBridgeBarSpanIdx(g.bridges);
            above = cat(1, g.bridges.above);
            idxAbove = find(above);
            idxBelow = find(~above);
            
            idxAbove = sortBySpan(idxAbove);
            idxBelow = sortBySpan(idxBelow);
            
            aboveBr = g.bridges(idxAbove);
            belowBr = g.bridges(idxBelow);
            
            function idx = sortBySpan(idx)
                span =  idRight(idx)- idLeft(idx);
                [~, sortOrder] = sort(span);
                idx = idx(sortOrder);
            end
        end
        
        function [bars, id1, id2] = findBarsInBridgeSpan(g, br)
            [idLeft, idRight, id1, id2] = g.getBridgeBarSpanIdx(br);
            bars = g.bars(idLeft:idRight);
        end

        function brAvoid = findBridgesToAvoid(g, br, prev)
            [prevLeft, prevRight] = g.getBridgeBarSpanIdx(prev);
            [myLeft, myRight] = g.getBridgeBarSpanIdx(br);
            if br.avoidAdjacentBridges
                mask = ~(prevRight < myLeft | prevLeft > myRight);
            else
                mask = ~(prevRight <= myLeft | prevLeft >= myRight);
            end
            brAvoid = prev(mask);
        end
    end
end
