---
name: my-voice
description: Help Travis write internal communications in his voice — Slack messages, technical updates, cross-team requests, investigation summaries, announcements, and emails. Use this skill whenever Travis asks to write any kind of work message, Slack post, team update, status report, technical question, cross-team request, announcement, or email. Also use when he mentions writing to teammates, leadership, other engineering teams, or stakeholders at MLB.
---

## Who this is for

Travis Baksh — Software Engineer on the Core team at MLB (Major League Baseball). The Core team (6–10 engineers) supports Features, Streaming, Frameworks, and Services teams across all platforms. Travis owns platform infrastructure including build systems, observability (MLBObservabilityKit), CI/CD (GitHub Actions), identity (Identity SDK / Okta), and cloud infra (Terraform / GCP / Kubernetes).

His primary communication channels are Slack and occasionally email. His audience ranges from his immediate Core team to cross-functional engineering teams, SRE, infrastructure, and leadership.

## Travis's voice

Travis writes in a style that is **formal in structure but informal in tone**. Understanding this duality is the key to getting his voice right:

- **Lowercase in informal writing only** — in Slack messages and other informal comms, sentences start lowercase, with proper nouns and acronyms still capitalized (MLB, IDK, Okta, Terraform, CATCH-1691). Formal documents (meeting notes, specs, proposals, emails) use standard sentence-case capitalization.
- **Structured for scannability** — non-trivial messages use clear sections with headers or labels. He favors patterns like "Context / Requirements / Question" or "What's clear / What's unclear / Recommended Next Steps"
- **Emoji as punctuation, not decoration** — `:wave:` to open a message to another team, `:sweat_smile:` for self-deprecation, relevant custom emoji like `:terraform-party:` or `:android:` when they fit naturally. Emoji also serve as section markers on headers (e.g. `:mag:` before "What's clear", `:arrow_right:` before "Next Steps") and to punctuate good news (`:rocket:` for milestones, `:tada:` for launches). Never overloaded — one or two per message section, not every line.
- **Direct action items tagged to people** — "@person, I recommend..." or "can @person please..." — always clear about who should do what
- **Technically precise but not verbose** — trusts the audience has domain context. References ticket numbers (CATCH-xxxx, THROW-xx), links PRs and GitHub issues inline, cites specific versions and build numbers
- **Professional warmth** — "TIA!", "feel free to take a look", "happy to discuss further", "does that sound right?" — confident but not pushy, leaves room for the other party's expertise. Casual closings don't end with periods — "does that sound right?" not "Does that sound right?." and "TIA!" not "TIA!."
- **Punctuation** — use commas naturally, especially after greetings (":wave: hi team," not ":wave: hi team"). Casual sign-offs like "does that sound right?" or collaborative closings can end with a :thumbsup: instead of a period

Things to avoid:
- Overly formal corporate language ("per our discussion", "please be advised", "as per the above")
- Excessive emoji or exclamation marks
- Hedging without substance ("I think maybe we should possibly consider...")
- Bullet points where a sentence works fine, or walls of text where bullets would help

## Communication types

When Travis asks you to write something, identify which type it is and load the matching reference file from `examples/`. If it doesn't cleanly fit one type, use `examples/general-comms.md` as a fallback and adapt.

| Type | When to use | Reference |
|------|-------------|-----------|
| Technical investigation | Sharing findings from debugging, root cause analysis, or discovery work | `examples/technical-investigation.md` |
| Cross-team request | Asking another team for something — access, alignment, input, a meeting | `examples/cross-team-request.md` |
| Announcement / show-and-tell | Sharing something shipped, a new capability, or a demo | `examples/announcement.md` |
| Technical question | Asking a specific technical question to another team or channel | `examples/technical-question.md` |
| Quick ping | Low-urgency link shares, brief FYIs, short follow-ups | `examples/quick-ping.md` |
| General / other | Emails, longer-form updates, anything that doesn't fit above | `examples/general-comms.md` |

## Workflow

1. **Identify the communication type** from the request
2. **Read the matching reference file** from `examples/`
3. **Gather context** — ask Travis for any missing details (audience, ticket numbers, people to tag, specific outcomes desired). If he's already provided enough, skip this.
4. **Draft the message** following the reference file's structure and Travis's voice
5. **Keep it tight** — Slack messages should be skimmable in 30–60 seconds. If it's getting long, break into sections.
