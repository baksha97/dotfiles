## General Communications

Fallback format for anything that doesn't fit the other templates — emails, longer-form updates, alignment requests, or hybrid messages.

## Principles

When no specific template applies, fall back to these core principles from Travis's writing:

1. **Structure over length** — if the message has more than one idea, break it into labeled sections. Headers, bold labels, or even just line breaks between logical chunks.
2. **Lead with the point** — don't build up to the ask. State what you need or what happened, then provide supporting context.
3. **Tag people with actions** — every person mentioned should know exactly what's expected of them. "@person, can you..." or "@person, I recommend..."
4. **Close with an opening** — invite response, feedback, or questions. "does that sound right?", "happy to discuss", "let me know if there's any questions"

## For emails

Travis's email style is slightly more structured than Slack but keeps the same voice:
- Subject line should be specific and scannable
- Still lowercase-default in the body
- Use sections/headers for anything beyond a few sentences
- Sign off simply — no "Best regards" or "Sincerely", just his name or nothing at all

## For alignment / coordination messages

When Travis needs multiple teams to align on something (shared contracts, event definitions, attribute keys), the pattern is:

```
[Brief context — what needs alignment and why]

[Section 1: specific area]
[Concrete question or ask]

[Section 2: specific area]
[Concrete question or ask]

Can [team/person] please work with [team/person] to provide [specific deliverable] ASAP?
```

## Example (cross-team alignment)

```
it appears that event-wise, team-B is only a subset of the events that team-A has defined.

I would like to see the events applicable to both platforms - especially for Phase I.

Events

Can these events be applied to Android even if you haven't denoted :android:? 
This is an assumption we're working under for PROJ-1691 (cc: @platform-lead)

Attributes

I need both teams to align on attribute keys, their meaning, and their value-source (e.g. the business logic description of where its derived)
We're currently working with the keys defined by team-A for PROJ-1691


Can team-B please work with team-A to provide an aligned/consolidated document for RUM Events (and attribute definitions) related to Streaming ASAP?
```
