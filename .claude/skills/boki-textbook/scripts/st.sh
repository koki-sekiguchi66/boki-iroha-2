#!/usr/bin/env bash
# 自己テスト：各ページを ?selftest で開き、画面上部の結果行（SELFTEST OK / NG …）を表示する
# usage: st.sh <public のフォルダ> page.html [page.html ...]
#   例: bash st.sh public ch01.html ch02.html     （all.html は時間がかかるので単独で）
# 環境変数 CHROME で Chrome の場所を変えられる
PUB=$(cd "$1" && { pwd -W 2>/dev/null || pwd; }); shift
CHROME="${CHROME:-/c/Program Files/Google/Chrome/Application/chrome.exe}"
PROF="${TMPDIR:-/tmp}/kb-st-prof"; mkdir -p "$PROF"
PROFW=$(cygpath -m "$PROF" 2>/dev/null || echo "$PROF")
for P in "$@"; do
  R=$("$CHROME" --headless=new --disable-gpu --allow-file-access-from-files \
    --user-data-dir="$PROFW" --window-size=430,900 --virtual-time-budget=60000 \
    --dump-dom "file:///${PUB}/${P}?selftest=1" 2>/dev/null | grep -o '<div id="kb-selftest"[^>]*>[^<]*' | sed 's/<[^>]*>//')
  printf '%-12s %s\n' "$P" "${R:-（バナーなし＝JSエラーかページが無い）}"
done
