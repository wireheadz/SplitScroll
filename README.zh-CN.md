# SplitScroll

[English](README.md) | [简体中文](README.zh-CN.md)

触控板自然滚动，鼠标传统滚动。在 macOS 菜单栏中，为每个设备分别设置垂直和水平滚动方向。

需要 **macOS 13 或更新版本**。设置保存在本机，不收集使用数据、不发送网络请求，也不记录输入操作。

## 安装

如需自行构建，请安装带有 Swift 5.9 或更新版本的 Xcode，然后运行：

```sh
git clone https://github.com/wireheadz/SplitScroll.git
cd SplitScroll
bash scripts/build-app.sh
open dist
```

将 **SplitScroll.app** 移到 **应用程序（Applications）** 文件夹后打开。当前构建未经 Apple 公证，生成的应用适用于构建时所用 Mac 的处理器架构。

## 设置与使用

1. 保持 **系统设置 → 触控板 → 滚动与缩放 → 自然滚动** 开启。
2. 在 SplitScroll 中点击 **Allow Accessibility**，然后前往 **系统设置 → 隐私与安全性 → 辅助功能**，启用 SplitScroll。如果列表中没有该应用，点击 **+** 添加。
3. 在 **Devices** 中选择设备，分别设置 **Reverse vertical scrolling**（反转垂直滚动）和 **Reverse horizontal scrolling**（反转水平滚动）。默认反转鼠标滚动方向，触控板保持不变。

点击菜单栏图标可修改设置。关闭 **Enable** 可暂停滚动调整，选择 **Quit** 可退出应用。需要开机自动运行时，可开启 **Launch at login**。如果隐藏了菜单栏图标，从 Finder 或 Spotlight 重新打开 SplitScroll 即可进入设置。

## 常见问题

- **滚动方向没有变化：** 检查 Enable 和辅助功能权限，然后退出并重新打开应用。
- **无法识别鼠标：** 尝试调整 **Other mouse wheels**。部分接收器连接的多个设备会共用一份设置。
- **重新连接后设置重置：** 缺少稳定设备标识的鼠标或触控板可能需要重新设置。

请避免同时运行其他滚动方向调整工具。兼容性可能因设备和 macOS 版本而异。

如需[反馈问题](https://github.com/wireheadz/SplitScroll/issues)，请提供 macOS 版本、设备型号和连接方式。

## 卸载

关闭 **Launch at login**，退出 SplitScroll，再将应用移到废纸篓。
