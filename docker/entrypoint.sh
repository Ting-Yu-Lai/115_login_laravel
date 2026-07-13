#!/bin/sh
set -e

# 本地開發階段先不做 config:cache/route:cache/view:cache——
# 那些是 production 部署優化（見 Laravel Deployment 文件 Optimization 段落），
# 開發階段做了反而會讓你改 .env、改路由時「怎麼改都沒生效」，先不做。

exec "$@"
