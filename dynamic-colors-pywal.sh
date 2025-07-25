#!/bin/bash

# Dynamic Color Script

WAYBAR_CONFIG_DIR="$HOME/.config/waybar"
WAYBAR_CONFIG="$WAYBAR_CONFIG_DIR/config.jsonc"
WAYBAR_STYLE="$WAYBAR_CONFIG_DIR/style.css"
WAYBAR_CONFIG_BACKUP="$WAYBAR_CONFIG_DIR/config.jsonc.backup"
WAYBAR_STYLE_BACKUP="$WAYBAR_CONFIG_DIR/style.css.backup"

KITTY_CONFIG_DIR="$HOME/.config/kitty"
KITTY_THEME="$KITTY_CONFIG_DIR/current-theme.conf"
KITTY_THEME_BACKUP="$KITTY_CONFIG_DIR/current-theme.conf.backup"

WOFI_CONFIG_DIR="$HOME/.config/wofi"
WOFI_STYLE="$WOFI_CONFIG_DIR/style.css"
WOFI_STYLE_BACKUP="$WOFI_CONFIG_DIR/style.css.backup"

# Get cur wallpaper from waypaper config
get_current_wallpaper() {
    local waypaper_config="$HOME/.config/waypaper/config.ini"
    if [[ -f "$waypaper_config" ]]; then
        grep "^wallpaper = " "$waypaper_config" | cut -d' ' -f3
    else
        echo "Error: waypaper config not found" >&2
        exit 1
    fi
}

# Backups for original config (only once)
backup_configs() {
    if [[ ! -f "$WAYBAR_CONFIG_BACKUP" ]]; then
        cp "$WAYBAR_CONFIG" "$WAYBAR_CONFIG_BACKUP"
        echo "Backed up original waybar config.jsonc"
    fi
    if [[ ! -f "$WAYBAR_STYLE_BACKUP" ]]; then
        cp "$WAYBAR_STYLE" "$WAYBAR_STYLE_BACKUP"
        echo "Backed up original waybar style.css"
    fi
    if [[ ! -f "$KITTY_THEME_BACKUP" ]]; then
        cp "$KITTY_THEME" "$KITTY_THEME_BACKUP"
        echo "Backed up original kitty theme"
    fi
    if [[ ! -f "$WOFI_STYLE_BACKUP" ]]; then
        cp "$WOFI_STYLE" "$WOFI_STYLE_BACKUP"
        echo "Backed up original wofi style.css"
    fi
}

# Geneerate pywal colors from wallpaper
generate_colors() {
    local wallpaper="$1"
    
    if [[ ! -f "$wallpaper" ]]; then
        echo "Error: Wallpaper file not found: $wallpaper" >&2
        exit 1
    fi
    
    echo "Generating colors from: $wallpaper"
    wal -i "$wallpaper" -n -q
    
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to generate colors with pywal" >&2
        exit 1
    fi
}

# Update waybar with colors, may change to update only color file instead of everything
update_waybar_config() {
    local config_template=$(cat << 'EOF'
{
    "layer": "bottom",
    "modules-left": ["custom/launcher","custom/bluetooth","clock","mpris","hyprland/workspaces"],
    "modules-center":["hyprland/window"],
    "modules-right": ["pulseaudio", "battery", "network", "custom/power"],

    "pulseaudio": {
        "tooltip": false,
        "scroll-step": 1,
        "markup": "pango",
        "format": "<span color='{color5}'>{icon} </span> <span color='{foreground}'>{volume}%</span>",
        "format-muted": "<span color='{color5}'>ﱝ</span> <span color='{foreground}'>muted</span>",
        "on-click": "pavucontrol",
        "format-icons": {
            "default": ["", "", ""]
        },
    },

"battery": {
    "markup": "pango",
    "format": "<span color='{color5}'>{icon} </span> <span color='{foreground}'>{capacity}%</span>",
    "format-charging": "<span color='{color5}'></span> <span color='{foreground}'>{capacity}%</span>",
    "format-full": "<span color='{color5}'></span> <span color='{color5}'></span> <span color='{foreground}'>Charged</span>",
    "format-time": "{H}h{M}m",
    "format-icons": ["", "", "", "", ""],
    "interval": 1,
    "states": {
        "warning": 25,
        "critical": 10
    },
    "tooltip": false,
    "on-click": "2"
},

    "custom/launcher": {
        "markup": "pango",
        "format": "<span color='{color5}'>󰣇 </span>",
        "on-click": "wofi -i --show drun --allow-images -D key_expand=Tab",
        "on-click-right": "killall rofi",
        "tooltip": false
    },

    "custom/power": {
        "markup": "pango",
        "format": "<span color='{color5}'>⏻ </span>",
        "tooltip": false,
        "on-click": "bash ~/.config/wofi/powermenu.sh",
        "on-click-right": "killall rofi",
		//"min-length": 5
    },

    "clock": {
        "markup": "pango",
        "format": "<span color='{color5}'></span> <span color='{foreground}'>{:%A - %B %d, %Y - %I:%M}</span>",
        "tooltip": false
    },

    "hyprland/workspaces": {
        "format": "{icon}",
        "tooltip": true,
        "format-icons": {
            "1": "", "2": "", "3": "", "4": "", "5": "",
            "6": "", "7": "", "8": "", "9": "", "10": "",
            "urgent": "",
            "active": "",
            "default": ""
        },
        "persistent_workspaces": {
            "outputs": ["*"],
            "workspaces": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        }
    },

    "tray": {
        "icon-size": 21,
        "spacing": 10
    },

    "network": {
        "markup": "pango",
        "interface": "wlo1",
        "format-wifi": "<span color='{color5}'>󰘊</span> <span color='{foreground}'>{essid}</span>",
        "format-ethernet": "<span color='{color5}'></span> <span color='{foreground}'>{ipaddr}</span> <span color='{foreground}'></span>",
        "format-disconnected": "<span color='{color5}'>󰘚</span> <span color='{foreground}'>disconnected</span>",
        "tooltip": true,
        "interval": 1,
        "min-length": 18,
        "max-length": 25
    },
    "mpris": {
        "player": "spotify",
        "markup": "pango",
        "format-playing": "<span color='{color5}'></span> <span color='{foreground}'>{artist} - {title}</span>",
        "format-paused": "<span color='{color5}'></span> <span color='{foreground}'>{artist} - {title}</span>",
        "format-stopped": "",
        "on-click": "playerctl play-pause",
        "on-click-right": "playerctl next",
        "on-click-middle": "playerctl previous",
        "tooltip": true,
        "tooltip-format": "{playerName}\n{title}\n{artist}",
        "max-length": 30
    },
    "hyprland/window": {
        "format": "<span color='{color5}'></span> <span color='{foreground}'> {}</span>",
        "rewrite": {
            "": "Desktop"
      },
        "max-length": 25,
        "tooltip": false
    },
    "custom/bluetooth": {
        "format": "",
        "tooltip": false,
        "on-click": "blueman-manager",
        "on-click-right": "bluetoothctl power off",
        "interval": 30
}


}
EOF
)

    # Source pywal colors
    source "$HOME/.cache/wal/colors.sh"
    
    # Replace color placeholders with actual pywal colors
    echo "$config_template" | \
        sed "s/{color5}/$color5/g" | \
        sed "s/{foreground}/$foreground/g" > "$WAYBAR_CONFIG"
    
    echo "Updated waybar config with pywal colors"
}

# Same as before, but style instead
update_waybar_style() {
    # Source pywal colors
    source "$HOME/.cache/wal/colors.sh"
    
    local style_template=$(cat << EOF
* {
	border: none;
	border-radius: 10;
    font-family: "JetBrainsMono Nerd Font", "JetBrains Mono", monospace;
	font-size: 15px;
	font-weight: bold;
	min-height: 10px;
}

window#waybar {
	background: transparent;
}

#network {
    margin-top: 10px;
    margin-left: 8px;
    padding-left: 10px;
    padding-right: 10px;
    margin-bottom: 0px;
    border-radius: 10px;
    transition: none;
    background: $background;
    color: $color5;
    border-bottom: 3px;
    border-style: solid;
    border-color: $background;
    transition: 0.3s;
}

#network:hover {
    color: $background;
    background: $color5;
}

#custom-keybinds {
    margin-top: 10px;
    margin-left: 8px;
    padding-left: 10px;
    padding-right: 10px;
    margin-bottom: 0px;
    border-radius: 10px;
    transition: none;
    color: $color5;
    background: $background;
    transition: 0.3s;
    border-bottom: 3px;
    border-style: solid;
    border-color: $background;
}
#custom-keybinds:hover {
    background: $color5;
    color: $background;
}

#cava{
    margin-top: 10px;
    margin-left: 8px;
    padding-left: 10px;
    padding-right: 10px;
    margin-bottom: 0px;
    border-radius: 10px;
    transition: none;
    background: $background;
    color: $color5;
    border-bottom: 3px;
    border-style: solid;
    border-color: $background;
    transition: 0.3s;
}

#cava:hover{
    color: $background;
    background: $color1;
}

#battery{
    margin-top: 10px;
    margin-left: 8px;
    padding-left: 10px;
    padding-right: 10px;
    margin-bottom: 0px;
    border-radius: 10px;
    transition: none;
    background: $background;
    color: $color5;
    border-bottom: 3px;
    border-style: solid;
    border-color: $background;
    transition: 0.3s;
}

#battery:hover{
    color: $background;
    background: $color5;
}


#pulseaudio {
    margin-top: 10px;
    margin-left: 8px;
    padding-left: 10px;
    padding-right: 10px;
    margin-bottom: 0px;
    border-radius: 10px;
    transition: none;
    background: $background;
    color: $color5;
    padding: 8px;
    border-bottom: 3px;
    border-style: solid;
    border-color: $background;
    transition: 0.3s;
}
#pulseaudio:hover{
    background: $color5;
    color: $background;
}
#pulseaudio.muted {
    color: $color5;
    background: $background;
    border-bottom: 3px;
    border-style: solid;
    border-color: $color5;
    transition: 0.3s;
}
#pulseaudio.muted:hover {
    background: $color5;
    color: $background;

}
#clock {
    margin-top: 10px;
    margin-left: 8px;
    padding-left: 10px;
    padding-right: 10px;
    margin-bottom: 0px;
    border-radius: 10px;
    transition: none;
    background: $background;
    color: $color5;
    border-bottom: 3px;
    border-style: solid;
    border-color: $background;
    transition: 0.3s;
}
#clock:hover {
    color: $background;
    background: $color5;
}
#privacy{
    margin-top: 10px;
    margin-left: 8px;
    padding-left: 10px;
    padding-right: 10px;
    margin-bottom: 0px;
    border-radius: 10px;
    transition: none;
    background: $background;
    color: $color5;
    border-bottom: 3px;
    border-style: solid;
    border-color: $background;
    transition: 0.3s;
}
#custom-launcher {
    font-size: 20px;
    margin-top: 10px;
    margin-left: 17px;
    padding-left: 10px;
    padding-right: 5px;
    border-radius: 10px;
    transition: none;
    color: $color5;
    background: $background;
    transition: 0.3s;
    border-bottom: 3px;
    border-style: solid;
    border-color: $background;
}
#custom-launcher:hover {
    background: $color5;
    color: $background;
}
#network.disconnected {
    color: $foreground;
    background: $background;
    border-bottom: 3px;
    border-style: solid;
    border-color: $color1;
}
#network.disconnected:hover {
    background: $color1;
    color: $background;
}
#custom-power {
    font-size: 15px;
    margin-top: 10px;
    margin-left: 8px;
    margin-right: 17px;
    padding-left: 10px;
    padding-right: 5px;
    margin-bottom: 0px;
    border-radius: 10px;
    transition: none;
    background: $background;
    color: $color5;
    border-bottom: 3px;
    border-style: solid;
    border-color: $background;
    transition: 0.3s;
}
#custom-power:hover {
    background: $color5;
    color: $background;
    border-color: $color5;

}
#workspaces {
    margin-top: 10px;
    margin-left: 8px;
    padding-right: 4px;
    background: $background;
    border-bottom: 3px;
    border-style: solid;
    border-color: $background;
    color: $color5;
    transition: 0.3s;
}

#workspaces button {
    color: $color5;
    transition: 0.3s;
}

#workspaces button:hover {
    background: transparent;
    color: transparent;
    box-shadow: none;
    text-shadow: none;
}

#tray{
    margin-top: 10px;
    margin-left: 8px;
    padding-left: 10px;
    padding-right: 10px;
    margin-bottom: 0px;
    border-radius: 10px;
    transition: none;
    background: $background;
    color: $color5;
    border-bottom: 3px;
    border-style: solid;
    border-color: $background;
    transition: 0.3s;
}
#tray menu{
    margin-top: 10px;
    margin-left: 8px;
    padding-left: 10px;
    padding-right: 10px;
    margin-bottom: 0px;
    border-radius: 10px;
    transition: none;
    background: $background;
    color: $color5;
    border-bottom: 3px;
    border-style: solid;
    border-color: $color5;
    transition: 0.3s;
}

#mpris {
  background: $background;
  color: $color5;
  border-radius: 10px;
  padding: 0 10px;
  margin-top: 10px;
  margin-left: 8px;
  border-bottom: 3px solid $background;
  transition: 0.3s;
}
#mpris:hover {
  background: $color5;
  color: $background;
}

#window {
  background-color: $background;
  font-family: "JetBrainsMono Nerd Font";
  font-size: 15px;
  font-weight: bold;
  padding: 0 10px;
  border-radius: 10px;
  margin: 10px 8px 0px 8px;
  border-bottom: 3px solid $background;
  min-width: 200px;
  transition: 0.3s;
}

#window:hover {
  background: $color5;
  color: $background;
}


#custom-bluetooth {
  background-color: $background;
  color: $color5;
  font-family: "JetBrainsMono Nerd Font";
  font-size: 16px;
  font-weight: bold;
  padding: 0 10px;
  border-radius: 10px;
  margin-top: 10px;
  margin-bottom: 0px;
  margin-left: 8px;
  border-bottom: 3px solid $background;
  transition: 0.3s;
}

#custom-bluetooth:hover {
  background-color: $color5;
  color: $background;
}
EOF
)

    echo "$style_template" > "$WAYBAR_STYLE"
    echo "Updated waybar style.css with pywal colors"
}

# Kitty's turn to be updated :D
update_kitty_theme() {
    # Source pywal colors
    source "$HOME/.cache/wal/colors.sh"
    
    local kitty_template=$(cat << EOF
# vim:ft=kitty

## name:     Pywal Generated Theme
## author:   Auto-generated from pywal colors
## license:  MIT
## blurb:    Dynamic theme based on current wallpaper

# The basic colors
foreground              $foreground
background              $background
selection_foreground    $background
selection_background    $foreground

# Cursor colors
cursor                  $cursor
cursor_text_color       $background

# URL underline color when hovering with mouse
url_color               $color4

# Kitty window border colors
active_border_color     $color5
inactive_border_color   $color8
bell_border_color       $color3

# OS Window titlebar colors
wayland_titlebar_color system
macos_titlebar_color system

# Tab bar colors
active_tab_foreground   $background
active_tab_background   $color5
inactive_tab_foreground $foreground
inactive_tab_background $color8
tab_bar_background      $background

# Colors for marks (marked text in the terminal)
mark1_foreground $background
mark1_background $color4
mark2_foreground $background
mark2_background $color5
mark3_foreground $background
mark3_background $color6

# The 16 terminal colors

# black
color0 $color0
color8 $color8

# red
color1 $color1
color9 $color9

# green
color2  $color2
color10 $color10

# yellow
color3  $color3
color11 $color11

# blue
color4  $color4
color12 $color12

# magenta
color5  $color5
color13 $color13

# cyan
color6  $color6
color14 $color14

# white
color7  $color7
color15 $color15
EOF
)

    echo "$kitty_template" > "$KITTY_THEME"
    echo "Updated kitty theme with pywal colors"
}

# Finally wofi, will do vim later
update_wofi_style() {
    source "$HOME/.cache/wal/colors.sh"
    
    local wofi_template=$(cat << EOF
* {
  font-family: "JetBrainsMono Nerd Font", "JetBrains Mono", bold;
  font-size: 14px;
}

/* Window */
window {
  margin: 0px;
  padding: 10px;
  border: 0.16em solid $color5;
  border-radius: 0.1em;
  background-color: $background;
  animation: slideIn 0.5s ease-in-out both;
}

/* Slide In */
@keyframes slideIn {
  0% {
     opacity: 0;
  }

  100% {
     opacity: 1;
  }
}

/* Inner Box */
#inner-box {
  margin: 5px;
  padding: 10px;
  border: none;
  background-color: $background;
  animation: fadeIn 0.5s ease-in-out both;
}

/* Fade In */
@keyframes fadeIn {
  0% {
     opacity: 0;
  }

  100% {
     opacity: 1;
  }
}

/* Outer Box */
#outer-box {
  margin: 5px;
  padding: 10px;
  border: none;
  background-color: $background;
}

/* Scroll */
#scroll {
  margin: 0px;
  padding: 10px;
  border: none;
  background-color: $background;
}

/* Input */
#input {
  margin: 5px 20px;
  padding: 10px;
  border: none;
  border-radius: 0.1em;
  color: $foreground;
  background-color: $background;
  animation: fadeIn 0.5s ease-in-out both;
}

#input image {
    border: none;
    color: $color1;
}

#input * {
  outline: 4px solid $color1!important;
}

/* Text */
#text {
  margin: 5px;
  border: none;
  color: $foreground;
  animation: fadeIn 0.5s ease-in-out both;
}

#entry {
  background-color: $background;
}

#entry arrow {
  border: none;
  color: $color5;
}

/* Selected Entry */
#entry:selected {
  border: 0.11em solid $color5;
}

#entry:selected #text {
  color: $color5;
}

#entry:drop(active) {
  background-color: $color5!important;
}
EOF
)

    echo "$wofi_template" > "$WOFI_STYLE"
    echo "Updated wofi style.css with pywal colors"
}

reload_waybar() {
    echo "Reloading waybar..."
    killall waybar
    sleep 1
    waybar &
    echo "Waybar reloaded with new colors!"
}

reload_kitty() {
    echo "Reloading kitty terminals..."
    pkill -SIGUSR1 kitty 2>/dev/null
    echo "Kitty terminals reloaded with new colors!"
}

restore_configs() {
    if [[ -f "$WAYBAR_CONFIG_BACKUP" ]]; then
        cp "$WAYBAR_CONFIG_BACKUP" "$WAYBAR_CONFIG"
        echo "Restored original waybar config.jsonc"
    fi
    if [[ -f "$WAYBAR_STYLE_BACKUP" ]]; then
        cp "$WAYBAR_STYLE_BACKUP" "$WAYBAR_STYLE"
        echo "Restored original waybar style.css"
    fi
    if [[ -f "$KITTY_THEME_BACKUP" ]]; then
        cp "$KITTY_THEME_BACKUP" "$KITTY_THEME"
        echo "Restored original kitty theme"
    fi
    if [[ -f "$WOFI_STYLE_BACKUP" ]]; then
        cp "$WOFI_STYLE_BACKUP" "$WOFI_STYLE"
        echo "Restored original wofi style.css"
    fi
    reload_waybar
    reload_kitty
}

main() {
    case "${1:-}" in
        --restore)
            restore_configs
            exit 0
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS] [WALLPAPER_PATH]"
            echo "Options:"
            echo "  --restore    Restore original waybar, kitty, and wofi configs"
            echo "  --help, -h   Show this help message"
            echo ""
            echo "If no wallpaper path is provided, uses current wallpaper from waypaper config"
            echo "This script updates waybar, kitty, and wofi with colors from your wallpaper"
            exit 0
            ;;
    esac
    
    # Get wallpaper path
    local wallpaper="${1:-$(get_current_wallpaper)}"
    
    # Expand tilde in wallpaper path
    wallpaper="${wallpaper/#\~/$HOME}"
    
    echo "Starting waybar, kitty, and wofi color update process..."
    
    backup_configs
    
    generate_colors "$wallpaper"
    
    update_waybar_config
    update_waybar_style
    update_kitty_theme
    update_wofi_style
    
    reload_waybar
    reload_kitty
    
    echo "Process completed successfully!"
    echo "Waybar, kitty, and wofi have been updated with colors from your wallpaper!"
}

main "$@"
