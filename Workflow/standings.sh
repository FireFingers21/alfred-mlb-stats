#!/bin/zsh --no-rcs

# Get current/selected season
[[ "$(date +%s)" -ge "$(date -jv 3m +%s)" ]] && seasonYear="$(date +%Y)" || seasonYear="$(($(date +%Y) - 1))"
seasonDir="${alfred_workflow_data}/${seasonYear}"

# Auto Update
set -o extendedglob
[[ -f ${alfred_workflow_data}/*/*(#i)standings.json(#qNY1) ]] \
&& [[ "$(date -r "${alfred_workflow_data}" +%s)" -lt "$(date -v -"${autoUpdate}"M +%s)" || ! -d "${seasonDir}" ]] && reload=$(./reload.sh)

# Load Standings
jq -cs \
   --arg alfred_workflow_keyword "${alfred_workflow_keyword}" \
   --arg favTeam "$(iconv -f UTF-8-MAC -t UTF-8 <<< ${(L)favTeam})" \
   --arg grouping "${grouping}" \
   --arg icons_dir "${seasonDir}/icons" \
   --arg seasonYear "${seasonYear}" \
'{
    "variables": {
        "keyword": $alfred_workflow_keyword,
        "icons_dir": $icons_dir,
        "seasonYear": $seasonYear
    },
    "skipknowledge": true,
	"items": (if (length != 0) then
		reduce .[0].records[].teamRecords as $r ([]; . + $r) |
		([.[] | select(.clinchIndicator).team.division.name]) as $clinchedDivisions |
		(if ($grouping != "sport") then map({(.team."\($grouping)".name): ."\($grouping)Sequence"}) else "" end) as $groupingSeqs |
		map(((.name|ascii_downcase) == $favTeam) as $isFavourite | {
			"title": "\(."\($grouping)Rank")  \(.name)  \(.clinchIndicator | if (.) then "(\(.))" else "" end)  \(if ($isFavourite) then "★" else "" end)",
			"subtitle": "[ W: \(.wins)  L: \(.losses)  PCT: \(.pct) ]    L10: \(.record_lastTen // "-")    STRK: \(.streak // "-")    [ RS: \(.runsScored)  RA: \(.runsAllowed)  DIFF: \(.runDifferential | (if . > 0 then "+"+(.|tostring) else . end)) ]",
			"arg": "stats",
			"match": [
                ."\($grouping)Rank", .name,
                (.team.division.name| . + " " + gsub("(merican |ational |eague)";"")),
                (if (.wildCardRank) then "wildcard" else "" end),
                (if (.clinched) then "clinched" else "" end)
            ] | map(select(.)) | join(" "),
			"icon": { "path": "\($icons_dir)/\(.id).png" },
			"text": { "copy": .name },
			"variables": {
			    "favTeamNew": .name,
			    "teamId": .id, "teamName": .name, "seq": ."\($grouping)Rank",
				"divSeq": (.team.division.name | if (contains("East")) then 1 elif (contains("Central")) then 2 elif (contains("West")) then 3 else 4 end),
				"league": .team.league.name,
				"division": (.team.division.name|gsub("(merican |ational |eague)";"")),
				"divFullName": .team.division.name
			},
			"mods": {
			    "cmd": {"subtitle": "⌘↩ Sort by Division", "arg": "", "variables": {"grouping":"division"}},
			    "alt": {"subtitle": "⌥↩ Sort by League", "arg": "", "variables": {"grouping":"league"}},
			    "ctrl": {"subtitle": "⌃↩ Sort by Sport", "arg": "", "variables": {"grouping":"sport"}},
				"cmd+shift": {"subtitle": "⇧⌘↩ \(if ($isFavourite) then "Unset" else "Set" end) Favourite Team"}
			}
		}) | (if ($grouping != "sport") then ([
		    (unique_by(.variables."\($grouping)")[] | select((.variables.seq) == 1)) |
		    (. |= (.variables.divFullName) as $division | (.variables.league) as $league | {
				"title":"—————  \($league)  —————",
				"subtitle":(if ($grouping == "division") then (.variables.division | " "*(46-length/2)+.) else "" end),
				"icon": {"path":"images/iconLarge.png"},
				"match":"\($league) \(.variables.division) \($groupingSeqs | map(."\($grouping)" | select(.)) | join(" ")) \(if ($clinchedDivisions | contains([$division])) then "clinched" else "" end) wildcard",
				"variables": .variables, "mods":.mods, "valid": false
			}) | (.variables.seq |= 0) | (.variables.favTeamNew |= "") | (.mods."cmd+shift".subtitle |= "")
		]+.) end)
		| (if ($grouping == "sport") then sort_by(.variables.seq) elif ($grouping == "league") then sort_by(.variables.league, .variables.seq) elif ($grouping == "division") then sort_by(.variables.league, .variables.divSeq, .variables.seq) end)
		| [(.[] | select(($grouping == "sport" and .variables.seq == 1) | not) | select(.variables.seq != 0 and (.variables.teamName|ascii_downcase) == $favTeam)) | (.match |= "")] + .
	else
		[{
			"title": "No Standings Found",
			"subtitle": "Press ↩ to load standings for the current season",
			"arg": "reload"
		}]
	end)
}' "${seasonDir}/standings.json"