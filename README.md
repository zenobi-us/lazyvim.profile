# 💤 LazyVim

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started.

```bash
rm -rf ~/.config/nvim
git clone https://github.com/zenobi-us/lazyvim.profile.git ~/.config/nvim
```

Markdown code fences render with full-width backgrounds using `render-markdown.nvim`.
Markdown language features use `markdown-oxide`, which must be available on `$PATH`.

## Website deployment

GitHub Actions publishes `docs/website` to
<https://zenobi-us.github.io/lazyvim.profile/>.
GitHub Pages uses the **GitHub Actions** source.

The website uses React, Vite, TanStack Router, Tailwind CSS v4, and shadcn/ui.
Edit the application in `docs/src/` and the standalone cheatsheet UX comparison in
`docs/public/cheatsheet-preview.html`.
The Reference section includes cheatsheet option 01: a searchable keymap table with
editor-mode and task filters, exact commands, source links, and an empty-state reset.
Keep `docs/src/cheatsheet.tsx` in sync with `lua/config/keymaps.lua` when mappings change.

```sh
cd docs
bun install --frozen-lockfile
bun run dev
```

Open <http://127.0.0.1:4273/lazyvim.profile/>.
The cheatsheet comparison is at
<http://127.0.0.1:4273/lazyvim.profile/cheatsheet-preview.html>.
It proposes three interaction models; choosing one stores a browser-local preference only.

Run `bun run build` from `docs` to typecheck and generate `docs/website`.
Run `bun run preview` to serve that production build.
Generated files and dependencies are ignored by Git.
Vite and TanStack Router use `/lazyvim.profile/` as the site base path.
Update both through `docs/vite.config.ts` if the deployment path changes.

Push changes to `docs/**` or `.github/workflows/pages.yml` on `main` to build and deploy automatically.
To deploy manually, run **Deploy website to GitHub Pages** from the repository's **Actions** tab on `main`.
The workflow uses `GITHUB_TOKEN`; no additional deployment secret is required.

`DESIGN.md` and `UIFOUNDATION.md` are unchanged copies from the Ledger app’s
`DESIGN.md` and `UI-FOUNDATION.md`. The website adopts their compact typography,
square geometry, and violet-dusk tokens. References to finance, benchmark reports,
and Ledger behavior describe the source applications, not this documentation site.
The requested viewport-height landing card is specific to this site.
