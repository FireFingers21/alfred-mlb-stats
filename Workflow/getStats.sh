#!/bin/zsh --no-rcs

# Get age of stats files in minutes
[[ -f "${hitting_stats_file}" ]] && minutes="$((($(date +%s)-$(date -r "${hitting_stats_file}" +%s))/60))"

# Download Stats Data
if [[ "${forceReload}" -eq 1 ]]; then
    # Rate limit to only refresh if data is older than 1 minute
    [[ "${minutes}" -gt 0 || -z "${minutes}" ]] && reload=$(./reload.sh) && minutes=0
fi

# Format Last Updated Time
if [[ ! -f "${hitting_stats_file}" || ${minutes} -eq 0 ]]; then
    lastUpdated="Just now"
elif [[ ${minutes} -eq 1 ]]; then
    lastUpdated="${minutes} minute ago"
elif [[ ${minutes} -lt 60 ]]; then
    lastUpdated="${minutes} minutes ago"
elif [[ ${minutes} -ge 60 && ${minutes} -lt 120 ]]; then
    lastUpdated="$((${minutes}/60)) hour ago"
elif [[ ${minutes} -ge 120 && ${minutes} -lt 1440 ]]; then
    lastUpdated="$((${minutes}/60)) hours ago"
else
    lastUpdated="$(date -r "${hitting_stats_file}" +'%Y-%m-%d')"
fi

# Format Stats to Markdown
lastUpdatedDate="$(date -r "${hitting_stats_file}" +%Y-%m-%d)"
mdOutput=$(jq -crs --argjson teamId "${teamId}" --arg division "${division}" --arg icons_dir "${icons_dir}" --arg lastUpdatedDate "${lastUpdatedDate}" \
'[.[].stats[] | select(.teamId == $teamId)] |
40 as $spaces |
    "![Team Logo](\($icons_dir)/\($teamId)small.png)\n",
    "# \(.[0].teamName)",
    "\n**Games Played:** \(.[0].gamesPlayed)      ·      **League:** \($division|sub("(?<x>\\w+$)";"(\(.x))"))      ·      **Date:** \($lastUpdatedDate)",
    "\n***\n\n### Hitting\n\n```",
    ("Games Played:"|.+" "*($spaces-length))+"\(.[0].gamesPlayed)",
    ("At Bats:"|.+" "*($spaces-length))+"\(.[0].atBats)",
    "",
    ("Runs:"|.+" "*($spaces-length))+"\(.[0].runs)",
    ("Hits:"|.+" "*($spaces-length))+"\(.[0].hits)",
    ("Doubles:"|.+" "*($spaces-length))+"\(.[0].doubles)",
    ("Triples:"|.+" "*($spaces-length))+"\(.[0].triples)",
    ("Home Runs:"|.+" "*($spaces-length))+"\(.[0].homeRuns)",
    ("Runs Batted In:"|.+" "*($spaces-length))+"\(.[0].rbi)",
    "",
    ("Walks:"|.+" "*($spaces-length))+"\(.[0].baseOnBalls)",
    ("Strikeouts:"|.+" "*($spaces-length))+"\(.[0].strikeOuts)",
    "",
    ("Stolen Bases:"|.+" "*($spaces-length))+"\(.[0].stolenBases)",
    ("Caught Stealing:"|.+" "*($spaces-length))+"\(.[0].caughtStealing)",
    "",
    ("Batting Average:"|.+" "*($spaces-length))+"\(.[0].avg)",
    ("On-Base Percentage:"|.+" "*($spaces-length))+"\(.[0].obp)",
    ("Slugging Percentage:"|.+" "*($spaces-length))+"\(.[0].slg)",
    ("On-Base Plus Slugging:"|.+" "*($spaces-length))+"\(.[0].ops)",
    "```",
    "\n\n### Pitching\n\n```",
    ("Wins:"|.+" "*($spaces-length))+"\(.[1].wins)",
    ("Losses:"|.+" "*($spaces-length))+"\(.[1].losses)",
    ("Earned Run Average:"|.+" "*($spaces-length))+"\(.[1].era)",
    "",
    ("Games:"|.+" "*($spaces-length))+"\(.[1].gamesPitched)",
    ("Games Started:"|.+" "*($spaces-length))+"\(.[1].gamesStarted)",
    ("Complete Games:"|.+" "*($spaces-length))+"\(.[1].completeGames)",
    ("Shutouts:"|.+" "*($spaces-length))+"\(.[1].shutouts)",
    ("Saves:"|.+" "*($spaces-length))+"\(.[1].saves)",
    ("Save Opportunities:"|.+" "*($spaces-length))+"\(.[1].saveOpportunities)",
    "",
    ("Innings Pitched:"|.+" "*($spaces-length))+"\(.[1].inningsPitched)",
    ("Hits:"|.+" "*($spaces-length))+"\(.[1].hits)",
    ("Runs:"|.+" "*($spaces-length))+"\(.[1].runs)",
    ("Earned Runs:"|.+" "*($spaces-length))+"\(.[1].earnedRuns)",
    ("Home Runs:"|.+" "*($spaces-length))+"\(.[1].homeRuns)",
    ("Hit Batsmen:"|.+" "*($spaces-length))+"\(.[1].hitBatsmen)",
    ("Walks:"|.+" "*($spaces-length))+"\(.[1].baseOnBalls)",
    ("Strikeouts:"|.+" "*($spaces-length))+"\(.[1].strikeOuts)",
    "",
    ("Walks & Hits Per Inning Pitched:"|.+" "*($spaces-length))+"\(.[1].whip)",
    ("Batting Average Against:"|.+" "*($spaces-length))+"\(.[1].avg)",
    "```"
' "${hitting_stats_file}" "${pitching_stats_file}" | sed 's/\"/\\"/g')

# Output Formatted Stats to Text View
cat << EOB
{
    "variables": { "forceReload": 1 },
    "response": "${mdOutput//$'\n'/\n}",
    "footer": "Last Updated: ${lastUpdated}            ⌥↩ Update Now"
}
EOB