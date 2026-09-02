# 支付宝小程序开发者工具 Wine 验收 TODO

## 已完成

- [x] 建立独立项目、缓存、状态、工作区和 Wine 前缀。
- [x] 固定支付宝开发者工具 3.10.5 官方下载地址与 SHA-256。
- [x] 验证基线 Wine 11.0 与 3.8.21/3.10.5 均阻塞在工作台骨架屏。
- [x] 构建 Wine 11.0 + Wine Staging v11.0 用户级 Flatpak runner。
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

- [ ] 验证调试器、Console、断点、文件保存及热更新。
- [ ] 接入并验收 `xdg-desktop-portal` 系统文件选择和保存对话框。
- [ ] 验证上传流程。
- [ ] 验证重启后的登录态、最近项目和设置持久化。
- [ ] 为 Flatpak 应用补齐 desktop 文件、图标、元信息及稳定升级路径。
- [ ] 清理实验构建备份并形成可复现的发布构建产物。

## 已确认的关键兼容条件

- 基线 Wine 11.0 能安装、启动和创建工程窗口，但 Workbench/Project 状态不推进。
- 单独切换 GPU/软件渲染、工具版本或补装通用运行库不能解除骨架屏阻塞。
- Wine Staging v11.0 补丁集配合 Wine 11 new WoW64 能解除工作台阻塞。
- `--allow=multiarch` 是 Flatpak seccomp 兼容要求，不代表安装 i386 Unix runtime。
- 会议摄像头和屏幕共享不属于本项目范围。
