function s = plural(n)
% s = plural(n)
% 
% Utility function to optionally plurailze words based on the value
% of n.
%
% From Intan Technologies

if (n == 1)
    s = '';
else
    s = 's';
end

return

