import type { ReactElement } from "react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Cheatsheet } from "./cheatsheet";
import "./page.css";

export function DocumentationPage(): ReactElement {
  return (
    <div className="profile-page" id="top">
      <a className="profile-skip" href="#main-content">Skip to documentation</a>
      <header className="profile-header">
        <a className="profile-brand" href="#top" aria-label="lazyvim.profile home">
          <span aria-hidden="true">[ lv ]</span> lazyvim.profile
        </a>
        <nav className="profile-nav" aria-label="Documentation sections">
          {sections.map((section) => (
            <a key={section.id} href={`#${section.id}`}>{section.title}</a>
          ))}
        </nav>
        <a className="profile-repository" href={repository}>GitHub <span aria-hidden="true">↗</span></a>
      </header>

      <main className="profile-main" id="main-content" tabIndex={-1}>
        <Card className="profile-landing" aria-labelledby="profile-title">
          <div className="profile-landing-top">
            <span className="profile-eyebrow">Neovim configuration / documentation</span>
            <Badge variant="outline">Built on LazyVim</Badge>
          </div>
          <div className="profile-landing-body">
            <div className="profile-introduction">
              <p className="profile-eyebrow">A personal editing environment</p>
              <h1 id="profile-title">lazyvim.profile</h1>
              <p className="profile-lead">
                Familiar editing keys. Mouse-aware navigation. Markdown with its source still visible.
              </p>
              <p>
                A LazyVim profile for people who work in code and notes. Install it safely,
                learn the local keymaps, and find the Lua behind each choice.
              </p>
              <div className="profile-actions">
                <Button asChild><a href="#tutorial">Start the tutorial <span aria-hidden="true">↓</span></a></Button>
                <Button asChild variant="outline"><a href="#reference">Look up a key</a></Button>
              </div>
              <p className="profile-upstream">
                New to Neovim? Start with the <a href="https://www.lazyvim.org/">LazyVim documentation</a> for the inherited editor features.
              </p>
            </div>
            <nav className="profile-index" aria-label="Choose your documentation path">
              <p className="profile-eyebrow">Find your next step</p>
              {sections.map((section) => (
                <a className="profile-index-link" key={section.id} href={`#${section.id}`}>
                  <span className="profile-index-number" aria-hidden="true">{section.number}</span>
                  <span><strong>{section.title}</strong><span>{section.description}</span></span>
                  <span aria-hidden="true">↗</span>
                </a>
              ))}
            </nav>
          </div>
          <div className="profile-landing-bottom">
            <span>Lua configuration · local plugins · no separate distribution</span>
            <a href="#explanation">Understand the profile <span aria-hidden="true">↓</span></a>
          </div>
        </Card>

        <div className="profile-documentation">
          <section className="profile-section" id="tutorial" aria-labelledby="tutorial-title">
            <SectionHeading id="tutorial-title" number="01" title="Tutorial" intent="Learning-oriented" description="Install the profile and save your first note." />
            <div className="profile-section-content">
              <div className="profile-section-intro">
                <h3>From an existing setup to a first edit</h3>
                <p>This walkthrough uses a POSIX shell on Linux or macOS. Close existing Neovim sessions before you start.</p>
              </div>
              <ol className="profile-steps">
                <li>
                  <h4>Prepare the tools</h4>
                  <p>
                    Install Neovim and Git. Check the <a href="https://www.lazyvim.org/installation">current LazyVim requirements</a> for
                    supported versions, terminal support, and external tools.
                    The first launch needs network access to download plugins.
                  </p>
                  <p>
                    For Markdown language features, install <a href="https://github.com/Feel-ix-343/markdown-oxide">markdown-oxide</a> and
                    make its executable available on <code>$PATH</code> before you start Neovim.
                    This profile does not install it through Mason.
                  </p>
                  <CodeBlock label="Check the executables in your shell" code={'nvim --version\ngit --version\ncommand -v markdown-oxide'} />
                </li>
                <li>
                  <h4>Back up the configuration, then clone</h4>
                  <p>
                    The commands move an existing configuration into a uniquely named backup directory.
                    They preserve the old files instead of deleting them.
                  </p>
                  <CodeBlock label="Install from GitHub" code={'config="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"\nif [ -e "$config" ] || [ -L "$config" ]; then\n  backup="$(mktemp -d "${config}.backup.XXXXXX")" || exit 1\n  mv "$config" "$backup/nvim" || exit 1\n  printf \'Configuration backup: %s\\n\' "$backup/nvim"\nfi\nmkdir -p "$(dirname "$config")" &&\n  git clone https://github.com/zenobi-us/lazyvim.profile.git "$config"'} />
                  <p className="profile-muted">
                    Keep the printed backup path. Existing Neovim data, state, and cache remain untouched.
                    If you need a clean data environment, read LazyVim’s installation guidance before moving those directories.
                  </p>
                </li>
                <li>
                  <h4>Start Neovim and let the plugins install</h4>
                  <CodeBlock label="First launch" code="nvim" />
                  <p>
                    The bootstrap installs lazy.nvim if it is missing, then loads LazyVim and this profile.
                    Let plugin installation finish. Use <code>:Lazy</code> to inspect plugin status and <code>:checkhealth</code> to inspect missing tools.
                  </p>
                  <p>After installation, quit and restart Neovim before your first editing session.</p>
                </li>
                <li>
                  <h4>Write a note and save it</h4>
                  <p>Run <code>:edit ~/lazyvim-profile-notes.md</code>. Press <kbd>i</kbd> to enter Insert mode, then write a Markdown heading.</p>
                  <p>
                    Press <kbd>Esc</kbd> to return to Normal mode. Press <kbd>Ctrl+s</kbd> to save.
                    Markdown code fences use full-width backgrounds without hiding their delimiters.
                  </p>
                  <p>
                    Press <kbd>Ctrl+q</kbd> to quit all windows. If a buffer has unsaved changes, Neovim refuses to quit.
                    Save those changes before you try again.
                  </p>
                </li>
              </ol>
              <p className="profile-source-note">
                Sources: <a href={`${repository}/blob/main/lua/config/lazy.lua`}>plugin bootstrap</a>,{" "}
                <a href={`${repository}/blob/main/lua/plugins/markdown-oxide.lua`}>Markdown language server</a>,{" "}
                <a href={`${repository}/blob/main/lua/plugins/render-markdown.lua`}>Markdown rendering</a>.
              </p>
            </div>
          </section>

          <section className="profile-section" id="how-to" aria-labelledby="how-to-title">
            <SectionHeading id="how-to-title" number="02" title="How-to guides" intent="Task-oriented" description="Solve a specific editing or configuration task." />
            <div className="profile-section-content profile-guide-list">
              <article>
                <h3>Navigate from a symbol or import</h3>
                <p>
                  In Normal mode, put the cursor on a symbol and press <kbd>gd</kbd>.
                  You can also double-click or use <kbd>Ctrl+Left click</kbd>.
                  Use <kbd>Alt+Left click</kbd> for a type definition.
                </p>
                <p>
                  The helper asks an attached language server first. Without a suitable definition server,
                  it tries a file path, then the local declaration.
                  Mouse gestures depend on terminal support.
                </p>
                <a href={`${repository}/blob/main/lua/config/goto-thing.lua`}>Read the navigation helper <span aria-hidden="true">↗</span></a>
              </article>
              <article>
                <h3>Copy, cut, and move text</h3>
                <p>
                  In Normal mode, <kbd>Ctrl+c</kbd> copies the current line and <kbd>Ctrl+x</kbd> cuts it to the system clipboard.
                  In Visual mode, these keys act on the selection instead.
                  Use <kbd>Ctrl+v</kbd> to paste.
                </p>
                <p>
                  Use <kbd>Shift+Up</kbd> or <kbd>Shift+Down</kbd> to start a linewise selection in Normal mode.
                  Use <kbd>Ctrl+Shift+Up</kbd> or <kbd>Ctrl+Shift+Down</kbd> to move lines.
                  Clipboard access needs a working Neovim clipboard provider.
                </p>
                <a href={`${repository}/blob/main/lua/config/keymaps.lua`}>Read the editing mappings <span aria-hidden="true">↗</span></a>
              </article>
              <article>
                <h3>Diagnose a key that does not arrive</h3>
                <p>
                  Run <code>:KeymapProbe</code>. Use <kbd>j</kbd> and <kbd>k</kbd> to choose a key,
                  then press <kbd>Enter</kbd> to capture it. Press <kbd>q</kbd> or <kbd>Esc</kbd> to close the probe outside capture mode.
                </p>
                <p>
                  Modified arrow keys depend on your terminal’s keyboard protocol.
                  To inspect the active Normal-mode mapping, run <code>:verbose nmap &lt;C-w&gt;</code>.
                  Use <code>:verbose imap &lt;C-s&gt;</code> for Insert mode.
                </p>
                <a href={`${repository}/blob/main/lua/custom/keymap-probe/lua/keymap-probe/init.lua`}>Read the keymap probe <span aria-hidden="true">↗</span></a>
              </article>
              <article>
                <h3>Choose and persist a colorscheme</h3>
                <p>
                  Run <code>:colorscheme mono-slate</code> to try the bundled theme for this session.
                  The default comes from <code>NEOVIM_THEME_NAME</code>, or <code>monoglow</code> if that variable is absent.
                </p>
                <p>
                  The repository’s <code>.mise.toml</code> sets <code>NEOVIM_THEME_NAME = "mono-slate"</code>.
                  Start Neovim from a shell that loads that environment to use it.
                  In the Snacks colorscheme picker, <kbd>Ctrl+s</kbd> saves the selected theme through <code>mise</code>.
                  That picker action requires the <code>mise</code> executable.
                </p>
                <a href={`${repository}/blob/main/lua/plugins/dashboard.lua`}>Read theme persistence <span aria-hidden="true">↗</span></a>
              </article>
              <article>
                <h3>Change the profile without editing upstream plugins</h3>
                <p>
                  Add editor options in <code>lua/config/options.lua</code> and local mappings in <code>lua/config/keymaps.lua</code>.
                  Add or override plugin specifications under <code>lua/plugins/</code>.
                  The bootstrap imports that directory after LazyVim and its configured extras.
                </p>
                <p>
                  The example specification returns an empty table and does not activate its sample plugins.
                  Create a separate specification for changes you want to load.
                </p>
                <a href={`${repository}/tree/main/lua/plugins`}>Browse plugin specifications <span aria-hidden="true">↗</span></a>
              </article>
            </div>
          </section>

          <section className="profile-section" id="reference" aria-labelledby="reference-title">
            <SectionHeading id="reference-title" number="03" title="Reference" intent="Information-oriented" description="Local keys, modes, dependencies, and source files." />
            <div className="profile-section-content">
              <h3>Local editing mappings</h3>
              <p>
                These are profile mappings, not the full LazyVim keymap.
                <code>&lt;leader&gt;</code> means your configured leader key.
                Normal mode accepts commands. Insert mode enters text. Visual mode selects text.
              </p>
              <aside className="profile-caution" aria-labelledby="keymap-caution">
                <h4 id="keymap-caution">Changed defaults</h4>
                <p>
                  <kbd>Ctrl+w</kbd> closes the current buffer with <code>:bd</code>.
                  It replaces Neovim’s Normal-mode window-command prefix, so do not start a window command with it.
                </p>
                <p>
                  <kbd>Ctrl+q</kbd> runs <code>:qa</code>, not <code>:qa!</code>.
                  It does not force-discard unsaved changes. <kbd>Ctrl+c</kbd> in Normal mode copies a line instead of acting as an interrupt.
                </p>
              </aside>
              <Cheatsheet />

              <h3 className="profile-subheading">Plugin and context-specific keys</h3>
              <dl className="profile-reference-list">
                <div>
                  <dt>Copilot suggestions · Insert mode</dt>
                  <dd>
                    <kbd>Alt+Right</kbd> accepts a suggestion. <kbd>Ctrl+Down</kbd> selects the next suggestion and <kbd>Ctrl+Up</kbd> the previous one.
                    Suggestions auto-trigger, including in YAML and Markdown. Copilot requires its own authentication.
                    {" "}<a href={`${repository}/blob/main/lua/plugins/copilot.lua`}>Copilot configuration</a>.
                  </dd>
                </div>
                <div>
                  <dt>mini.move · Normal and Visual modes</dt>
                  <dd>
                    <kbd>Ctrl+Shift+Left</kbd>, <kbd>Ctrl+Shift+Right</kbd>, <kbd>Ctrl+Shift+Up</kbd>, and <kbd>Ctrl+Shift+Down</kbd> configure movement in each direction.
                    Normal mode acts on lines. Visual mode acts on selections.
                    Vertical keys also have explicit mappings in the local keymap file, so inspect the active mapping when behavior differs.
                    {" "}<a href={`${repository}/blob/main/lua/plugins/mini-move.lua`}>Movement configuration</a>.
                  </dd>
                </div>
                <div>
                  <dt>Snacks picker input · Normal and Insert modes</dt>
                  <dd>
                    <kbd>Ctrl+s</kbd> saves the selected colorscheme to the profile’s <code>.mise.toml</code>.
                    This picker mapping differs from the global save-buffer key.
                    {" "}<a href={`${repository}/blob/main/lua/plugins/dashboard.lua#L37-L60`}>Picker action source</a>.
                  </dd>
                </div>
                <div>
                  <dt>Worktree picker · Normal and Insert modes</dt>
                  <dd>
                    Click the working-directory segment in the statusline to open the picker.
                    <kbd>a</kbd> creates a worktree and <kbd>d</kbd> requests removal of a selected, non-current worktree with confirmation.
                    Selection changes the tab-local directory. This integration needs <code>wt</code> (Worktrunk) on <code>$PATH</code>.
                    {" "}<a href={`${repository}/blob/main/lua/plugins/statusline.lua`}>Statusline source</a>.
                  </dd>
                </div>
              </dl>

              <h3 className="profile-subheading">Configuration map</h3>
              <dl className="profile-source-map">
                {configurationFiles.map((file) => (
                  <div key={file.path}>
                    <dt><a href={`${repository}/blob/main/${file.path}`}>{file.path}</a></dt>
                    <dd>{file.description}</dd>
                  </div>
                ))}
              </dl>
              <p><a href="#cheatsheet">Cheatsheet 01 — searchable keymapping reference <span aria-hidden="true">↑</span></a></p>
            </div>
          </section>

          <section className="profile-section" id="explanation" aria-labelledby="explanation-title">
            <SectionHeading id="explanation-title" number="04" title="Explanation" intent="Understanding-oriented" description="Understand what the profile changes and what it inherits." />
            <div className="profile-section-content profile-guide-list">
              <article>
                <h3>LazyVim supplies the editor; this repository supplies the differences</h3>
                <p>
                  lazy.nvim manages the plugins. The bootstrap imports LazyVim first, then the Copilot, TypeScript,
                  and JSON extras, then the local plugin specifications.
                  This order keeps profile-specific changes next to the code that owns them.
                </p>
                <p>
                  The local configuration uses absolute line numbers, disables relative numbers, and sets <code>conceallevel</code> to zero.
                  The intent is a readable editing surface with the source text visible.
                  Most other editor behavior still comes from LazyVim.
                </p>
                <a href={`${repository}/blob/main/lua/config/options.lua`}>Read the editor options <span aria-hidden="true">↗</span></a>
              </article>
              <article>
                <h3>Familiar shortcuts change some Vim expectations</h3>
                <p>
                  The profile maps save, clipboard, close, and quit actions to familiar control keys.
                  These are deliberate replacements, not extra aliases that leave every default untouched.
                  The window-prefix change is the most important difference for experienced Vim users.
                </p>
                <p>
                  Modes still matter. Copy acts on a whole line in Normal mode and on selected text in Visual mode.
                  Paste inserts clipboard text in Insert mode but replaces selected text in Visual mode.
                  The reference separates these actions so the same key does not imply the same operation everywhere.
                </p>
              </article>
              <article>
                <h3>Language intelligence and Markdown appearance are separate</h3>
                <p>
                  A language server provides navigation and language-aware actions.
                  For Markdown, that server is the external <code>markdown-oxide</code> executable.
                  Its configuration disables Mason installation and enables dynamic file-watch registration.
                </p>
                <p>
                  <code>render-markdown.nvim</code> controls appearance instead.
                  It gives code fences full-width backgrounds, a thin border, language labels, and visible delimiters.
                  A rendered Markdown buffer alone does not prove the language server is available.
                </p>
              </article>
              <article>
                <h3>Mouse features keep the underlying tools in charge</h3>
                <p>
                  Symbol navigation uses the local fallback helper, while contextual language-server menus expose supported actions directly.
                  Neo-tree clipboard menu entries appear only in a suitable Neo-tree buffer.
                  They use Neo-tree’s clipboard rather than a separate filesystem implementation.
                </p>
                <p>
                  The Snacks explorer is a separate integration: a left-side list with hidden files visible and no preview.
                  Its list returns to Normal mode on entry.
                  Neo-tree-specific menu entries do not describe Snacks explorer behavior.
                </p>
                <a href={`${repository}/tree/main/lua/plugins/popups`}>Read contextual menu definitions <span aria-hidden="true">↗</span></a>
              </article>
            </div>
          </section>
        </div>
      </main>
      <footer className="profile-footer">
        <span>lazyvim.profile / documentation</span>
        <div><a href={repository}>Source on GitHub</a><a href="#top">Back to top <span aria-hidden="true">↑</span></a></div>
      </footer>
    </div>
  );
}

function SectionHeading(props: { id: string; number: string; title: string; intent: string; description: string }): ReactElement {
  return (
    <header className="profile-section-heading">
      <p className="profile-eyebrow"><span aria-hidden="true">{props.number} / </span>{props.intent}</p>
      <h2 id={props.id}>{props.title}</h2>
      <p>{props.description}</p>
    </header>
  );
}

function CodeBlock(props: { label: string; code: string }): ReactElement {
  return (
    <figure className="profile-code">
      <figcaption>{props.label}</figcaption>
      <pre><code>{props.code}</code></pre>
    </figure>
  );
}

const repository = "https://github.com/zenobi-us/lazyvim.profile";

const sections = [
  { id: "tutorial", number: "01", title: "Tutorial", description: "Install, launch, make your first edit." },
  { id: "how-to", number: "02", title: "How-to guides", description: "Get a specific task done." },
  { id: "reference", number: "03", title: "Reference", description: "Find a key, mode, or source file." },
  { id: "explanation", number: "04", title: "Explanation", description: "Understand the configuration choices." },
];


const configurationFiles = [
  { path: "lua/config/lazy.lua", description: "Plugin bootstrap, LazyVim extras, and local plugin imports." },
  { path: "lua/config/keymaps.lua", description: "Global profile shortcuts and mouse navigation bindings." },
  { path: "lua/config/options.lua", description: "Absolute line numbers and visible source text." },
  { path: "lua/plugins/markdown-oxide.lua", description: "External Markdown language server configuration." },
  { path: "lua/plugins/render-markdown.lua", description: "Markdown code-fence appearance." },
  { path: "lua/plugins/no-color-collections.lua", description: "Environment-selected colorscheme and monoglow fallback." },
];
