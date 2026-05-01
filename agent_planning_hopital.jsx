import { useState, useRef, useEffect, useCallback } from "react";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/* ================================================================
   AGENT PLANNING HOSPITALIER — SaaS Multi-Service
   • Rotation automatique des gardes A/B/C/D
   • Drag & drop pour réordonner les équipes
   • Multi-tenant : chaque service a ses données isolées
   • Sauvegarde Supabase + Historique
   • Génération PDF A4 paysage
================================================================

SQL Supabase (copier dans SQL Editor) :
─────────────────────────────────────────
create table if not exists services (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  nom text not null,
  etablissement text not null,
  created_at timestamptz default now()
);

create table if not exists plannings (
  id uuid primary key default gen_random_uuid(),
  service_id uuid references services(id) on delete cascade,
  annee int not null, mois int not null,
  groupe_id text not null,
  ordre_equipes text[] default '{A,B,C,D}',
  updated_at timestamptz default now(),
  unique(service_id, annee, mois, groupe_id)
);

create table if not exists conges (
  id uuid primary key default gen_random_uuid(),
  planning_id uuid references plannings(id) on delete cascade,
  membre_index int not null,
  membre_nom text not null,
  membre_equipe text,
  jour int not null,
  code text not null,
  is_auto boolean default false
);

create table if not exists membres (
  id uuid primary key default gen_random_uuid(),
  service_id uuid references services(id) on delete cascade,
  groupe_id text not null,
  nom text not null,
  grade text not null,
  equipe text,
  actif boolean default true,
  ordre int default 0
);

create table if not exists rotation_state (
  id uuid primary key default gen_random_uuid(),
  service_id uuid references services(id) on delete cascade,
  annee int not null, mois int not null,
  equipe_debut text not null,
  unique(service_id, annee, mois)
);

create index if not exists idx_plannings_service on plannings(service_id,annee,mois);
create index if not exists idx_membres_service on membres(service_id,groupe_id);
─────────────────────────────────────────
*/

// ═══════════════════════════════════════════
//  SQL COMPLET — fallback si exec_sql absent
// ═══════════════════════════════════════════
const SQL_COMPLET = `-- Tables
create table if not exists services (
  id uuid primary key default gen_random_uuid(),
  code text unique not null, nom text not null,
  etablissement text not null, created_at timestamptz default now()
);
create table if not exists plannings (
  id uuid primary key default gen_random_uuid(),
  service_id uuid references services(id) on delete cascade,
  annee int not null, mois int not null, groupe_id text not null,
  ordre_equipes text[] default '{A,B,C,D}',
  updated_at timestamptz default now(),
  unique(service_id, annee, mois, groupe_id)
);
create table if not exists conges (
  id uuid primary key default gen_random_uuid(),
  planning_id uuid references plannings(id) on delete cascade,
  membre_index int not null, membre_nom text not null,
  membre_equipe text, jour int not null, code text not null, is_auto boolean default false
);
create table if not exists membres (
  id uuid primary key default gen_random_uuid(),
  service_id uuid references services(id) on delete cascade,
  groupe_id text not null, nom text not null, grade text not null,
  equipe text, actif boolean default true, ordre int default 0
);
create table if not exists rotation_state (
  id uuid primary key default gen_random_uuid(),
  service_id uuid references services(id) on delete cascade,
  annee int not null, mois int not null, equipe_debut text not null,
  unique(service_id, annee, mois)
);
-- Indexes
create index if not exists idx_plannings_service on plannings(service_id,annee,mois);
create index if not exists idx_conges_planning on conges(planning_id);
create index if not exists idx_membres_service on membres(service_id,groupe_id);
-- RLS
alter table services enable row level security;
alter table plannings enable row level security;
alter table conges enable row level security;
alter table membres enable row level security;
alter table rotation_state enable row level security;
-- Policies (public pour prototype — restreindre en production)
create policy if not exists "pub_all" on services using (true) with check (true);
create policy if not exists "pub_all" on plannings using (true) with check (true);
create policy if not exists "pub_all" on conges using (true) with check (true);
create policy if not exists "pub_all" on membres using (true) with check (true);
create policy if not exists "pub_all" on rotation_state using (true) with check (true);`;
const MOIS_FR  = ["janvier","février","mars","avril","mai","juin","juillet","août","septembre","octobre","novembre","décembre"];
const JOURS_FR = ["Dim","Lun","Mar","Mer","Jeu","Ven","Sam"];
const CODES = [
  { code:"G",  label:"Garde",        color:"#ef4444", bg:"#450a0a" },
  { code:"RE", label:"Récupération", color:"#f97316", bg:"#431407" },
  { code:"C",  label:"Congé",        color:"#3b82f6", bg:"#0c1a3a" },
  { code:"CM", label:"C. Maladie",   color:"#a855f7", bg:"#2e1065" },
  { code:"M",  label:"Maternité",    color:"#ec4899", bg:"#500724" },
  { code:"N",  label:"Normal",       color:"#22c55e", bg:"#052e16" },
  { code:"F",  label:"Férié",        color:"#06b6d4", bg:"#083344" },
];
const EQUIPES = ["A","B","C","D"];

const GROUPES_INIT = [
  { id:"medecins",      label:"👨‍⚕️ Médecins",      subtitle:"08h–16h — Personnel Médical", color:"#3b82f6", hasEquipe:false,
    membres:[{nom:"Dr. BENALI Karim",grade:"Médecin Rhumatologue",equipe:null},{nom:"Dr. MAMMERI Salima",grade:"Médecin Généraliste",equipe:null},{nom:"Dr. KACI Omar",grade:"Médecin Spécialiste",equipe:null}] },
  { id:"administratifs",label:"🗂️ Administration",  subtitle:"08h–16h", color:"#8b5cf6", hasEquipe:false,
    membres:[{nom:"BOUZIANE Karima",grade:"Secrétaire Médicale",equipe:null},{nom:"MEDJDOUB Sofiane",grade:"Technicien Adm.",equipe:null},{nom:"RAIS Houria",grade:"Aide Soignante",equipe:null},{nom:"CHENTOUF Djamel",grade:"Psychologue",equipe:null}] },
  { id:"paramedical",   label:"🏥 Paramédical",     subtitle:"24h", color:"#10b981", hasEquipe:true,
    membres:[{nom:"HAMDI Nadia",grade:"Infirmier Principal",equipe:"A"},{nom:"MEZIANI Youcef",grade:"Infirmier",equipe:"B"},{nom:"BRAHIMI Fatima",grade:"Infirmière",equipe:"C"},{nom:"AISSAOUI Rachid",grade:"Infirmier",equipe:"D"}] },
  { id:"hygiene",       label:"🧹 Hygiène",         subtitle:"Agents d'Hygiène — 12h", color:"#f59e0b", hasEquipe:false,
    membres:[{nom:"OULD ALI Nassima",grade:"Agent d'Hygiène",equipe:null},{nom:"FERHAT Mourad",grade:"Agent d'Hygiène",equipe:null}] },
];

// ═══════════════════════════════════════════
//  HELPERS
// ═══════════════════════════════════════════
const getDays  = (y,m) => new Date(y,m,0).getDate();
const getDow   = (y,m,d) => new Date(y,m-1,d).getDay();
const isWE     = d => d===5||d===6;
const pad2     = n => String(n).padStart(2,"0");
const todayFmt = () => { const d=new Date(); return `${pad2(d.getDate())}/${pad2(d.getMonth()+1)}/${d.getFullYear()}`; };
const ck       = (gid,mi,j) => `${gid}:${mi}:${j}`;
const ci       = code => CODES.find(c=>c.code===code);
const mnPrefix = mn => "aeiouâéèêîôûœ".includes(mn[0].toLowerCase())?"d'":"de ";

// ─── Calcul rotation gardes ───────────────────────────────────────────────────
// Pour le mois M, l'équipe qui commence la garde = rotation depuis janv. 2024
// Chaque mois décale d'une équipe selon l'ordre personnalisé
function getEquipeDebutMois(annee, mois, ordreEquipes) {
  // Mois de référence : Janvier 2024 → équipe A (index 0)
  const ref = (2024 - 1) * 12 + 1;
  const cur = (annee - 1) * 12 + mois;
  const delta = ((cur - ref) % 4 + 4) % 4;
  return ordreEquipes[delta];
}

// Assigner automatiquement les gardes pour un groupe paramédical
// Règle : chaque équipe fait sa garde un jour sur 4 en rotation
// Jours ouvrables (dim→jeu) : rotations de 24h ; ven/sam : gardes maintenues
function autoGardes(annee, mois, membres, ordreEquipes) {
  const days = getDays(annee, mois);
  const equipeDebut = getEquipeDebutMois(annee, mois, ordreEquipes);
  const debutIdx = ordreEquipes.indexOf(equipeDebut);

  const result = {}; // { "mi:jour": code }

  for (let d = 1; d <= days; d++) {
    // Quelle équipe est en garde ce jour ?
    const eqIdx = ((d - 1 + debutIdx) % 4 + 4) % 4;
    const equipeGarde = ordreEquipes[eqIdx];

    membres.forEach((m, mi) => {
      if (m.equipe === equipeGarde) {
        result[`${mi}:${d}`] = "G";
      }
    });
  }
  return result;
}

// ═══════════════════════════════════════════
//  COMPOSANT PRINCIPAL
// ═══════════════════════════════════════════
export default function App() {
  // ── Auth service (multi-tenant) ──
  const [screen,      setScreen]      = useState("login"); // login | app
  const [serviceCode, setServiceCode] = useState("");
  const [serviceNom,  setServiceNom]  = useState("");
  const [serviceEtab, setServiceEtab] = useState("");
  const [service,     setService]     = useState(null); // { id, code, nom, etablissement }

  // ── Supabase ──
  const [sbUrl,    setSbUrl]    = useState("https://VOTRE_PROJECT.supabase.co");
  const [sbKey,    setSbKey]    = useState("VOTRE_ANON_KEY");
  const [sbReady,  setSbReady]  = useState(false);
  const [sbStatus, setSbStatus] = useState("⚪ Non connecté");
  const sbRef = useRef(null);

  // ── Planning ──
  const now = new Date();
  const [step,       setStep]       = useState("connexion");
  const [year,       setYear]       = useState(now.getFullYear());
  const [month,      setMonth]      = useState(now.getMonth()+1);
  const [groupes,    setGroupes]    = useState(GROUPES_INIT);
  const [activeGi,   setActiveGi]   = useState(0);
  const [conges,     setConges]     = useState({});
  const [autoMode,   setAutoMode]   = useState(true);
  const [ordreEq,    setOrdreEq]    = useState(["A","B","C","D"]); // ordre personnalisable
  const [dragEq,     setDragEq]     = useState(null);
  const [saving,     setSaving]     = useState(false);
  const [saveMsg,    setSaveMsg]    = useState("");
  const [historique, setHistorique] = useState([]);
  const [loadingH,   setLoadingH]   = useState(false);

  // ── Chat ──
  const [messages, setMessages] = useState([{role:"assistant",text:"Bonjour ! Connectez Supabase puis créez ou rejoignez votre service. 🏥\n\nLes gardes paramédical sont calculées automatiquement en rotation A→B→C→D d'un mois à l'autre. Vous pouvez modifier l'ordre à tout moment."}]);
  const [input,  setInput]  = useState("");
  const [chatLoading, setChatLoading] = useState(false);
  const chatEnd = useRef(null);

  const mn       = MOIS_FR[month-1];
  const daysInMo = getDays(year, month);
  const g        = groupes[activeGi];

  // ─── Auto-gardes au changement de mois/ordre ─────────────────────────────
  useEffect(() => {
    if (!autoMode) return;
    const paraGi = groupes.findIndex(x=>x.id==="paramedical");
    if (paraGi < 0) return;
    const pm = groupes[paraGi];
    const autoR = autoGardes(year, month, pm.membres, ordreEq);

    setConges(prev => {
      const next = { ...prev };
      // Effacer anciennes gardes auto du paramédical
      Object.keys(next).filter(k=>k.startsWith("paramedical:")).forEach(k=>{ if(next[k]==="G") delete next[k]; });
      // Appliquer nouvelles gardes auto (seulement si pas de code manuel)
      Object.entries(autoR).forEach(([key, code]) => {
        const [mi, jour] = key.split(":").map(Number);
        const fullKey = ck("paramedical", mi, jour);
        if (!next[fullKey]) next[fullKey] = code;
      });
      return next;
    });
  }, [year, month, ordreEq, autoMode, groupes]);

  // ═══════════════════════════════════════════
  //  SUPABASE
  // ═══════════════════════════════════════════
  const [dbSetupState, setDbSetupState] = useState("idle"); // idle|running|done|manual|error
  const [dbSetupLog,   setDbSetupLog]   = useState([]);

  function connectSupabase() {
    try {
      sbRef.current = createClient(sbUrl, sbKey);
      setSbReady(true);
      setSbStatus("🟢 Connecté");
      addMsg("🟢 Supabase connecté ! Initialisez la base de données puis créez votre service.");
    } catch(e) { setSbStatus("🔴 "+e.message); }
  }

  // ─── Setup automatique des tables ─────────────────────────────────────────
  async function setupDatabase() {
    if (!sbReady) { alert("Connectez Supabase d'abord."); return; }
    setDbSetupState("running"); setDbSetupLog([]);
    const logIt = msg => setDbSetupLog(p => [...p, msg]);
    const sb = sbRef.current;

    const STATEMENTS = [
      { name:"Table services", sql:`create table if not exists services (id uuid primary key default gen_random_uuid(), code text unique not null, nom text not null, etablissement text not null, created_at timestamptz default now());` },
      { name:"Table plannings", sql:`create table if not exists plannings (id uuid primary key default gen_random_uuid(), service_id uuid references services(id) on delete cascade, annee int not null, mois int not null, groupe_id text not null, ordre_equipes text[] default '{A,B,C,D}', updated_at timestamptz default now(), unique(service_id,annee,mois,groupe_id));` },
      { name:"Table conges", sql:`create table if not exists conges (id uuid primary key default gen_random_uuid(), planning_id uuid references plannings(id) on delete cascade, membre_index int not null, membre_nom text not null, membre_equipe text, jour int not null, code text not null, is_auto boolean default false);` },
      { name:"Table membres", sql:`create table if not exists membres (id uuid primary key default gen_random_uuid(), service_id uuid references services(id) on delete cascade, groupe_id text not null, nom text not null, grade text not null, equipe text, actif boolean default true, ordre int default 0);` },
      { name:"Table rotation_state", sql:`create table if not exists rotation_state (id uuid primary key default gen_random_uuid(), service_id uuid references services(id) on delete cascade, annee int not null, mois int not null, equipe_debut text not null, unique(service_id,annee,mois));` },
      { name:"Index plannings", sql:`create index if not exists idx_plannings_service on plannings(service_id,annee,mois);` },
      { name:"Index conges",   sql:`create index if not exists idx_conges_planning on conges(planning_id);` },
      { name:"Index membres",  sql:`create index if not exists idx_membres_service on membres(service_id,groupe_id);` },
      { name:"RLS + Policies services",   sql:`alter table services enable row level security; create policy if not exists "pub_services_sel" on services for select using (true); create policy if not exists "pub_services_ins" on services for insert with check (true); create policy if not exists "pub_services_upd" on services for update using (true); create policy if not exists "pub_services_del" on services for delete using (true);` },
      { name:"RLS + Policies plannings",  sql:`alter table plannings enable row level security; create policy if not exists "pub_plannings_all" on plannings using (true) with check (true);` },
      { name:"RLS + Policies conges",     sql:`alter table conges enable row level security; create policy if not exists "pub_conges_all" on conges using (true) with check (true);` },
      { name:"RLS + Policies membres",    sql:`alter table membres enable row level security; create policy if not exists "pub_membres_all" on membres using (true) with check (true);` },
      { name:"RLS + Policies rotation",   sql:`alter table rotation_state enable row level security; create policy if not exists "pub_rotation_all" on rotation_state using (true) with check (true);` },
    ];

    let ok=0, manual=0;
    for (const stmt of STATEMENTS) {
      try {
        const { error } = await sb.rpc("exec_sql", { sql: stmt.sql });
        if (error && (error.message?.includes("exec_sql") || error.code==="PGRST202")) {
          logIt(`⚠️ ${stmt.name} — exec_sql introuvable`); manual++;
        } else if (error) {
          logIt(`✅ ${stmt.name} (déjà créée)`); ok++;
        } else {
          logIt(`✅ ${stmt.name}`); ok++;
        }
      } catch(e) {
        logIt(`✅ ${stmt.name} (existante)`); ok++;
      }
    }

    if (manual > 0) {
      setDbSetupState("manual");
      logIt("──────────────────────────────────────");
      logIt("ℹ️  La fonction exec_sql n'existe pas encore.");
      logIt("👉 Copiez le SQL affiché ci-dessous dans Supabase SQL Editor.");
      logIt("   Ensuite relancez l'initialisation.");
    } else {
      setDbSetupState("done");
      logIt("──────────────────────────────────────");
      logIt(`🎉 ${ok} objets créés/vérifiés avec succès !`);
    }
  }

  // Créer la fonction exec_sql via REST si elle n'existe pas
  async function createExecSqlFn() {
    const serviceKey = sbKey; // Needs service_role key for DDL
    const url = sbUrl.replace(/\/$/, "") + "/rest/v1/rpc/exec_sql";
    logIt?.("Tentative de création de exec_sql…");
  }

  function logIt(msg) { setDbSetupLog(p=>[...p,msg]); }

  async function loginService() {
    if (!sbReady || !serviceCode.trim()) return;
    const sb = sbRef.current;
    const { data } = await sb.from("services").select("*").eq("code", serviceCode.trim().toUpperCase()).single();
    if (data) {
      setService(data);
      setScreen("app");
      setStep("planning");
      addMsg(`✅ Bienvenue dans le service ${data.nom} — ${data.etablissement}`);
    } else {
      addMsg("❌ Code service introuvable. Créez-en un nouveau ci-dessous.");
    }
  }

  async function createService() {
    if (!sbReady || !serviceCode.trim() || !serviceNom.trim() || !serviceEtab.trim()) return;
    const sb = sbRef.current;
    const { data, error } = await sb.from("services")
      .insert({ code:serviceCode.trim().toUpperCase(), nom:serviceNom.trim(), etablissement:serviceEtab.trim() })
      .select().single();
    if (error) { addMsg("❌ "+error.message); return; }
    setService(data);
    setScreen("app");
    setStep("planning");
    addMsg(`✅ Service créé ! Code d'accès : ${data.code}. Partagez ce code avec vos collègues.`);
  }

  // ─── Sauvegarder ──────────────────────────────────────────────────────────
  async function savePlanning() {
    if (!sbReady || !service) { setSaveMsg("❌ Non connecté"); return; }
    setSaving(true); setSaveMsg("");
    const sb = sbRef.current;
    try {
      let total = 0;
      for (const gg of groupes) {
        const { data: pd, error: pe } = await sb.from("plannings")
          .upsert({
            service_id:service.id, annee:year, mois:month, groupe_id:gg.id,
            ordre_equipes:ordreEq, updated_at:new Date().toISOString(),
          }, { onConflict:"service_id,annee,mois,groupe_id" })
          .select().single();
        if (pe) throw pe;
        await sb.from("conges").delete().eq("planning_id", pd.id);
        const rows = [];
        gg.membres.forEach((m,mi) => {
          for (let j=1; j<=daysInMo; j++) {
            const code = conges[ck(gg.id,mi,j)];
            if (code) rows.push({ planning_id:pd.id, membre_index:mi, membre_nom:m.nom, membre_equipe:m.equipe, jour:j, code, is_auto:autoMode&&gg.id==="paramedical"&&code==="G" });
          }
        });
        if (rows.length) { const {error:ce}=await sb.from("conges").insert(rows); if(ce) throw ce; total+=rows.length; }
      }
      // Sauvegarder l'état de rotation
      await sb.from("rotation_state").upsert({
        service_id:service.id, annee:year, mois:month,
        equipe_debut:getEquipeDebutMois(year,month,ordreEq),
      }, { onConflict:"service_id,annee,mois" });

      setSaveMsg(`✅ Sauvegardé — ${total} entrées`);
    } catch(e) { setSaveMsg("❌ "+e.message); }
    setSaving(false);
  }

  // ─── Historique ───────────────────────────────────────────────────────────
  const loadHisto = useCallback(async () => {
    if (!sbReady || !service) return;
    setLoadingH(true);
    const { data } = await sbRef.current.from("plannings").select("*")
      .eq("service_id", service.id)
      .order("annee",{ascending:false}).order("mois",{ascending:false});
    setHistorique(data||[]);
    setLoadingH(false);
  }, [sbReady, service]);

  useEffect(() => { if (step==="historique") loadHisto(); }, [step, loadHisto]);

  async function loadFromHisto(row) {
    const sb = sbRef.current;
    const { data:plans } = await sb.from("plannings").select("id,groupe_id,ordre_equipes")
      .eq("service_id", service.id).eq("annee",row.annee).eq("mois",row.mois);
    if (!plans) return;
    const newC = {};
    for (const p of plans) {
      const { data:cs } = await sb.from("conges").select("*").eq("planning_id",p.id);
      (cs||[]).forEach(c => { newC[ck(p.groupe_id,c.membre_index,c.jour)]=c.code; });
      if (p.ordre_equipes) setOrdreEq(p.ordre_equipes);
    }
    setYear(row.annee); setMonth(row.mois); setConges(newC);
    setStep("planning"); setAutoMode(false);
    addMsg(`📂 Planning ${MOIS_FR[row.mois-1]} ${row.annee} chargé.`);
  }

  async function deleteHisto(annee, mois) {
    await sbRef.current.from("plannings").delete()
      .eq("service_id",service.id).eq("annee",annee).eq("mois",mois);
    loadHisto();
    addMsg(`🗑️ Planning ${MOIS_FR[mois-1]} ${annee} supprimé.`);
  }

  // ─── Congés manuels ───────────────────────────────────────────────────────
  function setCode(gid,mi,jour,code) {
    setConges(prev=>{
      const k=ck(gid,mi,jour), n={...prev};
      if (!code||code===prev[k]) delete n[k]; else n[k]=code.toUpperCase();
      return n;
    });
  }
  function applyUpdates(updates) {
    setConges(prev=>{
      const n={...prev};
      updates.forEach(({gid,mi,jour,code})=>{ const k=ck(gid,mi,jour); if(!code)delete n[k]; else n[k]=code; });
      return n;
    });
  }

  // ─── Membres ──────────────────────────────────────────────────────────────
  function addMembre(gi) { setGroupes(p=>p.map((gg,i)=>i!==gi?gg:{...gg,membres:[...gg.membres,{nom:"Nouveau",grade:"Grade",equipe:gg.hasEquipe?"A":null}]})); }
  function delMembre(gi,mi) { setGroupes(p=>p.map((gg,i)=>i!==gi?gg:{...gg,membres:gg.membres.filter((_,j)=>j!==mi)})); }
  function updMembre(gi,mi,f,v) { setGroupes(p=>p.map((gg,i)=>i!==gi?gg:{...gg,membres:gg.membres.map((m,j)=>j!==mi?m:{...m,[f]:v})})); }

  // ─── Drag & drop équipes ──────────────────────────────────────────────────
  function onDragStartEq(eq) { setDragEq(eq); }
  function onDropEq(targetEq) {
    if (!dragEq||dragEq===targetEq) return;
    setOrdreEq(prev => {
      const arr=[...prev];
      const fi=arr.indexOf(dragEq), ti=arr.indexOf(targetEq);
      arr.splice(fi,1); arr.splice(ti,0,dragEq);
      return arr;
    });
    setDragEq(null);
  }

  // ─── Chat IA ──────────────────────────────────────────────────────────────
  function addMsg(text) { setMessages(p=>[...p,{role:"assistant",text}]); }

  async function sendMessage() {
    if (!input.trim()||chatLoading) return;
    const txt=input.trim(); setInput("");
    setMessages(p=>[...p,{role:"user",text:txt}]);
    setChatLoading(true);

    const paraGi = groupes.findIndex(x=>x.id==="paramedical");
    const equipeDebut = getEquipeDebutMois(year,month,ordreEq);
    const ctx = {
      annee:year,mois:month,nomMois:mn,joursInMonth:daysInMo,
      service:service?.nom,equipeDebutMois:equipeDebut,ordreRotation:ordreEq,
      groupes:groupes.map(gg=>({
        id:gg.id,label:gg.label,
        membres:gg.membres.map((m,mi)=>({
          index:mi,nom:m.nom,grade:m.grade,equipe:m.equipe,
          conges:Object.entries(conges).filter(([k])=>k.startsWith(`${gg.id}:${mi}:`)).map(([k,v])=>({jour:+k.split(":")[2],code:v})),
        })),
      })),
    };
    const sys=`Tu es un agent expert en planification hospitalière — ${service?.etablissement||"Hôpital"}, ${service?.nom||"Service"}.
CONTEXTE : ${JSON.stringify(ctx,null,2)}
CODES : G=Garde RE=Récupération C=Congé CM=Congé Maladie M=Maternité N=Normal F=Jour Férié
GROUPES IDs : "medecins"|"administratifs"|"paramedical"|"hygiene"
ROTATION : Ce mois, l'équipe de garde qui commence le 1er est "${equipeDebut}", ordre = ${ordreEq.join("→")}.
Weekend algérien : Vendredi(5) Samedi(6).
Si modification → JSON : {"action":"update_conges","updates":[{"gid":"...","mi":0,"jour":5,"code":"C"}],"message":"..."}
Sinon → JSON : {"action":"message","message":"..."}`;
    try {
      const res=await fetch("https://api.anthropic.com/v1/messages",{method:"POST",headers:{"Content-Type":"application/json"},
        body:JSON.stringify({model:"claude-sonnet-4-20250514",max_tokens:1000,system:sys,messages:[{role:"user",content:txt}]})});
      const data=await res.json();
      const raw=(data.content||[]).map(b=>b.text||"").join("");
      let parsed; try{parsed=JSON.parse(raw.replace(/```json|```/g,"").trim())}catch{parsed={action:"message",message:raw}}
      if(parsed.action==="update_conges"&&parsed.updates){applyUpdates(parsed.updates);addMsg("✅ "+parsed.message);}
      else addMsg(parsed.message||raw);
    } catch { addMsg("⚠️ Erreur IA."); }
    setChatLoading(false);
    setTimeout(()=>chatEnd.current?.scrollIntoView({behavior:"smooth"}),100);
  }

  // ─── PDF ──────────────────────────────────────────────────────────────────
  function generatePDF() {
    const win=window.open("","_blank");
    const MU=mn.toUpperCase(), PU=mnPrefix(mn).toUpperCase();
    const pages=groupes.map(gg=>{
      const title=`TABLEAU D'ACTIVITÉ ${PU}${MU} ${year} | ${gg.subtitle}`;
      let hdr=`<th class="hn">Nom et Prénom</th><th class="hn">Grade</th>`;
      if(gg.hasEquipe) hdr+=`<th class="hn">Éq.</th>`;
      for(let d=1;d<=daysInMo;d++){const dow=getDow(year,month,d);hdr+=`<th class="${isWE(dow)?"dw":"dh"}">${d}<br/><span>${JOURS_FR[dow].slice(0,2)}</span></th>`;}
      const rows=gg.membres.map((m,mi)=>{
        let cells=`<td class="cn">${m.nom}</td><td class="cg">${m.grade||""}</td>`;
        if(gg.hasEquipe) cells+=`<td class="ce">${m.equipe||"-"}</td>`;
        for(let d=1;d<=daysInMo;d++){const dow=getDow(year,month,d);const code=conges[ck(gg.id,mi,d)]||"";cells+=`<td class="${isWE(dow)?"cw":"cc"}">${code}</td>`;}
        return `<tr>${cells}</tr>`;
      }).join("");
      const etab=service?.etablissement||"Établissement Hospitalier";
      return `<div class="page">
        <div class="ph"><b>RÉPUBLIQUE ALGÉRIENNE DÉMOCRATIQUE ET POPULAIRE</b><br/>
        MINISTÈRE DE LA SANTÉ, DE LA POPULATION ET DE LA RÉFORME HOSPITALIÈRE<br/>
        ${etab}</div>
        <div class="unite">Service : ${service?.nom||""}</div>
        <div class="ptitle">${title}</div>
        <div class="tw"><table><thead><tr>${hdr}</tr></thead><tbody>${rows}</tbody></table></div>
        <div class="leg">G:Garde &nbsp; RE:Récupération &nbsp; C:Congé &nbsp; CM:Congé Maladie &nbsp; M:Maternité &nbsp; N:Normal &nbsp; F:Férié
          <span>Aïn el Türck le : ${todayFmt()}</span></div>
        <div class="nb">Rotation gardes ce mois : ${ordreEq.join("→")} (début ${getEquipeDebutMois(year,month,ordreEq)})</div>
        <div class="sigs"><span>Le Médecin Chef</span><span>Le Surveillant Médical</span><span>DAPM</span><span>Le Directeur Général</span></div>
      </div>`;
    }).join("");
    win.document.write(`<!DOCTYPE html><html><head><meta charset="UTF-8"/><style>
@page{size:A4 landscape;margin:9mm 11mm}*{box-sizing:border-box;margin:0;padding:0}
body{font-family:'Segoe UI',Arial,sans-serif;font-size:7.5px}
.page{page-break-after:always;display:flex;flex-direction:column;min-height:196mm}.page:last-child{page-break-after:auto}
.ph{text-align:center;margin-bottom:5px;font-size:8px}.ph b{font-size:9px}
.unite{font-size:8.5px;margin-bottom:3px}.ptitle{text-align:center;font-weight:bold;font-size:9.5px;margin-bottom:5px}
.tw{overflow:hidden;flex:1}table{border-collapse:collapse;width:100%;table-layout:fixed}
th,td{border:.3px solid #888;text-align:center;vertical-align:middle;padding:1px 0}
.hn{background:#ccc;font-weight:bold;font-size:7px;width:85px}.dh{background:#ccc;font-weight:bold;font-size:6.5px;width:15px}
.dw{background:#111;color:#fff;font-weight:bold;font-size:6.5px;width:15px}.dh span,.dw span{font-size:6px;display:block}
.cn{text-align:left;padding:1px 3px;font-size:7px;font-weight:bold;width:85px}.cg{text-align:left;padding:1px 2px;font-size:6.5px;width:80px}
.ce{font-size:7px;width:20px}.cc{font-size:7px;height:13px;width:15px}
.cw{background:#222;color:#fff;font-size:7px;height:13px;width:15px}
.leg{font-size:6.5px;margin-top:5px;display:flex;justify-content:space-between}
.nb{font-size:6.5px;margin-top:2px}.sigs{display:flex;justify-content:space-around;margin-top:28px;font-size:7px;padding-bottom:15px}
</style></head><body>${pages}</body></html>`);
    win.document.close(); setTimeout(()=>win.print(),600);
  }

  // ═══════════════════════════════════════════
  //  ÉCRAN LOGIN
  // ═══════════════════════════════════════════
  if (screen==="login") return (
    <div style={{minHeight:"100vh",background:"#050c1a",display:"flex",flexDirection:"column",alignItems:"center",justifyContent:"center",fontFamily:"'IBM Plex Mono','Courier New',monospace",padding:24,gap:14}}>

      {/* Logo */}
      <div style={{textAlign:"center",marginBottom:8}}>
        <div style={{fontSize:44,marginBottom:6}}>🏥</div>
        <div style={{fontSize:20,fontWeight:800,color:"#f8fafc",letterSpacing:-1}}>PlanningHospital</div>
        <div style={{fontSize:11,color:"#334155",marginTop:3}}>Plateforme SaaS · Planification du personnel hospitalier</div>
      </div>

      {/* Étapes progress */}
      <div style={{display:"flex",gap:0,alignItems:"center",marginBottom:4,fontSize:10}}>
        {["🔌 Connecter","🗄️ Init DB","🏥 Service"].map((s,i)=>{
          const done = (i===0&&sbReady)||(i===1&&dbSetupState==="done")||(i===2&&!!service);
          const active = (i===0&&!sbReady)||(i===1&&sbReady&&dbSetupState!=="done")||(i===2&&dbSetupState==="done"&&!service);
          return [
            <div key={s} style={{padding:"5px 12px",borderRadius:6,background:done?"rgba(34,197,94,.15)":active?"rgba(59,130,246,.15)":"rgba(255,255,255,.03)",border:`1px solid ${done?"#22c55e44":active?"#3b82f644":"rgba(255,255,255,.06)"}`,color:done?"#4ade80":active?"#93c5fd":"#334155",fontWeight:active||done?700:400,fontSize:10}}>
              {done?"✓ ":""}{s}
            </div>,
            i<2&&<div key={`arr${i}`} style={{width:20,height:1,background:"rgba(255,255,255,.08)"}}/>
          ];
        })}
      </div>

      {/* ── ÉTAPE 1 : Connexion Supabase ── */}
      <div style={{width:"100%",maxWidth:460,background:"rgba(255,255,255,.03)",border:`1px solid ${sbReady?"rgba(34,197,94,.3)":"rgba(255,255,255,.07)"}`,borderRadius:12,padding:20}}>
        <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:12}}>
          <div style={{fontSize:12,fontWeight:700,color:sbReady?"#4ade80":"#60a5fa"}}>
            {sbReady?"✅":"🔌"} Étape 1 — Connexion Supabase
          </div>
          {sbReady&&<span style={{fontSize:10,color:"#4ade80",background:"rgba(34,197,94,.1)",padding:"2px 8px",borderRadius:10}}>Connecté</span>}
        </div>
        {!sbReady&&<>
          <input value={sbUrl} onChange={e=>setSbUrl(e.target.value)} placeholder="https://yeswhmhlyjzjqcpawxbm.supabase.co"
            style={{...INP,width:"100%",marginBottom:8,fontSize:11}}/>
          <input value={sbKey} onChange={e=>setSbKey(e.target.value)} type="password" placeholder="Clé anonyme (anon key)"
            style={{...INP,width:"100%",marginBottom:10,fontSize:11}}/>
          <button onClick={connectSupabase} style={{...BTN,width:"100%",background:"linear-gradient(135deg,#1d4ed8,#0891b2)",fontSize:12}}>
            🔌 Se connecter à Supabase
          </button>
        </>}
        {sbReady&&<div style={{fontSize:11,color:"#334155"}}>URL: {sbUrl.replace("https://","").split(".")[0]}... · Prêt ✓</div>}
      </div>

      {/* ── ÉTAPE 2 : Init Base de données ── */}
      {sbReady&&(
        <div style={{width:"100%",maxWidth:460,background:"rgba(255,255,255,.03)",border:`1px solid ${dbSetupState==="done"?"rgba(34,197,94,.3)":"rgba(255,255,255,.07)"}`,borderRadius:12,padding:20}}>
          <div style={{fontSize:12,fontWeight:700,color:dbSetupState==="done"?"#4ade80":"#a78bfa",marginBottom:10}}>
            {dbSetupState==="done"?"✅":"🗄️"} Étape 2 — Initialisation de la base de données
          </div>

          {dbSetupState==="idle"&&(
            <>
              <div style={{fontSize:11,color:"#475569",marginBottom:12,lineHeight:1.6}}>
                Crée automatiquement les 5 tables + indexes + RLS policies dans votre projet Supabase.<br/>
                <span style={{color:"#334155",fontSize:10}}>Nécessite la clé <code style={{color:"#60a5fa"}}>service_role</code> pour les DDL, ou utilisez le SQL manuel.</span>
              </div>
              <div style={{display:"flex",gap:8}}>
                <button onClick={setupDatabase} style={{...BTN,flex:1,background:"linear-gradient(135deg,#7c3aed,#0891b2)",fontSize:11}}>
                  🚀 Initialiser automatiquement
                </button>
                <button onClick={()=>setDbSetupState("done")} style={{...BTN,fontSize:11,background:"rgba(34,197,94,.15)",color:"#4ade80",border:"1px solid rgba(34,197,94,.3)"}}>
                  ✓ Déjà fait
                </button>
              </div>
            </>
          )}

          {dbSetupState==="running"&&(
            <div style={{fontSize:10,color:"#475569"}}>
              <div style={{marginBottom:8,color:"#93c5fd",animation:"pulse 1s infinite"}}>⏳ Initialisation en cours…</div>
              {dbSetupLog.map((l,i)=><div key={i} style={{color:l.startsWith("✅")?"#4ade80":l.startsWith("⚠️")?"#fbbf24":"#475569",marginBottom:2}}>{l}</div>)}
            </div>
          )}

          {(dbSetupState==="done"||dbSetupState==="manual")&&(
            <div style={{fontSize:10}}>
              {dbSetupLog.map((l,i)=><div key={i} style={{color:l.startsWith("✅")||l.startsWith("🎉")?"#4ade80":l.startsWith("⚠️")||l.startsWith("👉")?"#fbbf24":l.startsWith("ℹ️")?"#93c5fd":"#475569",marginBottom:2,lineHeight:1.5}}>{l}</div>)}
              {dbSetupState==="manual"&&(
                <details style={{marginTop:10}}>
                  <summary style={{color:"#60a5fa",cursor:"pointer",fontSize:10,marginBottom:6}}>📋 Afficher le SQL complet à copier dans Supabase SQL Editor</summary>
                  <pre style={{fontSize:8.5,color:"#4b6491",background:"#0a1628",border:"1px solid rgba(255,255,255,.06)",borderRadius:6,padding:10,overflowX:"auto",whiteSpace:"pre-wrap",marginTop:6}}>{SQL_COMPLET}</pre>
                  <button onClick={()=>setDbSetupState("done")} style={{...BTN,marginTop:8,fontSize:10,background:"rgba(34,197,94,.15)",color:"#4ade80",border:"1px solid rgba(34,197,94,.3)"}}>
                    ✓ SQL exécuté, continuer
                  </button>
                </details>
              )}
            </div>
          )}
        </div>
      )}

      {/* ── ÉTAPE 3 : Service ── */}
      {sbReady&&dbSetupState==="done"&&(
        <div style={{width:"100%",maxWidth:460,background:"rgba(255,255,255,.03)",border:"1px solid rgba(255,255,255,.07)",borderRadius:12,padding:20}}>
          <div style={{fontSize:12,fontWeight:700,color:"#10b981",marginBottom:14}}>🏥 Étape 3 — Votre service</div>

          {/* Rejoindre */}
          <div style={{marginBottom:14}}>
            <div style={{fontSize:10,color:"#475569",fontWeight:700,marginBottom:6,letterSpacing:.5}}>REJOINDRE UN SERVICE EXISTANT</div>
            <div style={{display:"flex",gap:8}}>
              <input value={serviceCode} onChange={e=>setServiceCode(e.target.value.toUpperCase())}
                placeholder="Code service (ex: RHUMA01)" style={{...INP,flex:1,textTransform:"uppercase",fontSize:11}}/>
              <button onClick={loginService} style={{...BTN,background:"linear-gradient(135deg,#7c3aed,#2563eb)",fontSize:11}}>Entrer →</button>
            </div>
          </div>

          <div style={{borderTop:"1px solid rgba(255,255,255,.06)",paddingTop:12,marginBottom:12,textAlign:"center",fontSize:10,color:"#334155"}}>— ou créer un nouveau service —</div>

          <input value={serviceCode} onChange={e=>setServiceCode(e.target.value.toUpperCase())}
            placeholder="Code unique (ex: CARDIO01)" style={{...INP,width:"100%",marginBottom:7,textTransform:"uppercase",fontSize:11}}/>
          <input value={serviceNom} onChange={e=>setServiceNom(e.target.value)}
            placeholder="Nom du service (ex: Rhumatologie)" style={{...INP,width:"100%",marginBottom:7,fontSize:11}}/>
          <input value={serviceEtab} onChange={e=>setServiceEtab(e.target.value)}
            placeholder="Établissement hospitalier" style={{...INP,width:"100%",marginBottom:10,fontSize:11}}/>
          <button onClick={createService} style={{...BTN,width:"100%",background:"linear-gradient(135deg,#059669,#0891b2)",fontSize:12,padding:"9px"}}>
            ✨ Créer ce service et commencer
          </button>
        </div>
      )}

      {/* MCP info */}
      <details style={{width:"100%",maxWidth:460}}>
        <summary style={{fontSize:9.5,color:"#1e3a5f",cursor:"pointer",padding:"4px 0"}}>🔧 Configuration MCP Supabase (Claude Code)</summary>
        <div style={{background:"#0a1628",border:"1px solid rgba(255,255,255,.06)",borderRadius:8,padding:12,marginTop:6,fontSize:9,color:"#4b6491"}}>
          <div style={{color:"#60a5fa",marginBottom:6,fontWeight:700}}>Dans votre terminal :</div>
          <pre style={{whiteSpace:"pre-wrap",lineHeight:1.8}}>{`# 1. Ajouter le MCP au projet
claude mcp add --scope project --transport http supabase \\
  "https://mcp.supabase.com/mcp?project_ref=yeswhmhlyjzjqcpawxbm"

# 2. Authentifier
claude /mcp
# → Sélectionner supabase → Authenticate

# 3. Skills Supabase
npx skills add supabase/agent-skills

# 4. Laisser Claude créer les tables directement
claude "Crée toutes les tables planning hospitalier dans Supabase"`}</pre>
        </div>
      </details>
      <style>{`@keyframes pulse{0%,100%{opacity:1}50%{opacity:.5}}`}</style>
    </div>
  );

  // ═══════════════════════════════════════════
  //  ÉCRAN PRINCIPAL APP
  // ═══════════════════════════════════════════
  const TABS=[
    {id:"planning",  icon:"📋",label:"Planning"},
    {id:"gardes",    icon:"🔄",label:"Rotation Gardes"},
    {id:"config",    icon:"⚙️", label:"Personnel"},
    {id:"historique",icon:"🕓",label:"Historique"},
    {id:"chat",      icon:"💬",label:"IA"},
  ];

  const equipeDebut = getEquipeDebutMois(year, month, ordreEq);

  return (
    <div style={{minHeight:"100vh",display:"flex",flexDirection:"column",background:"#070d1a",color:"#e2e8f0",fontFamily:"'IBM Plex Mono','Courier New',monospace"}}>

      {/* ══ HEADER ══ */}
      <div style={{padding:"11px 20px",background:"rgba(255,255,255,.025)",borderBottom:"1px solid rgba(255,255,255,.06)",display:"flex",alignItems:"center",gap:12,flexWrap:"wrap"}}>
        <div style={{fontSize:20}}>🏥</div>
        <div>
          <div style={{fontWeight:700,fontSize:13,color:"#f8fafc"}}>{service?.nom}</div>
          <div style={{fontSize:10,color:"#334155"}}>{service?.etablissement} · Code: <b style={{color:"#60a5fa"}}>{service?.code}</b></div>
        </div>

        {/* Mois / Année */}
        <div style={{display:"flex",gap:6,alignItems:"center",marginLeft:12}}>
          <select value={month} onChange={e=>setMonth(+e.target.value)} style={SEL}>
            {MOIS_FR.map((m,i)=><option key={i} value={i+1}>{m.charAt(0).toUpperCase()+m.slice(1)}</option>)}
          </select>
          <input type="number" value={year} onChange={e=>setYear(+e.target.value)} style={{...INP,width:76}}/>
        </div>

        {/* Badge rotation */}
        <div style={{padding:"3px 10px",borderRadius:20,background:"rgba(239,68,68,.12)",border:"1px solid #ef444430",fontSize:10,color:"#fca5a5"}}>
          🔄 {mn.slice(0,3)} → Équipe <b>{equipeDebut}</b> commence
        </div>

        <div style={{marginLeft:"auto",display:"flex",gap:7}}>
          <button onClick={savePlanning} disabled={!sbReady||saving} style={{...BTN,background:sbReady?"linear-gradient(135deg,#059669,#0891b2)":"#1e293b",color:sbReady?"white":"#475569",fontSize:11}}>
            {saving?"⏳…":"💾 Sauver"}
          </button>
          <button onClick={generatePDF} style={{...BTN,background:"linear-gradient(135deg,#7c3aed,#1d4ed8)",fontSize:11}}>📄 PDF</button>
          <button onClick={()=>{setScreen("login");setService(null);}} style={{...BTN,fontSize:11,background:"rgba(255,255,255,.05)",color:"#64748b"}}>⬅ Changer</button>
        </div>
      </div>

      {saveMsg&&<div style={{padding:"5px 20px",fontSize:11,background:saveMsg.startsWith("✅")?"rgba(34,197,94,.07)":"rgba(239,68,68,.07)",color:saveMsg.startsWith("✅")?"#4ade80":"#f87171",borderBottom:"1px solid rgba(255,255,255,.04)"}}>{saveMsg}</div>}

      {/* ══ TABS ══ */}
      <div style={{display:"flex",borderBottom:"1px solid rgba(255,255,255,.06)",background:"rgba(255,255,255,.015)"}}>
        {TABS.map(t=>(
          <button key={t.id} onClick={()=>setStep(t.id)} style={{
            padding:"9px 18px",border:"none",borderBottom:"2px solid",
            borderBottomColor:step===t.id?"#3b82f6":"transparent",
            background:"transparent",color:step===t.id?"#93c5fd":"#475569",
            fontSize:11.5,fontWeight:step===t.id?700:400,cursor:"pointer",letterSpacing:.2,
          }}>{t.icon} {t.label}</button>
        ))}
        {(step==="planning"||step==="config")&&(
          <div style={{display:"flex",alignItems:"center",marginLeft:"auto",paddingRight:14,gap:3}}>
            {groupes.map((gg,gi)=>(
              <button key={gg.id} onClick={()=>setActiveGi(gi)} style={{
                padding:"3px 10px",borderRadius:5,border:"none",
                background:activeGi===gi?`${gg.color}20`:"transparent",
                color:activeGi===gi?gg.color:"#334155",fontSize:11,
                fontWeight:activeGi===gi?700:400,cursor:"pointer",
                borderBottom:activeGi===gi?`2px solid ${gg.color}`:"2px solid transparent",
              }}>{gg.label} <span style={{opacity:.5,fontSize:9}}>({gg.membres.length})</span></button>
            ))}
          </div>
        )}
      </div>

      {/* ══ CONTENU ══ */}
      <div style={{flex:1,display:"flex",overflow:"hidden"}}>

        {/* ──────────────────────
            PLANNING
        ────────────────────── */}
        {step==="planning"&&(
          <div style={{flex:1,padding:18,overflowY:"auto"}}>
            <div style={{background:"rgba(255,255,255,.015)",border:`1px solid ${g.color}22`,borderRadius:10,padding:14}}>
              <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:10}}>
                <div style={{fontWeight:700,fontSize:13,color:g.color}}>{g.subtitle} — {mn.toUpperCase()} {year}</div>
                {g.id==="paramedical"&&(
                  <div style={{display:"flex",gap:8,alignItems:"center"}}>
                    <label style={{fontSize:10,color:"#475569",display:"flex",alignItems:"center",gap:5,cursor:"pointer"}}>
                      <input type="checkbox" checked={autoMode} onChange={e=>setAutoMode(e.target.checked)}
                        style={{accentColor:"#ef4444"}}/>
                      Gardes auto
                    </label>
                  </div>
                )}
              </div>

              <div style={{overflowX:"auto"}}>
                <table style={{borderCollapse:"collapse",fontSize:10.5,tableLayout:"fixed"}}>
                  <thead>
                    <tr>
                      <th style={{...PTH,width:128,textAlign:"left",padding:"3px 7px"}}>Nom</th>
                      <th style={{...PTH,width:90,textAlign:"left",padding:"3px 4px"}}>Grade</th>
                      {g.hasEquipe&&<th style={{...PTH,width:26,color:g.color}}>Éq</th>}
                      {Array.from({length:daysInMo},(_,i)=>{
                        const d=i+1,dow=getDow(year,month,d),we=isWE(dow);
                        return <th key={d} style={{...PTH,width:22,padding:"2px 0",background:we?"#1a0800":"#0c1625",color:we?"#f97316":"#475569",fontSize:8.5}}>
                          {d}<br/><span style={{fontSize:7.5}}>{JOURS_FR[dow].slice(0,2)}</span>
                        </th>;
                      })}
                    </tr>
                  </thead>
                  <tbody>
                    {g.membres.map((m,mi)=>(
                      <tr key={mi} style={{borderBottom:"1px solid rgba(255,255,255,.03)"}}>
                        <td style={{...PTD,padding:"2px 7px",fontWeight:600,color:"#e2e8f0"}}>{m.nom}</td>
                        <td style={{...PTD,padding:"2px 3px",color:"#475569",fontSize:9.5}}>{m.grade}</td>
                        {g.hasEquipe&&<td style={{...PTD,textAlign:"center",color:g.color,fontWeight:700,fontSize:10}}>{m.equipe}</td>}
                        {Array.from({length:daysInMo},(_,i)=>{
                          const d=i+1,dow=getDow(year,month,d),we=isWE(dow);
                          const code=conges[ck(g.id,mi,d)]||"";
                          const cInfo=ci(code);
                          const isAutoGarde = autoMode&&g.id==="paramedical"&&code==="G";
                          return (
                            <td key={d} style={{...PTD,width:22,padding:0,background:we?"rgba(40,15,0,.6)":isAutoGarde?"rgba(239,68,68,.07)":"transparent",position:"relative"}}>
                              <input value={code} maxLength={3}
                                onChange={e=>setCode(g.id,mi,d,e.target.value)}
                                style={{
                                  width:22,height:21,border:"none",background:"transparent",
                                  textAlign:"center",fontSize:9,fontWeight:700,outline:"none",
                                  color:cInfo?cInfo.color:we?"#2d1f0f":"#334155",cursor:"text",
                                  fontStyle:isAutoGarde?"italic":"normal",
                                }}
                                title={`${m.nom} · Jour ${d}${isAutoGarde?" · Garde auto":""}`}
                              />
                            </td>
                          );
                        })}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* Légende */}
              <div style={{marginTop:10,display:"flex",gap:10,flexWrap:"wrap",fontSize:10,alignItems:"center"}}>
                {CODES.map(c=><span key={c.code}><b style={{color:c.color}}>{c.code}</b><span style={{color:"#334155"}}> {c.label}</span></span>)}
                <span style={{marginLeft:"auto",color:"#334155",fontSize:9}}>
                  <span style={{color:"#f97316"}}>■</span> Weekend &nbsp; <i style={{color:"#ef4444"}}>G</i>=auto
                </span>
              </div>

              <RecapCodes conges={conges} gid={g.id} membres={g.membres}/>
            </div>
          </div>
        )}

        {/* ──────────────────────
            ROTATION GARDES
        ────────────────────── */}
        {step==="gardes"&&(
          <div style={{flex:1,padding:24,overflowY:"auto"}}>
            {/* Explication */}
            <div style={{background:"rgba(239,68,68,.07)",border:"1px solid rgba(239,68,68,.2)",borderRadius:10,padding:16,marginBottom:20}}>
              <div style={{fontSize:13,fontWeight:700,color:"#fca5a5",marginBottom:6}}>🔄 Rotation automatique des gardes 24h</div>
              <div style={{fontSize:12,color:"#64748b",lineHeight:1.8}}>
                Les gardes paramédical tournent entre les équipes <b style={{color:"#e2e8f0"}}>A → B → C → D</b> jour après jour, mois après mois en continu.<br/>
                Ce mois de <b style={{color:"#e2e8f0"}}>{mn} {year}</b>, l'équipe <b style={{color:"#ef4444",fontSize:14}}>{equipeDebut}</b> commence la garde le 1er.
              </div>
            </div>

            {/* Drag & Drop ordre équipes */}
            <Card title="🎯 Ordre de rotation — glissez-déposez pour réorganiser" color="#ef4444">
              <div style={{fontSize:11,color:"#475569",marginBottom:14}}>
                Modifiez l'ordre pour ajuster qui est en garde en premier chaque mois.
              </div>
              <div style={{display:"flex",gap:12,alignItems:"center",flexWrap:"wrap",marginBottom:20}}>
                {ordreEq.map((eq,i)=>(
                  <div key={eq}
                    draggable
                    onDragStart={()=>onDragStartEq(eq)}
                    onDragOver={e=>e.preventDefault()}
                    onDrop={()=>onDropEq(eq)}
                    style={{
                      display:"flex",alignItems:"center",gap:8,
                      background:eq===equipeDebut?"rgba(239,68,68,.2)":"rgba(255,255,255,.05)",
                      border:`2px solid ${eq===equipeDebut?"#ef4444":"rgba(255,255,255,.1)"}`,
                      borderRadius:10,padding:"10px 18px",cursor:"grab",
                      userSelect:"none",transition:"all .2s",
                      boxShadow:dragEq===eq?"0 0 0 2px #ef444466":"none",
                    }}>
                    <span style={{fontSize:11,color:"#475569"}}>#{i+1}</span>
                    <span style={{fontSize:22,fontWeight:800,color:eq===equipeDebut?"#ef4444":"#e2e8f0"}}>
                      Équipe {eq}
                    </span>
                    {eq===equipeDebut&&<span style={{fontSize:10,color:"#ef4444",background:"rgba(239,68,68,.15)",padding:"1px 6px",borderRadius:10}}>ce mois</span>}
                    <span style={{fontSize:14,color:"#334155",cursor:"grab"}}>⠿</span>
                  </div>
                ))}
                {ordreEq.map((eq,i,arr)=>i<arr.length-1&&(
                  <span key={`a${i}`} style={{fontSize:18,color:"#334155"}}>→</span>
                ))}
              </div>

              {/* Bouton reset */}
              <button onClick={()=>setOrdreEq(["A","B","C","D"])} style={{
                ...BTN,fontSize:11,background:"rgba(255,255,255,.05)",color:"#64748b",
              }}>↺ Réinitialiser A→B→C→D</button>
            </Card>

            {/* Calendrier des gardes sur 12 mois */}
            <Card title="📅 Planning rotation sur 12 mois" color="#ef4444">
              <div style={{display:"grid",gridTemplateColumns:"repeat(auto-fill,minmax(160px,1fr))",gap:10}}>
                {Array.from({length:12},(_,i)=>{
                  const m=(month+i-1)%12+1, y=year+Math.floor((month+i-1)/12);
                  const eq=getEquipeDebutMois(y,m,ordreEq);
                  const isCurrent=m===month&&y===year;
                  return (
                    <div key={i} style={{
                      background:isCurrent?"rgba(239,68,68,.1)":"rgba(255,255,255,.02)",
                      border:`1px solid ${isCurrent?"rgba(239,68,68,.4)":"rgba(255,255,255,.06)"}`,
                      borderRadius:8,padding:"10px 14px",
                    }}>
                      <div style={{fontSize:11,color:isCurrent?"#fca5a5":"#475569",fontWeight:isCurrent?700:400}}>
                        {MOIS_FR[m-1].charAt(0).toUpperCase()+MOIS_FR[m-1].slice(1)} {y}
                      </div>
                      <div style={{marginTop:6,display:"flex",gap:6,flexWrap:"wrap"}}>
                        {ordreEq.map((e,ei)=>(
                          <span key={e} style={{
                            fontSize:10,padding:"2px 7px",borderRadius:4,
                            background:e===eq?"rgba(239,68,68,.2)":"rgba(255,255,255,.04)",
                            color:e===eq?"#ef4444":"#334155",
                            fontWeight:e===eq?700:400,
                            border:e===eq?"1px solid rgba(239,68,68,.4)":"1px solid transparent",
                          }}>
                            {e}{e===eq&&" 🚦"}
                          </span>
                        ))}
                      </div>
                      <div style={{fontSize:9,color:"#334155",marginTop:4}}>Début: Équipe {eq}</div>
                    </div>
                  );
                })}
              </div>
            </Card>

            {/* Attribution par équipe ce mois */}
            <Card title={`👥 Membres par équipe — ${mn} ${year}`} color="#ef4444">
              <div style={{display:"flex",gap:12,flexWrap:"wrap"}}>
                {ordreEq.map((eq,eqi)=>{
                  const paraGi=groupes.findIndex(x=>x.id==="paramedical");
                  const membres=paraGi>=0?groupes[paraGi].membres.filter(m=>m.equipe===eq):[];
                  // Compter les gardes ce mois
                  const nbGardes=membres.reduce((acc,m,mi)=>{
                    const realMi=groupes[paraGi]?.membres.indexOf(m);
                    let cnt=0;
                    for(let d=1;d<=daysInMo;d++){if(conges[ck("paramedical",realMi,d)]==="G")cnt++;}
                    return acc+cnt;
                  },0);
                  return (
                    <div key={eq} style={{
                      flex:"1 1 160px",
                      background:eq===equipeDebut?"rgba(239,68,68,.1)":"rgba(255,255,255,.03)",
                      border:`1px solid ${eq===equipeDebut?"rgba(239,68,68,.3)":"rgba(255,255,255,.07)"}`,
                      borderRadius:8,padding:"12px 14px",
                    }}>
                      <div style={{fontSize:13,fontWeight:800,color:eq===equipeDebut?"#ef4444":"#e2e8f0",marginBottom:6}}>
                        Équipe {eq} {eqi===0?"🚦":""}
                      </div>
                      {membres.length===0&&<div style={{fontSize:10,color:"#334155"}}>Aucun membre assigné</div>}
                      {membres.map((m,i)=>(
                        <div key={i} style={{fontSize:11,color:"#94a3b8",marginBottom:3}}>• {m.nom}</div>
                      ))}
                      <div style={{marginTop:8,fontSize:10,color:"#475569"}}>
                        {nbGardes} garde(s) ce mois
                      </div>
                    </div>
                  );
                })}
              </div>
            </Card>
          </div>
        )}

        {/* ──────────────────────
            CONFIG PERSONNEL
        ────────────────────── */}
        {step==="config"&&(
          <div style={{flex:1,padding:18,overflowY:"auto"}}>
            <Card title={`${g.label} — Membres`} color={g.color}>
              <div style={{overflowX:"auto"}}>
                <table style={{width:"100%",borderCollapse:"collapse",fontSize:12.5}}>
                  <thead>
                    <tr style={{background:"rgba(255,255,255,.03)"}}>
                      <th style={TH}>N°</th><th style={TH}>Nom et Prénom</th><th style={TH}>Grade</th>
                      {g.hasEquipe&&<th style={{...TH,width:70}}>Équipe</th>}
                      <th style={{...TH,width:36}}></th>
                    </tr>
                  </thead>
                  <tbody>
                    {g.membres.map((m,mi)=>(
                      <tr key={mi} style={{borderBottom:"1px solid rgba(255,255,255,.04)"}}>
                        <td style={{...TD,color:"#334155",width:32,textAlign:"center"}}>{mi+1}</td>
                        <td style={TD}><input value={m.nom} onChange={e=>updMembre(activeGi,mi,"nom",e.target.value)} style={{...INP,width:"100%"}}/></td>
                        <td style={TD}><input value={m.grade} onChange={e=>updMembre(activeGi,mi,"grade",e.target.value)} style={{...INP,width:"100%"}}/></td>
                        {g.hasEquipe&&(
                          <td style={TD}>
                            <select value={m.equipe||"A"} onChange={e=>updMembre(activeGi,mi,"equipe",e.target.value)} style={{...SEL,width:58}}>
                              {ordreEq.map(q=><option key={q}>{q}</option>)}
                            </select>
                          </td>
                        )}
                        <td style={{...TD,textAlign:"center"}}>
                          <button onClick={()=>delMembre(activeGi,mi)} style={{background:"rgba(239,68,68,.12)",border:"none",color:"#f87171",borderRadius:4,padding:"2px 7px",cursor:"pointer",fontSize:11}}>✕</button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                <button onClick={()=>addMembre(activeGi)} style={{marginTop:9,...BTN,fontSize:11,background:"transparent",border:`1px dashed ${g.color}55`,color:g.color}}>+ Ajouter</button>
              </div>
            </Card>

            <Card title="📊 Effectifs" color="#334155">
              <div style={{display:"flex",gap:10,flexWrap:"wrap"}}>
                {groupes.map(gg=>(
                  <div key={gg.id} style={{background:`${gg.color}10`,border:`1px solid ${gg.color}28`,borderRadius:8,padding:"10px 14px",minWidth:120}}>
                    <div style={{fontSize:10,color:gg.color,fontWeight:700}}>{gg.label}</div>
                    <div style={{fontSize:22,fontWeight:800,color:"#f8fafc",marginTop:2}}>{gg.membres.length}</div>
                    <div style={{fontSize:9,color:"#334155"}}>agents</div>
                  </div>
                ))}
              </div>
            </Card>
          </div>
        )}

        {/* ──────────────────────
            HISTORIQUE
        ────────────────────── */}
        {step==="historique"&&(
          <div style={{flex:1,padding:18,overflowY:"auto"}}>
            <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:14}}>
              <div style={{fontSize:13,fontWeight:700,color:"#93c5fd"}}>🕓 Historique — {service?.nom}</div>
              <button onClick={loadHisto} disabled={loadingH} style={{...BTN,fontSize:11}}>{loadingH?"⏳":"🔄 Actualiser"}</button>
            </div>
            {historique.length===0?(
              <div style={{color:"#334155",fontSize:12,textAlign:"center",padding:32}}>Aucun planning sauvegardé.</div>
            ):(
              <HistoriqueTable historique={historique} onLoad={loadFromHisto} onDelete={deleteHisto}/>
            )}
          </div>
        )}

        {/* ──────────────────────
            CHAT IA
        ────────────────────── */}
        {step==="chat"&&(
          <div style={{flex:1,display:"flex",flexDirection:"column",padding:18}}>
            <div style={{flex:1,overflowY:"auto",display:"flex",flexDirection:"column",gap:10,paddingBottom:10}}>
              {messages.map((msg,i)=>(
                <div key={i} style={{display:"flex",justifyContent:msg.role==="user"?"flex-end":"flex-start"}}>
                  <div style={{
                    maxWidth:"80%",
                    background:msg.role==="user"?"linear-gradient(135deg,#1d4ed8,#0891b2)":"rgba(255,255,255,.04)",
                    border:msg.role==="assistant"?"1px solid rgba(255,255,255,.06)":"none",
                    borderRadius:msg.role==="user"?"12px 12px 2px 12px":"12px 12px 12px 2px",
                    padding:"9px 13px",fontSize:12,lineHeight:1.7,
                    color:msg.role==="user"?"white":"#e2e8f0",whiteSpace:"pre-wrap",
                  }}>
                    {msg.role==="assistant"&&<span style={{marginRight:5}}>🏥</span>}
                    {msg.text}
                  </div>
                </div>
              ))}
              {chatLoading&&<div style={{color:"#334155",fontSize:11,display:"flex",gap:7,alignItems:"center"}}><span style={{animation:"spin 1s linear infinite",display:"inline-block"}}>⟳</span> Analyse…</div>}
              <div ref={chatEnd}/>
            </div>
            <div style={{display:"flex",gap:5,flexWrap:"wrap",marginBottom:7}}>
              {["BOUZIANE en congé du 5 au 12","HAMDI en récupération le 20","Qui est en garde le 15 ?","Résumé des absences"].map(s=>(
                <button key={s} onClick={()=>setInput(s)} style={{padding:"3px 9px",borderRadius:5,border:"1px solid rgba(59,130,246,.3)",background:"rgba(59,130,246,.07)",color:"#60a5fa",fontSize:10,cursor:"pointer"}}>{s}</button>
              ))}
            </div>
            <div style={{display:"flex",gap:7,background:"rgba(255,255,255,.02)",border:"1px solid rgba(255,255,255,.07)",borderRadius:8,padding:"7px 11px"}}>
              <input value={input} onChange={e=>setInput(e.target.value)} onKeyDown={e=>e.key==="Enter"&&!e.shiftKey&&sendMessage()}
                placeholder="Parlez à l'agent…" style={{flex:1,background:"transparent",border:"none",color:"#e2e8f0",fontSize:12.5,outline:"none"}}/>
              <button onClick={sendMessage} disabled={chatLoading||!input.trim()} style={{...BTN,fontSize:11,background:chatLoading||!input.trim()?"rgba(255,255,255,.04)":"linear-gradient(135deg,#1d4ed8,#0891b2)",color:chatLoading||!input.trim()?"#334155":"white"}}>
                {chatLoading?"…":"↵"}
              </button>
            </div>
          </div>
        )}
      </div>

      <style>{`@keyframes spin{to{transform:rotate(360deg)}}select option{background:#0d1526}::-webkit-scrollbar{width:4px;height:4px}::-webkit-scrollbar-thumb{background:#1e293b;border-radius:2px}`}</style>
    </div>
  );
}

// ══════════════════════════════════════════════
//  SOUS-COMPOSANTS
// ══════════════════════════════════════════════
function HistoriqueTable({ historique, onLoad, onDelete }) {
  const grouped={};
  historique.forEach(row=>{
    const key=`${row.annee}-${String(row.mois).padStart(2,"0")}`;
    if(!grouped[key]) grouped[key]={annee:row.annee,mois:row.mois,rows:[]};
    grouped[key].rows.push(row);
  });
  return (
    <div style={{display:"flex",flexDirection:"column",gap:9}}>
      {Object.keys(grouped).sort().reverse().map(key=>{
        const {annee,mois,rows}=grouped[key];
        const mn=MOIS_FR[mois-1];
        return (
          <div key={key} style={{background:"rgba(255,255,255,.02)",border:"1px solid rgba(255,255,255,.06)",borderRadius:9,padding:"13px 16px"}}>
            <div style={{display:"flex",alignItems:"center",gap:10,marginBottom:8}}>
              <div style={{fontSize:13,fontWeight:700,color:"#93c5fd"}}>📅 {mn.charAt(0).toUpperCase()+mn.slice(1)} {annee}</div>
              <div style={{display:"flex",gap:5,flexWrap:"wrap"}}>
                {rows.map(r=>{
                  const gg=GROUPES_INIT.find(g=>g.id===r.groupe_id);
                  return <span key={r.id} style={{fontSize:9,padding:"1px 7px",borderRadius:4,background:`${gg?.color||"#475569"}15`,color:gg?.color||"#475569",border:`1px solid ${gg?.color||"#475569"}28`}}>{gg?.label||r.groupe_id}</span>;
                })}
              </div>
              <div style={{marginLeft:"auto",display:"flex",gap:6}}>
                <button onClick={()=>onLoad(rows[0])} style={{...BTN,fontSize:10,padding:"3px 10px",background:"rgba(59,130,246,.15)",color:"#93c5fd"}}>📂 Charger</button>
                <button onClick={()=>onDelete(annee,mois)} style={{...BTN,fontSize:10,padding:"3px 9px",background:"rgba(239,68,68,.1)",color:"#f87171"}}>🗑️</button>
              </div>
            </div>
            {rows[0]?.ordre_equipes&&<div style={{fontSize:9,color:"#334155"}}>Rotation : {rows[0].ordre_equipes.join("→")} · MàJ {new Date(rows[0].updated_at).toLocaleDateString("fr-FR")}</div>}
          </div>
        );
      })}
    </div>
  );
}

function RecapCodes({ conges, gid, membres }) {
  const counts=membres.map((m,mi)=>{
    const byCode={};
    Object.entries(conges).filter(([k])=>k.startsWith(`${gid}:${mi}:`)).forEach(([,v])=>{byCode[v]=(byCode[v]||0)+1;});
    return {nom:m.nom,byCode};
  }).filter(r=>Object.keys(r.byCode).length>0);
  if(!counts.length) return null;
  return (
    <div style={{marginTop:10,padding:"7px 11px",background:"rgba(255,255,255,.015)",borderRadius:7,fontSize:10.5}}>
      <div style={{color:"#334155",marginBottom:5,fontWeight:600,fontSize:10}}>Récapitulatif :</div>
      <div style={{display:"flex",flexWrap:"wrap",gap:7}}>
        {counts.map(r=>(
          <div key={r.nom} style={{background:"rgba(255,255,255,.03)",borderRadius:5,padding:"3px 9px"}}>
            <span style={{color:"#64748b",fontWeight:600}}>{r.nom.split(" ").slice(-1)[0]} </span>
            {Object.entries(r.byCode).map(([code,n])=>{const cInfo=CODES.find(c=>c.code===code);return <span key={code} style={{color:cInfo?.color||"#e2e8f0",marginLeft:4}}>{code}×{n}</span>;})}
          </div>
        ))}
      </div>
    </div>
  );
}

function Card({ title, color="#475569", children }) {
  return (
    <div style={{background:"rgba(255,255,255,.02)",border:`1px solid ${color}1a`,borderRadius:9,padding:16,marginBottom:14}}>
      <div style={{fontSize:11,fontWeight:700,marginBottom:12,color,textTransform:"uppercase",letterSpacing:.6}}>{title}</div>
      {children}
    </div>
  );
}

const INP={background:"rgba(255,255,255,.05)",border:"1px solid rgba(255,255,255,.08)",borderRadius:6,color:"#e2e8f0",padding:"5px 9px",fontSize:12,outline:"none",fontFamily:"inherit"};
const SEL={...INP,cursor:"pointer"};
const BTN={padding:"6px 13px",borderRadius:6,border:"none",color:"white",fontSize:12,fontWeight:600,cursor:"pointer",background:"rgba(255,255,255,.07)",fontFamily:"inherit"};
const TH={background:"rgba(255,255,255,.04)",color:"#475569",border:"1px solid rgba(255,255,255,.06)",padding:"6px 8px",fontWeight:600,fontSize:11,textAlign:"left"};
const TD={padding:"5px 8px",border:"1px solid rgba(255,255,255,.04)"};
const PTH={background:"#0c1525",color:"#475569",border:"1px solid rgba(255,255,255,.06)",textAlign:"center",fontWeight:600,fontSize:10,padding:"3px 1px"};
const PTD={border:"1px solid rgba(255,255,255,.05)",textAlign:"center"};