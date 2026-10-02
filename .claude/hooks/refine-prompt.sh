#!/bin/bash
# UserPromptSubmit hook —— refine 模式触发器
# 机制：UserPromptSubmit 的 stdin 是 JSON，用 jq 取 .prompt 拿到本轮用户输入；
#       本脚本 stdout 的内容会被追加进本轮上下文（UserPromptSubmit / SessionStart 特有）。
# 作用：只有当 prompt 以 `refine:` / `refine：`（兼容中文冒号）开头时，注入一条指令，
#       让 Claude 进入 refine 模式：把粗糙需求整理成规范 prompt 输出给用户 review，先别执行。
# 注意：hook 本身不改写 prompt（shell 无法调用大模型），真正的润色由 Claude 完成，这里只注入指令。

# stdin 只能读一次，先存下来
INPUT=$(cat)
PROMPT=$(printf '%s' "$INPUT" | jq -r '.prompt // empty')

# 去掉开头空白后，匹配 refine: / refine：（大小写不敏感，兼容全角冒号）
TRIMMED=$(printf '%s' "$PROMPT" | sed -e 's/^[[:space:]]*//')
shopt -s nocasematch
if [[ "$TRIMMED" == refine:* || "$TRIMMED" == refine：* ]]; then
  cat <<'EOF'
【refine 模式已触发】本轮用户输入以 refine: 前缀开头，请按以下流程处理，不要直接执行需求：
1. 把前缀后面的原始需求，整理成一份结构清晰、无歧义的规范 prompt（补全隐含约束、拆分子任务、点明验收标准与不确定处）。
2. 用代码块输出这份改写后的 prompt，供用户 review。
3. 明确停下等待用户反馈：用户可能回复「执行」表示照此办理，或给出修改意见让你迭代。
4. 在用户明确说「执行」之前，不要动手改代码或跑命令。
EOF
fi
exit 0
