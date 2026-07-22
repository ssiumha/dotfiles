local wezterm = require 'wezterm'

local OPENPATH = wezterm.home_dir .. '/dots/bin/openpath'

-- any slashed file path ending in an alpha extension, optionally rooted at / or
-- ~/: /Users/.../note.md, ~/dots/zshrc.lua, projects/foo/bar.md,
-- infra/idc/.../haproxy.cfg, src/a/b.ts … (alpha ext avoids matching 1.2/3.4)
local file_path = [[(?:~/|/)?(?:[\w.-]+/)+[\w.-]+\.[A-Za-z]\w*]]

-- pane cwd as a plain path, tolerating both the Url-object and string forms
local function pane_cwd(pane)
  local d = pane:get_current_working_dir()
  if d == nil then return nil end
  if type(d) == 'userdata' then return d.file_path end
  return (tostring(d):gsub('^file://[^/]*', ''))
end

-- hand a path to bin/openpath, resolved against the pane's cwd. opener is
-- nil (auto: vault .md → Obsidian, else editor), 'obsidian', or 'vim'.
local function open_with(pane, path, opener)
  if not path or path == '' then return end
  path = path:gsub('%s+$', '')
  local args = { OPENPATH, '--base', pane_cwd(pane) or wezterm.home_dir }
  if opener then table.insert(args, '--' .. opener) end
  table.insert(args, path)
  wezterm.background_child_process(args)
end

-- quick-select a file path on screen, then open it with the given opener
local function quick_open(opener)
  return wezterm.action.QuickSelectArgs {
    label = 'open path → ' .. (opener or 'auto'),
    patterns = { file_path },
    action = wezterm.action_callback(function(window, pane)
      open_with(pane, window:get_selection_text_for_pane(pane), opener)
    end),
  }
end

-- Cmd+click a path → route through openpath (carries cwd, auto-dispatches app)
wezterm.on('open-uri', function(window, pane, uri)
  local p = uri:match('^wezopen:(.*)$')
  if not p then return true end -- not ours; let wezterm open it normally
  open_with(pane, p, nil)
  return false
end)

-- default rules + gh:owner/repo#NNN → GitHub PR URL
local hyperlink_rules = wezterm.default_hyperlink_rules()
table.insert(hyperlink_rules, {
  regex = [[\bgh:([\w.-]+/[\w.-]+)#(\d+)]],
  format = 'https://github.com/$1/pull/$2',
})
-- file paths → clickable; handled by the open-uri callback above
table.insert(hyperlink_rules, {
  -- lookbehind (not \b) so a leading / or ~/ is captured, not stranded
  regex = [[(?<![\w./~-])]] .. file_path .. [[\b]],
  format = 'wezopen:$0',
})

-- ref: https://wezfurlong.org/wezterm/config/lua/config
return {
  hyperlink_rules = hyperlink_rules,
  window_background_opacity = 0.65,
  text_background_opacity = 0.8,
  macos_window_background_blur = 0,
  window_decorations = 'RESIZE',

  hide_tab_bar_if_only_one_tab = true,
  font_size = 12.0,

  normalize_output_to_unicode_nfc = true,

  font = wezterm.font_with_fallback {
    'D2Coding Nerd Font Mono',
    'Menlo',
    'Monaco',
    'Fira Code',
  },

  keys = {
    -- quick-select a file path on screen, then force-open it:
    { key = 'o', mods = 'CMD|SHIFT', action = quick_open('obsidian') },
    { key = 'e', mods = 'CMD|SHIFT', action = quick_open('vim') },
    -- { key = '1', mods = 'ALT', action = wezterm.action.ShowLauncher },
    -- { key = '1', mods = 'ALT', action = wezterm.action.ShowLauncherArgs { flags = 'FUZZY|TABS|LAUNCH_MENU_ITEMS' }, },
  },

  launch_menu = {
    {
      args = { 'top' },
    },
    {
      label = 'Bash',
      args = { 'bash', '-l' },
    }
  }
}
