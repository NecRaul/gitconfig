#!/bin/bash

__parse() {
    echo -n "$(sed -rn "$1" <<<"$2")"
}

__git_branch() {
    local dir=${1:-.} git_status branch_info branch remote

    if ! git_status=${2:-"$(git status -sb 2>/dev/null)"}; then
        return 0
    fi

    branch_info=$(head -n 1 <<<"$git_status")
    branch=$(__parse "s/^## (HEAD \(no branch\))$/\1/p" "$branch_info")
    branch=${branch:-$(__parse "s/^## No commits yet on (.*)$/\1/p" "$branch_info")}
    branch=${branch:-$(__parse "s/^## (.*)[\.]{3}[^ ]*.*$/\1/p" "$branch_info")} # branch...remote
    branch=${branch:-$(__parse "s/^## (.*)[^ ]*.*$/\1/p" "$branch_info")}        # branch

    remote=$(__parse "s/^## .*[\.]{3}([^ ]*).*$/\1/p" "$branch_info")
    printf " %s%s%s" "${branch}$([ -n "$remote" ] && echo -n " ⎇  $remote")"
}

__git_state() {

    local git_status changes state ahead behind unpushed

    if ! git_status=${1:-"$(git status -sb 2>/dev/null)"}; then
        return 0
    fi

    changes=$(echo "$git_status" | tail -n +2 | wc -l | xargs)

    [ "$changes" -gt 0 ] && state="✗$changes"

    ahead=$(__parse "s/^## .* \[.*ahead ([0-9]*).*$/\1/p" "$git_status")
    behind=$(__parse "s/^## .* \[.*behind ([0-9]*).*$/\1/p" "$git_status")

    unpushed=$(
        [ -n "$ahead" ] && echo -n "↑$ahead"
        [ -n "$behind" ] && echo -n "↓$behind"
    )

    if [ -z "$state" ] && [ -z "$unpushed" ]; then
        printf " "
    else
        printf " %s%s " "${state}" "${unpushed}"
    fi
}
