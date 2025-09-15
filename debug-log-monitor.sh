#!/bin/bash

echo "🔧 デバッガー監視開始..."

# Node.js プロセス管理
NODE_PID=""
WS_PID=""

# クリーンアップ関数
cleanup() {
    if [ ! -z "$NODE_PID" ]; then
        kill $NODE_PID 2>/dev/null
        wait $NODE_PID 2>/dev/null
    fi
    if [ ! -z "$WS_PID" ]; then
        kill $WS_PID 2>/dev/null
        wait $WS_PID 2>/dev/null
    fi
    pkill -f "debug-log-monitor" 2>/dev/null
    echo "🛑 監視終了..."
    exit 0
}

# 割り込みハンドラー設定
trap cleanup SIGINT SIGTERM

# 1. Node.js を debug モードで起動 (バックグラウンド)
echo "🚀 Node.js 起動中..."
node --inspect=9229 sample-script.js &
NODE_PID=$!

# Node.js の起動完了を待つ
sleep 2

# 2. WebSocket URLを取得
echo "🔍 WebSocket URL取得中..."
WEBSOCKET_URL=""
for i in {1..10}; do
    WEBSOCKET_URL=$(curl -s http://127.0.0.1:9229/json 2>/dev/null | node -p "try { JSON.parse(require('fs').readFileSync(0, 'utf8'))[0]?.webSocketDebuggerUrl || '' } catch(e) { '' }")
    if [ ! -z "$WEBSOCKET_URL" ]; then
        echo "✅ WebSocket URL取得成功: $WEBSOCKET_URL"
        break
    fi
    echo "⏳ WebSocket URL取得待機中... ($i/10)"
    sleep 1
done

if [ -z "$WEBSOCKET_URL" ]; then
    echo "❌ WebSocket URL取得失敗"
    cleanup
    exit 1
fi

# 3. WebSocket 監視スクリプトを Node.js で実行
echo "🔌 WebSocket 監視開始..."
cat << EOF | node &
const WebSocket = require('ws');

let ws;
let isPaused = false;
let scriptId = null;
let requestId = 1000; // ID管理用のカウンター

console.log('[DEBUG] WebSocket 接続試行中...');

// WebSocket 接続
ws = new WebSocket('$WEBSOCKET_URL');

ws.on('open', function() {
    console.log('[' + new Date().toISOString() + '] WebSocket接続成功');
    
    // Runtime と Debugger を有効化
    ws.send(JSON.stringify({
        id: 1,
        method: 'Runtime.enable'
    }));
    
    ws.send(JSON.stringify({
        id: 2,
        method: 'Debugger.enable'
    }));
});

ws.on('message', function(data) {
    const message = JSON.parse(data);
    
    // 変数の値を取得する関数
    function getVariableValues(scopeObjectId, scopeType) {
        if (!scopeObjectId || scopeObjectId === '') return;
        
        requestId++;
        const getPropsCommand = {
            id: requestId,
            method: 'Runtime.getProperties',
            params: {
                objectId: scopeObjectId,
                ownProperties: true,
                generatePreview: true
            }
        };
        ws.send(JSON.stringify(getPropsCommand));
    }
    
    // Runtime.getPropertiesの応答処理
    if (message.id && message.result && message.result.result) {
        // システム変数を除外して重要な変数のみ表示
        const systemVars = [
            'require', 'module', 'exports', '__filename', '__dirname',
            'process', 'global', 'globalThis', 'console', 'Buffer',
            'internalBinding', 'primordials', 'validateString', 'validateFunction',
            'ERR_', 'Safe', 'Reflect', 'Array', 'Object', 'String', 'Boolean',
            'path', 'fs', 'vm_', 'kIs', 'kEmpty', 'CHAR_', 'nmChars',
            'debug', 'trace', 'emit', 'wrap', 'load', 'compile', 'content', 'source', 
            'extension', 'nmLen', 'createRequireError', 'kEvaluated', 'filename',
            'request', 'isMain', 'threw', 'logLabel'
        ];
        
        const importantVars = message.result.result.filter(function(prop) {
            if (!prop.value || prop.value.value === 'undefined') return false;
            if (prop.value.type === 'function' || prop.value.type === 'symbol') return false;
            
            // システム変数除外
            for (let i = 0; i < systemVars.length; i++) {
                if (prop.name.indexOf(systemVars[i]) === 0) return false;
            }
            return true;
        });
        
        if (importantVars.length > 0) {
            importantVars.forEach(function(prop) {
                console.log('  ' + prop.name + ': ' + prop.value.value);
            });
        }
        return;
    }
    
    // エラー応答処理
    if (message.id && message.error) {
        console.log('❌ エラー: ' + message.error.message);
        return;
    }
    
    // デバッガーの一時停止
    if (message.method === 'Debugger.paused') {
        console.log('🔴 実行停止!');
        console.log('停止位置:', message.params.callFrames[0] ? message.params.callFrames[0].location : '不明');
        
        // Node.js内部関数を除外
        const internalFunctions = ['traceSync', 'wrapModuleLoad', 'executeUserEntryPoint'];
        
        if (message.params && message.params.callFrames) {
            message.params.callFrames.forEach(function(frame, index) {
                if (frame.functionName && !internalFunctions.includes(frame.functionName)) {
                    console.log('[関数 ' + index + '] ' + frame.functionName);
                    if (frame.scopeChain) {
                        frame.scopeChain.forEach(function(scope) {
                            if (scope.type === 'local' || scope.type === 'block' || scope.type === 'closure') {
                                getVariableValues(scope.object.objectId, scope.type);
                            }
                        });
                    }
                }
            });
        }
    }
    
    // デバッガーが再開したとき
    if (message.method === 'Debugger.resumed') {
        isPaused = false;
    }
});

ws.on('error', function(error) {
    console.error('WebSocket エラー:', error.message);
});

ws.on('close', function() {
    console.log('WebSocket 接続が閉じられました');
    process.exit(0);
});

EOF

WS_PID=$!

# 監視継続
echo "📊 監視中... (Ctrl+C で終了)"
wait
