# Funding Radar

A private dashboard of funding opportunities (grants, accelerators, fellowships, competitions, investors) matched to a portfolio of projects, with deadlines, application drafts and questions from a daily search agent.

- `index.html` is the whole app. It is served by GitHub Pages and asks you to sign in.
- Data lives in Supabase in one table, `fr_docs`. Row-level security lets only approved, confirmed accounts read or write it; see `supabase/schema.sql`.
- The Supabase URL and publishable key in `index.html` are meant to be public. They grant nothing without an approved sign-in.
- A scheduled Claude task searches for opportunities each day and writes to the same table. It drafts applications but never submits them.

To give someone access, add their email to the `fr_owners` table and have them create an account on the sign-in page.

## Instant link processing

`supabase/functions/fr-process-link` is a Supabase Edge Function. When a link is dropped on the dashboard it checks the caller is an approved user, then asks Claude (with web search) to find the programme's official page, confirm the deadline, pick the best-fit project and record the result. It needs an `ANTHROPIC_API_KEY` secret set in the Supabase project; without it, dropped links simply wait for the daily scan.
