function demo(varargin)
    p = inputParser();
    p.addParameter('style', 'rectangle', @ischar);
    p.addParameter('ksdensity', true, @islogical);
    p.addParameter('seed', 1, @isscalar);
    p.addParameter('nGroups', 3, @isscalar);
    p.addParameter('nBars', 6, @isscalar);
    p.addParameter('labelRotation', 0, @isscalar);
    p.addParameter('labelAlignment', 'center', @ischar);
    p.addParameter('nBridgesWithin', 3, @isscalar);
    p.addParameter('nBridgesSpanning', 3, @isscalar);
    p.addParameter('allPositive', true, @islogical);
    p.addParameter('confidenceIntervals', false, @islogical);
    p.addParameter('avoidAdjacentBridges', false, @islogical);
    p.addParameter('bridgeTickLength', 0.1, @isscalar); % in mm, can be 0
    p.addParameter('bridgesExtendToBars', false, @islogical); 
    p.parse(varargin{:});

    s = RandStream('mt19937ar','Seed', p.Results.seed);
    RandStream.setGlobalStream(s);

    clf;
    bp = BarPlot('ylabel', 'Value');

    G = p.Results.nGroups;
    B = p.Results.nBars;

    cmap = parula(B);

    for iG = 1:G
        g = bp.addGroup(sprintf('Group %d', iG));
        for iB = 1:B
            barArgsCommon = {'FaceColor', cmap(iB, :), ...
                'LabelRotation', p.Results.labelRotation, ...
                'HorizontalAlignment', p.Results.labelAlignment};
            
            if strcmp(p.Results.style, 'rectangle')
                v = 10*randn;
                if p.Results.allPositive
                    v = abs(v);
                end
                if ~p.Results.confidenceIntervals
                    % draw error away from baseline
                    errorArgs =  {'error', abs(2*randn)};
                else
                    % draw full interval error
                    errorArgs = {'errorHigh', abs(2*randn), 'errorLow', abs(2*randn)};
                end
                g.addBar(sprintf('Bar %d', iB), v, 'labelAbove', sprintf('%.1f', v), ...
                    errorArgs{:}, barArgsCommon{:});
                
            elseif strcmp(p.Results.style, 'violin')
                v = 10*randn + 2*randn(100, 1);
                if p.Results.allPositive
                    v = abs(v);
                end
                if p.Results.ksdensity
                    g.addViolinBar(sprintf('Bar %d', iB), v, 'locationType', 'median', 'style', 'ksdensity', barArgsCommon{:});
                else
                    g.addViolinBar(sprintf('Bar %d', iB), v, 'locationType', 'median', 'style', 'histogram', 'binWidth', 0.2, barArgsCommon{:});
                end
            end
        end

        % draw random subset of bridges
        [I, J] = ndgrid(1:B, 1:B);
        eligMat = J > I;
        
        for n = 1:p.Results.nBridgesWithin
            if ~any(eligMat(:))
                break;
            end
            idxElig = find(eligMat(:));
            idx = randsample(idxElig, 1);
            [i, j] = ind2sub(size(eligMat), idx);
            eligMat(i, j) = false;
            g.addBridge(repmat('*', 1, min(4, j-i+1)), g.bars(i), g.bars(j), ...
                'tickLength', p.Results.bridgeTickLength, 'avoidAdjacentBridges', p.Results.avoidAdjacentBridges, ...
                'FontSize', 6, 'extendToBars', p.Results.bridgesExtendToBars);
        end
    end

    % draw random subset of spanning bridges
    [allBars, groupIdx] = bp.getAllBars();
    N = numel(allBars);
    [I, J] = ndgrid(1:N, 1:N);
    eligMat = groupIdx(I) ~= groupIdx(J);

    for n = 1:p.Results.nBridgesSpanning
        if ~any(eligMat)
            break;
        end
        idxElig = find(eligMat(:));
        idx = randsample(idxElig, 1);
        [i, j] = ind2sub(size(eligMat), idx);
        eligMat(i, j) = false;
        bp.addBridge('**', allBars(i), allBars(j), ...
            'tickLength', p.Results.bridgeTickLength, 'avoidAdjacentBridges', p.Results.avoidAdjacentBridges, ...
            'FontSize', 6, 'extendToBars', p.Results.bridgesExtendToBars);
    end

    bp.render();

    ax = AutoAxis(gca);
    ax.gridOn('y', 'yMinor', true);
    ax.update();
end
