## figs = run_code_and_save_figures (code, options)
##
## Evaluate code and save generated figures to options.output_dir.
##
## The following options with their default values are supported.
##
##   options.output_dir = "./output";
##   options.ignore_errors = false;
##
## Returns a cell array of strings with files written to options.output_dir.

function figs = run_code_and_save_figures (code, options)

if (! ischar (code))
  print_usage ();
endif

if (nargin == 1)
  options.output_dir = "./output";
  options.ignore_errors = false;
endif
options = validate_options (options);

figs = {};

## Create output directory.
[status, msg] = mkdir (options.output_dir);
if (status != 1)
  error ("run_code_and_save_figures: Cannot create output directory '%s'.", ...
         msg);
endif

## No screen output, as the code does not run interactively.
page_screen_output (false, "local");

## Remember previously opened figures.
fig_ids = findall (0, "type", "figure");

## Create a new figure, if there are existing plots.
if (! isempty (fig_ids))
  figure ();
endif

# Evaluate code.
if (options.ignore_errors)
  s = evalc (code, "");
else
  s = evalc (code);
endif
clear s;

## Check for newly created figures ...
fig_ids_new = setdiff (findall (0, "type", "figure"), fig_ids);
## ... and save them
for j = 1:numel (fig_ids_new)
  drawnow ();
  if (isempty (get (fig_ids_new(j), "children")))
    continue;
  endif
  file_name = sprintf ("%s.png", hash ("sha256", [code, char(j)]));
  file_path = fullfile (options.output_dir, file_name);
  print (fig_ids_new(j), file_path, "-dpng", "-color");
  delete (fig_ids_new(j));
  figs{end+1} = file_name;
endfor

endfunction


function options = validate_options (options)
  if (! isstruct (options))
    error ("options must be a struct");
  endif
  if (isfield (options, "ignore_errors"))
    if (! islogical (options.ignore_errors))
      error ("options.ignore_errors must be a logical value");
    endif
  else
    options.ignore_errors = false;
  endif
  if (isfield (options, "output_dir"))
    if (! (ischar (options.output_dir)))
      error ("options.output_dir must be character string");
    endif
  else
    options.output_dir = "./output";
  endif
endfunction

