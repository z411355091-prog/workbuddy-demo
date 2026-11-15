# ghdl.sh 使用说明

GitHub 在国内直连不稳定时，用这个脚本可以依赖镜像把仓库拉下来。

## 基本用法

```bash
bash ghdl.sh <owner/repo>            # 下载默认分支并自动解压
bash ghdl.sh <owner/repo> main        # 指定分支
bash ghdl.sh <owner/repo> clone       # 改用 git clone --depth 1
bash ghdl.sh <owner/repo> main ./out  # 指定输出目录
```

## 支持的输入形式

脚本接受以下几种写法，内部会统一解析成 `owner/repo`：

- `torvalds/linux`
- `https://github.com/torvalds/linux`
- `https://github.com/torvalds/linux/tree/master`
- `github.com/torvalds/linux.git`

## 镜像策略

依次尝试以下镜像，前一个失败自动切换：

1. `https://gh-proxy.com/`
2. `https://ghfast.top/`
3. `https://ghproxy.net/`

## 注意

- 镜像只代理**文件下载**（archive / raw / clone），不支持登录、OAuth 授权、Issue 等交互功能。
- 仓库体积很大时（数百 MB 以上），镜像可能限速，建议配置代理后直连。
- 公开仓库无需登录即可下载。
