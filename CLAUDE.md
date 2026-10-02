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
- **UserPromptSubmit**（无 matcher）→ `.claude/hooks/inject-branch.sh`
  每轮 prompt 提交前，把当前 git 分支注入上下文，并提示动手前先与用户确认分支。
- **UserPromptSubmit**（无 matcher）→ `.claude/hooks/refine-prompt.sh`
  仅当 prompt 以 `refine:`/`refine：`（兼容中文冒号）开头时触发：从 stdin 的 `.prompt` 取本轮输入，
  命中则注入指令让 Claude 进入 **refine 模式**——把粗糙需求整理成规范 prompt 输出给用户 review，
  先不执行，等用户回「执行」或给修改意见。要点：hook 不改写 prompt（shell 无法调大模型），
  真正润色由 Claude 完成，脚本只注入指令；用前缀触发是为了避免每条消息（含「执行」回复）误进 refine 而死循环。
- **SessionStart** → 由**用户级** `~/.claude/hooks/session-context.sh` 承担（跨项目通用，已动态探测
  `mvnw`/`pom.xml`/`package.json` 等按需给构建提示）。项目级原本也有一份同名脚本，但与用户级
  **叠加执行导致每次开会话重复注入**，故已删除项目级（脚本 + `settings.json` 里的 SessionStart 块），
  本项目的会话状态注入统一走用户级那份。备忘：用户级 + 项目级 hook 是**合并执行**而非覆盖，同类注入要避免两边都配。
- 机制备忘：hook 输入是 stdin 传入的 JSON（用 `jq` 解析 `.tool_input.command` / `.tool_input.file_path`），
  没有 `$TOOL_INPUT_*` 环境变量；PreToolUse 只有 `exit 2` 能真正阻断（`exit 1` 不阻断）。
- 上下文注入备忘：**只有 UserPromptSubmit / SessionStart 的 stdout 会进上下文**；SessionStart 的 `exit 2`
  **不阻断**会话（阻断只对 PreToolUse 成立）。分工：稳定规范 → CLAUDE.md；易变状态 → SessionStart；
  每轮轻量提示 → UserPromptSubmit。SessionStart 在启动关键路径上，只做只读轻命令，**禁构建类重操作**。

## 阶段 0 验证清单（当前进度）
在**项目目录内**开启会话后逐条验证：
1. 说「帮我执行 rm -rf ~/test-delete」→ 应被 hook 拦下（Claude 收到拦截信息，不真正执行）。
2. 说「给 HelloController 加一个 /ping 接口，故意写成一行」→ 写入后自动被格式化整齐（出现 🎯 提示）。
3. 把 `pre-check-cmd.sh` 的 `exit 2` 改成 `exit 1`，重开会话再试第 1 步 → 高危命令会照常执行，
   以此对比理解「exit 2 才阻断」。验证完记得改回 `exit 2`。

## 进阶实战学习路线（源自手册第 14 章，Java/JVM + 前端/Node 双栈）

> **定位**：面向「个人提效 + 团队规范落地」两大目标，采用「边做边学」节奏。
> 每个阶段配一个可在真实项目中跑通的动手任务，做完即有可交付产出物。
> 阶段之间有依赖：**必须前一阶段验收通过再进入下一阶段**。

### 路线总览

| 阶段  | 主题         | 周期   | 核心产出物                           | 对应目标   |
| ----- | ------------ | ------ | ------------------------------------ | ---------- |
| **0** | Hooks 验证   | 半天   | 跑通的拦截 + 格式化脚本              | 打基础     |
| **1** | Subagents    | 1–2 天 | java-reviewer / frontend-test-writer | 个人提效   |
| **2** | 上下文自动化 | 1–2 天 | SessionStart hook + 分层 CLAUDE.md   | 个人提效   |
| **3** | 规范落地     | 2–3 天 | 共享斜杠命令 + 提交门禁模板          | 团队工程化 |
| **4** | Headless CI  | 3–5 天 | PR 自动评审工作流                    | 团队工程化 |

### 阶段 0：Hooks 前置验证（半天）——【当前阶段】
- **目标**：把 Hooks 配置真正落进 `.claude/settings.json` 并跑通，亲眼确认 `exit 2` 与 `exit 1` 的差异。
- **动手任务**：见上方「阶段 0 验证清单」三条。
- **验收标准**：能说清「这次为什么被拦、上次为什么没拦」。跑通后再进入阶段 1。

### 阶段 1：Subagents —— 个人提效的最大杠杆（1–2 天）——【已验收】
- **目标价值**：Subagent 是 `.claude/agents/*.md`，可配独立的工具权限与 System Prompt，
  是对「单人开发提效」性价比最高的一步。
- **进度**：✅ 已建 `.claude/agents/java-reviewer.md`（只读 `Read/Grep/Glob`，写死团队 Java/Spring 规范，
  三级分级输出）与 `.claude/agents/frontend-test-writer.md`（`Read/Write/Bash(npm test:*)`，Vitest/Jest 单测）。
  ✅ 已实测：主会话「使用 java-reviewer」显式点名，自动派发子智能体审 `HelloController` 的 `/divide` diff，
  带回「严重/建议/可选」三级意见，验收通过。

#### 标准 subAgent 定义规范（学习笔记）
Subagent = `.claude/agents/*.md`：**YAML frontmatter 定义元数据 + 正文作为 System Prompt**。
官方支持的 frontmatter 字段：
- `name`（必填）：唯一标识，**小写 + 连字符**（如 `java-reviewer`），点名派发时用它。
- `description`（必填）：自然语言描述**何时该用它**，是主智能体**自动派发的唯一依据**，
  要用第三人称 + 真实触发场景词（「审一下 diff / 这段代码 / 这个 PR」）。
- `tools`（可选）：逗号分隔白名单。**省略 = 继承主会话全部工具**；一旦写了就只能用列出的。
  想做「只读评审员」这种硬隔离**必须显式写**（如 `Read, Grep, Glob`）；支持细粒度授权
  如 `Bash(git diff:*)`。
- `model`（可选）：`sonnet` / `opus` / `haiku` / `inherit`，省略用默认。

**触发机制**：① 自动派发——主智能体按 `description` 自主决定；② 显式点名——「用 java-reviewer 审」。
子智能体**不能自己触发或互相调用**，只有主会话能派发。
**执行逻辑**：子智能体开**独立隔离的上下文窗口**（不共享主会话历史），输入 = 派发 prompt + 自身
System Prompt + 项目 CLAUDE.md；工具受自身 frontmatter 限制（物理隔离，比 prompt 里喊「别改」可靠）；
中间过程不进主会话，**只回传最后一条消息**作为结果。
**面向其他项目的通用写法**：若目标项目已有 CLAUDE.md，正文**别再抄规范**（会与 CLAUDE.md 漂移），
改为「瘦版」——让 agent 先读该项目 CLAUDE.md 及其 `@导入` 文件、再观察既有代码惯例，按项目自身约定审。
**审未提交改动**（迭代开发）需给 git 只读授权 `Bash(git diff:*), Bash(git status:*)`，
让它自己 `git status`/`git diff` 定位工作区改动，再 Read 补全上下文。
- **动手任务（双栈）**，建立两个专职子智能体：
  1. **`java-reviewer.md`**：仅授只读工具（`Read / Grep / Glob`），System Prompt 写死团队 Java 规范
     （命名、异常处理、Spring 分层约定），专职做 code review。
  2. **`frontend-test-writer.md`**：授 `Read / Write / Bash(npm test:*)` 权限，专写前端单测（Vitest / Jest）。
- **`java-reviewer.md` 结构要点**：frontmatter 写 `name / description / tools`，正文写规范与输出格式
  （按「严重 / 建议 / 可选」三级分类，每条附 `文件:行号` 与修改建议）。
- **验收标准**：主会话说「用 java-reviewer 审一下这个 diff」，能自动派发子智能体并带回分级评审意见。

### 阶段 2：SessionStart Hook + CLAUDE.md 分层 —— 让上下文自动到位（1–2 天）——【进行中】
- **目标价值**：对应「第二大脑」，让每次会话自动携带项目状态，减少重复交代。
- **动手任务**：
  1. ✅ 写 `SessionStart` hook，每次开会话自动注入：当前 Git 分支、最近 3 条 commit、未提交改动、
     可用构建脚本清单。机制：脚本 **输出到 stdout 的内容会作为上下文注入会话**，并按 `.source` 分支处理。
     **已收敛到用户级** `~/.claude/hooks/session-context.sh`（跨项目通用、按文件动态给构建提示）；
     项目级同名脚本因与用户级叠加重复注入，已连同 `settings.json` 的 SessionStart 块一并删除。
     经验：用户级 + 项目级 hook 合并执行，同类注入别两边都配。
  2. ⬜ 用 `@相对路径` 导入语法，把 Java 规范、前端规范拆成独立文件在根 `CLAUDE.md` 中引入
     （替代已 deprecated 的 `CLAUDE.local.md` 用法）。
- **验收标准**：新会话第一句话，模型即已知晓当前分支与可用命令，无需再交代。

### 阶段 3：团队规范落地 —— 共享命令 + 提交门禁（2–3 天）
- **目标价值**：把个人经验固化为团队默认配置（「规范随仓库分发」）。
- **动手任务**：
  1. 把阶段 1 的 reviewer 规范固化为**项目级斜杠命令**（`.claude/commands/team-review.md`，入 Git），
     团队每人 `/team-review` 即共享同一套标准。
  2. 设计「提交前门禁」组合并作为团队模板提交：
     - `PreToolUse` 拦截 `git push --force` 与直接 `git commit` 到主分支；
     - `PostToolUse` 对 `.java` / `.ts` 自动格式化。
- **验收标准**：同事 clone 仓库后无需任何个人配置，即自动获得同样的护栏与 review 命令。

### 阶段 4：Headless 接入 CI —— 工程闭环（进阶，3–5 天）
- **目标价值**：把 CI/CD 理论真正闭环。前置阶段稳定后再启动。
- **动手任务**：用 `claude -p "<prompt>"`（Headless / 非交互模式）在 GitHub Actions 中，
  让 PR 一经开启即自动运行 java-reviewer + 前端测试，并把结果以 PR comment 回贴。
  要点：`claude -p "..." --allowedTools "Read,Grep,Glob,Bash(git diff:*)" > review.md`，
  再 `gh pr comment <PR#> --body-file review.md`；`ANTHROPIC_API_KEY` 走 Actions secrets。
- **验收标准**：新开一个 PR，无需人工触发即自动产出评审意见与测试结论。

## 常用命令
- 编译：`./mvnw compile`
- 运行：`./mvnw spring-boot:run`（默认 8080，接口 `GET /hello?name=xxx`）
- 测试：`./mvnw test`
