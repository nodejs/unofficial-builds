#!/usr/bin/env node

// Generate build-status pages, refreshed by periodic.sh on every timer tick.
// No dependencies beyond Node.js builtins.
//
//   logs/status-fragment.html  bare markup: current activity, a build matrix
//                              for the latest release of each active release
//                              line (per the Node.js release schedule), and
//                              recent builds; fetched and embedded by
//                              www/index.html
//   logs/status.html           the same content as a standalone page
//   logs/status.json           the same facts, machine-readable
//   logs/summary.html          symlink to status.html (back-compat)
//
// Matrix cells link to the thing itself: artifact tarball when a build
// succeeded, the recipe's build log when it was attempted but produced no
// artifact.
//
// Table originally by @sxa, see
// https://github.com/nodejs/unofficial-builds/issues/47

'use strict'

const { execFileSync, spawnSync } = require('node:child_process')
const fs = require('node:fs')
const path = require('node:path')

const bindir = __dirname
const workdir = process.env.workdir || path.resolve(bindir, '..', '..')
const distdir = path.join(workdir, 'download')
const logdir = path.join(workdir, 'logs')
const queuefile = path.join(workdir, 'var', 'build_queue')
const recipesdir = path.resolve(bindir, '..', 'recipes')
const lockfile = '/var/run/lock/node-build'

// The recipe list lives in _config.sh; it is the single source of truth
const recipes = execFileSync('bash', ['-c',
  `source '${path.join(bindir, '_config.sh')}' && printf '%s\\n' "\${recipes[@]}"`
]).toString().trim().split('\n')

const semverSort = (a, b) => {
  const pa = a.slice(1).split('.').map(Number)
  const pb = b.slice(1).split('.').map(Number)
  return pa[0] - pb[0] || pa[1] - pb[1] || pa[2] - pb[2]
}

// The Node.js release schedule says which lines are active. Cached for a
// day; a failed fetch falls back to a stale cache. No schedule at all (fresh
// install, offline) just means an empty matrix until one is fetched.
const scheduleUrl = 'https://raw.githubusercontent.com/nodejs/Release/main/schedule.json'
const scheduleCache = path.join(workdir, 'var', 'release-schedule.json')

async function releaseSchedule () {
  let age = Infinity
  try {
    age = Date.now() - fs.statSync(scheduleCache).mtimeMs
  } catch {}
  if (age > 24 * 60 * 60 * 1000) {
    try {
      const res = await fetch(scheduleUrl, { signal: AbortSignal.timeout(5000) })
      fs.writeFileSync(scheduleCache, JSON.stringify(JSON.parse(await res.text())))
    } catch {}
  }
  try {
    return JSON.parse(fs.readFileSync(scheduleCache, 'utf8'))
  } catch {
    return {}
  }
}

// Latest version present of each schedule-active major line
function activeVersions (schedule) {
  const byMajor = new Map()
  let names = []
  try {
    names = fs.readdirSync(path.join(distdir, 'release')).filter((n) => /^v\d+\.\d+\.\d+$/.test(n))
  } catch {}
  for (const name of names.sort(semverSort)) {
    byMajor.set(name.split('.')[0], name)
  }
  const now = Date.now()
  return [...byMajor.entries()]
    .filter(([major]) => {
      const line = schedule[major]
      return line && Date.parse(line.start) <= now && now < Date.parse(line.end)
    })
    .map(([, name]) => name)
}

// The artifact identifying a recipe within a version's release directory
function artifactName (recipe, version) {
  const platform = recipe === 'headers' ? 'headers'
    : recipe === 'musl' ? 'linux-x64-musl'
      : `linux-${recipe}`
  return `node-${version}-${platform}.tar.xz`
}

function gatedOut (recipe, version) {
  const shouldbuild = path.join(recipesdir, recipe, 'should-build.sh')
  if (!fs.existsSync(shouldbuild)) {
    return false
  }
  return spawnSync(shouldbuild, [bindir, version], { stdio: 'ignore' }).status !== 0
}

// Build log directories are named {YYYYMMDDHHMM}-{version}, newest last
function buildDirs () {
  try {
    return fs.readdirSync(logdir).filter((n) => /^\d{12}-v\d/.test(n)).sort()
  } catch {
    return []
  }
}

const builds = buildDirs()

function latestBuildDirFor (version) {
  return builds.filter((b) => b.slice(13) === version).pop()
}

// ok: artifact exists; failed: attempted (recipe log present) but no
// artifact; na: gated out; none: never attempted
function cellState (recipe, version) {
  const artifact = artifactName(recipe, version)
  if (fs.existsSync(path.join(distdir, 'release', version, artifact))) {
    return { state: 'ok', href: `/download/release/${version}/${artifact}` }
  }
  if (gatedOut(recipe, version)) {
    return { state: 'na' }
  }
  const builddir = latestBuildDirFor(version)
  if (builddir && fs.existsSync(path.join(logdir, builddir, `${recipe}.log`))) {
    return { state: 'failed', href: `/logs/${builddir}/${recipe}.log` }
  }
  return { state: 'none' }
}

function currentActivity () {
  let building = null
  try {
    const pid = parseInt(fs.readFileSync(lockfile, 'utf8'), 10)
    process.kill(pid, 0)
    const builddir = builds[builds.length - 1]
    if (builddir) {
      const stamp = stampToDate(builddir)
      building = {
        version: builddir.slice(13),
        builddir,
        startedUTC: stamp,
        minutes: Math.max(0, Math.round((Date.now() - Date.parse(stamp + ':00Z')) / 60000))
      }
    }
  } catch {}
  let queue = []
  try {
    queue = fs.readFileSync(queuefile, 'utf8').trim().split('\n').filter(Boolean)
  } catch {}
  return { building, queue }
}

function stampToDate (builddir) {
  const s = builddir.slice(0, 12)
  return `${s.slice(0, 4)}-${s.slice(4, 6)}-${s.slice(6, 8)} ${s.slice(8, 10)}:${s.slice(10, 12)}`
}

// Artifacts promote to download/{disttype}/{fullversion}/ where disttype is
// encoded in the version suffix (see _decode_version.sh)
function disttypeOf (version) {
  const m = version.match(/-(rc|test|nightly)[.\d]/)
  return m ? m[1] : 'release'
}

// A recipe with a log but no artifact has failed, unless this build is still
// running, in which case it is merely not finished yet
function recentBuilds (count, activeBuilddir) {
  return builds.slice(-count).reverse().map((builddir) => {
    const version = builddir.slice(13)
    const versiondir = path.join(distdir, disttypeOf(version), version)
    const tally = { ok: 0, failed: 0, pending: 0, na: 0 }
    for (const recipe of recipes) {
      if (fs.existsSync(path.join(versiondir, artifactName(recipe, version)))) {
        tally.ok++
      } else if (fs.existsSync(path.join(logdir, builddir, `${recipe}.log`))) {
        tally[builddir === activeBuilddir ? 'pending' : 'failed']++
      } else if (builddir === activeBuilddir && !gatedOut(recipe, version)) {
        tally.pending++
      } else {
        tally.na++
      }
    }
    return { builddir, version, startedUTC: stampToDate(builddir), tally }
  })
}

const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')

function renderFragment (versions, matrix, activity, recent) {
  const out = []
  out.push('<h2>Build activity</h2>')
  if (activity.building) {
    const b = activity.building
    out.push(`<p><span class="badge building">building</span> <code>${esc(b.version)}</code>` +
      ` for ${b.minutes} min &middot; <a href="/logs/${esc(b.builddir)}/">watch logs</a></p>`)
  } else {
    out.push('<p>No build in progress.</p>')
  }
  if (activity.queue.length > 0) {
    out.push(`<p>Queued: ${activity.queue.map((v) => `<code>${esc(v)}</code>`).join(' ')}</p>`)
  }

  out.push('<h2>Latest build per release line</h2>')
  out.push('<p>Green cells link directly to the download; red cells link to the failing build log.</p>')
  out.push('<table>')
  out.push(`  <thead><tr><th>recipe</th>${versions.map((v) =>
    `<th><a href="/download/release/${esc(v)}/">${esc(v)}</a></th>`).join('')}</tr></thead>`)
  out.push('  <tbody>')
  for (const recipe of recipes) {
    out.push(`    <tr><th>${esc(recipe)}</th>`)
    for (const version of versions) {
      const { state, href } = matrix[recipe][version]
      const label = { ok: 'ok', failed: 'failed', na: 'n/a', none: '&mdash;' }[state]
      const badge = `<span class="badge ${state}">${label}</span>`
      out.push(`      <td>${href ? `<a class="cell" href="${esc(href)}">${badge}</a>` : badge}</td>`)
    }
    out.push('    </tr>')
  }
  out.push('  </tbody>')
  out.push('</table>')

  out.push('<h2>Recent builds</h2>')
  out.push('<table>')
  out.push('  <thead><tr><th>started (UTC)</th><th>version</th><th>result</th><th>logs</th></tr></thead>')
  out.push('  <tbody>')
  for (const b of recent) {
    const result = [
      b.tally.ok ? `<span class="badge ok">${b.tally.ok} ok</span>` : '',
      b.tally.failed ? `<span class="badge failed">${b.tally.failed} failed</span>` : '',
      b.tally.pending ? `<span class="badge building">${b.tally.pending} in progress</span>` : '',
      b.tally.na ? `<span class="badge na">${b.tally.na} skipped</span>` : ''
    ].filter(Boolean).join(' ')
    out.push(`    <tr><th>${esc(b.startedUTC)}</th><td><code>${esc(b.version)}</code></td>` +
      `<td>${result}</td><td><a href="/logs/${esc(b.builddir)}/">${esc(b.builddir)}</a></td></tr>`)
  }
  out.push('  </tbody>')
  out.push('</table>')

  out.push(`<p class="generated">Generated ${new Date().toISOString().replace('T', ' ').slice(0, 16)} UTC` +
    ' &middot; n/a = version excluded by the recipe\'s <code>should-build.sh</code>' +
    ' &middot; &mdash; = never attempted</p>')
  return out.join('\n') + '\n'
}

// Shared with www/index.html, keep the two in sync
const style = `<style>
  :root {
    color-scheme: light dark;
    --bg: #ffffff; --fg: #1a1a1a; --muted: #6b7280; --line: #e5e7eb;
    --accent: #3E863D;
    --ok-bg: #dcfce7; --ok-fg: #166534;
    --fail-bg: #fee2e2; --fail-fg: #991b1b;
    --na-bg: #f3f4f6; --na-fg: #6b7280;
    --build-bg: #dbeafe; --build-fg: #1e40af;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --bg: #111418; --fg: #e5e7eb; --muted: #9ca3af; --line: #2a2f36;
      --accent: #5FA04E;
      --ok-bg: #14351f; --ok-fg: #6ee7a0;
      --fail-bg: #3b1518; --fail-fg: #f4a0a0;
      --na-bg: #1c2128; --na-fg: #8b949e;
      --build-bg: #172a54; --build-fg: #93c5fd;
    }
  }
  body {
    background: var(--bg); color: var(--fg);
    font: 15px/1.5 system-ui, -apple-system, "Segoe UI", sans-serif;
    max-width: 60rem; margin: 2rem auto; padding: 0 1rem;
  }
  header { display: flex; align-items: baseline; gap: 0.7rem; margin-bottom: 0.4rem; }
  header img { height: 28px; align-self: center; }
  header .unofficial { font-size: 1.25rem; font-weight: 600; }
  h1 { font-size: 1.3rem; margin-bottom: 0.2rem; }
  h2 { font-size: 1.05rem; margin-top: 2rem; border-bottom: 2px solid var(--accent); padding-bottom: 0.2rem; }
  code { font-family: ui-monospace, monospace; font-size: 0.9em; }
  table { border-collapse: collapse; width: 100%; }
  th, td { padding: 0.45rem 0.8rem; text-align: left; border-bottom: 1px solid var(--line); }
  thead th { font-weight: 600; }
  tbody th { font-weight: 400; font-family: ui-monospace, monospace; font-size: 0.9rem; }
  table a {
    text-decoration: underline; text-decoration-style: dotted;
    text-decoration-color: var(--muted); text-underline-offset: 3px;
  }
  table a.cell { text-decoration: none; }
  .badge {
    display: inline-block; padding: 0.1rem 0.55rem; border-radius: 999px;
    font-size: 0.8rem; font-weight: 600;
  }
  .ok       { background: var(--ok-bg);    color: var(--ok-fg); }
  .failed   { background: var(--fail-bg);  color: var(--fail-fg); }
  .na, .none { background: var(--na-bg);   color: var(--na-fg); font-weight: 400; }
  .building { background: var(--build-bg); color: var(--build-fg); }
  .generated, footer { color: var(--muted); font-size: 0.85rem; margin-top: 1rem; }
  a { color: inherit; }
</style>`

function renderPage (fragment) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="refresh" content="300">
<title>Node.js unofficial-builds status</title>
${style}
</head>
<body>
<header>
  <a href="/"><picture>
    <source srcset="/logo-dark.svg" media="(prefers-color-scheme: dark)">
    <img src="/logo.svg" alt="Node.js">
  </picture></a>
  <span class="unofficial">unofficial builds status</span>
</header>
<p><a href="/">back to unofficial-builds.nodejs.org</a></p>
${fragment}</body>
</html>
`
}

function writeAtomic (file, content) {
  fs.writeFileSync(`${file}.tmp`, content)
  fs.renameSync(`${file}.tmp`, file)
}

async function main () {
  const versions = activeVersions(await releaseSchedule())
  const matrix = {}
  for (const recipe of recipes) {
    matrix[recipe] = {}
    for (const version of versions) {
      matrix[recipe][version] = cellState(recipe, version)
    }
  }
  const activity = currentActivity()
  const recent = recentBuilds(8, activity.building && activity.building.builddir)

  const fragment = renderFragment(versions, matrix, activity, recent)
  fs.mkdirSync(logdir, { recursive: true })
  writeAtomic(path.join(logdir, 'status-fragment.html'), fragment)
  writeAtomic(path.join(logdir, 'status.html'), renderPage(fragment))
  writeAtomic(path.join(logdir, 'status.json'), JSON.stringify({
    generated: new Date().toISOString(),
    activity,
    versions,
    matrix,
    recent
  }, null, 2) + '\n')
  // summary.html predates this script as a regular file; replace with a symlink
  const summary = path.join(logdir, 'summary.html')
  try {
    if (!fs.lstatSync(summary).isSymbolicLink()) {
      fs.unlinkSync(summary)
    }
  } catch {}
  try {
    fs.symlinkSync('status.html', summary)
  } catch (err) {
    if (err.code !== 'EEXIST') {
      throw err
    }
  }
}

main()
