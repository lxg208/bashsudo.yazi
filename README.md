
# Table of Contents

1.  [Disclaimer](#org1a2cac5)
2.  [Requirements](#org27157af)
3.  [Installation](#org4f6157c)
    1.  [Via `ya pkg` (recommended)](#org53f71b1)
    2.  [Manual](#orga397d33)
4.  [Keymap](#org06cb1e3)
5.  [Commands](#orgdc25477)
6.  [License](#orgb568351)

A [yazi](https://github.com/sxyazi/yazi) plugin that performs file operations with `sudo` — copy, move, rename,
link, create, delete, chmod, and edit — using pure `bash`. No [Nushell](https://www.nushell.sh/) required.

Inspired by [sudo.yazi](https://github.com/TD-Sky/sudo.yazi).


<a id="org1a2cac5"></a>

# Disclaimer

> **This plugin is a work in progress.** It is functional but has not been
> extensively tested across all environments and edge cases.

Several operations in this plugin invoke `sudo` to perform privileged file
operations. This means:

-   Commands may prompt for your password
-   Mistakes (e.g. wrong path, wrong mode) are executed with root privileges
-   **There is no undo** for permanent deletions (`R D`)

Use with caution. The authors take no responsibility for data loss or
system damage caused by the use of this plugin.

**Always double-check your selection before confirming any destructive operation.**


<a id="org27157af"></a>

# Requirements

-   `bash`
-   `sudo`
-   A trash tool for non-permanent deletion (one of the following):
    -   [trash-cli](https://github.com/andreafrancia/trash-cli) — provides `trash-put`
    -   `gio` — available on most GNOME-based systems


<a id="org4f6157c"></a>

# Installation


<a id="org53f71b1"></a>

## Via `ya pkg` (recommended)

    ya pkg add lxg208/bashsudo


<a id="orga397d33"></a>

## Manual

    git clone https://github.com/lxg208/bashsudo.yazi.git \
      ~/.config/yazi/plugins/bashsudo.yazi
    chmod +x ~/.config/yazi/plugins/bashsudo.yazi/assets/bashsudo.sh


<a id="org06cb1e3"></a>

# Keymap

Add the following to your `~/.config/yazi/keymap.toml`:

    # sudo cp/mv (paste)
    [[mgr.prepend_keymap]]
    on = ["R", "p", "p"]
    run = "plugin bashsudo -- paste"
    desc = "bashsudo paste"
    
    # sudo cp/mv --force (paste, overwrite)
    [[mgr.prepend_keymap]]
    on = ["R", "P"]
    run = "plugin bashsudo -- paste --force"
    desc = "bashsudo paste (force)"
    
    # sudo mv (rename)
    [[mgr.prepend_keymap]]
    on = ["R", "r"]
    run = "plugin bashsudo -- rename"
    desc = "bashsudo rename"
    
    # sudo ln -s (absolute path)
    [[mgr.prepend_keymap]]
    on = ["R", "p", "l"]
    run = "plugin bashsudo -- link"
    desc = "bashsudo symlink (absolute)"
    
    # sudo ln -s (relative path)
    [[mgr.prepend_keymap]]
    on = ["R", "p", "r"]
    run = "plugin bashsudo -- link --relative"
    desc = "bashsudo symlink (relative)"
    
    # sudo ln (hardlink)
    [[mgr.prepend_keymap]]
    on = ["R", "p", "L"]
    run = "plugin bashsudo -- hardlink"
    desc = "bashsudo hardlink"
    
    # sudo touch / mkdir
    [[mgr.prepend_keymap]]
    on = ["R", "a"]
    run = "plugin bashsudo -- create"
    desc = "bashsudo create file/dir"
    
    # sudo trash
    [[mgr.prepend_keymap]]
    on = ["R", "d"]
    run = "plugin bashsudo -- remove"
    desc = "bashsudo trash"
    
    # sudo delete permanently
    [[mgr.prepend_keymap]]
    on = ["R", "D"]
    run = "plugin bashsudo -- remove --permanent"
    desc = "bashsudo delete permanently"
    
    # sudo chmod
    [[mgr.prepend_keymap]]
    on = ["R", "m"]
    run = "plugin bashsudo -- chmod"
    desc = "bashsudo chmod"
    
    # edit with $EDITOR (sudo if needed)
    [[mgr.prepend_keymap]]
    on = ["R", "e"]
    run = "plugin bashsudo -- edit"
    desc = "bashsudo edit with $EDITOR"


<a id="orgdc25477"></a>

# Commands

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />
</colgroup>
<thead>
<tr>
<th scope="col" class="org-left">Key</th>
<th scope="col" class="org-left">Command</th>
<th scope="col" class="org-left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td class="org-left">R p p</td>
<td class="org-left">paste</td>
<td class="org-left">Copy or move yanked files with sudo</td>
</tr>

<tr>
<td class="org-left">R P</td>
<td class="org-left">paste &ndash;force</td>
<td class="org-left">Same, but overwrite existing files</td>
</tr>

<tr>
<td class="org-left">R r</td>
<td class="org-left">rename</td>
<td class="org-left">Rename hovered file with sudo</td>
</tr>

<tr>
<td class="org-left">R p l</td>
<td class="org-left">link</td>
<td class="org-left">Create absolute symlink with sudo</td>
</tr>

<tr>
<td class="org-left">R p r</td>
<td class="org-left">link &ndash;relative</td>
<td class="org-left">Create relative symlink with sudo</td>
</tr>

<tr>
<td class="org-left">R p L</td>
<td class="org-left">hardlink</td>
<td class="org-left">Create hard link with sudo</td>
</tr>

<tr>
<td class="org-left">R a</td>
<td class="org-left">create</td>
<td class="org-left">Create file or directory (append / for directory)</td>
</tr>

<tr>
<td class="org-left">R d</td>
<td class="org-left">remove</td>
<td class="org-left">Move selected files to trash</td>
</tr>

<tr>
<td class="org-left">R D</td>
<td class="org-left">remove &ndash;permanent</td>
<td class="org-left">Permanently delete selected files with sudo</td>
</tr>

<tr>
<td class="org-left">R m</td>
<td class="org-left">chmod</td>
<td class="org-left">Change file permissions with sudo</td>
</tr>

<tr>
<td class="org-left">R e</td>
<td class="org-left">edit</td>
<td class="org-left">Open hovered file in $EDITOR (sudo if not writable)</td>
</tr>
</tbody>
</table>


<a id="orgb568351"></a>

# License

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see [https://www.gnu.org/licenses/](https://www.gnu.org/licenses/).

