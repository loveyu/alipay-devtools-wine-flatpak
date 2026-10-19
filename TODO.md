# 支付宝小程序开发者工具 Wine 验收 TODO

## 已完成

- [x] 应用层接入与企业微信、微信开发者工具相同的共享 Deepin Wine 10.14deepin11 基础包。
- [x] 默认命令和菜单使用 Deepin，Staging/基线前缀隔离并保留回退。
- [x] 增加前缀复制迁移、拒绝覆盖、幂等和跨应用停止隔离测试。
- [x] 共享底层补充常用字体，修复 Electron 28 私用区字符布局导致的空白框架。
- [x] 在共享 Deepin Wine 下验证欢迎页、样例工程编译、文件树和 iPhone 13 模拟器。
- [x] 增加独立 Electron 字体布局探针，并完成可用欢迎页的 CPU/PSS 采样。
- [x] 建立独立项目、缓存、状态、工作区和 Wine 前缀。
- [x] 固定支付宝开发者工具 3.10.5 官方下载地址与 SHA-256。
- [x] 验证基线 Wine 11.0 与 3.8.21/3.10.5 均阻塞在工作台骨架屏。
- [x] 构建 Wine 11.0 + Wine Staging v11.0 用户级 Flatpak runner。
- [x] 构建 Wine 11.17 + Wine Staging v11.17 runner，并以软件渲染验证启动和 service-host。
- [x] 接入 XDG Desktop Portal，覆盖 Win32 A/W、IFileDialog、SHBrowseForFolderW 和 hook 路径。
- [x] 实测“打开项目”调用系统文件夹选择器，Portal 计数为 OpenFile=5、SaveFile=3。
- [x] 将 explorer 选中文件和普通文档打开转交宿主 FileManager1/winebrowser。
- [x] `/data` 仅使用本机 Flatpak override 授权，不写入清单或发布包。
- [x] 使用 new WoW64：i386/x86-64 Windows PE，纯 x86-64 Unix 侧。
- [x] 不安装宿主机 32 位 Wine 包，不依赖 Compat.i386 Flatpak 扩展。
- [x] 在独立 Staging 前缀中校验并静默安装开发者工具 3.10.5。
- [x] 启用内置 service-host，并验证 `/service/v1/ready`。
- [x] 完整渲染欢迎页和项目设置页面。
- [x] 通过 service-host 导入 `wine-flatpak-smoke` 最小样例项目。
- [x] 编译样例并在 iPhone 13 模拟器中渲染页面。
- [x] 验证中文字体和 Fcitx5 拼音输入，输入框与数据绑定正常。
- [x] 扫码登录，验证 `checkLogin`、账号资料和应用列表接口成功。
- [x] 选择真实应用，进入项目详情并读取真实 AppID 和线上配置。
- [x] 使用真实 AppID 完成预览构建，服务端返回成功并生成预览二维码。
- [x] 跟随系统 150% 缩放，同时设置 Wine 144 DPI 和 Electron 1.5 倍缩放。
- [x] 确认 Staging 实例与企业微信 Flatpak/Wine 实例相互隔离。
- [x] 验证项目自身实例可用 `staging-stop` 定向停止。

## 待完成

- [ ] 在共享 Deepin Wine 上重新验证扫码登录、输入法和真实 AppID 预览。
- [ ] 验证调试器、Console、断点、文件保存及热更新。
- [ ] 验证上传流程。
- [ ] 验证重启后的登录态、最近项目和设置持久化。
- [x] 补齐 KDE/GNOME desktop 菜单、官方程序图标和已有实例激活逻辑。
- [ ] 补齐 Flatpak AppStream 元信息及稳定升级路径。
- [ ] 清理实验构建备份并形成可复现的发布构建产物。

## 已确认的关键兼容条件

- 基线 Wine 11.0 能安装、启动和创建工程窗口，但 Workbench/Project 状态不推进。
- 共享 Deepin Wine 10.14 下缺少 Windows 常见字体时，Electron 28 在私用区字符布局中
  触发字体回退断言；将常用中西文字体和符号字体加入基础包后，欢迎页和样例模拟器正常。
- 单独切换 GPU/软件渲染、工具版本或补装通用运行库不能解除骨架屏阻塞。
- Wine Staging v11.0 补丁集配合 Wine 11 new WoW64 能解除工作台阻塞。
- Freedesktop SDK 25.08 缺少 OpenCL 头文件；构建 Wine 11.17 时必须使用
  `--without-opencl`，构建脚本通过配置签名自动触发重新配置。
- Wine 11.17 的 Chromium GPU 合成路径会黑屏并报告 `CreateCommandBuffer` 失败；
  默认设置 `"disable-gpu": true` 后主窗口可正常进入软件渲染路径。
- `--allow=multiarch` 是 Flatpak seccomp 兼容要求，不代表安装 i386 Unix runtime。
- 会议摄像头和屏幕共享不属于本项目范围。
