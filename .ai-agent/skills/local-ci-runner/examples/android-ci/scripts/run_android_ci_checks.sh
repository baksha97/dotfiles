#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Run Android monorepo CI-equivalent checks locally.

Usage:
  run_android_ci_checks.sh [options]

Options:
  --repo-root <path>    Monorepo root containing .github/workflows and Android/
  --base-ref <ref>      Base ref used for change detection (default: origin/main)
  --full                Run all Android Integrity check groups
  --include-milb        Force MiLB fastlane PR check
  --skip-milb           Skip MiLB fastlane PR check
  --milb-only           Run only MiLB fastlane PR check
  --skip-spotless       Skip spotless check/apply
  --spotless-apply      Run spotlessApply instead of spotlessCheck
  --parallel            Run selected check groups in parallel and report each status independently
  --serial              Force sequential mode (default)
  --dashboard           Run in parallel with a live browser dashboard (implies --parallel)
  --dry-run             Print commands without executing
  --help                Show this help
EOF
}

log() {
  printf '[android-ci] %s\n' "$*"
}

run_in_dir() {
  local dir="$1"
  shift
  log "($dir) $*"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    return 0
  fi
  (
    cd "$dir"
    "$@"
  )
}

bool_word() {
  if [[ "$1" -eq 1 ]]; then
    printf 'true'
  else
    printf 'false'
  fi
}

is_shared_trigger_path() {
  local file="$1"
  [[ "$file" == ".github/workflows/Android-Integrity.yml" ]] ||
  [[ "$file" == ".github/workflows/pr-android.yml" ]] ||
  [[ "$file" == ".github/actions/monorepo-android-setup/action.yml" ]]
}

is_android_library_path() {
  local file="$1"
  case "$file" in
    Android/Bullpen/*|Android/DesignTokens/*|Android/FieldPass/*|Android/MAASDK/*|Android/MLBAndroidPlatform/*|Android/MLBTVWatch/*|Android/MLBUIComponents/*|Android/MLBUIDataModels/*|Android/Onboarding/*|Android/Shared/*|Android/SurfaceBuilder/*|Android/build-logic/*|Android/gradle/*)
      return 0
      ;;
  esac

  # Matches top-level files in Android/ such as build.gradle.kts, settings.gradle.kts, gradle.properties.
  if [[ "$file" == Android/* && "$file" != Android/*/* ]]; then
    return 0
  fi

  return 1
}

is_xplat_library_path() {
  local file="$1"
  case "$file" in
    xplat/MLBObservabilityKit/jvm/*|xplat/MLBObservabilityKit/android/*|xplat/MLBObservabilityKit/shared/*|xplat/MLBAuthKit/*|xplat/MLBDeepLinkSchema/*|xplat/Gradle/gradle/libs.versions.toml)
      return 0
      ;;
  esac
  return 1
}

is_milb_trigger_path() {
  local file="$1"
  [[ "$file" == Android/MiLB-App/* ]] ||
  [[ "$file" == MiLB/milb-midfield-kmp/* ]] ||
  [[ "$file" == .github/workflows/Android-MiLB-Integrity.yml ]]
}

set_status() {
  local check="$1"
  local status="$2"
  case "$check" in
    spotless) status_spotless="$status" ;;
    xplat) status_xplat="$status" ;;
    libraries) status_libraries="$status" ;;
    mobile) status_mobile="$status" ;;
    tv) status_tv="$status" ;;
    ui) status_ui="$status" ;;
    milb) status_milb="$status" ;;
    *)
      echo "Unknown check for status: $check" >&2
      exit 1
      ;;
  esac
}

set_reason() {
  local check="$1"
  local reason="$2"
  case "$check" in
    spotless) reason_spotless="$reason" ;;
    xplat) reason_xplat="$reason" ;;
    libraries) reason_libraries="$reason" ;;
    mobile) reason_mobile="$reason" ;;
    tv) reason_tv="$reason" ;;
    ui) reason_ui="$reason" ;;
    milb) reason_milb="$reason" ;;
    *)
      echo "Unknown check for reason: $check" >&2
      exit 1
      ;;
  esac
}

get_reason() {
  local check="$1"
  case "$check" in
    spotless) printf '%s' "$reason_spotless" ;;
    xplat) printf '%s' "$reason_xplat" ;;
    libraries) printf '%s' "$reason_libraries" ;;
    mobile) printf '%s' "$reason_mobile" ;;
    tv) printf '%s' "$reason_tv" ;;
    ui) printf '%s' "$reason_ui" ;;
    milb) printf '%s' "$reason_milb" ;;
    *)
      echo "Unknown check for reason: $check" >&2
      exit 1
      ;;
  esac
}

get_status() {
  local check="$1"
  case "$check" in
    spotless) printf '%s' "$status_spotless" ;;
    xplat) printf '%s' "$status_xplat" ;;
    libraries) printf '%s' "$status_libraries" ;;
    mobile) printf '%s' "$status_mobile" ;;
    tv) printf '%s' "$status_tv" ;;
    ui) printf '%s' "$status_ui" ;;
    milb) printf '%s' "$status_milb" ;;
    *)
      echo "Unknown check for status: $check" >&2
      exit 1
      ;;
  esac
}

run_check_spotless() {
  if [[ "$SPOTLESS_APPLY" -eq 1 ]]; then
    run_in_dir "$REPO_ROOT/Android" ./gradlew spotlessApply "${GRADLE_FLAGS[@]}"
  else
    run_in_dir "$REPO_ROOT/Android" ./gradlew spotlessCheck "${GRADLE_FLAGS[@]}"
  fi
}

run_check_xplat() {
  run_in_dir "$REPO_ROOT/xplat/MLBObservabilityKit/jvm" ./gradlew assemble test "${GRADLE_FLAGS[@]}"
  run_in_dir "$REPO_ROOT/xplat/MLBObservabilityKit/jvm/compiler" ./gradlew assemble test "${GRADLE_FLAGS[@]}"
  run_in_dir "$REPO_ROOT/xplat/MLBObservabilityKit/android" ./gradlew assemble test "${GRADLE_FLAGS[@]}"
  run_in_dir "$REPO_ROOT/xplat/MLBAuthKit/jvm" ./gradlew assemble test "${GRADLE_FLAGS[@]}"
  run_in_dir "$REPO_ROOT/xplat/MLBAuthKit/android" ./gradlew assemble test "${GRADLE_FLAGS[@]}"
  run_in_dir "$REPO_ROOT/xplat/MLBDeepLinkSchema/jvm" ./gradlew assemble test "${GRADLE_FLAGS[@]}"
}

run_check_libraries() {
  run_in_dir "$REPO_ROOT/Android/MAASDK" ./gradlew assemble testDebugUnitTest testAmazonDebugUnitTest testGoogleDebugUnitTest "${GRADLE_FLAGS[@]}"
  run_in_dir "$REPO_ROOT/Android/MLBAndroidPlatform" ./gradlew assemble testDebug "${GRADLE_FLAGS[@]}"
  run_in_dir "$REPO_ROOT/Android/Onboarding" ./gradlew -x app:assembleRelease assemble testDebug "${GRADLE_FLAGS[@]}"
  run_in_dir "$REPO_ROOT/Android/FieldPass" ./gradlew -x app:assembleRelease assemble testDebug "${GRADLE_FLAGS[@]}"
  run_in_dir "$REPO_ROOT/Android/Bullpen" ./gradlew -x app:assembleRelease assemble testDebug "${GRADLE_FLAGS[@]}"
  run_in_dir "$REPO_ROOT/Android/SurfaceBuilder" ./gradlew -x app:assembleRelease assemble testDebug "${GRADLE_FLAGS[@]}"
  run_in_dir "$REPO_ROOT/Android/MLBTVWatch" ./gradlew -x app:assembleRelease assemble testDebug "${GRADLE_FLAGS[@]}"
  run_in_dir "$REPO_ROOT/Android/MLBUIDataModels" ./gradlew assemble testDebug "${GRADLE_FLAGS[@]}"
  run_in_dir "$REPO_ROOT/Android/DesignTokens" ./gradlew assemble testDebug "${GRADLE_FLAGS[@]}"
  run_in_dir "$REPO_ROOT/Android/MLBUIComponents" ./gradlew -x app:assembleRelease assemble testDebug "${GRADLE_FLAGS[@]}"
}

run_check_mobile() {
  run_in_dir "$REPO_ROOT/Android/MLBAppMobile" ./gradlew assemble testDebugUnitTest "${GRADLE_FLAGS[@]}"
}

run_check_tv() {
  run_in_dir "$REPO_ROOT/Android/MLBAndroidTV" ./gradlew assemble testDebugUnitTest "${GRADLE_FLAGS[@]}"
}

run_check_ui() {
  run_in_dir "$REPO_ROOT/Android/MLBUIComponents" ./gradlew verifyPaparazziDebug
  run_in_dir "$REPO_ROOT/Android/SurfaceBuilder" ./gradlew verifyPaparazziDebug
  run_in_dir "$REPO_ROOT/Android/MLBAndroidTV" ./gradlew :tvUIComponents:verifyPaparazziDebug
  run_in_dir "$REPO_ROOT/Android/MLBAndroidTV" ./gradlew :app:assembleAndroidTest "${GRADLE_FLAGS[@]}"
  run_in_dir "$REPO_ROOT/Android/MLBAppMobile" ./gradlew :app:assembleAndroidTest "${GRADLE_FLAGS[@]}"
}

run_check_milb() {
  # CI runs: bundle exec fastlane PR --verbose (requires Firebase credentials).
  # Local fallback: ./gradlew build when bundle/fastlane or Firebase creds are unavailable.
  local has_bundle=0
  local has_firebase_creds=0
  command -v bundle >/dev/null 2>&1 && has_bundle=1
  [[ -n "${FIRST_PITCH_FIREBASE_CREDENTIALS_STAGING:-}" || -n "${FIRST_PITCH_FIREBASE_CREDENTIALS_PROD:-}" ]] && has_firebase_creds=1

  if [[ "$has_bundle" -eq 1 && "$has_firebase_creds" -eq 1 ]]; then
    run_in_dir "$REPO_ROOT/Android/MiLB-App" bundle exec fastlane PR --verbose
  else
    log "[milb] Firebase credentials or bundler not available locally — running ./gradlew build as local equivalent"
    run_in_dir "$REPO_ROOT/Android/MiLB-App" ./gradlew build "${GRADLE_FLAGS[@]}"
  fi
}

run_selected_check() {
  local check="$1"
  case "$check" in
    spotless) run_check_spotless ;;
    xplat) run_check_xplat ;;
    libraries) run_check_libraries ;;
    mobile) run_check_mobile ;;
    tv) run_check_tv ;;
    ui) run_check_ui ;;
    milb) run_check_milb ;;
    *)
      echo "Unknown check: $check" >&2
      return 1
      ;;
  esac
}

is_enabled_check() {
  local check="$1"
  case "$check" in
    spotless) [[ "$check_spotless" -eq 1 ]] ;;
    xplat) [[ "$check_xplat" -eq 1 ]] ;;
    libraries) [[ "$check_libraries" -eq 1 ]] ;;
    mobile) [[ "$check_mobile" -eq 1 ]] ;;
    tv) [[ "$check_tv" -eq 1 ]] ;;
    ui) [[ "$check_ui" -eq 1 ]] ;;
    milb) [[ "$check_milb" -eq 1 ]] ;;
    *) return 1 ;;
  esac
}

print_status_summary() {
  local all_checks=(spotless xplat libraries mobile tv ui milb)
  log "Status summary:"
  for check in "${all_checks[@]}"; do
    log "  - $check: $(get_status "$check")"
  done
}

print_selection_reasons() {
  local all_checks=(spotless xplat libraries mobile tv ui milb)
  local check
  log "Selection reasons:"
  for check in "${all_checks[@]}"; do
    if is_enabled_check "$check"; then
      log "  - $check: $(get_reason "$check")"
    fi
  done
}

json_str() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

write_status_json() {
  local is_done="false"
  [[ "${1:-}" == "done" ]] && is_done="true"
  local all_checks_list=(spotless xplat libraries mobile tv ui milb)
  local first=1
  {
    printf '{\n'
    printf '  "started_at": "%s",\n' "$RUN_STARTED_AT"
    printf '  "base_ref": "%s",\n' "$(json_str "$BASE_REF")"
    printf '  "changed_files": %d,\n' "${#changed_files[@]}"
    printf '  "done": %s,\n' "$is_done"
    printf '  "failures": %d,\n' "${failures:-0}"
    printf '  "checks": {\n'
    for chk in "${all_checks_list[@]}"; do
      if [[ "$first" -eq 0 ]]; then printf ',\n'; fi
      first=0
      local chk_status chk_reason log_file started_val ended_val
      chk_status="$(get_status "$chk")"
      chk_reason="$(get_reason "$chk")"
      if [[ -f "$logs_root/${chk}.log" ]]; then
        log_file="\"${chk}.log\""
      else
        log_file="null"
      fi
      local started="${check_started_at[$chk]:-}"
      local ended="${check_ended_at[$chk]:-}"
      if [[ -n "$started" ]]; then started_val="\"$started\""; else started_val="null"; fi
      if [[ -n "$ended" ]]; then ended_val="\"$ended\""; else ended_val="null"; fi
      printf '    "%s": { "status": "%s", "reason": "%s", "log": %s, "started_at": %s, "ended_at": %s }' \
        "$chk" "$chk_status" "$(json_str "$chk_reason")" "$log_file" "$started_val" "$ended_val"
    done
    printf '\n  }\n'
    printf '}\n'
  } > "$logs_root/status.json"
}

generate_dashboard_html() {
  cat << 'ENDDASH' > "$logs_root/dashboard.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Android CI — Local Run</title>
  <style>
    :root{--bg:#0f1117;--sur:#1a1d27;--sur2:#252a3a;--txt:#e0e0e0;--dim:#666;--grn:#4caf50;--red:#f44336;--ylw:#f59e0b}
    *{box-sizing:border-box;margin:0;padding:0}
    body{background:var(--bg);color:var(--txt);font-family:system-ui,-apple-system,sans-serif;font-size:14px;height:100vh;display:flex;flex-direction:column}
    header{background:var(--sur);padding:18px 24px;border-bottom:1px solid var(--sur2);flex-shrink:0}
    h1{font-size:17px;font-weight:600;margin-bottom:6px}
    #banner{display:inline-block;padding:3px 12px;border-radius:20px;font-size:11px;font-weight:700;letter-spacing:.06em;text-transform:uppercase;margin-bottom:8px}
    .b-idle{background:var(--sur2);color:var(--dim)}
    .b-run{background:var(--ylw);color:#111}
    .b-pass{background:var(--grn);color:#fff}
    .b-fail{background:var(--red);color:#fff}
    #meta{color:var(--dim);font-size:12px;display:flex;gap:18px;flex-wrap:wrap}
    #meta b{color:var(--txt)}
    .main{display:flex;flex:1;overflow:hidden}
    .tbl-wrap{flex:0 0 auto;overflow-y:auto;min-width:540px}
    table{border-collapse:collapse;width:100%}
    thead th{padding:9px 16px;text-align:left;font-size:11px;text-transform:uppercase;letter-spacing:.07em;color:var(--dim);background:var(--sur);border-bottom:1px solid var(--sur2);white-space:nowrap}
    tbody tr{border-bottom:1px solid #1c1f2b;cursor:pointer;transition:background .1s}
    tbody tr:hover{background:var(--sur)}
    tbody tr.sel{background:var(--sur2)}
    td{padding:10px 16px;vertical-align:middle}
    .badge{display:inline-block;padding:2px 10px;border-radius:12px;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.05em;min-width:68px;text-align:center}
    .s-QUEUED,.s-SKIPPED{background:#2a2d3a;color:var(--dim)}
    .s-RUNNING{background:var(--ylw);color:#111}
    .s-PASS{background:var(--grn);color:#fff}
    .s-FAIL{background:var(--red);color:#fff}
    .elapsed{color:var(--dim);font-size:12px;font-variant-numeric:tabular-nums;white-space:nowrap}
    .reason{color:var(--dim);font-size:12px;max-width:340px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
    .chkname{font-weight:600;font-size:13px}
    .spin{display:inline-block;width:10px;height:10px;border:2px solid #555;border-top-color:var(--ylw);border-radius:50%;animation:spin .7s linear infinite;margin-right:6px;vertical-align:middle}
    @keyframes spin{to{transform:rotate(360deg)}}
    #log-wrap{flex:1;display:flex;flex-direction:column;border-left:1px solid var(--sur2);min-width:0;overflow:hidden}
    #log-wrap.hidden{display:none}
    #log-hdr{background:var(--sur);padding:9px 14px;font-size:12px;color:var(--dim);display:flex;justify-content:space-between;align-items:center;border-bottom:1px solid var(--sur2);flex-shrink:0}
    #log-hdr b{color:var(--txt)}
    #log-close{cursor:pointer;background:var(--sur2);border:none;color:var(--txt);border-radius:4px;padding:2px 8px;font-size:11px}
    #log-close:hover{background:#3a3d50}
    #log-body{flex:1;overflow-y:auto;background:#0a0a0f}
    #log-body pre{color:#d4d4d4;font-family:'SF Mono',Menlo,monospace;font-size:12px;line-height:1.6;padding:14px 16px;white-space:pre-wrap;word-break:break-all}
    #hint{flex:1;display:flex;align-items:center;justify-content:center;color:var(--dim);font-size:13px}
  </style>
</head>
<body>
<header>
  <div id="banner" class="b-idle">Loading...</div>
  <h1>Android CI — Local Run</h1>
  <div id="meta"></div>
</header>
<div class="main">
  <div class="tbl-wrap">
    <table>
      <thead><tr><th>Check</th><th>Status</th><th>Elapsed</th><th>Reason</th></tr></thead>
      <tbody id="tbody"></tbody>
    </table>
  </div>
  <div id="log-wrap" class="hidden">
    <div id="log-hdr">
      <span><span class="spin" id="lspin" style="display:none"></span><b id="ltitle"></b></span>
      <button id="log-close" onclick="closeLog()">close ✕</button>
    </div>
    <div id="log-body"><pre id="log-pre">Select a check to view its log.</pre></div>
  </div>
  <div id="hint">← click a row to view its live log</div>
</div>
<script>
const ORDER=['spotless','xplat','libraries','mobile','tv','ui','milb'];
let sel=null,timer=null;

function esc(s){return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')}

function elapsed(start,end){
  if(!start)return'';
  const s=Math.floor(((end?new Date(end):new Date())-new Date(start))/1000);
  return s<60?s+'s':Math.floor(s/60)+'m '+(s%60)+'s';
}

function render(data){
  const tbody=document.getElementById('tbody');
  const banner=document.getElementById('banner');
  const meta=document.getElementById('meta');
  meta.innerHTML='<span>Base: <b>'+esc(data.base_ref||'')+'</b></span>'+
    '<span>Changed files: <b>'+(data.changed_files||0)+'</b></span>'+
    '<span>Started: <b>'+(data.started_at||'')+'</b></span>';
  const rows=ORDER.map(name=>{
    const c=data.checks&&data.checks[name];
    if(!c)return'';
    const isSel=sel===name?' sel':'';
    const spin=c.status==='RUNNING'?'<span class="spin"></span>':'';
    return'<tr class="'+isSel+'" onclick="pick(\''+name+'\')">'+
      '<td class="chkname">'+name+'</td>'+
      '<td>'+spin+'<span class="badge s-'+c.status+'">'+c.status+'</span></td>'+
      '<td class="elapsed">'+elapsed(c.started_at,c.ended_at)+'</td>'+
      '<td class="reason" title="'+esc(c.reason||'')+'">'+esc(c.reason||'')+'</td>'+
      '</tr>';
  }).join('');
  tbody.innerHTML=rows;
  const statuses=ORDER.map(n=>data.checks&&data.checks[n]&&data.checks[n].status).filter(Boolean);
  if(data.done){
    const f=data.failures||0;
    banner.className=f?'b-fail':'b-pass';
    banner.textContent=f?(f===1?'1 check failed':f+' checks failed'):'All checks passed';
  }else if(statuses.some(s=>s==='RUNNING')){
    const running=ORDER.filter(n=>data.checks&&data.checks[n]&&data.checks[n].status==='RUNNING');
    banner.className='b-run';
    banner.textContent='Running: '+running.join(', ');
  }else{
    banner.className='b-idle';
    banner.textContent='Queued';
  }
}

async function fetchLog(logFile){
  if(!logFile)return;
  try{
    const r=await fetch('/'+logFile+'?t='+Date.now());
    if(!r.ok)return;
    const txt=await r.text();
    const pre=document.getElementById('log-pre');
    const div=document.getElementById('log-body');
    const atBot=div.scrollHeight-div.scrollTop<=div.clientHeight+20;
    pre.textContent=txt;
    if(atBot)div.scrollTop=div.scrollHeight;
  }catch(e){}
}

function pick(name){
  sel=name;
  document.getElementById('log-wrap').classList.remove('hidden');
  document.getElementById('hint').style.display='none';
  document.getElementById('ltitle').textContent=name;
  document.getElementById('log-pre').textContent='Loading...';
  document.getElementById('log-body').scrollTop=0;
}

function closeLog(){
  sel=null;
  document.getElementById('log-wrap').classList.add('hidden');
  document.getElementById('hint').style.display='flex';
}

async function poll(){
  try{
    const r=await fetch('/status.json?t='+Date.now());
    if(!r.ok)throw 0;
    const data=await r.json();
    render(data);
    if(sel){
      const c=data.checks&&data.checks[sel];
      const spin=document.getElementById('lspin');
      if(c&&c.log){
        spin.style.display=c.status==='RUNNING'?'inline-block':'none';
        await fetchLog(c.log);
      }
    }
    if(!data.done){timer=setTimeout(poll,1000);return;}
    timer=null;
  }catch(e){timer=setTimeout(poll,2000);}
}

poll();
</script>
</body>
</html>
ENDDASH
}

start_http_server() {
  if ! command -v python3 >/dev/null 2>&1; then
    log "WARNING: python3 not found — dashboard HTTP server unavailable. Falling back to parallel mode without dashboard."
    DASHBOARD=0
    return 0
  fi

  HTTP_PORT="$(python3 -c 'import socket; s=socket.socket(); s.bind(("",0)); print(s.getsockname()[1]); s.close()')"

  python3 -m http.server "$HTTP_PORT" --directory "$logs_root" >/dev/null 2>&1 &
  HTTP_PID="$!"

  trap 'kill "$HTTP_PID" 2>/dev/null || true' EXIT

  local attempts=0
  until python3 -c "import socket,sys; s=socket.socket(); r=s.connect_ex(('localhost',$HTTP_PORT)); s.close(); sys.exit(r)" 2>/dev/null; do
    sleep 0.1
    attempts=$((attempts + 1))
    if [[ "$attempts" -gt 50 ]]; then
      log "WARNING: Dashboard HTTP server did not start. Continuing without dashboard."
      DASHBOARD=0
      return 0
    fi
  done

  open "http://localhost:$HTTP_PORT/dashboard.html" 2>/dev/null || true
  log "Dashboard opened: http://localhost:$HTTP_PORT/dashboard.html"
}

REPO_ROOT=""
BASE_REF="origin/main"
FULL_RUN=0
INCLUDE_MILB=0
SKIP_MILB=0
MILB_ONLY=0
SKIP_SPOTLESS=0
SPOTLESS_APPLY=0
PARALLEL=0
DASHBOARD=0
DRY_RUN=0
HTTP_PORT=""
HTTP_PID=""
RUN_STARTED_AT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-root)
      REPO_ROOT="$2"
      shift 2
      ;;
    --base-ref)
      BASE_REF="$2"
      shift 2
      ;;
    --full)
      FULL_RUN=1
      shift
      ;;
    --include-milb)
      INCLUDE_MILB=1
      shift
      ;;
    --skip-milb)
      SKIP_MILB=1
      shift
      ;;
    --milb-only)
      MILB_ONLY=1
      shift
      ;;
    --skip-spotless)
      SKIP_SPOTLESS=1
      shift
      ;;
    --spotless-apply)
      SPOTLESS_APPLY=1
      shift
      ;;
    --parallel)
      PARALLEL=1
      shift
      ;;
    --serial)
      PARALLEL=0
      shift
      ;;
    --dashboard)
      DASHBOARD=1
      PARALLEL=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ "$MILB_ONLY" -eq 1 ]]; then
  FULL_RUN=0
fi

if [[ "$REPO_ROOT" == "" ]]; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
fi

if [[ ! -f "$REPO_ROOT/.github/workflows/pr-android.yml" ]]; then
  echo "Unable to find repo-root workflow file at $REPO_ROOT/.github/workflows/pr-android.yml" >&2
  echo "Pass --repo-root with the monorepo root path." >&2
  exit 1
fi

# Unset CI so Gradle does not activate the remote build cache validation path,
# which requires secrets that are only present in GitHub Actions.
unset CI

# Detect git worktrees: .git is a file (pointer) instead of a directory.
# Spotless uses JGit for ratchetFrom, which does not follow the worktree indirection
# file and will fail with "Cannot find git repository in any parent directory".
# Auto-skip spotless and surface a clear message rather than crashing in Gradle.
IS_GIT_WORKTREE=0
if [[ -f "$REPO_ROOT/.git" ]]; then
  IS_GIT_WORKTREE=1
  log "WARNING: Running in a git worktree. Spotless's ratchetFrom (JGit) cannot resolve the repository through a worktree .git file. spotless will be skipped."
  log "         To run spotless, use a standard git clone instead of a worktree."
  SKIP_SPOTLESS=1
fi

GRADLE_FLAGS=(--console=plain '-DtestIncludePatterns=mlb.atbat.suite.*,mlb.atbat.suites.*')

check_spotless=0
check_xplat=0
check_libraries=0
check_mobile=0
check_tv=0
check_ui=0
check_milb=0

android_mobile=0
android_tv=0
android_library=0
xplat_library=0
milb_changed=0

status_spotless="SKIPPED"
status_xplat="SKIPPED"
status_libraries="SKIPPED"
status_mobile="SKIPPED"
status_tv="SKIPPED"
status_ui="SKIPPED"
status_milb="SKIPPED"

reason_spotless="Not selected by current change set"
reason_xplat="Not selected by current change set"
reason_libraries="Not selected by current change set"
reason_mobile="Not selected by current change set"
reason_tv="Not selected by current change set"
reason_ui="Not selected by current change set"
reason_milb="Not selected by current change set"

declare -A check_started_at=()
declare -A check_ended_at=()

mapfile -t changed_files < <(git -C "$REPO_ROOT" diff --name-only "$(git -C "$REPO_ROOT" merge-base "$BASE_REF" HEAD)"...HEAD)

if [[ "$FULL_RUN" -eq 1 ]]; then
  check_spotless=1
  check_xplat=1
  check_libraries=1
  check_mobile=1
  check_tv=1
  check_ui=1
  set_reason "spotless" "Selected by --full"
  set_reason "xplat" "Selected by --full"
  set_reason "libraries" "Selected by --full"
  set_reason "mobile" "Selected by --full"
  set_reason "tv" "Selected by --full"
  set_reason "ui" "Selected by --full"
else
  for file in "${changed_files[@]}"; do
    if is_shared_trigger_path "$file"; then
      android_mobile=1
      android_tv=1
      android_library=1
      xplat_library=1
    fi

    if [[ "$file" == Android/MLBAppMobile/* ]]; then
      android_mobile=1
    fi

    if [[ "$file" == Android/MLBAndroidTV/* ]]; then
      android_tv=1
    fi

    if is_android_library_path "$file"; then
      android_library=1
    fi

    if is_xplat_library_path "$file"; then
      xplat_library=1
    fi

    if is_milb_trigger_path "$file"; then
      check_milb=1
      milb_changed=1
    fi
  done

  if [[ "$android_mobile" -eq 1 || "$android_tv" -eq 1 || "$android_library" -eq 1 || "$xplat_library" -eq 1 ]]; then
    check_spotless=1
  fi

  check_xplat=$xplat_library
  check_libraries=$android_library

  if [[ "$android_library" -eq 1 || "$xplat_library" -eq 1 || "$android_mobile" -eq 1 ]]; then
    check_mobile=1
  fi

  if [[ "$android_library" -eq 1 || "$xplat_library" -eq 1 || "$android_tv" -eq 1 ]]; then
    check_tv=1
  fi

  check_ui=$android_library

  if [[ "$check_spotless" -eq 1 ]]; then
    set_reason "spotless" "Selected because Android integrity triggered (android-mobile=$android_mobile android-tv=$android_tv android-library=$android_library xplat-library=$xplat_library)"
  fi
  if [[ "$check_xplat" -eq 1 ]]; then
    set_reason "xplat" "Selected because xplat-library changes were detected"
  fi
  if [[ "$check_libraries" -eq 1 ]]; then
    set_reason "libraries" "Selected because android-library changes were detected"
  fi
  if [[ "$check_mobile" -eq 1 ]]; then
    set_reason "mobile" "Selected because one of android-library/xplat-library/android-mobile is true"
  fi
  if [[ "$check_tv" -eq 1 ]]; then
    set_reason "tv" "Selected because one of android-library/xplat-library/android-tv is true"
  fi
  if [[ "$check_ui" -eq 1 ]]; then
    set_reason "ui" "Selected because android-library changes were detected"
  fi
  if [[ "$check_milb" -eq 1 ]]; then
    set_reason "milb" "Selected because MiLB trigger path changes were detected"
  fi
fi

if [[ "$INCLUDE_MILB" -eq 1 ]]; then
  check_milb=1
  set_reason "milb" "Selected by --include-milb"
fi

if [[ "$SKIP_MILB" -eq 1 ]]; then
  check_milb=0
  set_reason "milb" "Skipped by --skip-milb"
fi

if [[ "$MILB_ONLY" -eq 1 ]]; then
  check_spotless=0
  check_xplat=0
  check_libraries=0
  check_mobile=0
  check_tv=0
  check_ui=0
  check_milb=1
  set_reason "spotless" "Skipped by --milb-only"
  set_reason "xplat" "Skipped by --milb-only"
  set_reason "libraries" "Skipped by --milb-only"
  set_reason "mobile" "Skipped by --milb-only"
  set_reason "tv" "Skipped by --milb-only"
  set_reason "ui" "Skipped by --milb-only"
  set_reason "milb" "Selected by --milb-only"
fi

if [[ "$SKIP_SPOTLESS" -eq 1 ]]; then
  check_spotless=0
  set_reason "spotless" "Skipped by --skip-spotless"
fi

log "Repo root: $REPO_ROOT"
log "Base ref: $BASE_REF"
log "Changed files: ${#changed_files[@]}"
log "Execution mode: $(if [[ "$PARALLEL" -eq 1 ]]; then printf 'parallel'; else printf 'sequential'; fi)"
log "Selected checks: spotless=$(bool_word "$check_spotless") xplat=$(bool_word "$check_xplat") libraries=$(bool_word "$check_libraries") mobile=$(bool_word "$check_mobile") tv=$(bool_word "$check_tv") ui=$(bool_word "$check_ui") milb=$(bool_word "$check_milb")"

if [[ ${#changed_files[@]} -gt 0 ]]; then
  log "Changed file list:"
  for file in "${changed_files[@]}"; do
    log "  - $file"
  done
fi

all_checks=(spotless xplat libraries mobile tv ui milb)
selected_checks=()
for check in "${all_checks[@]}"; do
  if is_enabled_check "$check"; then
    selected_checks+=("$check")
    set_status "$check" "QUEUED"
  fi
done

if [[ ${#selected_checks[@]} -eq 0 ]]; then
  log "No checks selected for current changes."
  print_status_summary
  exit 0
fi

print_selection_reasons

if [[ "$PARALLEL" -eq 0 ]]; then
  for check in "${selected_checks[@]}"; do
    set_status "$check" "RUNNING"
    log "Running [$check]"
    if run_selected_check "$check"; then
      set_status "$check" "PASS"
      log "[$check] PASS"
    else
      set_status "$check" "FAIL"
      log "[$check] FAIL"
      print_status_summary
      exit 1
    fi
  done
  print_status_summary
  log "All selected checks completed."
  exit 0
fi

logs_root="$REPO_ROOT/Android/build/ci-local-logs/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$logs_root"
RUN_STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
log "Parallel mode enabled. Per-check logs: $logs_root"

if [[ "$DASHBOARD" -eq 1 ]]; then
  generate_dashboard_html
  write_status_json
  start_http_server
fi

pids=()
names=()
logs=()
done_flags=()

for check in "${selected_checks[@]}"; do
  check_log="$logs_root/${check}.log"
  set_status "$check" "RUNNING"
  check_started_at[$check]="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  [[ "$DASHBOARD" -eq 1 ]] && write_status_json
  log "Starting [$check] in background -> $check_log"
  (
    set -euo pipefail
    run_selected_check "$check"
  ) >"$check_log" 2>&1 &
  pids+=("$!")
  names+=("$check")
  logs+=("$check_log")
  done_flags+=("0")
done

remaining=${#pids[@]}
failures=0

while [[ "$remaining" -gt 0 ]]; do
  for i in "${!pids[@]}"; do
    if [[ "${done_flags[$i]}" -eq 1 ]]; then
      continue
    fi

    pid="${pids[$i]}"
    name="${names[$i]}"
    check_log="${logs[$i]}"

    if ! kill -0 "$pid" 2>/dev/null; then
      if wait "$pid"; then
        set_status "$name" "PASS"
        check_ended_at[$name]="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        [[ "$DASHBOARD" -eq 1 ]] && write_status_json
        log "[$name] PASS (log: $check_log)"
      else
        set_status "$name" "FAIL"
        check_ended_at[$name]="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        failures=$((failures + 1))
        [[ "$DASHBOARD" -eq 1 ]] && write_status_json
        log "[$name] FAIL (log: $check_log)"
      fi
      done_flags[$i]=1
      remaining=$((remaining - 1))
    fi
  done
  if [[ "$remaining" -gt 0 ]]; then
    sleep 1
  fi
done

[[ "$DASHBOARD" -eq 1 ]] && write_status_json "done"
print_status_summary

if [[ "$failures" -gt 0 ]]; then
  log "Parallel run finished with $failures failing check group(s)."
  if [[ "$DASHBOARD" -eq 1 ]]; then
    log "Dashboard: http://localhost:$HTTP_PORT/dashboard.html — Press Ctrl+C to shut down."
    wait "$HTTP_PID" 2>/dev/null || true
  fi
  exit 1
fi

log "All selected checks completed."
if [[ "$DASHBOARD" -eq 1 ]]; then
  log "Dashboard: http://localhost:$HTTP_PORT/dashboard.html — Press Ctrl+C to shut down."
  wait "$HTTP_PID" 2>/dev/null || true
fi
