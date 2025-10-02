local function insert_lowercase_uuid()
  local uuid = vim.fn.system 'uuidgen'
  uuid = uuid:gsub('\n', ''):lower()
  vim.api.nvim_put({ uuid }, 'c', true, true)
end

vim.api.nvim_create_user_command('G', 'Git', {})
vim.api.nvim_create_user_command('W', 'write', {})
vim.api.nvim_create_user_command('Q', 'quit', {})

vim.api.nvim_create_user_command('Iuuid', insert_lowercase_uuid, {})

vim.api.nvim_create_user_command('Enew', function(opts)
  local current_dir = vim.fn.expand '%:h'
  local new_path = current_dir .. '/' .. opts.args
  vim.cmd('edit ' .. new_path)
end, { nargs = 1, complete = 'file' })

vim.api.nvim_create_user_command('Etest', function()
  local filepath = vim.api.nvim_buf_get_name(0)

  local test_filepath = nil

  if filepath:match '%.ex$' then
    -- Elixir source file
    test_filepath = filepath:gsub('%.ex$', '_test.exs')
  elseif filepath:match '%.vue$' then
    -- Vue component file
    test_filepath = filepath:gsub('%.vue$', '.Spec.ts')
  elseif filepath:match '%.ts$' then
    -- Typescript file
    test_filepath = filepath:gsub('%.ts$', '.Spec.ts')
  else
    print 'Unsupported file type.'
    return
  end

  -- Try to open the test file
  local f = io.open(test_filepath, 'r')
  if f ~= nil then
    io.close(f)
    vim.cmd('edit ' .. vim.fn.fnameescape(test_filepath))
  else
    print('Test file not found: ' .. test_filepath)
  end
end, { desc = 'Open corresponding test file for Elixir or Vue' })

vim.api.nvim_create_user_command('Efile', function()
  local filepath = vim.api.nvim_buf_get_name(0)

  local source_filepath = nil

  if filepath:match '_test%.exs$' then
    -- Elixir test file
    source_filepath = filepath:gsub('_test%.exs$', '.ex')
  elseif filepath:match '%.Spec%.ts$' then
    -- Vue or TypeScript test file - check for Vue first
    local potential_vue = filepath:gsub('%.Spec%.ts$', '.vue')
    local f = io.open(potential_vue, 'r')
    if f ~= nil then
      -- Vue file exists
      io.close(f)
      source_filepath = potential_vue
    else
      -- No Vue file, assume TypeScript
      source_filepath = filepath:gsub('%.Spec%.ts$', '.ts')
    end
  else
    print 'Unsupported test file type.'
    return
  end

  -- Try to open the source file
  local f = io.open(source_filepath, 'r')
  if f ~= nil then
    io.close(f)
    vim.cmd('edit ' .. vim.fn.fnameescape(source_filepath))
  else
    print('Source file not found: ' .. source_filepath)
  end
end, { desc = 'Open corresponding source file from test file' })

-- Toggle between test and source files
vim.keymap.set('n', '<C-y>', function()
  local filepath = vim.api.nvim_buf_get_name(0)

  -- Check if current file is a test file
  if filepath:match '_test%.exs$' or filepath:match '%.Spec%.ts$' then
    -- It's a test file, open source file
    vim.cmd 'Efile'
  elseif filepath:match '%.ex$' or filepath:match '%.vue$' or filepath:match '%.ts$' then
    -- It's a source file, open test file
    vim.cmd 'Etest'
  else
    print 'Unsupported file type for test/source toggle.'
  end
end, { desc = 'Toggle between test and source file' })

vim.api.nvim_create_user_command('AL', function()
  local buf = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(buf)

  -- Only for .ex files
  if not filename:match '%.ex$' then
    print 'SortAliasBlock: Only allowed for .ex files.'
    return
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  local start_idx, end_idx = nil, nil
  for i, line in ipairs(lines) do
    if line:match '^%s*alias ' then
      if not start_idx then
        start_idx = i
      end
      end_idx = i
    elseif start_idx and line:match '^%s*$' then
      -- ignore empty lines in block
    elseif start_idx then
      -- Block ends
      break
    end
  end

  if not start_idx or not end_idx then
    print 'No alias block found.'
    return
  end

  -- Extract & sort
  local alias_lines = {}
  for i = start_idx, end_idx do
    local line = lines[i]
    if line:match '^%s*alias ' then
      table.insert(alias_lines, line)
    end
  end
  table.sort(alias_lines)

  -- Replace lines
  vim.api.nvim_buf_set_lines(buf, start_idx - 1, end_idx, false, alias_lines)

  -- Save file
  vim.cmd 'write'
  print 'Alias block sorted and saved.'
end, {})
