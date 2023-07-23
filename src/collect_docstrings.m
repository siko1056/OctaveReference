## fcns = collect_docstrings (directory, options)
##
## Collect documentation strings from all functions in a given directory.
##
## The following options with their default values are supported.
##
##   options.max_recursion_depth = inf;  # "0" means no recusion
##   options.ignore_errors = false;
##   options.document_private_functions = false;
##   options.demos_collect_code = true;
##   options.demos_collect_figures = true;
##   options.output_dir = "./output";

function fcns = collect_docstrings (directory, options)

  if (! ischar (directory))
    print_usage ();
  endif

  if (nargin == 1)
    options.max_recursion_depth = inf;
    options.ignore_errors = false;
    options.document_private_functions = false;
    options.demos_collect_code = true;
    options.demos_collect_figures = true;
    options.output_dir = "./output";
  endif
  options = validate_options (options);

  fcns = collect_docstrings_recursive (directory, 0, options);

endfunction


function fcns = collect_docstrings_recursive (directory, recursion_depth, options)

  relative_path = strsplit (directory, filesep ());
  relative_path = strjoin (relative_path(end+(1-recursion_depth):end), ...
    filesep ());

  [items, err, msg] = readdir (directory);
  if (err)
    error ("couldn't read directory %s: %s", dir, msg);
  endif
  items(strcmp (items, ".") | strcmp (items, "..")) = [];

  if (options.document_private_functions)
    recurse_into_directory = @(x) true;
  else
    recurse_into_directory = @(x) ! strcmp (x, "private");
  end

  fcns = {};
  for i = 1:length (items)
    try
      absolute_item_path = strjoin ({directory, items{i}}, filesep ());
      if (recursion_depth)
        relative_item_path = strjoin ({relative_path, items{i}}, filesep ());
      else
        relative_item_path = items{i};
      endif

      if (isfile (absolute_item_path))
        [~, fname, ext] = fileparts (relative_item_path);
        printf ("Parse '%s'.\n", relative_item_path);
        if (strcmp (ext, ".m") || strcmp (ext, ".oct") ...
          || strcmp (ext, [".", mexext()]))
          fcn.name = fname;
          fcn.relative_path = relative_item_path;
          fcn.help_str = get_help_str (absolute_item_path);
          fcn.first_line = first_sentence_plain_text (fcn.help_str);
          fcn.demos = get_demos (absolute_item_path, options)
          fcns = [fcns, fcn];
        else
          warning ("  --> Ignore file '%s'.\n", relative_item_path);
        endif
      elseif (isfolder (absolute_item_path))
        if (recurse_into_directory (items{i}) ...
          && (recursion_depth < options.max_recursion_depth))
          fcns_r = collect_docstrings_recursive (absolute_item_path, ...
            recursion_depth + 1, options);
          fcns = [fcns, fcns_r];
        else
          warning ("  --> Ignore folder '%s'.\n", relative_item_path);
        endif
      else
        warning ("  --> Ignore entry '%s'.\n", relative_item_path);
      endif
    catch err
      if (options.ignore_errors)
        warning ("  --> Ignore error '%s'.\n", err.message);
      else
        rethrow (err);
      endif
    end_try_catch
  endfor

endfunction


function help_str = get_help_str (absolute_file_path)
  [help_str, format] = get_help_text_from_file (absolute_file_path);
  if (strcmp (format, "texinfo"))
    help_str = __makeinfo__ (help_str, "plain text");
  endif
endfunction


function demo_cstr = get_demos (absolute_file_path, options)
  demo_cstr = {};
  if (! options.demos_collect_code)
    return;
  endif
  [code_str, code_idx] = test (absolute_file_path, "grabdemo");
  for i = 1:(length (code_idx) - 1)
    demo_cstr{i}.code = code_str((code_idx(i) + 1):(code_idx(i + 1) - 1));
    if (options.demos_collect_figures)
      demo_cstr{i}.figures = run_code_and_save_figures (demo_cstr{i}.code, ...
                                                        options);
    else
      demo_cstr{i}.figures = {};
    endif
  endfor
endfunction


function text = first_sentence_plain_text (help_text)

  ## Sub-function copied and modified from Octave 8.2.0.

  ## Extract first line by searching for a period followed by whitespace
  ## followed by a capital letter (Nearly the same rule as Texinfo).
  period_idx = regexp (help_text, '\.\s+(?:[A-Z]|\n)', "once");
  ## ... or a double end-of-line (we subtract 1 because we are not interested
  ## in capturing the first newline).
  line_end_idx = regexp (help_text, "\n\n", "once") - 1;
  min_idx = min ([period_idx, line_end_idx, length (help_text)]);
  max_len = 80;
  if (min_idx < max_len)
    text = help_text(1:min_idx);
  else
    text = [help_text(1:(max_len - 3)), "..."];
  endif

endfunction


function options = validate_options (options)
  if (! isstruct (options))
    error ("options must be a struct");
  endif
  valid_fieldnames = {"max_recursion_depth", "ignore_errors", ...
    "document_private_functions", "demos_collect_code", ...
    "demos_collect_figures", "output_dir"};
  if (any (! ismember (fieldnames (options), valid_fieldnames)))
    error ("Allowed option fieldnames are: %s", ...
      strjoin (valid_fieldnames, ", "));
  endif
  if (isfield (options, "ignore_errors"))
    if (! islogical (options.ignore_errors))
      error ("options.ignore_errors must be a logical value");
    endif
  else
    options.ignore_errors = false;
  endif
  if (isfield (options, "document_private_functions"))
    if (! islogical (options.document_private_functions))
      error ("options.document_private_functions must be a logical value");
    endif
  else
    options.document_private_functions = false;
  endif
  if (isfield (options, "max_recursion_depth"))
    if (! (isscalar (options.max_recursion_depth) ...
      && isnumeric (options.max_recursion_depth) ...
      && (options.max_recursion_depth >= 0)))
      error ("options.max_recursion_depth must be a non-negative integer");
    endif
  else
    options.max_recursion_depth = inf;
  endif
  if (isfield (options, "demos_collect_code"))
    if (! islogical (options.demos_collect_code))
      error ("options.demos_collect_code must be a non-negative integer");
    endif
  else
    options.demos_collect_code = true;
  endif
  if (isfield (options, "demos_collect_figures"))
    if (! islogical (options.demos_collect_figures))
      error ("options.demos_collect_figures must be a non-negative integer");
    endif
  else
    options.demos_collect_figures = true;
  endif
  if (isfield (options, "output_dir"))
    if (! (ischar (options.output_dir)))
      error ("options.output_dir must be character string");
    endif
  else
    options.output_dir = "./output";
  endif
endfunction


%!error<must be a struct> collect_docstrings ("dir", "invalid");
%!error<Allowed option fieldnames are> collect_docstrings ("dir", ...
%!  struct ("invalid", true));
%!error<must be a logical value> collect_docstrings ("dir", ...
%!  struct ("ignore_errors", 4));
%!error<must be a non-negative integer> collect_docstrings ("dir", ...
%!  struct ("max_recursion_depth", true));

#%!test
#%! options.ignore_errors = false;
#%! options.document_private_functions = false;
#%! directory = "/home/siko1056/.local/share/octave/8.2.0/statistics-1.6.0";
#%! fcns = collect_docstrings (directory, options);

