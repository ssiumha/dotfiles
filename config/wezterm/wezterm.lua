local wezterm = require 'wezterm'

-- default rules + gh:owner/repo#NNN → GitHub PR URL
local hyperlink_rules = wezterm.default_hyperlink_rules()
table.insert(hyperlink_rules, {
  regex = [[\bgh:([\w.-]+/[\w.-]+)#(\d+)]],
  format = 'https://github.com/$1/pull/$2',
})

-- ref: https://wezfurlong.org/wezterm/config/lua/config
return {
  hyperlink_rules = hyperlink_rules,
  window_background_opacity = 0.9,

  hide_tab_bar_if_only_one_tab = true,
  font_size = 12.0,

  normalize_output_to_unicode_nfc = true,

  font = wezterm.font_with_fallback {
    'Menlo',
    'Monaco',
    'Fira Code',
  },

  keys = {
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
