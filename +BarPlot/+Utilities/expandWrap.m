function map = expandWrap(map, n)
    if isa(map, 'function_handle')
        map = map(n);
    else
        if ischar(map)
            map = {map};
        end
        if size(map, 1) < n
            % make at least big enough
            map = repmat(map, ceil(n / size(map, 1)), 1);
            % cut it down to size (typically not necessary)
            map = map(1:n, :);
        end
    end
end