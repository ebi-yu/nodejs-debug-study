# Node.jsのデバッグの仕組み

Node.jsは`--inspect`オプションを使って起動すると、**V8 Inspector**を通じて外部からデバッグできるようになります。

[V8 Inspector](https://v8.dev/docs/inspector)は、JSON-RPC風のJSONメッセージでやり取りするプロトコルです。デバッグ対象のプロセスと外部のデバッガーがWebSocketを通じて通信します。
[Chrome DevTools Protocol（CDP）](https://chromedevtools.github.io/devtools-protocol/)と高い互換性があり、ブラウザのDevToolsやVSCodeなど、多くのデバッガーがこのプロトコルを利用しています。

どのポートからデバッグ通信ができるかは、Node.js起動時に`--inspect`オプションで指定します。例えば、`--inspect=9229`とすると、9229番ポートでデバッグ通信ができるようになります。

## JSON-RPC(JSON Remote Procedure Call)とは

JSON-RPCは、リモート手続き呼び出し（Remote Procedure Call）をJSONで表現する軽量なプロトコルです。
リモート手続き呼び出しとは、ネットワークを介して別のコンピュータ上で実行される関数やメソッドを呼び出すことを指します。
JSON-RPCでは、クライアントがサーバーに対してJSON形式のリクエストを送信し、サーバーがJSON形式のレスポンスを返します。

V8 InspectorではJSON-RPCに“似た”JSONメッセージで通信します（厳密な準拠ではありません）。

## Node.jsのデバッグ通信のイベント

Node.jsのデバッグ通信(WebSocket通信)では、以下のようなイベントが発生します。

- `Debugger.paused`: デバッグセッションが一時停止したときに発生します。
- `Debugger.resumed`: デバッグセッションが再開されたときに発生します。
- `Debugger.scriptParsed`: 新しいスクリプトが解析されたときに発生します。
- `Debugger.breakpointResolved`: ブレークポイントが解決されたときに発生します。

### Debugger.paused

`Debugger.paused`イベントは、デバッグセッションが一時停止したときに発生します。このイベントは、ブレークポイントに到達したときや、ステップ実行が完了したときなどにトリガーされます。

このイベントには、以下のような情報が含まれます。

- `callFrames`: 現在のコールスタックの情報を含む配列です。各要素は、関数名、スクリプトID、行番号、列番号などの情報を持つオブジェクトです。
- `reason`: デバッグセッションが一時停止した理由を示す文字列です。例えば、`breakpoint`や`step`などがあります。
- `hitBreakpoints`: ヒットしたブレークポイントのIDを含む配列です。

## Node.jsのデバッグ通信のメソッド

以下のようなメソッドを使用することで、デバッグ中の情報を取得したり、操作を行ったりできます。

- `Runtime.getProperties`: 指定されたオブジェクトのプロパティを取得します。
- `Runtime.evaluate`: 指定された式を評価します。

### Runtime.getProperties

`Runtime.getProperties`メソッドは、指定されたオブジェクトのプロパティを取得するために使用されます。このメソッドは、オブジェクトのプロパティ名、値、属性などの情報を含む配列を返します。

## VSCodeでのauto attach設定

VSCodeでは、Node.jsのデバッグセッションを自動的にアタッチするための設定が用意されています。これにより、Node.jsプロセスが起動すると同時にデバッグセッションが開始されます。

Auto Attachが設定されていると、VSCodeはNode.jsプロセスを検知すると、自動的にデバッグセッションを開始します。これにより、手動でデバッグセッションを開始する手間が省けます。

## launch.jsonについて

VSCodeでデバッグセッションを設定するためのファイルです。`launch.json`ファイルには、デバッグ構成が含まれており、どのようにデバッグセッションを開始するかを指定します。

Auto Attachで自動的にアタッチができない場合、`launch.json`ファイルを使用して手動でデバッグセッションを開始することができます。

## 実際のデバッグ通信の内容をのぞいてみる

デバッグ通信の内容をのぞくために、`debug-log-monitor.sh`というシェルスクリプトを用意しました。このスクリプトは、指定したWebSocket URLに接続し、送受信されるメッセージをログとして表示します。

`debug-log-monitor.sh`実行時の処理の流れは以下の通りです。

1. sample-script.jsが`--inspect=9229`オプション付きで起動します。
2. sample-script.jsがデバッグポート(9229)で待機します。
3. websocketで9229ポートに接続します。
4. `Runtime.enable`と`Debugger.enable`メソッドを送信して、RuntimeとDebuggerを有効化します。
5. sample-script.jsが`Debugger.scriptParsed`イベントを送信します。
6. sample-script.jsが`Debugger.paused`イベントを送信します。

## テストコードのデバッグ

VitestやJestを使ったテストコードをデバッグしたい場合(おそらくNode.jsプロセスが子プロセスとして起動されるため)、Auto Attachがうまく動きません。

そのため、`launch.json`ファイルを使ってデバッグセッションを開始します。

## まとめ

- Node.jsのデバッグは、V8 Inspector（CDP互換）を用いたWebSocket通信で行われます。
- メッセージはJSON-RPC風のフォーマット（厳密な準拠ではない）でやり取りされます。
- Node.jsのデバッグ通信では、さまざまなイベントやメソッドが使用されます。
- VSCodeでは、Auto Attach機能でNode.jsのデバッグセッションに自動アタッチできます。
- `launch.json`ファイルを使って、手動でデバッグセッションを開始することもできます。

## 参考 : フロントエンドサービスのデバッグ

Webブラウザ上で動いているJavaScriptコードのデバッグは、Chrome DevToolsを使って行います。
Webブラウザ上のJavaScriptコードはV8 Inspector互換である**Chrome DevTools Protocol(CDP)**を用いているため、WebSocket通信に接続することにより、VSCode上でのデバッグが可能です。
※Webブラウザ上のJavaScriptコードはバンドルされていることが多いため、**ソースマップ**を用いて元のコードと対応付ける必要があります。

### ソースマップとは

ソースマップは、コンパイルされたコード（例えば、TypeScriptからJavaScriptへの変換や、ミニファイされたJavaScriptコード）と元のソースコード（TypeScriptコードなど）との対応関係を記述したファイルです。
これにより、デバッガーはコンパイル後のコードを実行しながら、元のソースコード上でブレークポイントを設定したり、ステップ実行を行ったりすることができます。
