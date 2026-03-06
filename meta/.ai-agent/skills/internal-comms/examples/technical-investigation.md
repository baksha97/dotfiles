## Technical Investigation

Use this format when Travis is sharing findings from debugging, root cause analysis, discovery tickets, or any situation where he's investigated an issue and needs to communicate what he found.

These messages tend to go to his immediate team, cross-functional partners, or a broader engineering channel. The audience has technical context but may not have been following the investigation closely.

## Structure

The pattern Travis uses most often for investigations:

```
:mag: What's clear:
[Confirmed facts — what was reproduced, what the root cause is, what's known for certain. Be specific: version numbers, build numbers, reproduction steps.]

:question: What's unclear:
[Open questions — things that still need investigation. Frame as questions.]

:arrow_right: Recommended Next Steps:
[@person, specific action item]
[@person, specific action item]
[Any additional context or caveats]
```

Use an emoji before each section header to make them visually scannable. Pick emoji that fit the vibe — `:mag:` for findings, `:question:` for unknowns, `:arrow_right:` for next steps are good defaults, but feel free to swap in something more contextually relevant.

This structure works because it separates fact from uncertainty and makes action items unmissable.

## Tone notes

- Lead with facts, not opinions. "The issue was reproduced by..." not "I think the issue might be..."
- When recommending actions to people on other teams, be direct but respectful: "@person, I recommend..." or "@person, given that this stems from X, I'd prefer Y to weigh in"
- It's fine to express uncertainty: "I cannot say for certain, but it appears that..." — this is honest, not weak
- Reference tickets, PRs, and GitHub issues inline
- If there's a hypothesis, label it as such: "I have a hypothesis..."

## Example

```
I have a hypothesis...

our app builds (including this one using the older SDK) uses vendor-sdk-1.x and anything related to testing web-auth which is using vendor-sdk-2.x

Can @identity-team-lead ask the vendor if there would be any issues going between versions? I suspect that our internal users bouncing between major sdk versions have landed their device in a corrupt state since they rewrote their Keychain implementation completely in 2.0.0.

We know that their previous keychain implementation was :party_poop: from previous incidents, so I have low confidence their newer implementation is bug free and contains the ability to downgrade appropriately
```

## Another example (full investigation summary)

```
:mag: What's clear:
Once we upgrade the SDK, the app cannot downgrade it, nor should a user downgrade their app.
Specifically, a user should not be downgraded logged in. 
If a downgrade occurs, users will be left with a broken app that they cannot resolve themselves unless they wipe the device or reset the keychain. Resetting the keychain is currently not possible in the production app (we've only added this capability to a dev build for testing).
1.26.1 ---upgrade---> 1.27.x seem to work as expected with the testing we've done today. 

:question: What's unclear:
Are there any other edge cases that a user is likely to encounter given users don't typically downgrade application versions on iOS?
Does Android contain similar issues?
Does this impact our ability to feature flag native vs web auth flows?

:arrow_right: Recommended Next Steps:
@identity-team-lead, I recommend the identity team reevaluate how multiple client applications are managed on a single device with the SDK, particularly in light of the vendor's reimplementation of credential storage. There appears to be something off here, at least when bouncing between versions.
The Core team will open tickets to investigate:
potential situations users can find themselves in with our upcoming release 
potential app feature-flag issues and points of failure / edge cases for this web-auth
potential Android related issues 
@identity-team-lead, given that this stems from the vendor's SDK update that the identity SDK picked up in the Web Auth version, I'd prefer the vendor to weigh in on the associated risks. I don't see any warnings about downgrading SDK in their documentation.

I cannot say for certain, but it appears that for now this concern should be isolated to internal folks who have used the latest SDK version on their device
```
