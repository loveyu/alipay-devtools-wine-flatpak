# 支付宝小程序开发者工具 Wine/Flatpak 兼容层

在 Debian/KDE Wayland 主机上，以用户级 Flatpak 封装 Wine Staging，运行 Windows
版支付宝小程序开发者工具。Wine 前缀、构建缓存、日志和工作区均独立，不复用企业微信
或微信开发者工具环境，也不向宿主机散装 Win32 依赖。

## 当前结论

方案 1 已达到“登录、配置和预览可用”的阶段。基线 Wine 11.0 会卡在工作台骨架屏；
应用 Wine Staging 11.0 补丁集，并改用 Wine 11 的 new WoW64 架构后，3.10.5 工作台、
项目窗口和模拟器均能完整渲染。

截至 2026-09-01 的实机结果：

| 验证项 | 基线 Wine 11.0 | Wine 11.0 Staging new WoW64 |
| --- | --- | --- |
| 官方安装包校验、静默安装 | 通过 | 通过 |
| 内置 `service-host` | 通过 | 通过 |
| 欢迎页完整渲染 | 失败：持续骨架屏 | 通过 |
| 导入本地样例工程 | 仅创建加载窗口 | 通过 |
| 编译及 iPhone 13 模拟器渲染 | 未进入 | 通过 |
| 设置页面 | 未进入 | 通过 |
| Fcitx5 拼音输入 | 未进入 | 通过，实测输入“测试” |
| 扫码登录 | 未进入 | 通过 |
| 账号资料及应用列表接口 | 未进入 | 通过 |
| 真实 AppID 项目设置 | 未进入 | 通过 |
| 真实 AppID 预览构建及二维码 | 未进入 | 通过 |
| 跟随系统显示缩放 | 未测试 | 通过：150% / Wine 144 DPI / Electron 1.5 |
| 上传 | 未测试 | 未测试 |
| 系统 portal 文件选择/保存 | 未测试 | 未集成 |

登录后客户端能取得账号资料和应用列表；仓库和文档不记录账号资料、二维码、登录凭据、
AppID 或应用名称。摄像头、会议和屏幕共享不属于本项目验收范围。

## 项目状态与运行依赖

这是社区兼容层，不是支付宝官方 Linux 客户端。当前推荐路径是 Wine Staging new
WoW64；保留普通 Wine 入口只是为了对照回归，不应把基线失败误判为安装失败。

验证环境为 Debian 13、KDE Plasma 6 Wayland/XWayland 和 Fcitx5。首次构建需要
用户级 Flatpak、`bash`、`curl`、`patch`、`tar`、常用校验工具以及足够的源码编译
磁盘空间；脚本会按需获取 Freedesktop SDK、Wine 官方源码和 Wine Staging 补丁。
宿主机不需要安装 Wine 或启用 Debian i386 架构。构建和运行均位于用户目录，现有
企业微信、微信开发者工具及其 Wine 前缀不会被复用。

## 固定版本与架构

- 支付宝小程序开发者工具：`3.10.5` Windows x64
- 官方下载域名：`alipay-miniapp-public.oss-cn-hangzhou.aliyuncs.com`
- 安装包 SHA-256：`06a877523b55b2688c0aec20062c1f2288fa7187aad66d6b6585721270553f7a`
- Wine：`11.0`
- Wine Staging：`v11.0`，提交 `6cc805ea57132eeaf44764e9213823c9b8d0d300`
- Flatpak：`io.github.huzhiyu.AlipayDevToolsWine//staging-25.08`
- Runtime/SDK：Freedesktop `25.08`

自定义 runner 使用 `--enable-archs=i386,x86_64` 构建 new WoW64：Windows PE 侧
包含 i386 和 x86-64，Unix 侧只有 x86-64，因此不需要在宿主机安装 32 位 Wine/Win32
包，也不挂载 `org.freedesktop.Platform.Compat.i386`。Flatpak 的 `multiarch` 权限仅用于
放行执行 32 位 PE 代码所需的系统调用。

仓库不提交或再分发支付宝安装包、Wine 前缀、登录数据和构建产物。`flatpak/` 中的清单
用于版本审计，权威的一键构建入口是 `scripts/build-staging-runner.sh`。

## 构建与使用

首次构建会下载 Wine 源码、Staging 补丁和 Freedesktop SDK，并在用户目录中编译：

```bash
make check
make build-staging-runner
make staging-install
make staging-enable-service
make staging-run
```

创建并打开仓库自带的最小样例项目：

```bash
make staging-open-sample
make staging-status
```

推荐顺序与各步骤含义：

1. `make check` 检查 shell 语法、仓库差异和安装包污染。
2. `make build-staging-runner` 下载、打补丁并构建独立 Flatpak runner。
3. `make staging-install` 从支付宝官方渠道下载、校验并安装固定版本。
4. `make staging-enable-service` 启用工具自带的本地 service-host。
5. `make staging-run` 启动 GUI，再用 `make staging-open-sample` 导入无敏感数据的
   最小样例。
6. `make staging-status` 查看实例与日志；结束时使用 `make staging-stop`。

升级 Wine、Staging 或开发者工具时，不应以版本号白名单阻止安装，但必须更新摘要
记录并重新验证工作台、模拟器、Fcitx5、缩放、登录态、真实 AppID 预览和上传路径。
若新版已经合入所需修复，应移除或跳过对应补丁，真实冲突必须显式失败。

结束本项目实例：

```bash
make staging-stop
```

`staging-open-sample` 调用开发工具内置的本地 HTTP service-host，不依赖鼠标操作文件
对话框。普通 `make install/run/open-sample/status` 仍指向原有基线 runner，用于兼容性
回归，不建议作为日常入口。

启动器会在每次启动时读取 `Xft.dpi`，无法取得时再读取 KScreen 主输出倍率，并同时设置
Wine DPI 与 Electron 设备缩放倍率。当前 KDE 150% 对应 144 DPI 和 1.5 倍 renderer。
可用 `ALIPAY_DEVTOOLS_SCALE_FACTOR=1.25 make staging-run` 临时覆盖，也可用两个开发工具
共用的 `DEVTOOLS_SCALE_FACTOR`。Wine/XWayland 使用进程级全局 DPI，修改系统缩放后需要
重启开发工具，暂不支持窗口跨不同缩放倍率显示器时动态切换。

## 隔离目录

Staging 方案的持久数据位于：

- `~/.local/share/alipay-devtools-wine-flatpak-staging/`：Wine 前缀、工作区、本地 Flatpak 仓库；
- `~/.local/state/alipay-devtools-wine-flatpak-staging/`：状态、PID 和日志；
- `~/.cache/alipay-devtools-wine-flatpak-staging/`：安装包、源码和编译缓存；
- Flatpak 用户安装：`~/.local/share/flatpak/app/io.github.huzhiyu.AlipayDevToolsWine/`。

上述目录与企业微信实例完全分离。停止脚本按项目记录的 Flatpak instance 处理，不通过
模糊进程名清理其他 Wine 应用。

## 已知边界与下一步

1. 验证调试器、Console、断点和修改文件后的热更新。
2. 将 Linux 系统文件选择/保存对话框接入 `xdg-desktop-portal`；当前打开样例使用
   service-host 绕过 Windows 文件对话框，尚未宣称 portal 已完成。
3. 验证上传流程、冷启动、登录态持久化和 Flatpak 更新后的回归。
4. 为 Flatpak 应用补齐 desktop 文件、图标和元信息，再生成稳定分发包。

如果后续发现特定 Windows API 缺失，优先把补丁和运行库固化到独立 runner，而不是
在宿主系统全局安装大量 Win32 包。

## 状态恢复与公开发布边界

发生启动或渲染异常时，先运行 `make staging-status` 保存不含账号数据的状态摘要，
再用 `make staging-stop` 精确停止本项目实例。Wine 前缀和工作区是持久数据，普通
停止不会删除；需要重新验证干净前缀时应另建测试目录，不直接覆盖现有登录数据。

公开仓库和 Release 不包含支付宝安装包、解包资源、Wine 前缀、登录凭据、二维码、
真实 AppID、应用列表、业务源码、运行日志或构建缓存。仓库自带 fixture 仅用于无
敏感数据的编译和模拟器验证。支付宝开发者工具及其资源仍是专有软件；用户机器从
官方渠道取得并校验，公开兼容脚本不代表获得重新分发其二进制的授权。
