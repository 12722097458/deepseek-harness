# Agent Note: 提供带提示的跨平台 Web 启动脚本

Status: implemented

[English](2026-09-03-powershell-web-launcher.md) | 中文

## 问题

`pnpm dsh web` 需要已生成的包和前端产物，但源码 checkout 没有说明应执行哪些构建步骤，也没有说明应打开哪个带 token 的地址。

Windows 和 macOS/Linux 用户在跳过构建或指定非法端口时，也需要清晰的恢复提示。

## 决策

`deploy/start-web.ps1` 从仓库根目录运行，检查 `pnpm`，默认构建完整产物树，然后在 `127.0.0.1` 上启动 `pnpm dsh web --no-open`。

`deploy/start-web.bat` 委托 PowerShell，支持双击和命令提示符启动。`deploy/start-web.sh` 为 macOS/Linux 提供相同流程，并通过 `open` 或 `xdg-open` 支持自动打开浏览器。

启动器为跳过构建模式校验必需的哨兵产物，支持端口和浏览器选项，并打印完整的带 token 地址，明确提示应在浏览器中打开。

README 双语文档记录各平台启动命令和选项；测试验证启动器文件均存在，并验证 Windows 启动器会在构建或启动服务器前拒绝非法端口。

## 备选方案

**只保留手动构建和启动命令。** 不采用，因为缺少产物会在运行时晚一步失败，且没有引导式恢复路径。

**让 `dsh web` 直接打开浏览器。** 不采用，因为启动脚本需要稳定展示带 token 的地址，并支持无法交接浏览器的终端环境。

**启动后台服务器并立即返回。** 不采用，因为用户需要在同一终端查看服务器日志并用 `Ctrl+C` 管理生命周期。

## 影响

Windows、macOS 和 Linux 贡献者现在都有文档化命令准备产物、启动服务器，并获得应在浏览器打开的准确地址。

`-SkipBuild` 只信任三个哨兵文件，不保证每个 bundle 都是最新版本；源码或依赖变化后应省略该选项。
