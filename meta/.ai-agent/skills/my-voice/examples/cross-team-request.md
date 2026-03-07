## Cross-Team Request

Use this format when Travis is reaching out to another team to ask for something — infrastructure access, alignment on a shared contract, input on an approach, or coordination on a deliverable.

These messages go to channels or people outside the Core team. The audience may have limited context on what Core is working on, so the message needs to be self-contained.

## Structure

```
:wave: hi team, [brief greeting or context-setting opener]

Context
[1-3 sentences: who you are, what you're working on, why you're reaching out. Link to relevant repos/docs if helpful.]

Requirements (... what I think we need)
[Numbered or bulleted list of specific asks. Be concrete.]

[Optional: brief rationale for each requirement]

does that sound right? if not, we're happy to follow your recommendations :thumbsup:

[Optional: TIA!]

cc: @relevant-person
```

Note the comma after the greeting (":wave: hi team,") — Travis always uses a comma there. The collaborative closing ("does that sound right?") stays lowercase with no period, and can end with a :thumbsup: to keep it friendly. This closing signals that Travis respects the other team's expertise and isn't dictating — it invites pushback in a way that's collaborative, not passive.

## Tone notes

- Open with `:wave:` — it's Travis's standard greeting for cross-team messages
- "Context" section should orient the reader quickly: team name, project, and why this matters
- Frame requirements as "what I think we need" — confident enough to propose, humble enough to defer
- Close warmly: "TIA!", "happy to discuss further", "does that sound right?"
- Always cc the relevant stakeholder on Travis's side

## Example

```
:wave: hi team, I wanted to ask some clarifying questions before spawning tickets for some :terraform-party: infrastructure

Context
I work on the app's Core team and we're looking to leverage Terraform for Datadog monitor and dashboard creation. We plan to be working closely with #sre on the actual implementation.
We currently house almost all of our code in our Monorepo here.

Requirements (... what I think we need) 

A Terraform workspace within the Monorepo, for the Monorepo to create it's own workspaces
This gives our team flexibility to create all our workspaces for different environments and setup folders/paths accordingly without having to PR into one of the Infra repos. 
Subsequently, we'll likely be creating a workspace for monitors and another for dashboards - for both NPD and for PROD.

A Vault integration for Datadog API keys to be able to create resources.


does that sound right? if not, we're happy to follow your recommendations :thumbsup:

TIA!

cc: @team-lead
```
