# QuinSQL — AI Assistant and Agent Skills

[← Back to User Guide](USERGUIDE.md)

---

## Table of Contents

- [Overview](#overview)
- [Configuring a model](#configuring-a-model)
  - [`[llm]` section](#llm-section)
  - [API key](#api-key)
  - [`[ai]` section](#ai-section)
  - [Fully local with Ollama](#fully-local-with-ollama)
- [/ask — natural language to SQL](#ask--natural-language-to-sql)
  - [What happens to the generated statement](#what-happens-to-the-generated-statement)
  - [Follow-ups and result context](#follow-ups-and-result-context)
  - [Headless `/ask`](#headless-ask)
- [ORA-error explain and fix](#ora-error-explain-and-fix)
- [Agent Skills](#agent-skills)
  - [Where skills live](#where-skills-live)
  - [Anatomy of a skill](#anatomy-of-a-skill)
  - [How a skill is activated](#how-a-skill-is-activated)
  - [SQL scripts run through the pipeline](#sql-scripts-run-through-the-pipeline)
  - [External scripts (opt-in)](#external-scripts-opt-in)
  - [Templates](#templates)
  - [/skills command](#skills-command)
  - [Moving skills between machines](#moving-skills-between-machines)
  - [Security notes](#security-notes)
- [Writing effective skills — best practices](#writing-effective-skills--best-practices)
- [Audit trail](#audit-trail)
- [Troubleshooting](#troubleshooting)

---

## Overview

QuinSQL's AI features never execute anything on their own. Every statement the model
produces — from `/ask`, from an error fix, or from a skill script — is **shown first**, then
classified by the safety engine and routed through the same pipeline as a statement you
type yourself: classify → policy gate → confirm → execute → audit. The model only ever
*proposes*; you approve.

| Feature | Command | Needs a model? |
|---|---|---|
| Natural language → SQL | `/ask <question>` | yes |
| Explain an ORA error and propose a fix | `/ask fix this error` (or automatic) | yes |
| Agent skills — Markdown runbooks activated from natural language | `/ask …`, `/ask @skill-name …` | yes |
| List / inspect / validate skills | `/skills`, `quinsql skills` | no |

With no model configured, QuinSQL works exactly as before; `/ask` prints a one-line message
and the REPL continues.

---

## Configuring a model

### `[llm]` section

Add to `~/.quinsql/config.toml`:

```toml
[llm]
provider = "anthropic"          # anthropic | openai | gemini | groq | xai |
                                # deepseek | openrouter | together | fireworks |
                                # cohere | zai | moonshot | minimax | nebius |
                                # ollama | ollama_cloud | openai_compatible
model    = "claude-sonnet-4-5"
# base_url        = ""          # ollama / OCI GenAI / any OpenAI-compatible endpoint
# max_tokens      = 4096
# temperature     = 0.1
# timeout_seconds = 60
# rate_limit_retries = 3
```

AI features activate only when both `provider` and `model` are set.

### API key

The key is **never** stored in `config.toml`. Resolution order:

1. Credential store — `quinsql llm-key set` prompts once (no echo) and stores the key in the
   OS keychain or the encrypted file store, exactly like connection passwords.
2. The provider's standard environment variable: `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`,
   `GEMINI_API_KEY`, `GROQ_API_KEY`, `XAI_API_KEY` (`openai_compatible` uses
   `OPENAI_API_KEY`). Other provider variables are:
   `DEEPSEEK_API_KEY`, `OPEN_ROUTER_API_KEY`, `TOGETHER_API_KEY`,
   `FIREWORKS_API_KEY`, `COHERE_API_KEY`, `ZAI_API_KEY`, `MOONSHOT_API_KEY`,
   `MINIMAX_API_KEY`, `NEBIUS_API_KEY`, `OLLAMA_API_KEY` (ollama_cloud).

```
quinsql llm-key set                     # for [llm].provider
quinsql llm-key set --provider openai   # for another provider
quinsql llm-key delete
```

Ollama needs no key. Keys travel inside the encrypted credential blob of
`quinsql export` / `import`, never in clear text.

### `[ai]` section

```toml
[ai]
auto_run_reads      = false     # run READ statements from /ask without the [Y/n] prompt
explain_errors      = "prompt"  # auto | prompt | off
max_context_tables  = 20        # tables included in the schema context
max_fk_hops         = 2         # FK neighbourhood depth when expanding the context
result_context_rows = 20        # rows of the last result passed to "/ask explain this result"
history_exchanges   = 3         # previous /ask exchanges kept as context
max_prompt_chars    = 2000
max_tool_turns      = 8         # model ↔ tool round-trips per /ask (spans skill confirmations)
tool_result_rows    = 50        # rows of a skill SQL result returned to the model
skill_sql_preview_lines = 8     # skill script lines shown in the [Y/n] frame before folding (0 = never)
log_prompts         = false     # log full prompts/responses at DEBUG

[ai.skills]
enabled        = true
dir            = "~/.quinsql/skills"
allow_scripts  = false          # external scripts (py/sh/ps1/…) in skills — SQL scripts are always allowed
script_timeout_seconds  = 120
max_script_output_chars = 20000
export_max_file_mb      = 10
```

### Fully local with Ollama

```toml
[llm]
provider = "ollama"
model    = "qwen2.5-coder:14b"
base_url = "http://localhost:11434"
```

Nothing leaves the machine. Schema names and the rows you explicitly share via
`/ask explain this result` are the only data sent to the model, local or remote.

### OCI Generative AI (OpenAI-compatible endpoint)

```toml
[llm]
provider = "openai_compatible"
model    = "xai.grok-4"          # any model the OCI endpoint serves
base_url = "https://inference.generativeai.<region>.oci.oraclecloud.com/openai/v1"
```

Store an OCI Generative AI API key with `quinsql llm-key set`. `base_url` is the
provider's *base*; QuinSQL appends `/chat/completions` itself (a trailing slash
is optional).

---

## /ask — natural language to SQL

```
/ask which employees earn more than their manager
/ask show the 10 largest tables in schema SH
/ask explain this result
/ask @partition-maintenance for SALES
```

QuinSQL builds a **schema context** from the local catalog — tables matching the words in
your question, their columns, primary/foreign keys, and FK neighbours — and sends it with
your question. The model can also call read-only catalog tools (`list_schemas`,
`list_tables`, `describe_table`, `get_constraints`, …) when the context is insufficient. It never queries
the database itself.

```
✦ generated SQL:
  SELECT e.last_name, e.salary, m.salary AS manager_salary
  FROM employees e JOIN employees m ON m.employee_id = e.manager_id
  WHERE e.salary > m.salary
  blast radius: READ
  ⚠  blast radius: READ  (SELECT e.last_name, e.salary …)
  proceed? [Y/n]
```

### What happens to the generated statement

| Classification | Behaviour |
|---|---|
| `READ` | Prompt `[Y/n]` — or runs immediately when `auto_run_reads = true` |
| `WRITE` / `DDL` with a policy that would allow it | Prompt `[Y/n]` anyway — AI SQL is always confirmed once |
| `WRITE` / `DDL` under `confirm` policy | Normal confirm prompt |
| `DESTRUCTIVE` / unparseable | Normal `/plan approve` gate |
| Policy `deny` | Denied and audited, nothing runs |

Answer `y` to run, `n` to discard. Both outcomes are written to the audit journal with
actor `ai-ask` and the original question as rationale.

If the question cannot be answered with SQL (or is ambiguous) the model replies in plain
text, marked `✦`.

### Follow-ups and result context

- The last `history_exchanges` questions and their SQL are sent along, so
  `/ask now break that down by region` works.
- After any query, `/ask explain this result` includes the column names and the first
  `result_context_rows` rows of the last result grid.

### Headless `/ask`

`quinsql exec "/ask …"` and `/ask` lines inside `quinsql file` scripts print the proposal
but **never** park for confirmation. The statement executes only when it is `READ` and
`auto_run_reads = true`; otherwise QuinSQL prints
`statement not executed — requires interactive confirmation`, audits the proposal and
continues with exit code 0. Scheduled jobs behave the same.

---

## ORA-error explain and fix

After a failed statement the TUI shows a source frame with the offending token underlined:

```
  ✗ ORA-00942: table or view does not exist
  ╭─[input:1:15]
  │ SELECT * FROM employes
  │               ────────
  ╰─
```

Then, depending on `[ai].explain_errors`:

| Value | Behaviour |
|---|---|
| `prompt` (default) | Hint chip `/ask fix this error` — nothing is sent until you ask |
| `auto` | `/ask fix this error` runs automatically (interactive only, never inside scripts or pastes) |
| `off` | No AI involvement |

`/ask fix this error` (also `explain this error`, `fix`) sends the error, the failing
statement, the schema objects it references and near-miss object names. The reply:

```
✦ proposed fix:
  SELECT * FROM employees
  ✦ explain  EMPLOYES does not exist in HR; EMPLOYEES is the closest table name.
  proceed? [Y/n]
```

The fix is a proposal like any other — classified, confirmed, audited (rationale
`ORA-00942 explain+fix`). When the model has no safe fix it explains only.

In headless mode the error frame is rendered with `miette`; explain is never automatic.

---

## Agent Skills

A skill is a folder of Markdown instructions (plus optional scripts, references and
templates) that captures *how your team does something* — "our standard partition
maintenance", "our masking policy check", "month-end reconciliation". QuinSQL follows the
[Anthropic Agent Skills](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)
format, so skills written for Claude Code or other agents work here and vice versa.

Skills are **not** slash-commands. The model picks a skill when your `/ask` request matches
its description, or you force one with `@skill-name`.

### Where skills live

`~/.quinsql/skills/<skill-name>/` (change with `[ai.skills].dir`). Each skill is one
sub-directory containing `SKILL.md`. Create and edit skills with any editor or keep them in a
git repository and symlink/copy the folder — QuinSQL only reads them.

A complete, runnable example ships in the repository under
[`examples/skills/table-stats-health`](examples/skills/README.md): a read SQL script with
binds, a `.j2` report template, a reference file and a confirm-gated `DBMS_STATS` refresh
step. Copy it into `~/.quinsql/skills/` to try the whole flow. A second example,
`table-auto-annotate` in the same directory, profiles an obscurely named object
and applies model-proposed annotations plus `COMMENT ON` via one gated PL/SQL
step (demo data under `examples/skills/demo-data/`).

### Anatomy of a skill

```
~/.quinsql/skills/
└── partition-maintenance/
    ├── SKILL.md                      # required
    ├── references/                   # optional: extra Markdown read on demand
    │   └── retention-policy.md
    ├── scripts/                      # optional
    │   ├── list_stale_partitions.sql # SQL / PL*SQL → runs through the QuinSQL pipeline
    │   ├── compress_partition.sql
    │   └── export_report.py          # external → only with allow_scripts = true
    └── templates/                    # optional (QuinSQL extension)
        ├── report.md                 # format the model should follow
        └── report.j2                 # rendered by QuinSQL from the last result set
```

```markdown
---
name: partition-maintenance
description: Lists stale SALES partitions older than the retention window and proposes the standard compress/drop sequence. Use when the user asks about partition maintenance, retention, or stale partitions.
license: internal
allowed-tools: catalog sql template
metadata:
  author: dba-team
  version: "1.2"
---
# Partition maintenance

## Workflow
1. Run `scripts/list_stale_partitions.sql` with `&retention_days` (default 90).
2. For each partition listed, run `scripts/compress_partition.sql` with `&partition_name`.
3. Re-run step 1 and confirm the list is empty.
4. Render `templates/report.j2` with the final list.

See [references/retention-policy.md](references/retention-policy.md) for the policy.
```

Frontmatter fields:

| Field | Required | Rules |
|---|---|---|
| `name` | yes | lowercase letters, digits, hyphens; ≤ 64 chars; **must equal the folder name** |
| `description` | yes | ≤ 1024 chars, no XML tags; say *what* the skill does **and when to use it** |
| `allowed-tools` | no | space-separated subset of `catalog sql script template`; default `catalog sql template` |
| `license`, `metadata` | no | free-form |

### How a skill is activated

Progressive disclosure keeps token cost low:

1. **Level 1 — always.** When at least one skill exists, every `/ask` includes one line per
   skill: `- name: description` (≈ 100 tokens each).
2. **Level 2 — on match.** If exactly one skill fits, the model calls `use_skill` and
   receives the SKILL.md body. `/ask @name …` forces this step.
3. **Level 3 — on demand.** The model reads `references/…`/`templates/…` with
   `read_skill_file`, runs `scripts/*.sql` with `run_skill_sql`, external scripts with
   `run_skill_script`, and renders `templates/*.j2` with `render_template` — only the tools
   permitted by `allowed-tools`.

The whole run is bounded by `max_tool_turns`.

### SQL scripts run through the pipeline

`scripts/*.sql` (also `.pls .plb .pks .pkb`) are executed **inside QuinSQL** on your
current connection — same transaction, `&var` substitution, SQL\*Plus compatibility, and
the full safety pipeline:

- `READ` statements run at once; their rows (up to `tool_result_rows`) go back to the
  model so it can take the next step.
- Anything else stops the run and shows the statement with a `[Y/n]` prompt:

  ```
  ✦ skill partition-maintenance · scripts/compress_partition.sql:
    ALTER TABLE sales MOVE PARTITION p_2023_q1 COMPRESS
    blast radius: DDL
    proceed? [Y/n]
  ```

  Skill scripts are shown folded in the confirmation frame (first
  `skill_sql_preview_lines` lines); press `?` at the `[Y/n]` prompt to print the
  whole statement, Shift+Tab to scroll while the prompt is pending.

  `y` executes it and the model continues with the outcome (rows affected or the ORA
  error); any other answer tells the model "user declined — do not retry this statement"
  and it carries on with the remaining steps. Destructive statements go through
  `/plan approve` / `/plan cancel` instead; while such an approval is pending, typing
  anything other than a `/plan` command abandons the skill run (audited as `AiAbandoned`).

Binds come from the model's `binds` argument; a script with an unresolved `&name` is
rejected with the list of missing names. By default a script's result goes only to
the model; to show it to the user as a native result grid as well, put `-- @display`
in the script's leading comment header (the skill author decides — this does not
depend on the model remembering anything). The model can also request it per call
with `display: true`.

A script whose result *is* SQL — rebuilt DDL, `DBMS_METADATA.GET_DDL` output — can
instead put `-- @render sql` in the header. The result is then shown as one
syntax-highlighted SQL block: the last column of each row becomes one line of the
script (one row per line, trailing whitespace trimmed). `@render sql` implies
display; any other `@render` value is ignored.

### External scripts (opt-in)

Python, shell, PowerShell or other files under `scripts/` run only when
`[ai.skills].allow_scripts = true` **and** the skill's `allowed-tools` includes `script`.
They run with the skill folder as working directory, an interpreter chosen by extension
(`.py` → `python3`/`python`, `.sh` → `sh`, `.ps1` → `pwsh`/`powershell`, `.js` → `node`,
otherwise executed directly), a `script_timeout_seconds` kill timer, and an environment
scrubbed of anything whose name contains `KEY`, `TOKEN`, `SECRET`, `PASSWORD`, `PASSWD`
or `CREDENTIAL`. `QUINSQL_SKILL_DIR`, `QUINSQL_PROFILE` and `QUINSQL_USER` are provided.
Combined output (truncated to `max_script_output_chars`) is returned to the model; the
run is audited with gate `SkillScript`.

### Templates

| File | Rendered by | Use |
|---|---|---|
| `templates/*.md` (any non-`.j2`) | the model | Loaded via `read_skill_file`; the model formats its answer to match. Good for prose reports. |
| `templates/*.j2` | QuinSQL (`minijinja`) | `render_template` fills it with `rows`, `columns`, `row_count` from the last result, plus `vars` from the model, `profile`, `user`, `now`. Deterministic, zero tokens. |

Rendered `.j2` output is printed in the scrollback and returned to the model.
Markdown in rendered templates and answers is rendered with styles in the
TUI (headings, bold, italics, inline code, lists, quotes); pipe tables become
native result grids and ````sql`/````plsql` fences become highlighted SQL
blocks; text following a grid is dimmed (footer role). Headless mode and
SPOOL keep the raw Markdown.

```jinja
# Partition report — {{ vars.schema }}

| {% for c in columns %}{{ c }} | {% endfor %}
|{% for c in columns %}---|{% endfor %}
{% for r in rows %}| {% for v in r %}{{ v }} | {% endfor %}
{% endfor %}
{{ row_count }} rows · {{ profile }} · {{ user }} · {{ now }}
```

### /skills command

Read-only; works without a model.

```
/skills list                list name, description, [tools: …]
/skills show <name>         frontmatter, files by folder, first 40 body lines, issues
/skills validate [<name>]   full validation report
/skills reload              re-read the skills directory
```

Headless equivalents for CI: `quinsql skills list`, `quinsql skills show <name>`,
`quinsql skills validate [<name>]` (exit 1 when any error-level issue exists).

Validation checks:

| Check | Severity |
|---|---|
| Spec violations — bad `name`, name ≠ folder, missing/overlong description, XML tags | error (skill skipped) |
| A `scripts/…`, `references/…`, `templates/…` path mentioned in SKILL.md does not exist | error |
| Unknown `allowed-tools` token | error |
| Description has no trigger phrase ("use when …") | warning |
| SKILL.md body longer than 500 lines | warning |
| Skill allows `script` but `allow_scripts = false` | warning |
| `http(s)://`, `curl`, `wget`, `Invoke-WebRequest` in body or scripts | warning — audit before use |
| Credential-looking strings (`api_key=`, `sk-…`, `Bearer …`, `password=`) | warning — skills travel in clear text |
| SQL script classified DESTRUCTIVE/UNKNOWN | info |

### Moving skills between machines

```
quinsql export backup.zip --include-skills
quinsql import backup.zip [--skills-dir /path] [--overwrite]
```

Skills are archived with forward-slash paths and restored byte-for-byte into the target
machine's `[ai.skills].dir`. Existing skill folders are skipped unless `--overwrite`.
Interpreters are chosen by extension, so `.py`/`.sh` skills keep working across
Linux/macOS/Windows; platform-specific scripts (`.ps1` vs `.sh`) are the author's concern.

### Security notes

Treat a skill like software you install: it can direct the model to run scripts and SQL.
Use skills you wrote or audited. Read every file — SKILL.md, scripts, references. Prefer
`allowed-tools: catalog sql template` (the default) and keep `allow_scripts = false` unless
a skill genuinely needs an external tool. Skills that fetch from the network are flagged
by `/skills validate`; fetched content can carry injected instructions. Nothing a skill
asks for bypasses the pipeline: writes still prompt, destructive statements still require
`/plan approve`, and everything lands in `/audit`.

---

## Writing effective skills — best practices

Distilled from Anthropic's
[skill authoring guide](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices),
adapted to database runbooks.

**Be concise — the model already knows SQL and Oracle.** SKILL.md competes for context with
the schema, your question and the conversation. Challenge every paragraph: does the model
need this? Explain *your* conventions (which tables, which filters, which order), not what
a partition or a foreign key is.

**Name and description are what the model matches on.** Use a noun phrase or gerund
(`partition-maintenance`, `auditing-grants`), not `helper` or `utils`. Write the
description in third person and include both *what* and *when*:

```yaml
description: Checks every table in the schema for missing FK indexes and proposes CREATE INDEX statements. Use when the user asks about missing indexes, slow joins, or foreign-key performance.
```

Avoid "Helps with indexes".

**Match the degree of freedom to the risk.**
- *Open field* (analysis, reporting): give goals and heuristics; let the model choose the query.
- *Narrow bridge* (DDL sequences, data fixes): give exact scripts and the exact order —
  "Run `scripts/compress_partition.sql` for each row; do not alter the statement."

Put fragile statements in `scripts/*.sql` so they are deterministic and still gated by the
pipeline, instead of asking the model to generate them.

**Use workflows with checkpoints and feedback loops.** Number the steps. Make the model
verify before and after: "run `scripts/count_rows.sql`; if the count is not zero, stop and
report." Information-gathering steps are plain `READ` scripts — their rows come back to the
model automatically.

**Progressive disclosure.** Keep SKILL.md under 500 lines and one level deep: link
`references/*.md` directly from SKILL.md, never from another reference. Give long
reference files a table of contents. Put rarely-needed detail (policy text, column
dictionaries, examples) in references so it costs nothing until read.

**Templates for output.** Use `templates/*.md` when the model should write the report;
use `templates/*.j2` when the report is a deterministic function of a result set. Say in
SKILL.md which one and when.

**Use `&binds`, not literals.** `WHERE owner = '&schema'` makes a script reusable; the
model fills `binds` from the user's request. Document the bind names and defaults in
SKILL.md.

**Declare the smallest `allowed-tools` set.** `catalog` for discovery, `sql` for scripts,
`template` for rendering; add `script` only when there is no SQL way.

**Avoid time-sensitive content and inconsistent terms.** No "before/after release X";
pick one word per concept (always "partition", not "segment/partition/piece").

**Write the evaluation before the skill.** Collect three representative `/ask` prompts
that should trigger the skill and one that should not. Run them without the skill, note
what goes wrong, write the minimum that fixes it, re-run. Test with every model you plan
to use — a small local model may need more explicit steps than a frontier model.

**Iterate from observation.** Watch which files the model reads and skips (`/audit` shows
every script run). If a rule keeps being missed, make it a numbered step or a `MUST`;
if a reference is never read, delete it or signal it better.

**Keep secrets out.** Skills are exported in clear text. Connection details come from the
QuinSQL profile; API keys from `llm-key`. `/skills validate` warns when something looks
like a credential.

**Forward slashes only** in paths (`scripts/x.sql`), even on Windows.

---

## Audit trail

Every AI interaction is in `/audit` with actor `ai-ask`:

| Gate | Meaning |
|---|---|
| `AiConfirmed` | AI-proposed statement the user approved and ran |
| `RequireConfirm` / `PlanCancelled` (outcome denied) | user declined the proposal |
| `AiProposal` | shown but not executable (headless) |
| `AiAnswer` | plain-text answer, no SQL |
| `AiExplain` | error explanation without a fix |
| `SkillScript` | external skill script run |
| `AiAbandoned` | a suspended skill run was abandoned |

The rationale column carries the natural-language question, `ORA-… explain+fix`, or
`skill:<name>/<script>`, followed by the classifier's own rationale.

---

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `no LLM provider configured — set [llm] in ~/.quinsql/config.toml` | Add `[llm] provider` and `model` |
| `⚠ [llm] provider 'anthropic' needs an API key` at startup | `quinsql llm-key set` or export `ANTHROPIC_API_KEY` |
| `LLM request timed out after 60s` | Raise `[llm].timeout_seconds`; check `base_url` for Ollama |
| `404 Not Found` from an OpenAI-compatible endpoint | `base_url` must be the API base (e.g. `…/openai/v1`), without `/chat/completions` |
| `429 Too Many Requests` | The provider's per-key rate limit; QuinSQL retries `[llm].rate_limit_retries` times with backoff — raise it, slow down, or pick a model with a higher quota |
| `/ask` answers in prose instead of SQL | The question was ambiguous — name the tables or columns you mean |
| Skill never activates | Check `/skills validate`; sharpen the description's "use when…" clause; force with `@name` |
| `skill '@x' not found` | Folder name must equal the frontmatter `name`; run `/skills reload` |
| `external scripts are disabled` | Set `[ai.skills].allow_scripts = true` and add `script` to `allowed-tools` |
| `missing bind: retention_days` | The script uses `&retention_days`; mention a value in your request or add a default in SKILL.md |
