# 検証と公開

## 環境（このPCで確認済み）

- Windows 11。Python と Node はない。使うのは **Git Bash の Perl 5.38**（`perl -CSD -Mutf8` で日本語を扱う）と **Chrome のヘッドレス**。
- 日本語を含む置換は、`sed` より Perl かスキルの `scripts/rep.pl`（`<<<<旧====新>>>>` の組を一括適用、旧は1回だけ現れること）を使う。
- 長いシェルの1行に Perl の `q{…}` や `=~` を詰め込むと引用符で壊れやすい。置換スクリプトはファイルに書いて実行する（DATA 節に置換の組を書く形が安全）。
- 公式資料のPDFを読むときは `scripts/pdftext.pl file.pdf`（FlateDecode と ToUnicode のCMapに対応。対応していないフォントのPDFでは何も出ない）。

## 毎回のビルド

```
perl build.pl
```
- 最後の2行に「検証OK」と件数（仕訳の貸借一致・T字勘定・sum 表の縦計・列数、演習の数、THINK選択式の数）が出る。警告があれば終了コード1。
- THINK選択式の数が、`::cfo` の数と一致しているか確かめる（選択肢のない cfo が残っていないか）。

## 自己テスト（ブラウザで動く演習の検査）

```
bash ~/.claude/skills/boki-textbook/scripts/st.sh public ch01.html ch02.html …
bash ~/.claude/skills/boki-textbook/scripts/st.sh public all.html      # 全章一気読み版（時間がかかる）
```
- 各ページの全演習（仕訳・穴埋め・分類・チェック表）に正解を入れて採点が通るか、THINK が選ぶまで閉じていて選ぶと開くか、シミュレーターが本文の数値（`@expect`）と一致するか、用語ポップアップ、模擬試験の採点を確かめる。
- 「SELFTEST OK」以外の行が出たら直す。「バナーなし」は JS のエラーかページがないこと。

## スマホ幅のはみ出し

```
bash ~/.claude/skills/boki-textbook/scripts/ovf.sh public $(cd public && ls *.html | grep -v all.html)
```
- 全ページ `n=0` であること。表は横スクロールの容器に入るので対象外。長いリンク、`whitespace-nowrap` の要素、幅の固定された入力欄が典型的な原因。

## 目で見る確認（新しい見た目の部品を足したとき）

```
bash ~/.claude/skills/boki-textbook/scripts/shot.sh public ch05.html 'aside.border-t-stone-700' real 1600 390
```
出力されたPNGを Read ツールで開いて確認する。THINK の選択後を撮るには事前JSで `d.querySelector('[data-think] .kb-opt[data-k="C"]').click()`。
ヘッドレスの注意：CSS transition は止まったままになる（状態で色が変わる部品に transition を付けない）。Tailwind の Play CDN はインラインスクリプトより後でCSSを生成するので、撮影は読み込みから1.5秒以上待つ（スクリプトは待つようになっている）。

## アイコン

ユーザーから画像をもらったら、PowerShell の System.Drawing で余白を詰めて正方形に切り抜き、`public/icons/` に `icon-32.png`・`icon-192.png`・`apple-touch-icon.png`（180px）を作る。build.pl の head にはすでにリンクが入っている（3級の build.pl を使う場合）。

## 公開（Git → GitHub → Cloudflare Pages）

- `git init` したら最初に、3級のリポジトリの `.gitattributes`（`* text=auto eol=lf`。build.pl が出す LF のまま管理する）と `.gitignore` をコピーする。ブランチ名は `main`。
- 新しいリポジトリを作る・公開する・push する前に、ユーザーの了承を取る（3級での了承は2級に引き継がない）。
- トークンは表示しない。push は `GCM_INTERACTIVE=never git push -q origin main`。出力はトークンを伏せるフィルタを通す。
- コミットメッセージの末尾には、会話で指示された帰属表示（Co-Authored-By と Claude-Session の行）を付ける。
- 章をいくつか書くごとにコミットする（長い作業の途中で文脈が要約されても戻れるように）。
- Cloudflare Pages の設定（ユーザーが画面で行う）：Framework preset なし、Build command 空欄、Build output directory `public`。main に push すると自動で再公開される。
- `README.md` に、公開方法・編集方法・記法の要点・演習の一覧・架空と実在の区別を書く（3級の README を雛形にする）。

## 最終チェックリスト

- [ ] ビルドの検証OK、警告なし
- [ ] 全ページと all.html の自己テストが OK
- [ ] 全ページのはみ出し n=0
- [ ] 新しい部品のスクリーンショットを確認
- [ ] 出典リンクが開ける（主なものを WebFetch で確認）
- [ ] 物語の日付・人物・数字が章をまたいで矛盾しない（設計書の年表と照合）
- [ ] フッター・使い方ガイドに「物語は架空、実際にあった話は公開資料にもとづく」
- [ ] コミット・push、ユーザーへの報告（何を変えたか、未確認のこと、出典）
