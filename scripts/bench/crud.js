// k6 scenario for the CRUD database benchmarks.
// Config (per project + implementation) is injected as a JSON file whose path
// is given via the CONFIG_FILE env var (mounted from the host). Example file:
// {
//   "project": "contacts",
//   "impl": "py-flask",
//   "server": "Flask (dev)",
//   "host": "bench-contacts-py-flask",
//   "port": 5000,
//   "seed": 100,
//   "ops": [
//     {"name":"create","method":"POST","path":"/api/contacts","weight":40,
//      "body":"{\"name\":\"{{name}}\",\"phone\":\"{{phone}}\",\"email\":\"{{email}}\"}","form":false},
//     {"name":"list","method":"GET","path":"/api/contacts","weight":25},
//     {"name":"search","method":"GET","path":"/api/contacts/search","weight":15,"query":"q={{q}}"},
//     {"name":"delete","method":"DELETE","path":"/api/contacts/{id}","weight":20,"usesId":true}
//   ]
// }
import http from 'k6/http';
import { Counter, Trend } from 'k6/metrics';

const cfg = JSON.parse(open(__ENV.CONFIG_FILE));

export const options = {
  scenarios: {
    load: {
      executor: 'constant-vus',
      vus: Number(__ENV.BENCH_VUS || 20),
      duration: __ENV.BENCH_DURATION || '30s',
    },
  },
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)'],
};

const firstNames = [
  'Ana', 'Luis', 'Maria', 'Carlos', 'Sofia', 'Diego', 'Valentina', 'Jorge',
  'Lucia', 'Andres', 'Camila', 'Miguel', 'Isabella', 'Felipe', 'Renata',
];
const lastNames = [
  'Garcia', 'Martinez', 'Lopez', 'Hernandez', 'Gonzalez', 'Perez', 'Rodriguez',
  'Sanchez', 'Ramirez', 'Torres', 'Flores', 'Rivera', 'Gomez', 'Diaz', 'Castro',
];
const words = [
  'alpha', 'beta', 'gamma', 'delta', 'epsilon', 'zeta', 'eta', 'theta', 'iota',
  'kappa', 'lambda', 'mu', 'nu', 'xi', 'pi', 'rho', 'sigma', 'tau', 'phi',
  'chi', 'psi', 'omega', 'project', 'meeting', 'report', 'task', 'note', 'idea',
  'plan', 'design', 'review', 'build', 'deploy', 'test',
];

function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}
function rnd(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}
function name() {
  return pick(firstNames) + ' ' + pick(lastNames);
}
function phone() {
  let s = '';
  for (let i = 0; i < 10; i++) s += Math.floor(Math.random() * 10);
  return s;
}
function email() {
  const base = (name() + rnd(0, 999)).toLowerCase().replace(/[^a-z0-9]/g, '');
  return base + '@example.com';
}
function wordsN(n) {
  const out = [];
  for (let i = 0; i < n; i++) out.push(pick(words));
  return out.join(' ');
}
function bool() {
  return Math.random() < 0.5;
}

function fillStr(tpl) {
  return tpl
    .replaceAll('{{name}}', name())
    .replaceAll('{{phone}}', phone())
    .replaceAll('{{email}}', email())
    .replaceAll('{{subject}}', wordsN(4))
    .replaceAll('{{from}}', name())
    .replaceAll('{{sender}}', name())
    .replaceAll('{{body}}', wordsN(8))
    .replaceAll('{{title}}', wordsN(3))
    .replaceAll('{{description}}', wordsN(6))
    .replaceAll('{{length}}', String(rnd(8, 20)))
    .replaceAll('{{use_upper}}', String(bool()))
    .replaceAll('{{use_lower}}', String(bool()))
    .replaceAll('{{use_digits}}', String(bool()))
    .replaceAll('{{use_symbols}}', String(bool()))
    .replaceAll('{{uppercase}}', String(bool()))
    .replaceAll('{{lowercase}}', String(bool()))
    .replaceAll('{{numbers}}', String(bool()))
    .replaceAll('{{symbols}}', String(bool()))
    .replaceAll('{{flag}}', bool() ? '1' : '0')
    .replaceAll('{{q}}', pick(words));
}

function parseBody(tpl) {
  if (!tpl) return null;
  try {
    return JSON.parse(fillStr(tpl));
  } catch (e) {
    return fillStr(tpl);
  }
}

function extractId(res) {
  try {
    const j = res.json();
    if (j === null || typeof j !== 'object') return null;
    if (Array.isArray(j)) {
      return j.length ? String(j[0].id ?? j[0].Id ?? j[0]._id ?? '') : null;
    }
    for (const k of ['id', 'Id', '_id']) {
      if (j[k] !== undefined && j[k] !== null) return String(j[k]);
    }
    for (const k of ['contact', 'message', 'task']) {
      if (j[k] && typeof j[k] === 'object' && j[k].id !== undefined) return String(j[k].id);
    }
    return null;
  } catch (e) {
    return null;
  }
}

function extractIdsFromList(res) {
  try {
    const j = res.json();
    if (Array.isArray(j)) {
      return j
        .map((x) => (x && typeof x === 'object' ? String(x.id ?? x.Id ?? x._id ?? '') : ''))
        .filter(Boolean);
    }
    return [];
  } catch (e) {
    return [];
  }
}

export function setup() {
  const base = 'http://' + cfg.host + ':' + cfg.port;
  const ids = [];
  const createOp = cfg.ops.find((o) => o.name === 'create');
  if (createOp) {
    for (let i = 0; i < (cfg.seed || 100); i++) {
      const res = http.post(
        base + createOp.path,
        JSON.stringify(parseBody(createOp.body)),
        { headers: { 'Content-Type': 'application/json' } }
      );
      const id = extractId(res);
      if (id) ids.push(id);
    }
  }
  if (ids.length === 0) {
    const listOp = cfg.ops.find((o) => o.name === 'list');
    if (listOp) {
      const res = http.get(base + listOp.path);
      ids.push(...extractIdsFromList(res));
    }
  }
  return { ids };
}

let pool = null;
const opTrends = {};
const opErrors = {};
const opCounts = {};
for (const o of cfg.ops) {
  opTrends[o.name] = new Trend('op_' + o.name + '_duration');
  opErrors[o.name] = new Counter('op_' + o.name + '_errors');
  opCounts[o.name] = new Counter('op_' + o.name + '_count');
}

function pickWeighted(ops) {
  let total = 0;
  for (const o of ops) total += o.weight;
  let r = Math.random() * total;
  for (const o of ops) {
    r -= o.weight;
    if (r < 0) return o;
  }
  return ops[ops.length - 1];
}

function runOp(op) {
  const base = 'http://' + cfg.host + ':' + cfg.port;
  let path = op.path;
  if (op.usesId) {
    if (!pool.length) return;
    const idx = Math.floor(Math.random() * pool.length);
    const id = pool[idx];
    path = path.replace('{id}', encodeURIComponent(id));
    if (op.name === 'delete') pool.splice(idx, 1);
  }
  let url = base + path;
  if (op.query) url += '?' + fillStr(op.query);

  const params = { tags: { name: op.name, project: cfg.project, impl: cfg.impl } };
  let res;
  if (op.form) {
    res = http.post(url, parseBody(op.body), params);
  } else if (op.method === 'GET') {
    res = http.get(url, params);
  } else {
    const payload = parseBody(op.body);
    const body = payload !== null ? JSON.stringify(payload) : null;
    params.headers = { 'Content-Type': 'application/json' };
    if (op.method === 'POST') res = http.post(url, body, params);
    else if (op.method === 'PUT') res = http.put(url, body, params);
    else res = http.del(url, null, params);
  }

  opTrends[op.name].add(res.timings.duration);
  opCounts[op.name].add(1);
  if (res.status >= 400) opErrors[op.name].add(1);

  if (op.name === 'create' && res.status >= 200 && res.status < 300) {
    const id = extractId(res);
    if (id) pool.push(id);
  }
}

export default function (data) {
  if (pool === null) pool = data && data.ids ? data.ids.slice() : [];
  const avail = cfg.ops.filter((o) => !o.usesId || pool.length > 0);
  const op = pickWeighted(avail.length ? avail : cfg.ops.filter((o) => !o.usesId));
  runOp(op);
}

export function handleSummary(data) {
  const dur = (data.state.testRunDurationMs || 1000) / 1000;
  const reqs = data.metrics.http_reqs ? data.metrics.http_reqs.values.count : 0;
  const failedRate = data.metrics.http_req_failed ? data.metrics.http_req_failed.values.rate : 0;
  const d = data.metrics.http_req_duration ? data.metrics.http_req_duration.values : {};
  const total = {
    requests: reqs,
    rps: +((data.metrics.http_reqs ? data.metrics.http_reqs.values.rate : 0)).toFixed(2),
    failed: Math.round(reqs * failedRate),
    error_rate: +(failedRate * 100).toFixed(2),
    avg_ms: +((d.avg) || 0).toFixed(2),
    p50_ms: +((d['p(50)'] !== undefined ? d['p(50)'] : d.med) || 0).toFixed(2),
    p95_ms: +((d['p(95)']) || 0).toFixed(2),
    p99_ms: +((d['p(99)']) || 0).toFixed(2),
  };
  const ops = {};
  for (const o of cfg.ops) {
    const t = data.metrics['op_' + o.name + '_duration'];
    if (!t) continue;
    const v = t.values;
    const c = data.metrics['op_' + o.name + '_count'];
    const errs = data.metrics['op_' + o.name + '_errors'];
    const count = c ? c.values.count : 0;
    const errors = errs ? errs.values.count : 0;
    ops[o.name] = {
      count,
      errors,
      error_rate: +(count ? (errors / count) * 100 : 0).toFixed(2),
      avg_ms: +((v.avg) || 0).toFixed(2),
      p50_ms: +((v['p(50)'] !== undefined ? v['p(50)'] : v.med) || 0).toFixed(2),
      p95_ms: +((v['p(95)']) || 0).toFixed(2),
      p99_ms: +((v['p(99)']) || 0).toFixed(2),
    };
  }
  const out = {
    project: cfg.project,
    impl: cfg.impl,
    server: cfg.server,
    duration_s: +dur.toFixed(1),
    total,
    ops,
  };
  return { [__ENV.BENCH_OUT]: JSON.stringify(out, null, 2) };
}