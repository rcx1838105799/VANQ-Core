# VANQ Core 正式签名配置指南

当前所有 APK 均为 debug 签名测试包。配好下面 5 个 Secrets 后，tag 构建产出的 release APK
即为正式签名包（不再带 `.dev` 后缀）。

## 一、需要配置的 5 个 Secrets

仓库路径：GitHub → `rcx1838105799/VANQ-Core` → Settings → Secrets and variables →
Actions → New repository secret，逐个新建：

| Secret 名 | 内容 |
|---|---|
| `KEYSTORE` | 签名 keystore 文件的 base64 文本（见第二节） |
| `KEY_ALIAS` | keystore 里的 key 别名，例如 `vanq` |
| `STORE_PASSWORD` | keystore 文件密码 |
| `KEY_PASSWORD` | key 密码（可与 store 密码相同） |
| `SERVICE_JSON` | Firebase 的 `google-services.json` 文件 base64 文本；不用 Firebase 可留空，构建会用自带 stub |

## 二、生成 keystore

在一台可信机器上执行（不要在公开机器或聊天记录里贴密码）：

```sh
keytool -genkeypair -v \
  -keystore vanq-release.jks \
  -alias vanq -keyalg RSA -keysize 2048 -validity 10000
```

按提示设好 store 密码与 key 密码，并记下来。随后转 base64：

```sh
# Linux
base64 -w0 vanq-release.jks
# macOS
base64 -i vanq-release.jks
```

把输出的整段 base64 文本贴进 `KEYSTORE`；`KEY_ALIAS` 填 `vanq`；两个密码分别填进
`STORE_PASSWORD` 与 `KEY_PASSWORD`。

`SERVICE_JSON` 同理：取 Firebase 控制台里包名 `com.vanq.core` 的
`google-services.json`，整文件转 base64 后贴入；不用 Firebase 则不建这个 Secret。

## 三、构建时如何使用

`.github/workflows/build.yaml` 的 `Setup Android Signing` 步骤（仅 Android 平台）会在
Secrets 非空时：

1. 把 `KEYSTORE` base64 解码写成 `android/app/keystore.jks`；
2. 把 `KEY_ALIAS` / `STORE_PASSWORD` / `KEY_PASSWORD` 追加进
   `android/local.properties`；
3. 把 `SERVICE_JSON` base64 解码写成 `android/app/google-services.json`。

`android/app/build.gradle.kts` 检测到 release 签名配置后，release 包即用该证书签名；
Secrets 为空时自动回退 debug 签名并加 `.dev` 后缀，不会报错中断。

## 四、注意事项

- keystore 与密码绝不要提交进仓库、不要贴进聊天记录，只能走 Secrets。
- keystore 一旦丢失，已安装的正式包将无法用同一签名升级，务必离线备份
  `vanq-release.jks` 与密码。
- 配好后打一个新 tag 即可验证：release 产物应为正式签名包，可用
  `apksigner verify --print-certs` 核对证书指纹。
- 本仓库的 workflow 文件只能由仓库所有者在 GitHub 网页端修改，本文档只说明
  Secrets 配置，不涉及 workflow 改动。
