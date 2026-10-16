# Annotation guidelines

## Why annotate

Oracle Select AI builds its prompt from the data dictionary. A table named
`XE01` with columns `C1..C8` gives the model nothing to work with; comments
and 23ai annotations (`display_name`, `description`, `semantic_type`) are
what make natural-language queries against such objects possible. Enable
them in the AI profile with `"comments": "true"` and `"annotations": "true"`.

## How to infer meaning

Use the evidence in this order of reliability:

1. **Keys.** `PK` → the row identifier. `FK -> OWNER.TABLE(COL)` → a
   reference to that table; name it after the referenced entity
   (`Employee`, `Department`), not after the column it points to.
2. **Type and statistics.** `DATE` with few distinct values and most rows
   recent → an event or status date. `NUMBER(p,s)` with scale → an amount.
   Very low `NUM_DISTINCT` on a `VARCHAR2` → a status or category code.
3. **Sample values.** Person-like names, department names, course titles,
   ISO country codes, email shapes, currency-like amounts. Treat the sample
   as evidence of the *kind* of value, never as a list to enumerate.
4. **View text.** For a view, the defining SQL reveals the base tables and
   expressions; a column computed as `SUM(...)` is a total, `COUNT(*)` a count.
5. **Existing comments.** Keep a comment that is already meaningful; replace
   placeholders like `TBD` or the column name repeated.

When two readings are plausible, choose the more general one and say so in
the final answer rather than guessing precisely.

## Vocabulary for `semantic_type`

Use one of: `identifier`, `foreign_key`, `person_name`, `email`, `phone`,
`address`, `organization`, `category`, `status`, `title`, `description`,
`date`, `timestamp`, `amount`, `quantity`, `percentage`, `score`, `flag`,
`country_code`, `currency_code`, `url`, `free_text`, `other`.

For the object itself use: `fact`, `dimension`, `reference`, `lookup`,
`transaction`, `log`, `view`.

## Writing the values

- `display_name`: 2–4 words, Title Case, no abbreviations (`Hire Date`, not
  `Hire Dt`).
- `description`: one plain-ASCII sentence, no single quotes, no square
  brackets (the apply script wraps the JSON in a `q'[...]'` literal), no
  sample values, no personal data.
- `semantic_type`: exactly one word from the vocabulary above.

## Privacy

Sample rows may contain personal data (names, emails, salaries). Use them to
understand the column, then forget them: nothing from a sample belongs in a
description, a display name or the final answer.

## Database support

- Annotations require Oracle Database 23ai or later. On 19c/21c
  `ALL_ANNOTATIONS_USAGE` does not exist; `scripts/object_summary.sql`
  reports `ANNOTATIONS_SUPPORTED = 'NO'` and the skill falls back to
  `COMMENT ON` only, which Select AI also reads.
- Column-level annotations on **views** can be modified in place with
  `ALTER VIEW ... MODIFY (col ANNOTATIONS (...))` on 23.26 (26ai) and later.
  On early 23ai releases this raises an error and the view would have to be
  recreated — report the error, do not try to recreate the view.
- The apply script needs `ALTER` on the object (owner, or `ALTER ANY TABLE`
  / `COMMENT ANY TABLE`). It refuses Oracle-maintained schemas.
