#!/bin/zsh --no-rcs

# Get current/selected season
[[ "$(date +%s)" -ge "$(date -jv 3m +%s)" ]] && seasonYear="$(date +%Y)" || seasonYear="$(($(date +%Y) - 1))"
seasonDir="${alfred_workflow_data}/${seasonYear}"

# Auto Update
set -o extendedglob
[[ -f ${alfred_workflow_data}/*/*(#i)standings.json(#qNY1) ]] \
&& [[ "$(date -r "${alfred_workflow_data}" +%s)" -lt "$(date -v -"${autoUpdate}"M +%s)" || ! -d "${alfred_workflow_data}/${seasonYear}" ]] && reload=$(./reload.sh)

# Get season files
standings_file="${seasonDir}/standings.json"
hitting_stats_file="${seasonDir}/hittingStats.json"
pitching_stats_file="${seasonDir}/pitchingStats.json"
icons_dir="${seasonDir}/icons"

# Load Standings
jq -cs \
   --arg icons_dir "${icons_dir}" \
   --arg favTeam "${(L)favTeam}" \
   --arg grouping "${grouping}" \
'{
    "variables": {
        "seasonYear": "'${seasonYear}'",
        "standings_file": "'${standings_file}'",
        "hitting_stats_file": "'${hitting_stats_file}'",
        "pitching_stats_file": "'${pitching_stats_file}'",
        "icons_dir": "'${icons_dir}'"
    },
    "skipknowledge": true,
	"items": (if (length != 0) then
		reduce .[].records[].teamRecords as $r ([]; . + $r) |
		([.[] | select(.clinchIndicator).team.division.name]) as $clinchedDivisions |
		(map({(.team.league.name): .leagueRank})) as $leagueSeqs |
		(map({(.team.division.name): .divisionRank})) as $divisionSeqs |
		("") as $sportSeqs | ("") as $sport |
		map({
			"title": "\(.'${grouping}Rank')  \(.name)  \(.clinchIndicator | if (.) then "(\(.))" else "" end)",
			"subtitle": "[ W: \(.wins)  L: \(.losses)  PCT: \(.pct) ]    L10: \(.record_lastTen // "-")    STRK: \(.streak // "-")    [ RS: \(.runsScored)  RA: \(.runsAllowed)  DIFF: \(.runDifferential | (if . > 0 then "+"+(.|tostring) else . end)) ]",
			"arg": "stats",
			"match": [
                .'${grouping}Rank', .name,
                (.team.division.name| . + " " + gsub("(merican |ational |eague)";"")),
                (if (.wildCardRank) then "wildcard" else "" end),
                (if (.clinched) then "clinched" else "" end)
            ] | map(select(.)) | join(" "),
			"icon": { "path": "\($icons_dir)/\(.id).png" },
			"text": { "copy": .name },
			"variables": {
			    "teamId": .id, "teamName": .name, "seq": .'${grouping}Rank',
				"divSeq": (.team.division.name | if (contains("East")) then 1 elif (contains("Central")) then 2 elif (contains("West")) then 3 else 4 end),
				"league": .team.league.name,
				"division": (.team.division.name|gsub("(merican |ational |eague)";"")),
				"divFullName": .team.division.name
			},
			"mods": {
			    "cmd": {"subtitle": "⌘↩ Sort by Division", "arg": "", "variables": {"grouping":"division"}},
			    "alt": {"subtitle": "⌥↩ Sort by League", "arg": "", "variables": {"grouping":"league"}},
			    "ctrl": {"subtitle": "⌃↩ Sort by Sport", "arg": "", "variables": {"grouping":"sport"}}
			}
		}) | (if ($grouping != "sport") then ([
		    (.[] | select((.variables.seq) == 1)) |
		    (. |= (.variables.divFullName) as $division | (.variables.league) as $league | {
				"title":"—————  \($league)  —————",
				"subtitle":(if ($grouping == "division") then (.variables.division | " "*(46-length/2)+.) else "" end),
				"icon": {"path":"images/iconLarge.png"},
				"match":"\($league) \(.variables.division) \($'${grouping}Seqs' | map(."\($'${grouping}')" | select(.)) | join(" ")) \(if ($clinchedDivisions | contains([$division])) then "clinched" else "" end) wildcard",
				"variables": .variables, "mods":.mods, "valid": false
			}) | (.variables.seq |= 0) | (.variables.teamName |= "")
		]+.) end)
		| (if ($grouping == "sport") then sort_by(.variables.seq) elif ($grouping == "league") then sort_by(.variables.league, .variables.seq) elif ($grouping == "division") then sort_by(.variables.league, .variables.divSeq, .variables.seq) end)
		| [(.[] | select(($grouping == "sport" and .variables.seq == 1) | not) | select((.variables.teamName|ascii_downcase) == $favTeam)) | (.match |= "")] + .
		| [(.[] | if ((.variables.teamName|ascii_downcase) == $favTeam) then (.title |= .+"  ★") end)]
	else
		[{
			"title": "No Standings Found",
			"subtitle": "Press ↩ to load standings for the current season",
			"arg": "reload"
		}]
	end)
}' "${standings_file}"