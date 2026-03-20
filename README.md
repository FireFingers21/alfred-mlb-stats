# <img src='Workflow/icon.png' width='45' align='center' alt='icon'> MLB Stats

View the latest MLB standings &amp; stats in Alfred

## Setup

This workflow requires [jq](https://jqlang.github.io/jq/) to function, which comes preinstalled on macOS 15 Sequoia and later.

## Usage

View the latest [MLB](https://www.mlb.com) standings via the `mlb` keyword. Type to filter by Team, Ranking, Division, League, Clinch, or Wildcard.

![Using the mlb keyword](Workflow/images/about/keyword.png)

* <kbd>↩</kbd> View Team Stats.
* <kbd>⌘</kbd><kbd>↩</kbd> Rank teams by Division.
* <kbd>⌥</kbd><kbd>↩</kbd> Rank teams by League.
* <kbd>⌃</kbd><kbd>↩</kbd> Rank teams by Sport.

Additional Team Stats can be viewed directly within Alfred. This includes Hitting and Pitching Stats.

![Viewing team stats in the Text View](Workflow/images/about/stats.png)

* <kbd>⌥</kbd><kbd>↩</kbd> Refresh Team Stats.

Append `::` to the configured [Keyword](https://www.alfredapp.com/help/workflows/inputs/keyword) to access other actions, such as manually reloading the standings cache.

![Other actions](Workflow/images/about/inlineSettings.png)

Configure the [Hotkey](https://www.alfredapp.com/help/workflows/triggers/hotkey/) as a shortcut for viewing standings.