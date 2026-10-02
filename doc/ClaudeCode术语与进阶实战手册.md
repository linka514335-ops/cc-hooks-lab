# Claude Code 术语与进阶实战手册

此文档用于记录 Claude Code 学习过程中的关键术语、架构体系、Hooks 安全与自动化机制、协作规范、CI/CD 自动化流水线、Jupyter Notebook 定位、结构化 Prompt 规范、MCP 协议体系及核心实战方法论。

---

## 1. 基础术语与概念

| 英文短语/单词                    | 中文释义             | 说明                                             |
| -------------------------------- | -------------------- | ------------------------------------------------ |
| **CLI Agentic Coding Assistant** | 命令行智能体编码助手 | 运行在终端内、具备自主行动能力的编程助手         |
| **Assistant**                    | 助手                 | 辅助开发者的 AI 实体                             |
| **Your codebase**                | 你的代码库           | 项目的完整源码与资源文件                         |
| **Task**                         | 任务                 | 需要完成的目标单元                               |
| **Language Model (LLM)**         | 大语言模型           | 提供理解、推理与文本生成的大脑中枢               |
| **Agent**                        | 智能体               | 具备环境感知、状态机闭环与工具调度能力的执行系统 |
| **Memory**                       | 记忆                 | 会话上下文与长期配置沉淀                         |
| **Tools / Skills**               | 工具 / 技能          | 赋予模型读写、运行命令的外部能力接口             |
| **Hooks**                        | 钩子系统             | 基于事件生命周期的拦截、校验与确定性自动化机制   |
| **MCP**                          | 模型上下文协议       | 连接 Agent 与外部数据源/工具的双向标准化通信协议 |
| **Gather context**               | 收集上下文           | 获取定位问题所需的代码与环境信息                 |
| **Formulate a plan**             | 制定计划             | 在执行前规划具体步骤                             |
| **Take an action**               | 执行操作             | 调用工具修改代码或运行命令                       |
| **Iterate**                      | 迭代 / 循环          | 报错后自我反思与重试闭环                         |
| **Command Line Interface (CLI)** | 命令行界面           | 终端字符交互环境                                 |
| **CI (Continuous Integration)**  | 持续集成             | 代码频繁合入主干并自动运行构建、测试与静态检查   |
| **CD (Continuous Delivery)**     | 持续交付             | 代码通过测试后自动打包制品，具备随时一键发布能力 |
| **CD (Continuous Deployment)**   | 持续部署             | 代码通过所有质量门禁后，全自动部署至生产环境     |

---

## 2. Agent 与 LLM 的关系与职责分工

| 核心维度     | LLM（大语言模型 / 大脑）                                                                                                                                                         | Agent（智能体 / 完整执行系统）                                                                                                                                                                              |
| ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **本质定位** | 思考、推理与决策中枢（Brain）                                                                                                                                                    | 环境感知、工具调度与自主闭环系统（System）                                                                                                                                                                  |
| **工作方式** | 被动响应，单轮/多轮“文本输入 → 文本输出”                                                                                                                                         | 主动循环，给定目标后自主拆解、多步执行                                                                                                                                                                      |
| **能力边界** | 仅在上下文窗口内处理文本/代码逻辑                                                                                                                                                | 通过 API/CLI 读写本地文件、执行 Shell、访问网络                                                                                                                                                             |
| **具体职责** | 1. **语义理解**：解析代码逻辑与用户意图<br>2. **任务拆解**：输出解决步骤与逻辑计划<br>3. **工具决策**：决定调用哪个工具并生成参数<br>4. **结果分析**：分析报错日志并重新推理方案 | 1. **上下文装配**：收集 Git、文件与配置信息喂给 LLM<br>2. **工具执行**：在操作系统上执行 Read/Write/Bash<br>3. **闭环循环**：维护 Plan-Action-Observe 状态机<br>4. **安全拦截**：管理权限边界，拦截危险操作 |
| **典型代表** | Claude 3.7 Sonnet, Opus 4.8, GPT-4o                                                                                                                                              | Claude Code, Cursor (Agent 模式), Aider, Devin                                                                                                                                                              |

---

## 3. Skills vs Hooks：能力扩展与确定性护栏

| 比较维度     | Skills / Tools（技能 / 工具）          | Hooks（钩子机制）                                     |
| ------------ | -------------------------------------- | ----------------------------------------------------- |
| **归属层级** | 模型能力层（LLM 调用的外部接口）       | Agent / 宿主工程环境（运行时拦截中间件）              |
| **本质定位** | **能力扩展**（Expanding Capability）   | **行为约束与确定性自动化**（Guards & Automation）     |
| **触发机制** | **LLM 主动调用**（由大模型推理决定）   | **系统被动触发**（由生命周期事件强制执行）            |
| **确定性**   | **概率性**（模型可能漏调、选错工具）   | **100% 确定性**（命中事件必执行，不受模型意志影响）   |
| **模型感知** | **有感知**（在 Prompt 中知晓其存在）   | **无感知**（由 Agent 框架静默执行拦截与处理）         |
| **典型代表** | `/git-add-commit`、`WebSearch`、`Read` | `PreToolUse`（安全拦截）、`PostToolUse`（自动格式化） |

---

## 4. 宏观 CI/CD 流水线与微观工具执行体系

| 维度         | 关注层级                  | 核心职责与典型场景                               |
| ------------ | ------------------------- | ------------------------------------------------ |
| **宏观 CI**  | 持续集成（工程主链路）    | 自动化编译构建、运行单元/集成测试、静态代码扫描  |
| **宏观 CD**  | 持续交付 / 持续部署       | 自动打包制品（Docker/JAR）、灰度验证、全自动发布 |
| **微观执行** | 开发者本地 / Agent 执行端 | 单次代码编辑、Git 提交前 Hook 校验、本地测试运行 |

---

## 5. Claude Code Hooks 系统与实战

Hooks 运行在开发者本地操作系统上，用于在工具执行前后或用户交互节点注入确定性逻辑。Hooks 配置写在 **`settings.json`** 中（Claude Code 没有独立的 `hooks.json` 文件），按作用域分为三层：
- 项目共享：`.claude/settings.json`（可入 Git）
- 项目个人：`.claude/settings.local.json`（本地保留，不入 Git）
- 全局通用：`~/.claude/settings.json`

### 5.1 支持的事件钩子（完整清单）
- **`PreToolUse`**：在某个工具即将被执行之前触发（主要用于权限风控与高危命令拦截，可阻断执行）。
- **`PostToolUse`**：在某个工具执行完成之后触发（主要用于自动格式化、语法编译与测试校验）。
- **`UserPromptSubmit`**：当用户提交新的 Prompt 时触发（用于动态注入环境上下文，如 Git 分支信息，或对输入做前置校验）。
- **`SubagentStop`**：子智能体（Task/Subagent）结束后触发（用于校验子任务产出物）。
- **`SessionStart` / `SessionEnd`**：会话开始 / 结束时触发（用于加载项目状态或做清理）。
- **`Stop`**：主智能体一轮响应结束时触发。
- **`Notification`**：Claude 发出通知（如等待用户确认）时触发。
- **`PreCompact`**：上下文压缩前触发。

### 5.2 配置文件范例（写入 `.claude/settings.json`）
> 注意结构：每个事件下用 `matcher`（工具名，支持正则）+ `hooks` 数组（每项 `type: "command"`），**不是** `tool` + `command`。
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/pre-check-cmd.sh" }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/post-format-check.sh" }
        ]
      }
    ]
  }
}
```

### 5.3 拦截与后置处理脚本范例

> 关键机制：Hook 的输入是通过 **stdin 传入的一段 JSON**（含 `tool_name`、`tool_input` 等），**不存在** `$TOOL_INPUT_COMMAND` 之类的环境变量，需用 `jq` 从 stdin 解析。可用环境变量主要是 `$CLAUDE_PROJECT_DIR`。

**1. 前置安全拦截（`pre-check-cmd.sh`）**
```bash
#!/bin/bash
# 从 stdin 读取 JSON，解析出 Bash 工具的 command 字段
CMD=$(jq -r '.tool_input.command')
if echo "$CMD" | grep -Eq "rm -rf /|git push .*(-f|--force)|DROP DATABASE|mvn .*deploy"; then
    echo "❌ [安全拦截] 检测到高危指令: '$CMD'，执行已被强制中止！" >&2
    exit 2   # PreToolUse 中 exit 2 才会真正阻断工具并把 stderr 回喂给模型；exit 1 属非阻断错误，工具照常执行
fi
exit 0
```

**2. 后置自动格式化与语法检查（`post-format-check.sh`）**
```bash
#!/bin/bash
# Edit/Write 的目标文件路径同样从 stdin JSON 解析
FILE_PATH=$(jq -r '.tool_input.file_path')
if [[ "$FILE_PATH" == *.go ]]; then
    gofmt -w "$FILE_PATH"
elif [[ "$FILE_PATH" == *.java ]]; then
    command -v google-java-format &> /dev/null && google-java-format --replace "$FILE_PATH"
    mvn test-compile -DskipTests -q 2>/dev/null || { echo "⚠️ [Java Hook] 编译检查失败，请修复语法错误" >&2; exit 2; }
fi
exit 0
```

---

## 6. Claude Code 内置工具表

| 工具名称         | 用途                                                                      |
| ---------------- | ------------------------------------------------------------------------- |
| **Bash**         | 运行 shell 命令                                                           |
| **Edit**         | 精准编辑已有文件                                                          |
| **Write**        | 创建新文件或完全覆盖文件                                                  |
| **Read**         | 读取文件内容                                                              |
| **Glob**         | 基于文件名模式查找文件路径                                                |
| **Grep**         | 在文件内容中搜索正则表达式模式                                            |
| **NotebookEdit** | 编辑/修改 Jupyter Notebook 单元格（读取已并入 Read，无独立 NotebookRead） |
| **Task / Agent** | 派生子智能体（Sub-agent）处理复杂子任务                                   |
| **TodoWrite**    | 维护结构化待办清单与进度跟踪                                              |
| **BashOutput**   | 读取后台运行命令的增量输出                                                |
| **KillShell**    | 终止后台运行的 Shell 命令                                                 |
| **SlashCommand** | 在会话中调用已注册的斜杠命令                                              |
| **WebFetch**     | 获取指定网页的文本/HTML内容                                               |
| **WebSearch**    | 触发网络搜索引擎查询实时信息                                              |

> 说明：早期的 **`MultiEdit`** 已被移除，现在的 `Edit` 单次调用即可完成多处替换；**`NotebookRead`** 已并入 `Read`（`Read` 可直接读取 `.ipynb`）。

---

## 7. Jupyter Notebook 的定位与工程认知

- **本质定位**：**交互式计算笔记本（Interactive Computational Notebook）**，非传统线性文本编辑器。基于 Cell（单元格）架构，将代码、执行结果、富媒体图表与 Markdown 融为一体（底层为 `.ipynb` JSON 结构）。
- **语言生态倾向**：深度倾向于 **Python**（源自 IPython，生态高度绑定 Pandas/NumPy/PyTorch 数据科学与 AI 探索）。Java/Go 在工程中以完整的编译型构建为主，主要使用专业 IDE。
- **压测角色定位**：
  - **适用场景**：轻量级接口摸底调试、压测结果数据清洗、绘制 P95/P99 耗时分布与吞吐量报告图表。
  - **不适用场景**：不适合作为高并发发压引擎。受限于解释器开销与 GIL，单机发压上限低且容易因客户端自身开销污染响应延迟测量；高并发发压应选用 `k6`、`wrk`、`JMeter` 或 `Locust`。

---

## 8. 配置文件体系（CLAUDE.md）

| 配置文件路径              | 作用域与共享范围                       | 用途                                                                                                                                                                |
| ------------------------- | -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`./CLAUDE.md`**         | 项目根目录，**团队共享**（需加入 Git） | 存放代码规范、常用构建/测试命令、架构约定                                                                                                                           |
| **`./CLAUDE.local.md`**   | 项目根目录，**个人独享**（本地保留）   | 个人特有的运行配置、本地环境路径等（⚠️ 已被官方标记为 deprecated，推荐改用 `.claude/settings.local.json` + 在 `CLAUDE.md` 中用 `@相对路径` 导入外部文件的方式替代） |
| **`~/.claude/CLAUDE.md`** | 用户主目录，**全局通用**（跨所有工程） | 适用于本机所有项目的全局编码偏好与准则                                                                                                                              |

---

## 9. 多实例协作与 Git Worktree 使用规范

当需要在同一项目中并行处理多个任务时，利用 Git Worktree 与多实例 Claude Code 协作是最佳实践，能有效避免多实例冲突。

### 推荐工作流示范（以 `.trees/` 集中收纳为例）
```bash
# 1. 确保在主仓库根目录（如 /Users/link/sys）
cd /Users/link/sys

# 2. 将工作树临时目录加入 .gitignore（只需配置一次）
echo ".trees/" >> .gitignore

# 3. 创建独立任务工作树与新分支
git worktree add .trees/test -b test-task

# 4. 进入该独立工作区启动独立的 CC
cd .trees/test
claude

# 5. 任务完成后，在主分支中进行合并并清理
cd /Users/link/sys
git merge test-task
git worktree remove .trees/test
```

---

## 10. 自定义命令与元命令体系（Meta Command）

Claude Code 支持在 `~/.claude/commands/`（全局）或 `.claude/commands/`（项目局部）目录下放置 Markdown 文件以注册为斜杠命令。

### 10.1 元命令脚手架：`meta-command.md`
```markdown
---
allowed-tools: Write(*), Read(*), Edit(*), Bash(ls:*), Bash(date:*)
description: Generate optimized slash commands
version: "3.3.0"
---

# Meta Command
Create slash commands using two-file architecture.

## Files to Generate
For command `XX`:
- **XX.md** - Command file
- **XX.changelog** - Version history

## Arguments Format
`<name> "<description>" [project|user] [requirements]`

## Process
1. Check if command exists:
   ls ~/.claude/commands/XX.md

2. Generate **XX.md**:
   ---
   allowed-tools: [required tools]
   description: one-line description
   version: "1.0.0"
   ---
   # Command logic

3. Generate **XX.changelog**:
   # Changelog for XX
   ## v1.0.0 - YYYY-MM-DD
   - Initial version
   Created: YYYY-MM-DD

## Version Rules
- New: v1.0.0
- Patch: Bug fixes (1.0.1)
- Minor: Features (1.1.0)
- Major: Breaking (2.0.0)

Execute: `/meta-command <name> "<desc>" [options]`
```

### 10.2 常用衍生命令示例：智能 Git 提交（`git-add-commit.md`）
```markdown
---
allowed-tools: [Bash(git:*), Read(*), Grep(*), LS(*)]
description: Add and commit with conventional style
version: "1.0.1"
---

# Intelligent Git Commit Command

You are creating a git commit with the following features:
- **Default language**: Chinese (中文) for commit messages
- **Conventional Commit style**: Use conventional commit format (type(scope): description)
- **User context integration**: Accept and incorporate user-provided additional context

## Workflow
1. **Analyze current changes**: Run git status & git diff
2. **Parse user input**: Check for specific scope or requirements
3. **Generate commit message**: Conventional commit format in Chinese
4. **Stage and commit**: Ask confirmation and create commit
```

---

## 11. 结构化任务型 Prompt 工程规范

在向 Claude Code 等 Agent 委派复杂重构、架构改造或多轮工具调用任务时，使用五步“结构化任务型 Prompt”能最大程度消除幻觉并保证执行精准度。

### 11.1 五步核心结构

| 模块    | 规范环节                                            | 核心价值                                                                                     |
| ------- | --------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| **# 1** | **上下文定位与定义现状 (Current State)**            | 精确锚定文件路径（如 `@backend/xxx`），指出当前系统的缺陷与瓶颈，避免模型误解现有架构。      |
| **# 2** | **清晰定义目标 (Desired State)**                    | 确立核心目标（Goal），让模型理解重构或交付的终点。                                           |
| **# 3** | **提供具体示例 (Concrete Example / Few-Shot)**      | 用具体端到端交互或调用链路消除抽象理解偏差。                                                 |
| **# 4** | **明确技术与边界约束 (Requirements & Constraints)** | 设立硬性边界（如最大轮次、终止判定条件、异常处理机制），防止过度设计或逻辑遗漏。             |
| **# 5** | **元指令与阶段控制 (Meta-Instruction)**             | 指定思考与执行策略（例如：派生两个并行子智能体进行头脑风暴，且明确“禁止写代码”），分步推进。 |

### 11.2 标准复用模板
```markdown
Refactor @backend/ai_generator-py to support sequential tool calling where Claude can make up to 2 tool calls in separate API rounds.

# 1. 清晰定义现状
Current behavior:
- Claude makes 1 tool call → tools are removed from API params → final response
- If Claude wants another tool call after seeing results, it can't (gets empty response)

# 2. 清晰定义目标
Desired behavior:
- Each tool call should be a separate API request where Claude can reason about previous results
- Support for complex queries requiring multiple searches

# 3. 提供具体示例
Example flow:
1. User: "Search for a course that discusses the same topic as lesson 4 of course X"
2. Claude: get course outline for course X - gets title of lesson 4
3. Claude: uses the title to search for a course that discusses the same topic → returns course information
4. Claude: provides complete answer

# 4. 给出明确的技术约束
Requirements:
- Maximum 2 sequential rounds per user query
- Terminate when: (a) 2 rounds completed, (b) Claude's response has no tool_use blocks, or (c) tool call fails

# 5. 提出元指令：派出子智能体
Use two parallel subagents to brainstorm possible plans. Do not implement any code.
```

---

## 12. MCP (Model Context Protocol) 架构与体系

### 12.1 基础定义与核心价值
- **定义**：Anthropic 开源的标准协议，用于在 AI 智能体与外部数据源/工具之间建立通用的双向通信链路。
- **定位**：AI 领域的“通用 USB 接口”，彻底解决不同 Agent 与数据源之间的点对点重复适配问题。
- **通信机制**：基于标准的 JSON-RPC 2.0 协议，支持 Stdio（标准输入输出进程）与 SSE（Server-Sent Events HTTP 服务）两种传输通道。

### 12.2 三大核心能力要素
| 协议要素       | 英文术语      | 核心职责                     | 典型场景                                          |
| -------------- | ------------- | ---------------------------- | ------------------------------------------------- |
| **工具**       | **Tools**     | LLM 可主动触发的外部执行能力 | 执行数据库 CRUD、发送 Slack 消息、拉取 Jira Issue |
| **资源**       | **Resources** | 暴露给 LLM 的只读上下文数据  | 数据库 Schema 结构、本地运行时日志、云端配置文件  |
| **提示词模板** | **Prompts**   | 预置在 Server 端的结构化指令 | 生产故障排查模板、代码规范安全评审指令            |

### 12.3 Claude Code MCP 配置范例
> MCP 服务器的标准配置位置：**项目级** 写在项目根目录的 `.mcp.json`（可入 Git 团队共享）；**用户级** 推荐用命令行 `claude mcp add ...` 添加（实际落盘在 `~/.claude.json`）。并没有 `~/.claude/mcp.json` 这个标准文件。下方为 `.mcp.json` 的结构范例：
```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-postgres",
        "postgresql://user:pass@localhost:5432/my_db"
      ]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_xxx"
      }
    }
  }
}
```

---

## 13. Claude Code 核心实战经验 (Key Insights)

- **范式转变：从“指令式工具”到“智能体伙伴”**：核心在于思维模式的跃迁。你需要将 Claude Code 视为一个能够自主规划、执行并进行反思的初级合伙人，而非一个被动的代码生成器。
- **上下文工程：对话的本质是信息架构**：与 AI 的每一次交互，都是一次微型的信息架构设计。成功的关键在于如何精准、高效地构建上下文，这决定了其输出质量的上限。
- **持久化记忆：构建项目的“第二大脑”**：通过 CLAUDE.md 系统，我们将为 AI 构建一个可版本化、可共享的项目知识库，实现跨会话、跨团队的知识沉淀与复用。
- **工程化整合：将 AI 注入开发生命周期**：真正的价值在于将 AI 无缝融入成熟的工程实践中，例如测试驱动调试（TDD）、并行开发（Git Worktree）和持续集成/持续部署（CI/CD）。
- **元编程思维：从“使用 AI”到“编排 AI”**：通过 MCPs 和 Hooks 等高级功能，开发者将从 AI 的“使用者”转变为 AI 工作流的“设计者与编排者”，实现开发流程的深度自动化与定制。

---

## 14. 进阶实战学习路线（Java/JVM + 前端/Node 双栈）

> **定位**：面向「个人提效 + 团队规范落地」两大目标，采用「边做边学」节奏。每个阶段配一个可在真实项目中跑通的动手任务，做完即有可交付产出物。
>
> **阶段 0（前置验证，半天）**：把第 5 节修正后的 Hooks 配置真正落进 `.claude/settings.json` 并跑通——让 Claude 尝试执行 `rm -rf`，验证 `exit 2` 能拦截（再故意改成 `exit 1` 观察工具照常执行，亲眼确认差异）；再编辑一个 `.java` 文件，确认 PostToolUse 自动触发格式化。**验收标准**：能说清「这次为什么被拦、上次为什么没拦」。跑通后再进入阶段 1。

### 14.1 阶段 1：Subagents —— 个人提效的最大杠杆（1–2 天）

**目标价值**：Subagent 是 `.claude/agents/*.md`，可配置独立的工具权限与 System Prompt，是对「单人开发提效」性价比最高的一步。

**动手任务（双栈）**：建立两个专职子智能体
1. **`java-reviewer.md`**：仅授只读工具（`Read / Grep / Glob`），System Prompt 写死团队 Java 规范（命名、异常处理、Spring 分层约定），专职做 code review。
2. **`frontend-test-writer.md`**：授 `Read / Write / Bash(npm test:*)` 权限，专写前端单测（Vitest / Jest）。

**子智能体文件范例（`.claude/agents/java-reviewer.md`）**：
```markdown
---
name: java-reviewer
description: 专职 Java 代码评审，依据团队规范给出结构化意见
tools: Read, Grep, Glob
---
你是资深 Java 评审专家。评审时严格依据以下团队规范：
- 命名：类名 PascalCase，常量全大写下划线
- 异常：禁止吞异常（空 catch），受检异常需转译为业务异常
- 分层：Controller 不得直接访问 Repository，须经 Service
输出格式：按「严重 / 建议 / 可选」三级分类，每条附文件:行号与修改建议。
```

**验收标准**：主会话中说「用 java-reviewer 审一下这个 diff」，它能自动派发子智能体并带回分级评审意见。

### 14.2 阶段 2：SessionStart Hook + CLAUDE.md 分层 —— 让上下文自动到位（1–2 天）

**目标价值**：对应第 8、13 节的「第二大脑」，让每次会话自动携带项目状态，减少重复交代。

**动手任务**：
1. 写一个 `SessionStart` hook，每次开会话自动注入：当前 Git 分支、最近 3 条 commit、可用构建脚本清单（`mvn`/`npm run`）。
2. 用 `@相对路径` 导入语法，把 Java 规范、前端规范拆成独立文件，在根 `CLAUDE.md` 中引入（替代已 deprecated 的 `CLAUDE.local.md` 用法）。

**SessionStart Hook 范例（`.claude/settings.json` 片段）**：
```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/session-context.sh" }
        ]
      }
    ]
  }
}
```
```bash
#!/bin/bash
# session-context.sh —— 输出到 stdout 的内容会作为上下文注入会话
echo "## 当前项目状态"
echo "分支: $(git branch --show-current 2>/dev/null)"
echo "最近提交:"
git log --oneline -3 2>/dev/null
echo "可用脚本: $(ls package.json pom.xml 2>/dev/null)"
```

**验收标准**：新会话第一句话，模型即已知晓当前分支与可用命令，无需再交代。

### 14.3 阶段 3：团队规范落地 —— 共享命令 + 提交门禁（2–3 天）

**目标价值**：本阶段是「团队工程化」目标的核心交付物，把个人经验固化为团队默认配置。

**动手任务**：
1. 把阶段 1 的 reviewer 规范固化为**项目级斜杠命令**（`.claude/commands/team-review.md`，入 Git），团队每人 `/team-review` 即共享同一套标准。
2. 设计「提交前门禁」组合并作为团队模板提交：
   - `PreToolUse` 拦截 `git push --force` 与直接 `git commit` 到主分支；
   - `PostToolUse` 对 `.java`/`.ts` 自动格式化。

**验收标准**：同事 clone 仓库后，无需任何个人配置即自动获得同样的护栏与 review 命令（即「规范随仓库分发」）。

### 14.4 阶段 4：Headless 接入 CI —— 工程闭环（进阶，3–5 天）

**目标价值**：把第 4 节的 CI/CD 理论真正闭环。前置阶段稳定后再启动。

**动手任务**：用 `claude -p "<prompt>"`（Headless / 非交互模式）在 GitHub Actions 中，让 PR 一经开启即自动运行 java-reviewer + 前端测试，并将结果以 PR comment 形式回贴。

**GitHub Actions 范例（要点示意）**：
```yaml
- name: Claude Auto Review
  run: |
    claude -p "评审本次 PR 的 diff，依据团队 Java/前端规范给出分级意见" \
      --allowedTools "Read,Grep,Glob,Bash(git diff:*)" \
      > review.md
    gh pr comment ${{ github.event.pull_request.number }} --body-file review.md
  env:
    ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

**验收标准**：新开一个 PR，无需人工触发即自动产出评审意见与测试结论。

### 14.5 路线总览

| 阶段  | 主题         | 周期   | 核心产出物                           | 对应目标   |
| ----- | ------------ | ------ | ------------------------------------ | ---------- |
| **0** | Hooks 验证   | 半天   | 跑通的拦截 + 格式化脚本              | 打基础     |
| **1** | Subagents    | 1–2 天 | java-reviewer / frontend-test-writer | 个人提效   |
| **2** | 上下文自动化 | 1–2 天 | SessionStart hook + 分层 CLAUDE.md   | 个人提效   |
| **3** | 规范落地     | 2–3 天 | 共享斜杠命令 + 提交门禁模板          | 团队工程化 |
| **4** | Headless CI  | 3–5 天 | PR 自动评审工作流                    | 团队工程化 |

## 15. 待学习目录：内置钩子挂点（Hook Events）

> **概念澄清**：钩子"挂点名"（如 `UserPromptSubmit`）是 Claude Code **内置的保留事件名**，
> 属于固定词汇表，写进 `settings.json` 时必须**逐字精确匹配**才会被自动识别；拼错则静默失效。
> 自定义的只是挂在该挂点下的脚本（`command`），Claude Code 不关心脚本叫什么。
> 下表为全部 9 个挂点，勾选表示本项目已实操，未勾选为待学习目标。

| 状态 | 挂点名（事件） | 触发时机 | 可否阻断 | 典型用途 | 本项目实操 |
| ---- | -------------- | -------- | -------- | -------- | ---------- |
| ✅ | `PreToolUse`        | 工具即将执行前         | 可（`exit 2`） | 高危命令拦截、权限风控        | `pre-check-cmd.sh` |
| ✅ | `PostToolUse`       | 工具执行完成后         | 否           | 自动格式化、编译/测试校验     | `post-format-check.sh` |
| ✅ | `UserPromptSubmit`  | 用户提交 Prompt 时     | 可（拒绝输入） | 注入上下文（Git 分支）、输入前置校验 | `inject-branch.sh` |
| ⬜ | `SessionStart`      | 会话开始时             | 否           | 加载项目状态、注入分支/命令清单 | 阶段 2 计划 |
| ⬜ | `SessionEnd`        | 会话结束时             | 否           | 清理临时文件、归档产出物       | —          |
| ⬜ | `Stop`              | 主智能体一轮响应结束时 | 可（阻止停止） | 校验产出、强制补做未完成步骤   | —          |
| ⬜ | `SubagentStop`      | 子智能体（Task）结束后 | 可（阻止停止） | 校验子任务产出物             | 阶段 1 关联 |
| ⬜ | `PreCompact`        | 上下文压缩前           | 否           | 压缩前保存关键上下文快照       | —          |
| ⬜ | `Notification`      | Claude 发出通知时      | 否           | 自定义提醒（桌面/IM 推送）    | —          |

### 待学习动手清单
- [ ] `SessionStart`：写 `session-context.sh`，开会话自动注入当前分支 + 最近 3 条 commit + 可用构建脚本（对应阶段 2）。
- [ ] `SubagentStop`：在 Subagent 产出后自动跑一次校验（对应阶段 1 验收）。
- [ ] `Stop`：尝试用其在"响应结束"时做收尾检查，理解与 `SubagentStop` 的区别。
- [ ] `SessionEnd` / `PreCompact` / `Notification`：了解触发时机与限制，各写一个最小 demo 验证。
- [ ] 对比实验：验证「拼错挂点名（如 `UserPromptSubmited`）会静默失效」，加深"名字精确匹配才被识别"的认知。