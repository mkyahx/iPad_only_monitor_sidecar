# iPad Sidecar 自动连接项目完工总结

## 目标

将 Mac 上的 Sidecar/iPad 显示器连接流程自动化，并支持：

- 手动从终端运行。
- 从 iPad 快捷指令通过 SSH 触发。
- Mac 用户登录后自动运行。

## 交付文件

- `sidecar.applescript`
  - 打开「系统设置 > 显示器」。
  - 判断 iPad 是否已经连接。
  - 如果未连接，点击「添加」菜单。
  - 优先选择 `airplayvideo` 菜单项，也就是「镜像或扩展至 iPad」，避免误点「连接键盘和鼠标至 iPad」。

- `com.steven.sidecar.plist`
  - LaunchAgent 配置文件。
  - 已安装到 `/Users/steven/Library/LaunchAgents/com.steven.sidecar.plist`。
  - 当前配置为用户登录后等待 5 秒执行一次 Sidecar 脚本。

- `sidecar.launchd.log`
  - LaunchAgent 标准输出日志。

- `sidecar.launchd.err`
  - LaunchAgent 错误日志。
  - 里面可能保留早期调试时的旧错误，不代表当前最终状态。

## 手动运行

```bash
/usr/bin/osascript /Users/steven/tools/sidecar.applescript
```

也可以指定设备名：

```bash
/usr/bin/osascript /Users/steven/tools/sidecar.applescript "iPad"
```

## iPad 快捷指令 SSH 运行

在 iPad「快捷指令」中使用「通过 SSH 运行脚本」，脚本内容：

```bash
/bin/launchctl asuser 501 /usr/bin/osascript /Users/steven/tools/sidecar.applescript
```

如果用户 ID 变化，可在 Mac 上运行：

```bash
id -u steven
```

并替换命令中的 `501`。

## 自动运行

自动运行由 LaunchAgent 负责。它不是无人登录的开机后台任务，而是 `steven` 用户登录图形界面后自动运行。

当前 LaunchAgent 执行命令：

```bash
sleep 5; /usr/bin/osascript /Users/steven/tools/sidecar.applescript
```

查看状态：

```bash
launchctl print gui/501/com.steven.sidecar
```

手动触发：

```bash
launchctl kickstart -k gui/501/com.steven.sidecar
```

卸载自动运行：

```bash
launchctl bootout gui/501 /Users/steven/Library/LaunchAgents/com.steven.sidecar.plist
```

## 权限说明

脚本依赖 macOS 图形界面自动化，需要：

- 用户已登录到图形会话。
- 「系统设置」可被打开。
- 运行脚本的环境有辅助功能权限。

如果遇到权限问题，检查：

`系统设置 > 隐私与安全性 > 辅助功能`

可能需要允许 Terminal、Codex、osascript 或 sshd。

## 当前状态

- 当前 macOS 版本：macOS 26.3，Build 25D125。
- `sidecar.applescript.bak` 已删除。
- AppleScript 已修复并可编译。
- LaunchAgent 已安装。
- 登录后自动运行延迟已改为 5 秒。
