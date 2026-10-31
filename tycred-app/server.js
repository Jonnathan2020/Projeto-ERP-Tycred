// TyCred · API local para o banco MySQL "tycred"
require('dotenv').config(); // lê o arquivo .env desta pasta
const express = require('express'), mysql = require('mysql2/promise'), path = require('path');
const DB = process.env.DB_NAME || 'tycred';
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost', port: +(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'root', password: process.env.DB_PASSWORD ?? '',
  database: DB, dateStrings: true, decimalNumbers: true, connectionLimit: 10
});
let META = {};

// Lê estrutura (colunas, PKs, FKs e CHECK ... IN (...)) direto do banco
async function loadMeta() {
  const [cols] = await pool.query("SELECT UPPER(TABLE_NAME) t,COLUMN_NAME n,DATA_TYPE d,IS_NULLABLE nl,COLUMN_KEY k,EXTRA x,COLUMN_DEFAULT df,CHARACTER_MAXIMUM_LENGTH ln FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=? ORDER BY TABLE_NAME,ORDINAL_POSITION", [DB]);
  const [fks] = await pool.query("SELECT UPPER(TABLE_NAME) t,COLUMN_NAME n,UPPER(REFERENCED_TABLE_NAME) rt,REFERENCED_COLUMN_NAME rc FROM information_schema.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA=? AND REFERENCED_TABLE_NAME IS NOT NULL", [DB]);
  let chk = [];
  try { [chk] = await pool.query("SELECT UPPER(tc.TABLE_NAME) t,cc.CHECK_CLAUSE c FROM information_schema.CHECK_CONSTRAINTS cc JOIN information_schema.TABLE_CONSTRAINTS tc ON tc.CONSTRAINT_SCHEMA=cc.CONSTRAINT_SCHEMA AND tc.CONSTRAINT_NAME=cc.CONSTRAINT_NAME WHERE tc.CONSTRAINT_SCHEMA=? AND tc.CONSTRAINT_TYPE='CHECK'", [DB]); } catch {}
  const M = {};
  for (const c of cols) {
    const t = M[c.t] ??= { name: c.t, cols: [], pk: [], fks: {}, enums: {} };
    const auto = /auto_increment/.test(c.x);
    t.cols.push({ name: c.n, type: c.d, len: c.ln, auto, blob: /blob/.test(c.d), req: c.nl === 'NO' && c.df == null && !auto });
    if (c.k === 'PRI') t.pk.push(c.n);
  }
  for (const f of fks) if (M[f.t]) M[f.t].fks[f.n] = { t: f.rt, c: f.rc };
  for (const k of chk) {
    const t = M[k.t], m = /`(\w+)`\s+in\s*\((.*)\)/i.exec(k.c);
    if (t && m) t.enums[m[1]] = [...m[2].matchAll(/'([^']*)'/g)].map(x => x[1]);
  }
  for (const t of Object.values(M)) if (t.pk.length === 1 && !t.cols.find(c => c.name === t.pk[0]).auto) t.cols.find(c => c.name === t.pk[0]).req = false; // ID gerado pela API
  META = M;
}

const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));
const w = fn => (q, s) => fn(q, s).catch(e => s.status(e.status || 400).json({ error: e.sqlMessage || e.message }));
const tb = n => { const t = META[String(n).toUpperCase()]; if (!t) throw Object.assign(new Error('Tabela inválida'), { status: 404 }); return t; };
const vis = t => t.cols.filter(c => !c.blob && c.name !== 'SENHA_HASH');
const bt = x => '`' + x + '`';
const clean = (t, b) => Object.fromEntries(vis(t).filter(c => c.name in b).map(c => [c.name, b[c.name] === '' ? null : b[c.name]]));
const wh = (t, q) => {
  if (!t.pk.length) throw new Error('Esta tabela não tem chave primária: edição e exclusão indisponíveis.');
  return [t.pk.map(k => bt(k) + '=?').join(' AND '), t.pk.map(k => q[k])];
};

app.get('/api/meta', (q, s) => s.json(META));

app.get('/api/t/:t', w(async (q, s) => {
  const t = tb(q.params.t), order = t.pk.length ? ' ORDER BY ' + t.pk.map(k => bt(k) + ' DESC').join(',') : '';
  const [r] = await pool.query(`SELECT ${vis(t).map(c => bt(c.name))} FROM ${bt(t.name)}${order} LIMIT 1000`);
  s.json(r);
}));

app.post('/api/t/:t', w(async (q, s) => {
  const t = tb(q.params.t), b = Object.fromEntries(Object.entries(clean(t, q.body)).filter(([, v]) => v != null));
  if (t.pk.length === 1 && b[t.pk[0]] == null && !t.cols.find(c => c.name === t.pk[0]).auto) {
    const [[m]] = await pool.query(`SELECT IFNULL(MAX(${bt(t.pk[0])}),0)+1 n FROM ${bt(t.name)}`);
    b[t.pk[0]] = m.n;
  }
  const k = Object.keys(b);
  const [r] = await pool.query(`INSERT INTO ${bt(t.name)} (${k.map(bt)}) VALUES (${k.map(() => '?')})`, k.map(x => b[x]));
  s.json({ ok: 1, id: r.insertId });
}));

app.put('/api/t/:t', w(async (q, s) => {
  const t = tb(q.params.t), [sql, v] = wh(t, q.query), b = clean(t, q.body);
  t.pk.forEach(k => delete b[k]);
  const k = Object.keys(b);
  await pool.query(`UPDATE ${bt(t.name)} SET ${k.map(x => bt(x) + '=?')} WHERE ${sql}`, [...k.map(x => b[x]), ...v]);
  s.json({ ok: 1 });
}));

app.delete('/api/t/:t', w(async (q, s) => {
  const t = tb(q.params.t), [sql, v] = wh(t, q.query);
  await pool.query(`DELETE FROM ${bt(t.name)} WHERE ${sql}`, v);
  s.json({ ok: 1 });
}));

// Dashboard: p = hoje | mes | 30d | tudo | custom (de, ate)
const VT = '(p.VALOR_INICIAL+p.VALOR_JUROS+p.VALOR_MULTA-p.VALOR_DESCONTO)';
const PG = '(VALOR_INICIAL_PAGO+IFNULL(VALOR_JUROS_PAGO,0)+IFNULL(VALOR_MULTA_PAGO,0)-IFNULL(VALOR_DESCONTO,0))';
app.get('/api/dashboard', w(async (q, s) => {
  const { p, de, ate } = q.query, dt = /^\d{4}-\d\d-\d\d$/;
  const pe = c => p === 'hoje' ? `DATE(${c})=CURDATE()`
    : p === 'mes' ? `DATE_FORMAT(${c},'%Y-%m')=DATE_FORMAT(CURDATE(),'%Y-%m')`
    : p === '30d' ? `${c}>=NOW()-INTERVAL 30 DAY`
    : p === 'custom' && dt.test(de) && dt.test(ate) ? `DATE(${c}) BETWEEN '${de}' AND '${ate}'` : '1=1';
  const Q = async x => (await pool.query(x))[0];
  const open = st => `SELECT IFNULL(SUM(${VT}),0) v,COUNT(*) qt FROM PARCELA p JOIN STATUS_PARCELA s ON s.ID_STATUS_PARCELA=p.STATUS_PARCELA WHERE s.NOME_STATUS_PARCELA IN (${st})`;
  const [[aberto], [atraso], [rec], [novos], [cli], [acd], emp, parc, clis, mensal, rmensal, score] = await Promise.all([
    Q(open("'A PAGAR','EM ATRASO','PARCIALMENTE PAGA'")), Q(open("'EM ATRASO'")),
    Q(`SELECT IFNULL(SUM(${PG}),0) v,COUNT(*) qt FROM PARCELA_LANCAMENTO WHERE ${pe('DATA_BAIXA')}`),
    Q(`SELECT COUNT(*) qt,IFNULL(SUM(VALOR_APROVADO),0) v FROM EMPRESTIMO WHERE ${pe('DATA_CADASTRO')}`),
    Q("SELECT COUNT(*) qt FROM CLIENTE c JOIN STATUS_CLIENTE s ON s.ID_STATUS_CLIENTE=c.STATUS_CLIENTE WHERE s.NOME_STATUS='ATIVO'"),
    Q(`SELECT COUNT(*) qt FROM ACORDO WHERE ${pe('DATA_CADASTRO')}`),
    Q(`SELECT s.NOME_STATUS n,COUNT(*) qt,IFNULL(SUM(e.VALOR_APROVADO),0) v FROM EMPRESTIMO e JOIN STATUS_EMPRESTIMO s ON s.ID_STATUS_EMPRESTIMO=e.STATUS_EMPRESTIMO WHERE ${pe('e.DATA_CADASTRO')} GROUP BY s.NOME_STATUS`),
    Q(`SELECT s.NOME_STATUS_PARCELA n,COUNT(*) qt,IFNULL(SUM(${VT}),0) v FROM PARCELA p JOIN STATUS_PARCELA s ON s.ID_STATUS_PARCELA=p.STATUS_PARCELA GROUP BY s.NOME_STATUS_PARCELA`),
    Q("SELECT s.NOME_STATUS n,COUNT(*) qt FROM CLIENTE c JOIN STATUS_CLIENTE s ON s.ID_STATUS_CLIENTE=c.STATUS_CLIENTE GROUP BY s.NOME_STATUS"),
    Q("SELECT DATE_FORMAT(IFNULL(DATA_DESEMBOLSO,DATA_CADASTRO),'%Y-%m') m,SUM(VALOR_APROVADO) v,AVG(VALOR_APROVADO) t FROM EMPRESTIMO WHERE VALOR_APROVADO IS NOT NULL GROUP BY m ORDER BY m DESC LIMIT 12"),
    Q(`SELECT DATE_FORMAT(DATA_BAIXA,'%Y-%m') m,SUM(${PG}) v FROM PARCELA_LANCAMENTO GROUP BY m ORDER BY m DESC LIMIT 12`),
    Q("SELECT CASE WHEN VALOR_SCORE<400 THEN 'Até 399' WHEN VALOR_SCORE<600 THEN '400 a 599' WHEN VALOR_SCORE<800 THEN '600 a 799' ELSE '800+' END n,COUNT(*) qt FROM CONSULTA_SCORE GROUP BY n ORDER BY n")
  ]);
  s.json({ aberto, atraso, rec, novos, ativos: cli.qt, acordos: acd.qt, emp, parc, clis, mensal, rmensal, score });
}));

const PORT = process.env.PORT || 3000;
loadMeta().then(() => app.listen(PORT, () => console.log(`TyCred rodando em http://localhost:${PORT} (banco: ${DB}, ${Object.keys(META).length} tabelas)`)))
  .catch(e => { console.error('Falha ao conectar no MySQL:', e.message, '\nConfira DB_HOST, DB_USER, DB_PASSWORD e DB_NAME.'); process.exit(1); });
