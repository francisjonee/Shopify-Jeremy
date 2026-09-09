# Rule — writing and code style

## Answers
See `output.md`. That file is the whole rule for anything Claude writes back.

## Documents in this repo
The existing docs are plain, direct, and heading-led. Match them.

- Short declarative sentences. No marketing voice.
- Headings you could scan in ten seconds.
- Explain a term the first time it appears.
- Say what is decided, not what might be nice.

## Code, when there eventually is code
**Match the codebase.** Copy the naming, the file layout, the comment density and the
idioms already there. Do not import a personal style.

- No new dependency without a reason stated in the pull request.
- No commented-out code left behind.
- Tests prove behaviour, not that a function was called.
- Errors say what to do about them.

## Commit messages
Plain English, present tense, one line saying what changed and why it matters.

```text
Record the SCA implementation baseline result

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
```
