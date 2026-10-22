import type { ReactElement } from 'react';
import { FileText, FolderTree, Keyboard, Moon, MousePointer2, MoveHorizontal, Orbit } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import './feature-introduction.css';

export function FeatureIntroduction(): ReactElement {
  return (
    <section className="feature-introduction" id="introduction" aria-labelledby="introduction-title">
      <header className="feature-heading">
        <div>
          <p className="profile-eyebrow">Introduction / profile inventory</p>
          <h2 id="introduction-title">Small changes.<br />A particular way to work.</h2>
        </div>
        <p className="feature-intro-copy">
          Keymaps, configured plugins, and local code—each change has a different origin.
          Here is what this profile brings together.
        </p>
      </header>
      <div className="feature-columns" aria-hidden="true"><span>Feature / interaction</span><span>Implementation origin</span></div>
      <ol className="feature-ledger">
        {features.map((feature, index) => (
          <li className="feature-entry" key={feature.id}>
            <span className="feature-number" aria-hidden="true">{String(index + 1).padStart(2, '0')}</span>
            <feature.icon className="feature-icon" size={20} strokeWidth={1.5} aria-hidden="true" />
            <div className="feature-copy">
              <h3>{feature.title}</h3>
              <p>{feature.description}</p>
              <span className="feature-interaction">{feature.interaction}</span>
            </div>
            <div className="feature-origin">
              <Badge variant="outline" className="feature-kind" data-kind={feature.kind}>{originLabels[feature.kind]}</Badge>
              <a className="feature-source" href={`https://github.com/zenobi-us/lazyvim.profile/blob/main/${feature.source}`} aria-label={`Source for ${feature.title}: ${feature.source}`}>{feature.source}</a>
            </div>
          </li>
        ))}
      </ol>
      <p className="feature-footnote">
        Origin labels distinguish profile choices from plugin capabilities and code implemented here.
        Vim modes still apply; modified arrows and mouse gestures depend on terminal support.
        {' '}<a href="#cheatsheet">See the mode-specific bindings in Cheatsheet 01</a>.
      </p>
    </section>
  );
}

const originLabels = {
  mapping: 'Profile keymap',
  configured: 'Configured plugin',
  local: 'Local code',
};

const features = [
  {
    id: 'keys', icon: Keyboard, kind: 'mapping',
    title: 'Windows-style editing keys',
    description: 'Save with Ctrl+s. Copy, cut, and paste with Ctrl+c / x / v. Use Shift+arrows for selection and Ctrl+Shift+arrows to move lines. Bindings remain mode-specific.',
    interaction: 'Ctrl+s · Ctrl+c / x / v', source: 'lua/config/keymaps.lua',
  },
  {
    id: 'markdown', icon: FileText, kind: 'configured',
    title: 'Markdown, without hiding the source',
    description: 'Full-width code-fence backgrounds, language labels, and visible delimiters keep notes readable while you edit the original text.',
    interaction: 'Visible code fences', source: 'lua/plugins/render-markdown.lua',
  },
  {
    id: 'tree', icon: FolderTree, kind: 'local',
    title: 'A file tree that resets to Normal mode',
    description: 'Focus the Snacks file tree from Insert mode and the profile leaves Insert mode automatically. Browse without an extra Esc.',
    interaction: 'Focus tree → Normal', source: 'lua/plugins/file-tree-normal-mode.lua',
  },
  {
    id: 'goto', icon: MousePointer2, kind: 'local',
    title: 'Double-click into a definition',
    description: 'Double-click a symbol for LSP go-to-definition. Ctrl+click does the same; Alt+click requests a type definition. The local helper falls back to file paths or declarations.',
    interaction: 'Double-click · Ctrl+click', source: 'lua/config/goto-thing.lua',
  },
  {
    id: 'words', icon: MoveHorizontal, kind: 'mapping',
    title: 'Word jumps on Ctrl+arrows',
    description: 'Move by word with Ctrl+Left and Ctrl+Right in Normal and Insert modes. Modified keys depend on your terminal keyboard protocol.',
    interaction: 'Ctrl+← / →', source: 'lua/config/keymaps.lua',
  },
  {
    id: 'theme', icon: Moon, kind: 'local',
    title: 'Monoslate, a local colour scheme',
    description: 'A bundled dark, mostly greyscale theme with restrained accents. Load it with :colorscheme mono-slate.',
    interaction: ':colorscheme mono-slate', source: 'lua/plugins/zenobius-themes.lua',
  },
  {
    id: 'logo', icon: Orbit, kind: 'local',
    title: 'An animated orbit on the dashboard',
    description: 'The local dashboard-logo.nvim renderer animates the orbit logo in Snacks. Its colour follows the active theme’s Special highlight.',
    interaction: 'Orbit · theme-aware colour', source: 'lua/plugins/dashboard.lua',
  },
] as const;
