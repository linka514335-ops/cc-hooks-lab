# cc-hooks-lab — Claude Code 进阶学习练手项目

## 项目定位
这是配套《ClaudeCode 术语与进阶实战手册》（位于 `~/Desktop/ClaudeCode术语与进阶实战手册.md`）的动手练习项目，
用于逐阶段实操 Claude Code 的 Hooks、Subagents、共享命令、CI 等进阶能力。
技术栈：Spring Boot 4.1.0 + Java 17 + Maven。

## 环境要点
- 构建用 Java 17（`./mvnw compile`）。
- `google-java-format` 需要 Java 21+，故格式化 hook 内部单独指定 `openjdk@26`
  （`/opt/homebrew/opt/openjdk@26/...`），与 Maven 的 17 互不干扰。

## 已配置的 Hooks（`.claude/settings.json`）
- **PreToolUse / matcher=Bash** → `.claude/hooks/pre-check-cmd.sh`
  拦截高危命令（`rm -rf ~`、`git push --force`、`DROP DATABASE` 等），命中即 `exit 2` 阻断。
- **PostToolUse / matcher=Edit|Write** → `.claude/hooks/post-format-check.sh`
  对 `.java` 自动执行 `google-java-format --replace`。
- 机制备忘：hook 输入是 stdin 传入的 JSON（用 `jq` 解析 `.tool_input.command` / `.tool_input.file_path`），
  没有 `$TOOL_INPUT_*` 环境变量；PreToolUse 只有 `exit 2` 能真正阻断（`exit 1` 不阻断）。

## 阶段 0 验证清单（当前进度）
在**项目目录内**开启会话后逐条验证：
1. 说「帮我执行 rm -rf ~/test-delete」→ 应被 hook 拦下（Claude 收到拦截信息，不真正执行）。
2. 说「给 HelloController 加一个 /ping 接口，故意写成一行」→ 写入后自动被格式化整齐（出现 🎯 提示）。
3. 把 `pre-check-cmd.sh` 的 `exit 2` 改成 `exit 1`，重开会话再试第 1 步 → 高危命令会照常执行，
   以此对比理解「exit 2 才阻断」。验证完记得改回 `exit 2`。

## 后续路线（详见手册第 14 章）
- 阶段 1：Subagents —— `java-reviewer` + `frontend-test-writer`（`.claude/agents/*.md`）
- 阶段 2：`SessionStart` hook 注入项目状态 + CLAUDE.md 分层
- 阶段 3：共享斜杠命令（`.claude/commands/`）+ 提交门禁
- 阶段 4：Headless（`claude -p`）接入 CI 自动评审

## 常用命令
- 编译：`./mvnw compile`
- 运行：`./mvnw spring-boot:run`（默认 8080，接口 `GET /hello?name=xxx`）
- 测试：`./mvnw test`
