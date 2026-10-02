#!/bin/bash
# PreToolUse hook (matcher: Bash)
# 输入通过 stdin 传入 JSON，用 jq 解析 Bash 工具的 command 字段。
# 命中高危指令时 exit 2 —— 这是唯一能真正阻断工具执行、并把 stderr 回喂给模型的退出码。（固定写法）
# （对照实验：把下面的 exit 2 改成 exit 1，被拦指令会照常执行，用来验证两者区别。）

CMD=$(jq -r '.tool_input.command // empty')

if echo "$CMD" | grep -Eq "rm -rf /|rm -rf ~|git push .*(-f|--force)|DROP DATABASE|:\(\)\{"; then
  echo "❌ [安全拦截] 检测到高危指令: '$CMD'，执行已被强制中止！" >&2
  exit 2
fi

exit 0
