# 本地优先使用指南

[简体中文](LOCAL_USAGE_GUIDE.md) | [English](LOCAL_USAGE_GUIDE.en.md)

本文把 Agent Memory Workflow 面向本地 Agent 的使用方式整理成一条单一路径。目标不是重复解释所有模板，而是回答四个实际问题：

- 本地用户应该选择哪条安装和运行路径。
- 第一次应该填写哪些文件。
- 应该把什么交给新的本地 Agent。
- 怎样判断它真的完成了长期导入，而不是只记在当前聊天里。

## 适用范围

本指南只面向能够读取本地文件系统的 Agent，例如：

- 本地 Codex 类编程 Agent
- 本地 IDE Agent
- 本地 CLI Agent
- 本地桌面 Agent

它不处理远程 Web Agent、附件转交流程、多设备同步或云端托管记忆。

## 默认推荐路径

对于大多数本地用户，推荐的默认组合是：

- 共享目录固定为 `$HOME\.agents`
- 以 `npx` 或固定 release tag 初始化工作流
- 以 `AGENT_BOOTSTRAP.md` 作为长期入口锚点
- 以 `AGENT_MEMORY_IMPORT_PROMPT.md` 作为导入协议
- 以导入回执和 `imports\IMPORT_REGISTRY.md` 作为完成证明

最短路径如下：

1. 运行 `preflight` 检查运行时和目标目录。
2. 运行 `init` 生成 `$HOME\.agents`。
3. 填写 `machine\` 下的稳定机器事实。
4. 运行 `verify` 确认结构、引用和敏感模式通过检查。
5. 把 `AGENT_MEMORY_IMPORT_PROMPT.md` 交给新的本地 Agent。
6. 要求 Agent 返回结构化导入回执。
7. 后续任务默认先读 `AGENT_BOOTSTRAP.md`，不再重新扫描整台机器。

## 选择哪种本地使用路径

| 你的目标 | 推荐路径 | 原因 |
| --- | --- | --- |
| 直接开始使用 | `npx -y github:s1oopX/agent-memory-workflow ...` | 零安装成本，适合绝大多数本地用户 |
| 严格复现某个版本 | `npx -y github:s1oopX/agent-memory-workflow#v0.1.20 ...` | 版本固定，适合团队复现和文档对齐 |
| 审查模板、离线阅读、参与开发 | 克隆仓库并运行 `tools\*.ps1` | 可以直接检查模板、脚本和变更 |

结论很简单：

- 普通本地用户优先选 `npx`
- 需要一致复现时改用固定 tag
- 只有在你要审查或修改模板时才需要克隆仓库

## 推荐的技术栈顺序

如果你正在设计自己的本地 Agent 记忆方案，推荐顺序是：

1. **文件协议**：把共享事实放进用户可审查的 Markdown/JSON 文件。
2. **npx / 本地 CLI**：提供初始化、升级、验证和导入提示输出。
3. **Agent 专属 Skill 或适配层**：只做薄封装，读取文件协议，不取代文件本身。
4. **SDK**：只有当多个本地工具都需要程序化访问同一套已验证状态时再引入。

这也是本仓库当前采用的顺序。结论不是“永远不要 Skill 或 SDK”，而是它们不应该先于本地文件协议成为事实来源。

## 第一次应该填写哪些文件

初始化后的模板只是框架，真正有价值的是你机器上的稳定事实。优先填写这些文件：

| 文件 | 作用 |
| --- | --- |
| `machine\MACHINE_ENVIRONMENT_MEMORY.md` | 完整机器事实库，写稳定环境结论 |
| `machine\AGENT_ENVIRONMENT_QUICK_REFERENCE.md` | 给 Agent 快速读取的短摘要 |
| `machine\AGENT_EXECUTION_PLAYBOOK.md` | 这台机器上优先用什么 shell、什么命令路径 |
| `machine\HOME_DIRECTORY_MAP.md` | 用户目录、工作区、配置目录、临时目录边界 |
| `machine\MAINTENANCE_POLICY.md` | 哪些目录是 live data，哪些清理动作禁止默认执行 |

写入原则：

- 只写稳定、非敏感、可复用的机器事实
- 不写密码、token、私钥、会话日志
- 不把当前任务的一次性结论冒充为长期规则

## 应该交给新 Agent 什么

给新的本地 Agent 的最小输入不是一大段手写 prompt，而是这条指令：

```text
Read $HOME\.agents\AGENT_MEMORY_IMPORT_PROMPT.md and import it into your local durable memory or persistent instruction layer.
```

如果 Agent 能直接读取本地文件，这条指令就够了。它接下来应该按导入提示读取规定文件，而不是只看 README。

## 不同本地 Agent 的持久化落点

| Agent 类型 | 建议写入位置 | 最低要求 |
| --- | --- | --- |
| Codex 类本地 Agent | 持久记忆、长期指令层、用户级规则层 | 不能只停留在当前聊天 |
| 本地 IDE Agent | IDE 的全局规则、用户说明、持久 memory feature | 至少保存 bootstrap 路径和稳定机器摘要 |
| 本地 CLI Agent | CLI 的用户配置、启动指令、全局规则文件 | 新会话仍能先读 bootstrap |
| 本地桌面 Agent | 应用的长期设置、记忆页、持久化说明区 | 如果需要手工确认，回执必须说明 |

关键点不是每个产品名字，而是两个问题：

- 它把长期规则写到哪里。
- 新会话或重启后还能不能先读 `AGENT_BOOTSTRAP.md`。

## 怎样判断导入真的成功

下面这些条件同时成立，才算“成功导入”：

1. Agent 按导入提示读取了规定文件，而不是只读一个摘要。
2. Agent 明确写入了 durable memory record，至少包含 bootstrap 路径和机器级稳定事实摘要。
3. Agent 说明了写入位置，例如持久记忆、规则页、用户配置或启动说明。
4. Agent 返回了基于 `AGENT_MEMORY_IMPORT_RECEIPT_TEMPLATE.md` 的结构化回执。
5. 如果它没有真正持久化，必须标记为 `chat_local_only` 或 `manual_user_action_required`，不能伪装成完成。

一句话判断标准：**能跨新会话保留，且有回执证明，才叫成功。**

## 本地维护循环

推荐把维护动作固定成下面这条循环：

1. 修改 `machine\` 下的机器事实或策略文件。
2. 运行 `verify`。
3. 如果模板或工作流版本变了，运行 `upgrade`。
4. 把新的 `import-prompt` 重新交给已接入 Agent。
5. 更新 `imports\IMPORT_REGISTRY.md` 或至少保留新的导入回执。

下面这些变化通常应触发重新导入：

- 机器环境事实发生实质变化
- `AGENT_MEMORY_IMPORT_PROMPT.md` 变化
- `AGENT_PLATFORM_ADAPTERS.md` 变化
- `AGENT_MEMORY_WORKFLOW_MANIFEST.json` 变化
- 验证策略或维护策略变化

## 不要这样做

- 不要把凭据写进 `.agents`
- 不要把当前聊天当成长期记忆
- 不要要求每个新 Agent 都重新审计整台机器
- 不要把事实只塞进某个产品的私有 memory，而不保留 bootstrap 路径
- 不要把远程 Web Agent 场景混进这套本地工作流

## 推荐的一句话工作流

如果你只想记住一个版本，请记这句：

**用 `npx` 或固定 tag 生成 `$HOME\.agents`，填写 `machine\` 事实，运行 `verify`，然后把 `AGENT_MEMORY_IMPORT_PROMPT.md` 交给每一个新的本地 Agent，并要求它返回可审计的导入回执。**
