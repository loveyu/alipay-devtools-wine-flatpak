const { app, BrowserWindow } = require('electron');

app.commandLine.appendSwitch('no-sandbox');
app.commandLine.appendSwitch('use-angle', 'd3d11');
app.disableHardwareAcceleration();
app.setPath('userData', 'C:\\font-smoke-profile');
app.on('render-process-gone', () => app.exit(1));

const samples = [
    ['latin', 'Wine font smoke'],
    ['cjk', '\u652f\u4ed8\u5b9d\u4e2d\u6587'],
    ['emoji', '\u263a \ud83d\ude00'],
    ['private-use', '\ue001 \ueabc'],
];

app.whenReady().then(async () => {
    const win = new BrowserWindow({
        width: 480,
        height: 240,
        webPreferences: { sandbox: false },
    });
    await win.loadURL('data:text/html;charset=UTF-8,<div id="probe"></div>');
    for (const [name, text] of samples) {
        console.log(`FONT_BEGIN ${name}`);
        // 强制布局并等待一次绘制，避免 loadURL 成功掩盖字体回退崩溃。
        await win.webContents.executeJavaScript(
            `document.body.style.fontFamily='Arial';` +
            `document.getElementById('probe').textContent=${JSON.stringify(text)};` +
            'document.body.offsetHeight'
        );
        await new Promise(resolve => setTimeout(resolve, 300));
        const actual = await win.webContents.executeJavaScript('document.body.innerText');
        if (actual !== text) throw new Error(`FONT_TEXT_MISMATCH ${name}`);
        console.log(`FONT_OK ${name}`);
    }
    console.log('FONT_ALL_OK');
    app.exit(0);
}).catch(error => {
    console.error(error.message);
    app.exit(1);
});
setTimeout(() => app.exit(2), 20000);
