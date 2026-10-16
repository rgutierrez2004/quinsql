---
name: table-auto-annotate
description: Infer the business meaning of an obscurely named table or view and its columns from the dictionary and a data sample, propose annotations (display_name, description, semantic_type) plus comments, and apply them so Oracle Select AI can understand the object — use when the user asks to annotate, document, describe, inspect, add metadata to, or explain the meaning of a table or view, or to show its current annotations or comments.
allowed-tools: catalog sql
license: MIT
metadata:
  author: quinsql
  version: "1.0"
---

# Table auto-annotate

Turn a cryptic table or view (`XE01`, columns `C1..C9`) into something Select AI
and humans can understand: profile it, sample it, propose annotations, show them
for review, and apply them only after the user confirms.

## Inputs

- `schema` — owner of the object. Use the schema the user named; otherwise the
  current session schema. Plain identifier only (e.g. `HR`).
- `object` — the table or view name. Plain identifier only. Ask if ambiguous.

## Workflow

1. Run `scripts/object_summary.sql` with binds `{"schema": "<SCHEMA>", "object": "<OBJECT>"}`.
   One row: `OBJECT_TYPE, NUM_ROWS, ANNOTATIONS_SUPPORTED, COMMENTS, VIEW_TEXT`.
   - No row → the object does not exist or is not visible; stop and say so.
   - `ANNOTATIONS_SUPPORTED = 'NO'` → the database is older than 23ai. Tell the
     user annotations are not available and offer step 6's `COMMENT ON`-only
     mode (bind `annotations: "N"`). Never run `scripts/show_annotations.sql`
     on such a database.
   - Remember `OBJECT_TYPE` (`TABLE` or `VIEW`); step 6 needs it.
2. Run `scripts/column_profile.sql` with the same binds. One row per column:
   `COLUMN_ID, COLUMN_NAME, DATA_TYPE, NULLABLE, KEYS, NUM_DISTINCT, NUM_NULLS, COMMENTS`.
   `KEYS` shows `PK`, `UNIQUE` or `FK -> OWNER.TABLE(COLUMN)` — a foreign key
   is the strongest hint about what a numeric column means.
3. Run `scripts/sample_rows.sql` with binds `{"schema": "<SCHEMA>", "object": "<OBJECT>", "sample_size": "15"}`.
   Read the values as evidence of meaning only. See
   `references/annotation-guidelines.md` for how to infer and what to avoid.
4. For the object and for **every** column, infer `display_name` (2–4 words,
   Title Case), `description` (one sentence, plain ASCII, no quotes or
   brackets) and `semantic_type` (one of the vocabulary in the reference file).
   Keep an existing `COMMENTS` value if it is already meaningful.
5. Build the proposal as one compact JSON array on a single line — call it
   `ANNOTATIONS_JSON` — with one element per entry:
   `{"column": "<NAME or null for the object itself>", "data_type": "<from step 2>", "display_name": "...", "description": "...", "semantic_type": "..."}`.
   The first element is the object (`"column": null`). Then run
   `scripts/preview_annotations.sql` with binds
   `{"object_type": "<TABLE|VIEW>", "annotations_json": "<ANNOTATIONS_JSON>"}`.
   It is read-only and QuinSQL shows its result grid to the user, so do not
   repeat the proposal as a table in your answer.
6. **Apply.** Unless the user asked only to *preview*, *suggest*, *inspect* or
   *show*, run `scripts/apply_annotations.sql` immediately after step 5 — in
   the same run, without asking the user first — with binds
   `{"schema": "<SCHEMA>", "object": "<OBJECT>", "object_type": "<TABLE|VIEW>", "annotations": "Y", "comments": "Y", "annotations_json": "<ANNOTATIONS_JSON, unchanged>"}`.
   - QuinSQL itself asks the user `[Y/n]` before the statement runs: that
     prompt *is* the approval of the proposal, so never end your turn with a
     "shall I apply?" question — just call the script. If the user declines,
     stop; do not retry or split it into smaller statements. Say that nothing
     was changed and that they can ask again with corrections (e.g. "C4 is
     the employment status").
   - `annotations: "N"` writes `COMMENT ON` only (pre-23ai); `comments: "N"`
     writes annotations only (if the user asked for annotations only).
7. After a successful apply, run `scripts/show_annotations.sql` with binds
   `{"schema": "<SCHEMA>", "object": "<OBJECT>"}`; QuinSQL shows its grid so
   the user sees what the dictionary now holds. Do not repeat it in your
   answer.
8. Answer in two or three sentences: what the object appears to be, how many
   columns were annotated (or proposed), and anything you were unsure about.
   Offer to adjust individual annotations.

## Inspect only (no proposal)

- If the user asks to **show the annotations** of an object, do steps 1 and 7
  only.
- If the user asks to **inspect / describe / show the current metadata** of an
  object (what is there *before* annotating), run step 1 with `display: true`
  (object type, row count, table-level comment), then
  `scripts/column_profile.sql` with `display: true` (columns and their
  comments), then step 7 (annotations at table and column level). Summarise in
  one or two sentences how many columns already have comments or annotations
  and offer to propose the missing ones. Do not propose anything yet.

## Rules

- Never annotate `SYS`, `SYSTEM` or other Oracle-maintained schemas.
- Never copy a sample value into a description — it may be personal data.
- Do not invent columns: annotate exactly the columns returned by step 2.
- Only `scripts/apply_annotations.sql` may change the database; never write
  your own `ALTER` or `COMMENT` statements.
