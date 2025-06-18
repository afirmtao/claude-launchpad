# Disable fish greeting
set fish_greeting

# Set Dracula theme colors
set -U fish_color_normal normal
set -U fish_color_command 8be9fd
set -U fish_color_quote f1fa8c
set -U fish_color_redirection ffb86c
set -U fish_color_end 50fa7b
set -U fish_color_error ff5555
set -U fish_color_param ff79c6
set -U fish_color_comment 6272a4
set -U fish_color_match --background=brblue
set -U fish_color_selection white --bold --background=brblack
set -U fish_color_search_match bryellow --background=brblack
set -U fish_color_history_current --bold
set -U fish_color_operator 00a6b2
set -U fish_color_escape 00a6b2
set -U fish_color_cwd green
set -U fish_color_cwd_root red
set -U fish_color_valid_path --underline
set -U fish_color_autosuggestion 6272a4
set -U fish_color_user brgreen
set -U fish_color_host normal
set -U fish_color_cancel -r
set -U fish_pager_color_completion normal
set -U fish_pager_color_description B3A06D yellow
set -U fish_pager_color_prefix normal --bold --underline
set -U fish_pager_color_progress brwhite --background=cyan

# Add paths to fish
set -gx PATH ~/.cargo/bin $PATH
set -gx PATH ~/go/bin $PATH
set -gx PATH ~/.npm/global/bin $PATH