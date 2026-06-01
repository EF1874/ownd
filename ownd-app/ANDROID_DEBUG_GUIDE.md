# Android 真机调试指南

## 前置条件检查

### 1. 检查 Android SDK 是否安装
运行以下命令检查 Flutter 环境：
```bash
flutter doctor -v
```

查看输出中的 `Android toolchain` 部分：
- ✅ 如果显示绿色勾号，说明 Android SDK 已安装
- ❌ 如果显示红叉或感叹号，需要安装 Android SDK

### 2. 安装 Android SDK（如果未安装）

**方法 1：通过 Android Studio**
1. 下载并安装 [Android Studio](https://developer.android.com/studio)
2. 打开 Android Studio
3. 进入 `Tools` → `SDK Manager`
4. 安装以下组件：
   - Android SDK Platform (API 33 或更高)
   - Android SDK Build-Tools
   - Android SDK Command-line Tools
   - Android SDK Platform-Tools

**方法 2：使用 Flutter 自动安装**
```bash
flutter doctor --android-licenses
```
按提示接受所有许可协议。

## 连接 Android 设备

### 1. 手机端设置
1. 打开 **设置** → **关于手机**
2. 连续点击 **版本号** 7 次，启用开发者选项
3. 返回设置，进入 **系统** → **开发者选项**
4. 开启以下选项：
   - ✅ **USB 调试**
   - ✅ **USB 安装**（部分手机有此选项）
   - ✅ **USB 调试（安全设置）**（部分手机有此选项）

### 2. 连接电脑
1. 使用 **原装数据线** 连接手机到电脑
2. 手机上选择 **文件传输 (MTP)** 或 **传输文件** 模式
3. 允许 USB 调试授权（勾选"始终允许"）

### 3. 验证连接
```bash
# 检查 ADB 是否识别设备
adb devices

# 应该看到类似输出：
# List of devices attached
# XXXXXXXX    device
```

如果显示 `unauthorized`，请在手机上重新授权 USB 调试。

### 4. 检查 Flutter 设备
```bash
flutter devices
```

应该能看到您的 Android 设备，例如：
```
Found 4 connected devices:
  SM G9810 (mobile) • XXXXXXXX • android-arm64 • Android 12 (API 31)
  Windows (desktop) • windows • windows-x64 • Microsoft Windows
  ...
```

## 运行应用

### 方法 1：自动选择设备
如果只连接了一台 Android 设备：
```bash
flutter run
```

### 方法 2：指定设备
```bash
# 列出所有设备
flutter devices

# 使用设备 ID 运行
flutter run -d <设备ID>

# 例如：
flutter run -d XXXXXXXX
```

### 方法 3：在 VS Code 中运行
1. 确保设备已连接
2. 点击右下角的设备选择器
3. 选择您的 Android 设备
4. 按 `F5` 或点击 `Run` → `Start Debugging`

## 常见问题排查

### 问题 1：`adb devices` 显示 `no permissions`
**解决方案（Windows）：**
1. 安装手机厂商的 USB 驱动
   - 小米：[小米驱动](https://www.mi.com/service/bijiben/drivers/)
   - 华为：[华为驱动](https://consumer.huawei.com/cn/support/hisuite/)
   - OPPO/vivo/一加：通常自动安装
2. 重启 ADB 服务：
   ```bash
   adb kill-server
   adb start-server
   ```

### 问题 2：设备显示 `offline`
```bash
adb kill-server
adb start-server
adb devices
```

### 问题 3：Flutter 无法识别设备
1. 确保 Android SDK 已正确安装
2. 检查环境变量 `ANDROID_HOME` 是否设置
3. 重启电脑和手机

### 问题 4：编译失败 - Gradle 错误
如果首次运行遇到 Gradle 下载慢的问题：
1. 等待 Gradle 自动下载（可能需要 10-30 分钟）
2. 或配置国内镜像（修改 `android/build.gradle`）

## 首次运行注意事项

首次在真机运行 Flutter 应用时：
- 需要下载 Gradle 和依赖（可能较慢）
- 需要编译 APK（约 2-5 分钟）
- 手机上会自动安装应用

## 快速测试命令

```bash
# 1. 检查 Flutter 环境
flutter doctor

# 2. 检查 ADB 连接
adb devices

# 3. 检查 Flutter 设备
flutter devices

# 4. 运行应用（调试模式）
flutter run

# 5. 运行应用（Release 模式，性能更好）
flutter run --release
```

## 性能优化建议

在真机上测试性能时，建议使用 **Profile** 或 **Release** 模式：
```bash
# Profile 模式（可以使用 DevTools 分析性能）
flutter run --profile

# Release 模式（最佳性能）
flutter run --release
```

Debug 模式会有额外的性能开销，不代表真实性能。
