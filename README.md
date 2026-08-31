# OPPO / ColorOS 主题源码

Git 只跟踪可编辑源码；`.theme` 与 ZIP blob 在**构建 APK 前**由脚本生成，不提交到仓库。

## 目录说明

| 路径 | Git | 说明 |
|------|-----|------|
| `src/themeInfo.xml` | 提交 | 主题元信息 |
| `src/*_unpacked/` | 提交 | 可编辑资源（改这里） |
| `src/wallpaper` 等 blob | **忽略** | 由 `pack.ps1` 从 `_unpacked` 生成 |
| `app/.../assets/.../*.theme` | **忽略** | 构建时生成，打进 APK |
| `scripts/` | 提交 | 解压 / 打包脚本 |

## 日常修改

1. 编辑 `src/*_unpacked/` 或 `themeInfo.xml`
2. 构建 APK（Android Studio Run / `./gradlew assembleDevDebug`）  
   → 自动执行 `packOppoTheme`，生成 assets 里的 `.theme`
3. 或手动打包：

```powershell
.\themes\oppo\scripts\pack.ps1
```

## 首次导入新主题

```powershell
.\themes\oppo\scripts\unpack.ps1 -ThemeFile ".\path\to\your.theme"
```

解压后保留 `*_unpacked/` 与 `themeInfo.xml` 即可；blob 会在下次 `pack.ps1` 时重建。

## App 内下载

用户在 **设置 → 下载 OPPO 主题** 导出的是 `assets` 里构建生成的 `haifengchui2.theme`。

## 克隆仓库后

首次构建前若没有 `.theme`，Gradle `preBuild` 会跑 `pack.ps1`。需本机有 **PowerShell**（Windows 自带；macOS/Linux 可装 `pwsh`）。
