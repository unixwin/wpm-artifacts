# wpm-artifacts

WinuxCmd WPM 自托管构件仓库:为"上游不稳定 / 直链被墙 / 无官方 Windows 构建"的包提供带 SHA-256 的可移植二进制,统一发布到本仓库 GitHub Releases,由 [wpm-source](https://github.com/unixwin/wpm-source) 索引引用。

## 发布约定

- 每个包一个 tag:`<pkg>-<version>`,如 `gawk-5.4.1`、`ncat-7.95`。
- Release 资产:
  - `<pkg>-<version>-win-x64.zip` — 可移植压缩包(exe + 所需 DLL)
  - `sha256.txt` — 全部资产的 SHA-256 清单
  - `size.txt` — 主构件字节数(供索引回填 size)
- 所有构建/镜像均由 `.github/workflows/` 自动完成,产物哈希记录在 release 内,入库前人工 review。

## 工作流

| Workflow | 策略 | 包 |
|---|---|---|
| `mirror-gawk.yml` | 镜像上游(ezwinports @ SourceForge) | gawk |
| `build-ncat.yml` | 从源码编译(MSYS2/MinGW) | ncat |
| `build-rust.yml` | 在 Windows runner 上用官方固定 toolchain 组装 portable bundle | rust |
| `build-openssl.yml` | 从固定版本 Windows installer 组装 portable bundle | openssl |

后续候选:`make`(ezwinports 镜像 + 捆绑 libintl/libiconv)、`socat`(MinGW 静态编译)。

## 已知注意事项

- ezwinports 的 `gawk-*-w32-bin.zip` 为 **32 位(x86)构建**,在 x64 Windows 上经 WOW64 运行正常;索引平台仍记为 `windows-x64`,但需在描述中注明。如需纯 x64,后续在 `build-gawk-src.yml` 用 MinGW 自建。
- SourceForge 直链对部分地区 IP 返回 403,GitHub Actions(美国节点)不受影响。

## repackage/

- `check-dll-deps.sh` — 用 `objdump -p` 遍历 exe 导入表,校验非系统 DLL 是否全部随包携带,防止 socat 式"缺 cygwin1.dll 无法启动"的包进入索引。
