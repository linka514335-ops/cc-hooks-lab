#!/bin/bash
# UserPromptSubmit hook
# 机制：本脚本 stdout 的内容会被 Claude Code 追加进本轮上下文（UserPromptSubmit / SessionStart 特有）。
# 作用：每次提交 prompt 前，把当前 git 分支注入上下文，并提示 Claude 动手前先与用户确认分支。
# 注意：非交互执行（无 TTY），这里不做弹窗，只做上下文注入；确认发生在对话里。

BRANCH=$(git branch --show-current 2>/dev/null)
# 注意：${BRANCH} 必须加花括号——变量后紧跟中文字符时，非 UTF-8 locale 下 bash 会把多字节字符误当成变量名一部分，导致取值失败。
[ -n "$BRANCH" ] && echo "【环境提示】当前 git 分支：${BRANCH}。动手前请先和用户确认分支是否正确，得到确认后再执行改动。"
exit 0
