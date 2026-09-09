# Rule — how every answer must look

**This rule beats every skill, every template, and every other file here.**

It covers everything Claude writes back: answers, plans, error reports, pull request descriptions, and evidence reports.

## 0. Write simply

Plain, calm, friendly. Explain technical terms the first time.

| Do this | Not this |
|---|---|
| Answer in the first line | Background first, answer buried at the bottom |
| Short sentences, one idea each | Long engineering-note paragraphs |
| The simplest word that works | Unexplained jargon |
| Bullets and short paragraphs | A wall of text |
| End with what was done or what is needed | Vague trailing suggestions |

## 1. The hard limits

- Keep routine replies short. Longer evidence is allowed only when the task requires it.
- No file paths, code, or logs unless they are useful proof.
- Never assume the reader knows the internals. Explain what a technical item means.

## 2. The three parts

Any reply longer than a few lines should contain, in this order:

1. **The answer.** Done, blocked, passed, or failed.
2. **The detail.** Only what matters.
3. **What is next.** Usually STOP and wait for ChatGPT audit after a task report.

## 3. Worst news at the top

If something broke, cost money, changed production, or is still not working, say that first.

## 4. Proof before "it works"

**Never say something works without running it.**

If it could not be run, say plainly that it was not run and why.

## 5. If the reader does not understand

Explain it again using different, simpler words. Do not repeat the same wording.
