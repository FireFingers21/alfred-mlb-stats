#!/bin/zsh --no-rcs

# Get current/selected season
[[ "$(date +%s)" -ge "$(date -jv 3m +%s)" ]] && seasonYear="$(date +%Y)" || seasonYear="$(($(date +%Y) - 1))"
seasonDir="${alfred_workflow_data}/${seasonYear}"

# Get season standings
mkdir -p "${seasonDir}"
curl -sf --compressed --parallel --connect-timeout 10 \
    -L "https://bdfed.stitch.mlbinfra.com/bdfed/transform-mlb-standings?&standingsView=division&season=${seasonYear}&leagueIds=103&leagueIds=104&standingsTypes=regularSeason&hydrateAlias=noSchedule" -o "${seasonDir}/standings.json" \
    -L "https://bdfed.stitch.mlbinfra.com/bdfed/stats/team?&env=prod&gameType=S&group=hitting&stats=season&season=${seasonYear}" -o "${seasonDir}/hittingStats.json" \
    -L "https://bdfed.stitch.mlbinfra.com/bdfed/stats/team?&env=prod&gameType=S&group=pitching&stats=season&season=${seasonYear}" -o "${seasonDir}/pitchingStats.json" \
&& downloadStatus=1

if [[ -n "${downloadStatus}" ]]; then
    set -o extendedglob
    if [[ -f "${seasonDir}/standings.json" && ! -n ${seasonDir}/icons/*.png(#qNY1) ]]; then
        # Get Team Logos
        mkdir -p "${seasonDir}/icons"
        teamLogos="$(jq -r '[.records[].teamRecords[].id] | join(",")' "${seasonDir}/standings.json")"
        curl -sf --compressed --parallel --output-dir "${seasonDir}/icons" -L "https://midfield.mlbstatic.com/v1/team/{${teamLogos}}/spots/256" -o "#1.png"
    fi
    touch "${alfred_workflow_data}"
    printf "Standings Updated"
else
    printf "Standings not Updated"
fi