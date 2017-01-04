function move_to_base_workspace(variable)

% move_to_base_workspace(variable)
%
% Move variable from function workspace to base MATLAB workspace so
% user will have access to it after the program ends.
%
% From Intan Technologies

variable_name = inputname(1);
assignin('base', variable_name, variable);

return
