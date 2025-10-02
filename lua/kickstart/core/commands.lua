local function insert_lowercase_uuid()
  local uuid = vim.fn.system 'uuidgen'
  uuid = uuid:gsub('\n', ''):lower()
  vim.api.nvim_put({ uuid }, 'c', true, true)
end

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
