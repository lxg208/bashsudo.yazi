#!/usr/bin/env bash

# ── Helpers ───────────────────────────────────────────────────────────────────

# Find a non-conflicting filename in the current directory.
# If file.txt exists, tries file_1.txt, file_2.txt, etc.
legit_name() {
    local name="$1"
    local new_name="$name"
    local i=1

    while [[ -e "$new_name" ]]; do
        if [[ "$name" == *.* ]]; then
            local stem="${name%.*}"
            local ext="${name##*.}"
            new_name="${stem}_${i}.${ext}"
        else
            new_name="${name}_${i}"
        fi
        ((i++))
    done

    echo "$new_name"
}

# ── Commands ──────────────────────────────────────────────────────────────────

cmd_cp() {
    local force=0
    if [[ "$1" == "--force" ]]; then
        force=1
        shift
    fi

    for src in "$@"; do
        local base dest
        base=$(basename "$src")
        if [[ $force -eq 1 ]]; then
            cp -rfv "$src" "$base"
        else
            dest=$(legit_name "$base")
            cp -rfv "$src" "$dest"
        fi
    done
}

cmd_mv() {
    local force=0
    if [[ "$1" == "--force" ]]; then
        force=1
        shift
    fi

    for src in "$@"; do
        local base dest
        base=$(basename "$src")
        if [[ $force -eq 1 ]]; then
            mv -v "$src" "$base"
        else
            dest=$(legit_name "$base")
            mv -v "$src" "$dest"
        fi
    done
}

cmd_ln() {
    local relative=0
    if [[ "$1" == "--relative" ]]; then
        relative=1
        shift
    fi

    for src in "$@"; do
        local base dest
        base=$(basename "$src")
        dest=$(legit_name "$base")
        if [[ $relative -eq 1 ]]; then
            ln -sr -v "$src" "$dest"
        else
            ln -s -v "$src" "$dest"
        fi
    done
}

cmd_hardlink() {
    for src in "$@"; do
        local base dest
        base=$(basename "$src")
        dest=$(legit_name "$base")
        ln -v "$src" "$dest"
    done
}

cmd_rm() {
    local permanent=0
    if [[ "$1" == "--permanent" ]]; then
        permanent=1
        shift
    fi

    for path in "$@"; do
        if [[ $permanent -eq 1 ]]; then
            rm -rfv "$path"
        else
            if command -v trash-put &>/dev/null; then
                trash-put "$path" || {
                    echo "remove: trash failed for $path" >&2
                    exit 1
                }
            elif command -v gio &>/dev/null; then
                gio trash "$path" || {
                    echo "remove: trash failed for $path" >&2
                    exit 1
                }
            else
                echo "remove: no trash tool found (install trash-cli or gio)" >&2
                exit 1
            fi
        fi
    done
}

# ── Dispatch ──────────────────────────────────────────────────────────────────

case "$1" in
    cp)         shift; cmd_cp "$@" ;;
    mv)         shift; cmd_mv "$@" ;;
    link)       shift; cmd_ln "$@" ;;
    hardlink)   shift; cmd_hardlink "$@" ;;
    remove)     shift; cmd_rm "$@" ;;
    "")         ;;
    *)          echo "Unknown command: $1" >&2; exit 1 ;;
esac
