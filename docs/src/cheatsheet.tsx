import { useRef, useState } from 'react';
import { Button } from '@/components/ui/button';
import './cheatsheet.css';

export function Cheatsheet() {
  const [query, setQuery] = useState('');
  const [mode, setMode] = useState('all');
  const [task, setTask] = useState('all');
  const search = useRef<HTMLInputElement>(null);
  const terms = query.trim().toLowerCase().split(/\s+/).filter(Boolean);
  const matches = mappings.filter((mapping) => {
    const modeMatches = mode === 'all' || (mode === 'visual'
      ? mapping.modes.includes('v') || mapping.modes.includes('x')
      : mode === 'select' ? mapping.modes.includes('v') : mapping.modes.includes(mode));
    const searchable = [mapping.action, mapping.key, mapping.task, mapping.command,
      mapping.modes.map((value) => modeNames[value]).join(' '),
      'lua/config/keymaps.lua', `line ${mapping.line}`].join(' ').toLowerCase();
    return modeMatches && (task === 'all' || mapping.task === task)
      && terms.every((term) => searchable.includes(term));
  });

  return (
    <div className="cheatsheet" id="cheatsheet">
      <h3>Keymapping cheatsheet</h3>
      <p>Search by action, key, command, or source line. Combine mode and task filters to find the exact binding.</p>
      <div className="cheatsheet-controls">
        <label htmlFor="keymap-search">Search mappings
          <input ref={search} id="keymap-search" type="search" value={query}
            onChange={(event) => setQuery(event.target.value)} placeholder="Try paste, C-v, or line 19" autoComplete="off" spellCheck={false} />
        </label>
        <label htmlFor="keymap-mode">Editor mode
          <select id="keymap-mode" value={mode} onChange={(event) => setMode(event.target.value)}>
            <option value="all">All modes</option><option value="n">Normal (n)</option>
            <option value="i">Insert (i)</option><option value="visual">Visual (v, x)</option>
            <option value="select">Select (v)</option>
          </select>
        </label>
        <label htmlFor="keymap-task">Task
          <select id="keymap-task" value={task} onChange={(event) => setTask(event.target.value)}>
            <option value="all">All tasks</option>
            {tasks.map((name) => <option key={name} value={name}>{name}</option>)}
          </select>
        </label>
        <Button type="button" variant="outline" onClick={() => {
          setQuery(''); setMode('all'); setTask('all'); search.current?.focus();
        }}>Reset filters</Button>
      </div>
      <p className="cheatsheet-status" role="status" aria-live="polite">{matches.length} of {mappings.length} mapping declarations.</p>
      {matches.length === 0 ? (
        <div className="cheatsheet-empty"><strong>No matching mappings.</strong><p>Change the search, mode, or task. Reset filters restores all mappings.</p></div>
      ) : (
        <div className="profile-table-scroll" role="region" aria-label="Keymapping cheatsheet" tabIndex={0}>
          <table className="profile-keymap-table cheatsheet-table">
            <caption>Custom mappings from lua/config/keymaps.lua</caption>
            <thead><tr><th scope="col">Action</th><th scope="col">Key</th><th scope="col">Source modes</th><th scope="col">Command &amp; source</th></tr></thead>
            <tbody>{matches.map((mapping) => (
              <tr key={mapping.line}>
                <th scope="row">{mapping.action}</th>
                <td><kbd>{mapping.key}</kbd></td>
                <td>{mapping.modes.map((value) => `${value} · ${modeNames[value]}`).join(' / ')}</td>
                <td><code>{mapping.command}</code><a className="cheatsheet-source" href={`https://github.com/zenobi-us/lazyvim.profile/blob/main/lua/config/keymaps.lua#L${mapping.line}`}>keymaps.lua:{mapping.line}</a></td>
              </tr>
            ))}</tbody>
          </table>
        </div>
      )}
      <p className="profile-source-note">n = Normal; i = Insert; v = Visual and Select; x = Visual only. The Visual filter includes v and x; Select includes v only. Keys are reference text, not browser shortcuts. Modified arrow keys and mouse gestures depend on terminal support.</p>
    </div>
  );
}

const modeNames: Record<string, string> = { n: 'Normal', i: 'Insert', v: 'Visual + Select', x: 'Visual only' };
const mappings = [
  { line: 5, task: 'Comments', action: 'Comment line', key: '<leader>/', modes: ['n'], command: 'gcc (remap)' },
  { line: 6, task: 'Comments', action: 'Comment selection', key: '<leader>/', modes: ['v'], command: 'gc (remap)' },
  { line: 9, task: 'Save & close', action: 'Save', key: '<C-s>', modes: ['n', 'i', 'v'], command: '<cmd>w<cr>' },
  { line: 10, task: 'Save & close', action: 'Close buffer', key: '<C-w>', modes: ['n', 'i', 'v'], command: '<cmd>bd<cr>' },
  { line: 11, task: 'Save & close', action: 'Quit Neovim', key: '<C-q>', modes: ['n', 'i', 'v'], command: '<cmd>qa<cr>' },
  { line: 14, task: 'Clipboard', action: 'Copy line', key: '<C-c>', modes: ['n'], command: '\"+yy' },
  { line: 15, task: 'Clipboard', action: 'Copy selection', key: '<C-c>', modes: ['v'], command: '\"+y' },
  { line: 16, task: 'Clipboard', action: 'Cut line', key: '<C-x>', modes: ['n'], command: '\"+dd' },
  { line: 17, task: 'Clipboard', action: 'Cut selection', key: '<C-x>', modes: ['v'], command: '\"+d' },
  { line: 18, task: 'Clipboard', action: 'Paste after cursor', key: '<C-v>', modes: ['n'], command: '\"+p' },
  { line: 19, task: 'Clipboard', action: 'Paste', key: '<C-v>', modes: ['i'], command: '<C-r>+' },
  { line: 20, task: 'Clipboard', action: 'Paste over selection', key: '<C-v>', modes: ['v'], command: '\"+p' },
  { line: 23, task: 'Select lines', action: 'Select lines up', key: '<S-Up>', modes: ['n'], command: 'V<Up>' },
  { line: 24, task: 'Select lines', action: 'Select lines down', key: '<S-Down>', modes: ['n'], command: 'V<Down>' },
  { line: 25, task: 'Select lines', action: 'Extend selection up', key: '<S-Up>', modes: ['x'], command: '<Up>' },
  { line: 26, task: 'Select lines', action: 'Extend selection down', key: '<S-Down>', modes: ['x'], command: '<Down>' },
  { line: 29, task: 'Move lines', action: 'Move line up', key: '<C-S-Up>', modes: ['n'], command: ':move .-2<cr>==' },
  { line: 30, task: 'Move lines', action: 'Move line down', key: '<C-S-Down>', modes: ['n'], command: ':move .+1<cr>==' },
  { line: 31, task: 'Move lines', action: 'Move selection up', key: '<C-S-Up>', modes: ['v'], command: ":move '<-2<cr>gv=gv" },
  { line: 32, task: 'Move lines', action: 'Move selection down', key: '<C-S-Down>', modes: ['v'], command: ":move '>+1<cr>gv=gv" },
  { line: 35, task: 'Word navigation', action: 'Move back one word', key: '<C-Left>', modes: ['n', 'i'], command: '<C-Left>' },
  { line: 36, task: 'Word navigation', action: 'Move forward one word', key: '<C-Right>', modes: ['n', 'i'], command: '<C-Right>' },
  { line: 42, task: 'Go to code', action: 'Go to definition', key: '<2-LeftMouse>', modes: ['n'], command: 'goto_thing("definition")' },
  { line: 43, task: 'Go to code', action: 'Go to definition', key: '<C-LeftMouse>', modes: ['n'], command: 'goto_thing("definition")' },
  { line: 44, task: 'Go to code', action: 'Go to type definition', key: '<A-LeftMouse>', modes: ['n'], command: 'goto_thing("type_definition")' },
  { line: 45, task: 'Go to code', action: 'Go to definition', key: 'gd', modes: ['n'], command: 'goto_thing("definition")' },
];
const tasks = [...new Set(mappings.map((mapping) => mapping.task))];
