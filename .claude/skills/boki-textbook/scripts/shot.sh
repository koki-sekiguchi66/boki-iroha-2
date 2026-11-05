#!/usr/bin/env bash
# 指定した要素が上端に来るようにスクロールして、幅 WIDTH の画面を撮影する（iframe 経由）
# usage: shot.sh <public のフォルダ> <page.html> <CSSセレクタ> [名前] [高さ=1600] [幅=390] [事前に実行するJS]
#   事前JSでは w（ページの window）と d（document）が使える。例: "d.querySelector('.kb-opt[data-k=\"C\"]').click()"
# 出力: $SHOTS（既定 ${TMPDIR:-/tmp}/kb-shots）/<page>_<名前>.png のパスを表示。Read ツールで画像を確認する
# 注意: ヘッドレスでは CSS の transition が止まったままになるので、状態で色が変わる要素に transition を付けない
PUB=$(cd "$1" && { pwd -W 2>/dev/null || pwd; })
PAGE="$2"; SEL="$3"; NAMEX="${4:-x}"; HEI="${5:-1600}"; WID="${6:-390}"; PRE="${7:-}"
CHROME="${CHROME:-/c/Program Files/Google/Chrome/Application/chrome.exe}"
SP="${SHOTS:-${TMPDIR:-/tmp}/kb-shots}"; mkdir -p "$SP"
W=$(cygpath -m "$SP" 2>/dev/null || echo "$SP")
NAME="${PAGE%.html}_${NAMEX}"
cat > "$SP/wrap_$NAME.html" <<EOF
<!DOCTYPE html><html><body style="margin:0;background:#888">
<iframe id="f" src="file:///${PUB}/${PAGE}" style="border:0;width:${WID}px;height:${HEI}px;background:#fff"></iframe>
<script>
document.getElementById('f').addEventListener('load', () => {
  setTimeout(() => {
    const w = document.getElementById('f').contentWindow, d = w.document;
    try { ${PRE} } catch (e) { document.title = 'PRE-ERR ' + e.message; }
    const el = d.querySelector(${SEL@Q});
    if (el) { el.scrollIntoView({ block: 'start' }); w.scrollBy(0, -64); } else document.title = 'NOTFOUND';
  }, 1500);
});
</script></body></html>
EOF
"$CHROME" --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files \
  --user-data-dir="$W/prof" --window-size=$((WID+40)),${HEI} --virtual-time-budget=9000 \
  --screenshot="$W/$NAME.png" "file:///$W/wrap_$NAME.html" >/dev/null 2>&1
echo "$W/$NAME.png"
