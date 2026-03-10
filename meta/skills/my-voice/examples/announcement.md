## Announcement / Show-and-Tell

Use this format when Travis is sharing something he shipped, a new capability, a demo, or any "here's what we built" message. These go to broader engineering channels and are meant to generate awareness and invite feedback.

## Structure

```
:wave: [opening line — what you did and why it matters, 1-2 sentences]

[Key details — what's different, what changed, what the audience should notice. Use bullets if there are multiple points, but keep each one to 1-2 lines.]

[Optional: "Attached: [description of screenshots, code snippets, or links]"]

feel free to take a look, test it yourself, and let me know if there's any questions or issues!
```

The closing invitation is characteristic — Travis wants people to engage, not just read.

## Tone notes

- Lead with the "so what" — why should the reader care?
- Be specific about what changed: "UserInfo/Entitlements/Favorite+Followed Teams are reactive" not "we improved the data flow"
- Include attachments or links to make it tangible (Datadog screenshots, code diffs, YAML snippets)
- Parenthetical asides for bonus context: "(don't worry - we have persistent device identifiers...)"
- Use a celebratory emoji (`:rocket:`, `:tada:`, `:chart_with_upwards_trend:`) to punctuate the key milestone or good-news line — especially when sharing something that's now live or fully rolled out. One per message, on the line that carries the most weight.
- End with an open invitation for questions

## Example

```
:wave: hi folks, just wrapped up the APM ticket and figured it'd be great to exemplify what a single RUM event looks like in Datadog!

You may not notice from the event data alone, but the behavior is quite different and much more consistent:

UserInfo/Entitlements/Favorite+Followed Teams are reactive
 if a user logs out, their user info is no longer associated (helps us understand user state in the journey)
don't worry - we have persistent device identifiers on both platforms that now persist through uninstalls on both platforms. This means that you can always narrow back down to a device's events - even when changing users!) 


All events are associated to a team to easily identify and create related notebooks/dashboards
Parameters are auto injected (ignorable if not needed)


There's a lot more things that the observability SDK brings, but this data is just what teams are mostly going to be interacting with.

Attached: Datadog Event, Code Change for Event, & snippet from Event YAML

Feel free to take a look, test it yourself, and let me know if there's any questions or issues!
```
