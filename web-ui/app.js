const state = { port: null, reader: null, frames: [], reading: false };
const $ = (id) => document.getElementById(id);

function setStatus(label, connected = false) {
  $("connectionPill").innerHTML = `<span></span><strong>${label}</strong>`;
  $("connectionPill").classList.toggle("connected", connected);
  const transportState = $("transportState"); if (transportState) transportState.textContent = label;
}

function addLine(text, kind = "rx") {
  $("terminal").querySelector(".terminal-empty")?.remove();
  const line = document.createElement("div");
  line.className = "terminal-line";
  line.textContent = `${new Date().toISOString()}  ${kind.toUpperCase()}  ${text}`;
  $("terminal").append(line);
  $("terminal").scrollTop = $("terminal").scrollHeight;
}

function bytesToHex(bytes) { return [...bytes].map((b) => b.toString(16).padStart(2, "0")).join(" "); }

async function readLoop() {
  state.reading = true;
  while (state.port?.readable && state.reading) {
    state.reader = state.port.readable.getReader();
    try {
      while (state.reading) {
        const { value, done } = await state.reader.read();
        if (done) break;
        if (value?.length) {
          state.frames.push({ timestamp: new Date().toISOString(), direction: "rx", bytes: [...value] });
          $("frameCount").textContent = state.frames.length;
          $("downloadButton").disabled = false;
          addLine(bytesToHex(value));
        }
      }
    } catch (error) { addLine(`read error: ${error.message}`, "system"); }
    finally { state.reader.releaseLock(); state.reader = null; }
  }
}

async function connect() {
  if (!("serial" in navigator)) {
    $("browserNotice") && ($("browserNotice").textContent = "Web Serial is unavailable in this browser. Use Chrome or Edge on macOS, or the native Swift transport.");
    return;
  }
  try {
    state.port = await navigator.serial.requestPort();
    // Freedom/FCSS link is 9600 bps, 7 data bits, even parity, 1 stop bit.
    // Evidence: documented (hiro0719jp FCSS article, device-manager settings for FCSS).
    // Opening at 8N1 garbles every byte, so 7E1 is fixed here rather than user-selectable.
    await state.port.open({ baudRate: Number($("baudRate").value), dataBits: 7, stopBits: 1, parity: "even" });
    setStatus("Connected", true);
    $("connectButton").disabled = true;
    $("disconnectButton").disabled = false;
    $("monitorSubtitle") && ($("monitorSubtitle").textContent = `Read-only capture at ${$("baudRate").value} baud, 7E1`);
    addLine("serial port opened", "system");
    readLoop();
  } catch (error) {
    setStatus("Offline");
    $("browserNotice") && ($("browserNotice").textContent = error.name === "NotFoundError" ? "No port selected." : `Connection failed: ${error.message}`);
  }
}

async function disconnect() {
  state.reading = false;
  if (state.reader) await state.reader.cancel().catch(() => {});
  if (state.port) await state.port.close().catch(() => {});
  state.port = null;
  setStatus("Offline");
  $("connectButton").disabled = false;
  $("disconnectButton").disabled = true;
  $("monitorSubtitle") && ($("monitorSubtitle").textContent = "Waiting for a local serial connection");
}

$("connectButton").addEventListener("click", connect);
$("disconnectButton").addEventListener("click", disconnect);
$("clearButton").addEventListener("click", () => { $("terminal").innerHTML = '<div class="terminal-empty">Capture cleared.</div>'; });
$("downloadButton").addEventListener("click", () => {
  const blob = new Blob([JSON.stringify(state.frames, null, 2)], { type: "application/json" });
  const link = document.createElement("a"); link.href = URL.createObjectURL(blob); link.download = "freedom-capture.json"; link.click(); URL.revokeObjectURL(link.href);
});

if (!("serial" in navigator) && $("browserNotice")) $("browserNotice").textContent = "Use Chrome or Edge on macOS for Web Serial. The app will never write to the ECU in this build.";
navigator.serial?.addEventListener("disconnect", disconnect);

function addExperimentStyles() {
  if (!document.querySelector('link[href="experiment.css"]')) {
    const link = document.createElement("link"); link.rel = "stylesheet"; link.href = "experiment.css"; document.head.append(link);
  }
}

function createExperimentView() {
  if (document.getElementById("view-experiment")) return;
  addExperimentStyles();
  const view = document.createElement("section");
  view.className = "view"; view.id = "view-experiment";
  view.innerHTML = `<div class="experiment-grid"><div><div class="panel"><div class="panel-head"><div><h2>Load three supervised runs</h2><p>Files stay in this browser tab. No ECU writes or cloud upload.</p></div><span class="tag safe">LOCAL ANALYSIS</span></div><div class="run-inputs"><label><span>Baseline run</span><input id="baselineFile" type="file" accept=".json,.jsonl,.txt"><small>Last accepted reference</small></label><label><span>Candidate run</span><input id="candidateFile" type="file" accept=".json,.jsonl,.txt"><small>After one small change</small></label><label><span>Repeat candidate</span><input id="repeatFile" type="file" accept=".json,.jsonl,.txt"><small>Required for acceptance</small></label></div><div class="experiment-controls"><label>Target lambda<input id="targetLambda" type="number" value="0.9" min="0.5" max="1.5" step="0.01"></label><button class="button primary" id="analyzeRunsButton">Analyze runs</button><span class="analysis-note" id="analysisNote">Waiting for three captures</span></div></div><div class="panel"><div class="panel-head"><div><h2>Run comparison</h2><p id="experimentSummary">Import baseline, candidate, and repeat candidate captures.</p></div><span class="tag" id="decisionTag">UNASSESSED</span></div><div class="experiment-chart-wrap"><canvas id="compareChart"></canvas><div class="chart-empty" id="compareChartEmpty">Lambda error and run stability appear here.</div></div><div class="compare-metrics" id="compareMetrics"></div></div></div><div><div class="panel concern-panel"><div class="panel-head"><h2>Concerns and checks</h2><span class="tag" id="concernTag">PENDING</span></div><div class="concern-list" id="concernList"><div class="empty-inline">Run the analysis to identify warnings and stop conditions.</div></div></div><div class="panel approval-panel"><div class="panel-head"><div><h2>Supervised approval</h2><p>Approval creates a review record only. ECU writes stay locked.</p></div><span class="tag safe">WRITE LOCKED</span></div><label class="check-row"><input type="checkbox" class="approval-check"> I reviewed the changed experiment and expected effect.</label><label class="check-row"><input type="checkbox" class="approval-check"> I verified the baseline backup and rollback path.</label><label class="check-row"><input type="checkbox" class="approval-check"> I understand and accept the displayed warnings.</label><label class="check-row"><input type="checkbox" class="approval-check"> I will supervise the controlled test and stop on a critical alert.</label><div class="approval-actions"><button class="button primary" id="approveExperimentButton" disabled>Approve supervised experiment</button><button class="button" id="rollbackExperimentButton" disabled>Mark rollback required</button></div><div class="approval-result" id="approvalResult">No approval decision yet.</div></div></div></div>`;
  document.querySelector(".content")?.append(view);
  document.querySelector('[data-view="experiment"]')?.addEventListener("click", () => showExperimentView());
  $("analyzeRunsButton").addEventListener("click", analyzeExperiment);
  $("rollbackExperimentButton").addEventListener("click", () => { $("approvalResult").textContent = "Rollback required. Preserve all three captures and investigate before another experiment."; });
  document.querySelectorAll(".approval-check").forEach((input) => input.addEventListener("change", updateApprovalButton));
}

function showExperimentView() {
  document.querySelectorAll(".view").forEach((node) => node.classList.toggle("active", node.id === "view-experiment"));
  document.querySelectorAll(".tree-item").forEach((node) => node.classList.toggle("active", node.dataset.view === "experiment"));
  $("pageTitle").textContent = "Review experiment"; $("pageSubtitle").textContent = "Compare runs, understand concerns, and approve only a supervised next step.";
}

async function readTelemetryFile(input) {
  const text = await input.files[0].text();
  try { const parsed = JSON.parse(text); return Array.isArray(parsed) ? parsed : (parsed.frames || []); }
  catch { return text.split(/\r?\n/).filter(Boolean).map((line) => JSON.parse(line)); }
}

function frameData(frame) { return frame?.decoded || frame || {}; }
function values(frames, key) { return frames.map(frameData).map((row) => Number(row[key])).filter(Number.isFinite); }
function mean(list) { return list.length ? list.reduce((sum, value) => sum + value, 0) / list.length : null; }
function frameStats(frames, target) {
  const lambda = values(frames, "lambda"); const errors = lambda.map((value) => Math.abs(value - target));
  const sequences = frames.map((frame) => frame.sequence).filter(Number.isInteger); const dropped = sequences.length > 1 ? Math.max(0, Math.max(...sequences) - Math.min(...sequences) + 1 - new Set(sequences).size) : 0;
  return { frames: frames.length, lambdaError: mean(errors), lambda, telemetry: dropped === 0, dropped, knock: frames.filter((frame) => frameData(frame).knock === true).length, rpm: values(frames, "rpm"), coolant: values(frames, "coolant_c") };
}
function drawExperimentChart(results) {
  const canvas = $("compareChart"), empty = $("compareChartEmpty"); if (!canvas) return; const context = canvas.getContext("2d"); const ratio = devicePixelRatio || 1; const box = canvas.getBoundingClientRect(); canvas.width = box.width * ratio; canvas.height = box.height * ratio; context.setTransform(ratio, 0, 0, ratio, 0, 0); const width = box.width, height = box.height; context.clearRect(0, 0, width, height); empty.style.display = "none"; context.strokeStyle = "rgba(255,255,255,.09)"; for (let y = 30; y < height; y += 48) { context.beginPath(); context.moveTo(0, y); context.lineTo(width, y); context.stroke(); }
  [[results.baseline, "#f1c75b"], [results.candidate, "#e47b84"], [results.repeat, "#74d29a"]].forEach(([run, color]) => { context.beginPath(); context.strokeStyle = color; context.lineWidth = 2; run.lambda.forEach((value, index) => { const x = index / Math.max(1, run.lambda.length - 1) * width; const y = height - 20 - Math.max(0, Math.min(1, Math.abs(value - results.target) / .2)) * (height - 40); index ? context.lineTo(x, y) : context.moveTo(x, y); }); context.stroke(); });
}
function concern(severity, title, detail) { return `<div class="concern ${severity}"><b>${severity}</b><div>${title}</div><p>${detail}</p></div>`; }
function updateApprovalButton() { const checks = [...document.querySelectorAll(".approval-check")]; $("approveExperimentButton").disabled = !checks.length || !checks.every((input) => input.checked) || window.experimentDecision !== "accept"; }
function analyzeExperiment() {
  const inputs = [$("baselineFile"), $("candidateFile"), $("repeatFile")]; if (inputs.some((input) => !input?.files.length)) { $("analysisNote").textContent = "Select all three captures first"; return; }
  Promise.all(inputs.map(readTelemetryFile)).then(([baselineFrames, candidateFrames, repeatFrames]) => { const target = Number($("targetLambda").value); const baseline = frameStats(baselineFrames, target), candidate = frameStats(candidateFrames, target), repeat = frameStats(repeatFrames, target); const improvement = baseline.lambdaError > 0 ? (baseline.lambdaError - candidate.lambdaError) / baseline.lambdaError : 0; const repeatDifference = Math.abs((mean(candidate.lambda) || 0) - (mean(repeat.lambda) || 0)); const repeatable = repeatDifference <= .03 && repeat.telemetry; const critical = candidate.knock > 0 || !candidate.telemetry || !repeat.telemetry; const accepted = !critical && improvement > 0 && repeatable; window.experimentDecision = accepted ? "accept" : critical ? "abort" : "review"; const result = { baseline, candidate, repeat, target, improvement, repeatable }; window.lastExperiment = result; drawExperimentChart(result); $("decisionTag").textContent = accepted ? "ACCEPT" : critical ? "ABORT" : "REVIEW"; $("concernTag").textContent = critical ? "STOP" : accepted ? "CLEAR" : "WARNINGS"; $("experimentSummary").textContent = accepted ? "Repeatable improvement. A smaller next step may be approved." : critical ? "Critical data or safety issue. Do not continue testing." : "Improvement is not yet proven. Review warnings and repeat the experiment."; $("analysisNote").textContent = `${candidate.frames + repeat.frames} candidate frames analysed locally`; $("compareMetrics").innerHTML = [["Improvement", `${(improvement * 100).toFixed(1)}%`], ["Repeatability", repeatable ? "PASS" : "FAIL"], ["Telemetry", candidate.telemetry && repeat.telemetry ? "COMPLETE" : "INCOMPLETE"], ["Knock events", String(candidate.knock + repeat.knock)]].map(([label, value]) => `<div><small>${label}</small><strong>${value}</strong></div>`).join(""); const concerns = []; if (critical) concerns.push(concern("critical", "Stop condition detected", candidate.knock ? "Knock event detected in the candidate run." : "Telemetry is incomplete or out of order.")); if (!repeatable) concerns.push(concern("warning", "Repeatability not proven", `Candidate and repeat lambda means differ by ${repeatDifference.toFixed(3)}. Repeat under matching conditions.`)); if (candidate.coolant.length && Math.max(...candidate.coolant) > 100) concerns.push(concern("critical", "Coolant limit exceeded", "Check cooling, load, mixture, timing, and sensor validity.")); $("concernList").innerHTML = concerns.length ? concerns.join("") : concern("warning", "No automatic fault found", "Review the complete log and mechanical measurements before approving."), $("rollbackExperimentButton").disabled = false; updateApprovalButton(); }).catch((error) => { $("analysisNote").textContent = `Could not parse capture: ${error.message}`; });
}

createExperimentView();

const chart = document.getElementById("runChart");
const chartEmpty = document.getElementById("chartEmpty");
const chartContext = chart?.getContext("2d");

function resizeChart() {
  if (!chart || !chartContext) return;
  const ratio = window.devicePixelRatio || 1;
  const box = chart.getBoundingClientRect();
  chart.width = Math.max(1, box.width * ratio);
  chart.height = Math.max(1, box.height * ratio);
  chartContext.setTransform(ratio, 0, 0, ratio, 0, 0);
}

function drawRun(run) {
  if (!chartContext || !chart) return;
  resizeChart();
  chartEmpty.style.display = "none";
  const width = chart.clientWidth;
  const height = chart.clientHeight;
  chartContext.clearRect(0, 0, width, height);
  chartContext.strokeStyle = "rgba(255,255,255,.09)";
  chartContext.lineWidth = 1;
  for (let y = 24; y < height; y += 48) { chartContext.beginPath(); chartContext.moveTo(0, y); chartContext.lineTo(width, y); chartContext.stroke(); }
  const traces = [
    ["rpm", "#f1c75b", (p) => p.rpm / 9000],
    ["afr", "#e47b84", (p) => (p.afr - 10) / 8],
    ["load", "#6bc2e6", (p) => p.load / 100],
    ["coolant", "#74d29a", (p) => (p.coolant - 60) / 40]
  ];
  for (const [, color, value] of traces) {
    chartContext.beginPath(); chartContext.strokeStyle = color; chartContext.lineWidth = 2;
    run.forEach((point, index) => {
      const x = (index / (run.length - 1)) * width;
      const y = height - 18 - Math.max(0, Math.min(1, value(point))) * (height - 36);
      index ? chartContext.lineTo(x, y) : chartContext.moveTo(x, y);
    }); chartContext.stroke();
  }
}

function demoRun() {
  const run = Array.from({ length: 120 }, (_, i) => {
    const phase = i / 119;
    return { rpm: 1100 + phase * 6900, afr: 14.5 - phase * 1.6 + Math.sin(i / 8) * .12, load: 18 + phase * 78, coolant: 76 + phase * 7 };
  });
  drawRun(run);
  document.getElementById("runSubtitle").textContent = "Demo run · illustrative only · not ECU data";
  document.getElementById("rpmValue").textContent = "8,000";
  document.getElementById("afrValue").textContent = "12.9";
  document.getElementById("loadValue").textContent = "96%";
  document.getElementById("coolantValue").textContent = "83°C";
  document.getElementById("ignitionValue").textContent = "—";
  document.getElementById("runtimeState").textContent = "Demo data";
}

document.getElementById("demoRunButton")?.addEventListener("click", demoRun);
document.getElementById("clearGraphButton")?.addEventListener("click", () => {
  chartContext?.clearRect(0, 0, chart.clientWidth, chart.clientHeight);
  chartEmpty.style.display = "grid";
  document.getElementById("runSubtitle").textContent = "No run loaded. Use demo data to preview the review tools.";
});
for (let i = 0; i < 50; i++) document.getElementById("mapGrid")?.append(document.createElement("span"));
window.addEventListener("resize", () => { if (chartEmpty?.style.display === "none") demoRun(); });

const viewMeta = {
  live: ["Live dashboard", "Connect to view live runtime values and capture a test run."],
  maps: ["Map editor", "Review decoded fuel, ignition, and throttle tables without writing to the ECU."],
  logs: ["Run logs", "Replay and compare captured test sessions."],
  compare: ["Compare baseline", "Find changed cells between a known baseline and a later backup."],
  setup: ["Connection & safety", "Transport settings and write protection."]
};
document.querySelectorAll(".tree-item").forEach((item) => item.addEventListener("click", () => {
  const view = item.dataset.view;
  document.querySelectorAll(".tree-item").forEach((node) => node.classList.toggle("active", node === item));
  document.querySelectorAll(".view").forEach((node) => node.classList.toggle("active", node.id === `view-${view}`));
  const [title, subtitle] = viewMeta[view] || viewMeta.live;
  document.getElementById("pageTitle").textContent = title;
  document.getElementById("pageSubtitle").textContent = subtitle;
}));

const fuelTable = document.getElementById("fuelTable");
if (fuelTable) {
  for (let row = 0; row < 5; row++) for (let col = 0; col < 10; col++) {
    const cell = document.createElement("span");
    cell.textContent = "—";
    fuelTable.append(cell);
  }
}

const profileFields = ["profileChassis", "profileEngine", "profileLoad", "profileInjection", "profileIgnition", "profileVVT"];
function updateProfileSummary() {
  const values = profileFields.map((id) => document.getElementById(id)?.selectedOptions[0]?.textContent || "");
  const mods = [...document.querySelectorAll(".modifications input:checked")].map((input) => input.value);
  const [chassis, engine, load, injection, ignition, vvt] = values;
  document.getElementById("profileSummary").innerHTML = `<strong>${chassis.split(" ")[0]} · ${engine}</strong><span>${injection} · ${ignition} · ${load} · ${vvt}${mods.length ? ` · ${mods.join(", ")}` : ""}</span>`;
}
profileFields.forEach((id) => document.getElementById(id)?.addEventListener("change", updateProfileSummary));
document.querySelectorAll(".modifications input").forEach((input) => input.addEventListener("change", updateProfileSummary));
document.getElementById("saveProfileButton")?.addEventListener("click", () => {
  const profile = Object.fromEntries(profileFields.map((id) => [id, document.getElementById(id).value]));
  profile.modifications = [...document.querySelectorAll(".modifications input:checked")].map((input) => input.value);
  localStorage.setItem("freedom-engine-profile", JSON.stringify(profile));
  document.getElementById("profileSummary").classList.add("saved");
});
