classdef BarPlot < handle
% function to plot bar plots with error bars

    properties
        ylabel
        groupGap = 1;
    end
        
    properties(SetAccess=protected)
        groups
        bridges
    end
        
    methods
        function bp = BarPlot(varargin)
            p = inputParser();
            p.addParameter('groupGap', 1, @isscalar);
            p.addParameter('ylabel', '', @isstringlike);
            p.parse(varargin{:});
            
            bp.ylabel = p.Results.ylabel;
            bp.groupGap = p.Results.groupGap;
        end
    end
    
    methods
        function g = addGroup(bp, name, varargin)
            g = BarPlot.BarGroup(name, bp, varargin{:});
            if isempty(bp.groups)
                bp.groups = g;
            else
                bp.groups(end+1, 1) = g;
            end
        end

        function br = addBridge(bp, label, bar1, bar2, varargin)
            % add spanning bridge
            g1 = bar1.group;
            g2 = bar2.group;
            if g1 == g2
                % within group, just defer to that group
                br = g1.addBridge(label, bar1, bar2, varargin{:});
                return
            end

            assert(ismember(g1, bp.groups));
            assert(ismember(g2, bp.groups));
            
            br = BarPlot.Bridge(label, bar1, bar2, bp, varargin{:});
            if isempty(bp.bridges)
                bp.bridges = br;
            else
                bp.bridges(end+1, 1) = br;
            end
        end  
        
        function xRight = render(bp, xLeft)
            if nargin < 2
                xLeft = 0;
            end
            xc = xLeft;
            axh = gca;
            aa = AutoAxis(axh);
            hold(axh, 'on');
            
            allBars = bp.getAllBars();
            allBarCenters = nan(numel(allBars), 1);
            barOffset = 0;
            for i = 1:numel(bp.groups)
                [xc, barCenters] = bp.groups(i).render(axh, aa, xc);
                xc = xc + bp.groupGap;
                allBarCenters(barOffset + (1:numel(barCenters))) = barCenters;
                barOffset = barOffset + numel(barCenters);
            end
            
            xRight = xc - bp.groupGap;

            % render bridges not owned by any group
            if numel(bp.bridges) > 0
                % sort them in order such that smaller bridges come first
                % and bridges that span them come later
                [belowBr, aboveBr] = bp.sortBridges();
                import AutoAxis.PositionType;
                
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
                        bridgesAvoid = bp.findBridgesToAvoid(br, prev);
                        bridgeCollections = arrayfun(@(br) br.getComponentsCollectionName(), bridgesAvoid, 'UniformOutput', false);

                        % find bars whose components this bridge should avoid
                        [barsSpanned, id1, id2] = bp.findBarsInBridgeSpan(br);
                        barCollections = arrayfun(@(bar) bar.getComponentsCollectionName(), barsSpanned, 'UniformOutput', false);

                        % render the bridge
                        hLine = br.render(axh, aa, allBarCenters(id1), allBarCenters(id2));

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
                            a.margin = 0.15+br.tickLength;
                        end;
                        aa.addAnchor(a);
                    end
                end
            end
            
            import AutoAxis.PositionType;
            a = AutoAxis.AnchorInfo('BarPlot_barLabels', PositionType.Top, axh, ...
                PositionType.Bottom, 'tickLabelOffset', ...
                'BarPlot: anchor bar labels to bottom of axis');
            aa.addAnchor(a);
            
            a = AutoAxis.AnchorInfo('BarPlot_groupLabels', PositionType.Top, 'BarPlot_barLabels', ...
                PositionType.Bottom, 'tickLabelOffset', ...
                'BarPlot: anchor group labels to bottom of bar labels');
            aa.addAnchor(a);
            aa.ylabel(bp.ylabel);
            aa.addAutoAxisY();
            set(axh, 'XTick', allBarCenters); % in case grid is used
            set(axh, 'XMinorTick', 'off'); % in case grid is used
            set(axh, 'XTickLabels', repmat({''}, numel(allBarCenters), 1));
            
            if xRight > xLeft
                xlim([xLeft xRight]);
            end
            aa.update();
            hold(axh, 'off');
        end

        function [allBars, groupIdx] = getAllBars(bp)
            bars = arrayfun(@(g) g.bars, bp.groups, 'UniformOutput', false);
            allBars = cat(1, bars{:});
            if nargout > 1
                nBarsByGroup = cellfun(@numel, bars);
                groupIdx = arrayfun(@(iG, n) repmat(iG, n, 1), (1:numel(bp.groups))', nBarsByGroup, 'UniformOutput', false);
                groupIdx = cat(1, groupIdx{:});
            end
        end
    end

    methods(Access=protected)
        function [idLeft, idRight, id1, id2] = getBridgeBarSpanIdx(bp, bridges)
            allBars = bp.getAllBars();
            findBar = @(b) find(b == allBars);
            id1 = arrayfun(findBar, cat(1, bridges.bar1));
            id2 = arrayfun(findBar, cat(1, bridges.bar2));
            idLeft = min(id1, id2);
            idRight = max(id1, id2);
        end

        function [idLeft, idRight] = getBridgeGroupSpanIdx(bp, bridges)
            % first, avoid all bridges in the groups I span
            findGroup = @(g) find(g == bp.groups);
            id1s = arrayfun(findGroup, cat(1, bridges.bar1.group));
            id2s = arrayfun(findGroup, cat(1, bridges.bar2.group));
            idLeft = min(id1s, id2s);
            idRight = max(id1s, id2s);
        end

        function [belowBr, aboveBr] = sortBridges(bp)
            [idLeft, idRight] = bp.getBridgeBarSpanIdx(bp.bridges);
            above = cat(1, bp.bridges.above);
            idxAbove = find(above);
            idxBelow = find(~above);
            
            idxAbove = sortBySpan(idxAbove);
            idxBelow = sortBySpan(idxBelow);
            
            aboveBr = bp.bridges(idxAbove);
            belowBr = bp.bridges(idxBelow);
            
            function idx = sortBySpan(idx)
                span =  idRight(idx)- idLeft(idx);
                [~, sortOrder] = sort(span);
                idx = idx(sortOrder);
            end
        end
        
        function [bars, id1, id2] = findBarsInBridgeSpan(bp, br)
            allBars = bp.getAllBars();
            [idLeft, idRight, id1, id2] = bp.getBridgeBarSpanIdx(br);
            bars = allBars(idLeft:idRight);
        end

        function brAvoid = findBridgesToAvoid(bp, br, prev)
            [idLeft, idRight] = bp.getBridgeGroupSpanIdx(br);
            brByGroup = arrayfun(@(g) g.bridges, bp.groups(idLeft:idRight), 'UniformOutput', false);
            
            % avoid previously drawn spanning bridges that overlap with me
            [prevLeft, prevRight] = bp.getBridgeBarSpanIdx(prev);
            [myLeft, myRight] = bp.getBridgeBarSpanIdx(br);
            if br.avoidAdjacentBridges
                mask = ~(prevRight < myLeft | prevLeft > myRight);
            else
                mask = ~(prevRight <= myLeft | prevLeft >= myRight);
            end
            brAvoid = prev(mask);

            brAvoid = cat(1, brByGroup{:}, brAvoid);
        end
    end
end

