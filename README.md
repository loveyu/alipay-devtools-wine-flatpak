# 支付宝小程序开发者工具 Wine/Flatpak 兼容层

在 Debian/KDE Wayland 主机上，以用户级 Flatpak 运行 Windows 版支付宝小程序开发者工具。
默认与企业微信、微信开发者工具共用 `io.github.loveyu.Wine.Deepin` 基础包中的
Deepin Wine 10.14deepin11、配套 adapter DLL、wineserver 和 Portal 模块。三个应用的
Wine 前缀、账号、进程、日志和工作区分别隔离，不向宿主机散装 Win32 依赖。

## 共享基础包与默认入口

基础包引用为 `runtime/io.github.loveyu.Wine.Deepin/x86_64/10.14deepin11-25.08`，
支付宝应用层为 `io.github.loveyu.AlipayDevToolsWine//stable-25.08`。
应用层通过 `/app/shared-wine` 挂载基础包，只安装链接、启动 wrapper、host-open
及 Portal 测试程序；不再复制 Wine 引擎，也不要求安装企业微信应用。

首次使用时，先在相邻的 `wecom-wine-flatpak` 仓库运行 `make shared-wine-runtime`，
或者安装该仓库完整构建生成的基础包。然后在本仓库运行：

```bash
make build-deepin-runner
make migrate-to-deepin   # 已有 Staging 安装时使用；复制前缀并保留原环境
# 全新环境使用 make install，替代 migrate-to-deepin
make run
make status
make stop
```

迁移会只停止支付宝实例，在持有新旧前缀的启动与安装锁时复制数据，再由 Wine 10
更新 builtin DLL；拒绝覆盖已有非空目标。旧 Staging 前缀保留，回退时先 `make stop`，
再使用 `make staging-run`。未迁移的旧工作区仍保留在原路径，不删除业务文件。
`make enable-service`、`make open-sample` 和 `make test-portal` 均使用默认共享底层。

Deepin 默认附加 `--no-sandbox --use-angle=d3d11`，允许显式传入 ANGLE/GL 参数；
外层 Flatpak 隔离仍生效。软件渲染设置仍由 `ALIPAY_DEVTOOLS_DISABLE_GPU` 控制。
共享基础包主要节省磁盘、下载和维护成本；不会让多个应用共用一个进程或前缀，
不能据此宣称 CPU 或应用私有内存下降。

2026-10-19 在共享 Deepin Wine 下验证支付宝 3.10.5（Electron 28.3.3-mini.2 /
Chromium 120.0.6099.291）：欢迎页、样例工程文件树、编译和 iPhone 13 模拟器均正常显示，
`service-host` 返回 ready，150% 缩放正常。缺少 Windows 常见字体时，私用区字符布局会进入
Chromium 字体回退断言，使渲染进程退出并留下空白框架；基础包现直接内置常用中西文字体及
符号回退，无需修改支付宝程序或混入其他 Wine 引擎。构建前需准备本机 Windows 字体目录，
详见企业微信仓库的 `SHARED_WINE_WINDOWS_FONTS` 配置。

`make test-fonts` 使用支付宝自带 Electron 和独立测试前缀，覆盖拉丁文、中文、emoji 和
私用区字符的实际布局；不读取业务资源或账号。欢迎页 120 秒采样的 PSS 为 680～685 MiB，
CPU 中位数约单核 7.1%、最高 9.5%，应用自身 swap 为 0；同机此前 Staging 欢迎页约
3249～3375 MiB。该结果只代表本机此次引擎及字体配置，不能单独归因于基础包共享。
样例编辑器、模拟器及欢迎页同时打开时，另一次 120 秒采样的 PSS 为 1964～2056 MiB，
CPU 中位数约单核 17.1%、最高 28.6%，自身 swap 仍为 0。

## 历史 Staging 验证

方案 1 已达到“登录、配置和预览可用”的阶段。历史基线 Wine 11.0 会卡在工作台
骨架屏；应用同版本 Wine Staging 补丁集并改用 Wine new WoW64 架构后，3.10.5
工作台、项目窗口和模拟器均能完整渲染。2026-09-09 已将本机构建基线更新到
Wine/Wine Staging 11.17，并完成源码构建、静默安装和 GUI 启动；主窗口、后台服务窗口
及扩展进程均已创建，`/service/v1/ready` 返回成功。11.17 的 GPU 合成路径会黑屏，
已默认切换为软件渲染。文件选择、保存和目录选择已接入 XDG Desktop Portal，文件定位
和普通文档打开也会转交宿主环境。登录、项目编译和模拟器等完整回归仍沿用下表的
11.0 Staging 结果，尚未在 11.17 上重新确认。

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

2026-09-09 在 Wine 11.17 上完成 Portal 专项验收：Win32 A/W、`IFileDialog`、
`SHBrowseForFolderW` 和 hook 回退共捕获 `OpenFile=5`、`SaveFile=3`；开发者工具的
“打开项目”实测发出 `directory=true` 的系统文件夹选择请求。

## 项目状态与运行依赖

这是社区兼容层，不是支付宝官方 Linux 客户端。当前默认路径是共享 Deepin Wine；
Wine Staging new WoW64 保留用于回退和对照回归，历史普通 Wine 基线需显式设置
`ALIPAY_DEVTOOLS_RUNNER_VARIANT=baseline`。

验证环境为 Debian 13、KDE Plasma 6 Wayland/XWayland 和 Fcitx5。首次构建需要
用户级 Flatpak、`bash`、`curl`、常用校验工具和 Freedesktop SDK 25.08 的 mingw-w64
扩展；共享底层由企业微信仓库构建。Staging 源码构建另需 `patch`、`tar` 和编译磁盘空间。
宿主机不需要安装 Wine 或启用 Debian i386 架构。构建和运行均位于用户目录，现有
企业微信和微信开发者工具的 Wine 前缀不会被复用。

## 固定版本与架构

- 支付宝小程序开发者工具：`3.10.5` Windows x64
- 官方下载域名：`alipay-miniapp-public.oss-cn-hangzhou.aliyuncs.com`
- 安装包 SHA-256：`06a877523b55b2688c0aec20062c1f2288fa7187aad66d6b6585721270553f7a`
- 默认 Wine：`10.14deepin11`，共享基础包分支 `10.14deepin11-25.08`
- 默认 Flatpak：`io.github.loveyu.AlipayDevToolsWine//stable-25.08`
- 回退 Wine/Staging：`11.17` / `v11.17`，提交 `83acf91a00c7db33ac85a704293159fb47aaed24`
- 回退 Flatpak：`io.github.loveyu.AlipayDevToolsWine//staging-25.08`
- Runtime/SDK：Freedesktop `25.08`

构建时显式使用 `--without-opencl`。Freedesktop SDK 25.08 未提供 OpenCL
头文件，而支付宝开发者工具无需该接口；此设置避免 Wine 仅检测到加载库后误启用
OpenCL，同时不向宿主机额外安装开发包。构建脚本使用配置签名检测参数变化，已有
构建目录也会自动重新运行 `configure`，无需手动删除缓存。

Wine 11.17 下 Chromium GPU 进程会报告 `CreateCommandBuffer` 失败并导致主窗口黑屏。
`make staging-enable-service` 默认写入 `"disable-gpu": true`，由 SwiftShader/软件合成
完成界面渲染；如后续版本修复，可用 `ALIPAY_DEVTOOLS_DISABLE_GPU=0` 显式回归硬件加速。

Staging runner 使用 `--enable-archs=i386,x86_64` 构建 new WoW64：Windows PE 侧
包含 i386 和 x86-64，Unix 侧只有 x86-64，因此不需要在宿主机安装 32 位 Wine/Win32
包，也不挂载 `org.freedesktop.Platform.Compat.i386`。Flatpak 的 `multiarch` 权限仅用于
放行执行 32 位 PE 代码所需的系统调用。

仓库不提交或再分发支付宝安装包、Wine 前缀、登录数据和构建产物。`flatpak/` 中的清单
用于 Staging 版本审计；共享应用层入口是 `scripts/build-deepin-runner.sh`，
回退 runner 入口是 `scripts/build-staging-runner.sh`。

## Staging 构建与回退

首次构建会下载 Wine 源码、Staging 补丁和 Freedesktop SDK，并在用户目录中编译：

```bash
make check
make build-staging-runner
make staging-test-portal
make staging-install
make install-user-integration
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
3. `make staging-test-portal` 用隔离前缀验证打开、保存和目录选择 Portal。
4. `make staging-install` 从支付宝官方渠道下载、校验并安装固定版本，同时创建
   KDE/GNOME 启动菜单和用户级应用图标。
5. `make install-user-integration` 可单独修复或刷新启动菜单，不重装开发者工具。
6. `make staging-enable-service` 启用工具自带的本地 service-host。
7. `make staging-run` 启动 GUI，再用 `make staging-open-sample` 导入无敏感数据的
   最小样例。
8. `make staging-status` 查看实例与日志；结束时使用 `make staging-stop`。

Wine 11.17 与 Staging v11.17 的校验后源码归档默认复用
`/data/code/wine/source-cache/`；可用 `WINE_SOURCE_CACHE_DIR` 覆盖位置。该本机缓存不会
进入 Git、Flatpak 或发布包。

升级 Wine、Staging 或开发者工具时，不应以版本号白名单阻止安装，但必须更新摘要
记录并重新验证工作台、模拟器、Fcitx5、缩放、登录态、真实 AppID 预览和上传路径。
若新版已经合入所需修复，应移除或跳过对应补丁，真实冲突必须显式失败。

结束本项目实例：

```bash
make staging-stop
```

`staging-open-sample` 调用开发工具内置的本地 HTTP service-host，不依赖鼠标操作文件
对话框。普通 `make install/run/open-sample/status` 和菜单入口均使用共享 Deepin Wine。

## 启动菜单

`make install` 或 `make migrate-to-deepin` 会安装“支付宝小程序开发者工具（Wine）”菜单项；也可运行
`make install-user-integration` 单独刷新。桌面入口位于
`~/.local/share/applications/io.github.loveyu.AlipayDevToolsWine.desktop`，启动器位于
`~/.local/bin/alipay-devtools-wine`。图标从已经校验并安装的支付宝官方 EXE 提取，只
写入用户图标目录，不提交到仓库或打包进 Flatpak。菜单默认使用共享 Deepin 环境，
并启用 service-host/软件渲染；重复点击只激活已有窗口，不启动第二个 Wine 实例。

启动器会在每次启动时读取 `Xft.dpi`，无法取得时再读取 KScreen 主输出倍率，并同时设置
Wine DPI 与 Electron 设备缩放倍率。当前 KDE 150% 对应 144 DPI 和 1.5 倍 renderer。
可用 `ALIPAY_DEVTOOLS_SCALE_FACTOR=1.25 make staging-run` 临时覆盖，也可用两个开发工具
共用的 `DEVTOOLS_SCALE_FACTOR`。Wine/XWayland 使用进程级全局 DPI，修改系统缩放后需要
重启开发工具，暂不支持窗口跨不同缩放倍率显示器时动态切换。

## 文件与目录打开

标准打开、保存和目录选择对话框通过 XDG Desktop Portal 进入宿主系统；
`explorer.exe /select` 通过 `org.freedesktop.FileManager1.ShowItems` 在文件管理器中定位，
普通文档和媒体文件则由 `winebrowser` 交给宿主默认应用。可执行文件和脚本不接管，仍由
Wine 自身处理。

仓库和 Flatpak 清单不会声明整个 `/data`。需要访问该目录的机器应单独授权：

```bash
flatpak override --user --filesystem=/data io.github.loveyu.AlipayDevToolsWine
```

这是本机用户级 override，不会进入 runner、安装包或发布产物。移除授权可执行
`flatpak override --user --nofilesystem=/data io.github.loveyu.AlipayDevToolsWine`。

## 隔离目录

默认共享方案的持久数据位于：

- `~/.local/share/alipay-devtools-wine-flatpak-deepin/`：Wine 前缀、工作区、本地应用层仓库；
- `~/.local/state/alipay-devtools-wine-flatpak-deepin/`：状态、实例 ID 和日志；
- `~/.cache/alipay-devtools-wine-flatpak-deepin/`：安装包和应用层构建缓存。

Staging 回退方案保留原有路径：

- `~/.local/share/alipay-devtools-wine-flatpak-staging/`：Wine 前缀、工作区、本地 Flatpak 仓库；
- `~/.local/state/alipay-devtools-wine-flatpak-staging/`：状态、PID 和日志；
- `~/.cache/alipay-devtools-wine-flatpak-staging/`：安装包、源码和编译缓存；
- Flatpak 用户安装：`~/.local/share/flatpak/app/io.github.loveyu.AlipayDevToolsWine/`。

上述目录与其他应用完全分离。停止脚本校验记录的 instance 属于支付宝 App ID，
并收拢本项目独占 App ID 的 Deepin/Staging 残留，不停止企业微信或微信开发者工具。

## 已知边界与下一步

1. 验证调试器、Console、断点和修改文件后的热更新。
2. 验证上传流程、冷启动、登录态持久化和 Flatpak 更新后的回归。
3. 为 Flatpak 应用补齐 desktop 文件、图标和元信息，再生成稳定分发包。

如果后续发现特定 Windows API 缺失，优先把补丁和运行库固化到独立 runner，而不是
在宿主系统全局安装大量 Win32 包。

## 状态恢复与公开发布边界

发生启动或渲染异常时，先运行 `make status` 保存不含账号数据的状态摘要，
再用 `make stop` 精确停止本项目实例。Wine 前缀和工作区是持久数据，普通
停止不会删除；需要重新验证干净前缀时应另建测试目录，不直接覆盖现有登录数据。

公开仓库和 Release 不包含支付宝安装包、解包资源、Wine 前缀、登录凭据、二维码、
真实 AppID、应用列表、业务源码、运行日志或构建缓存。仓库自带 fixture 仅用于无
敏感数据的编译和模拟器验证。支付宝开发者工具及其资源仍是专有软件；用户机器从
官方渠道取得并校验，公开兼容脚本不代表获得重新分发其二进制的授权。
