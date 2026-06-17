# Agent Memory Workflow

[简体中文](README.md) | [English](README.en.md)

Agent Memory Workflow 是一个本地优先的 Agent 记忆文件协议，用于为编程 Agent 维护可复用、可审查、可验证的运行上下文。它通过标准化的 `.agents` 目录、通用模板、初始化脚本和验证脚本，让本地 Agent 能够共享同一套机器级指导信息，而不依赖云端记忆服务或特定 Agent 产品。

## 概览

编程 Agent 经常运行在不同产品、不同会话或不同工作目录中。工具可用性、机器路径、执行策略、维护规则等本地上下文，往往需要反复识别，或在 Agent 切换后丢失。

本项目将这些上下文整理为本地文件。用户初始化 `.agents` 目录，填写非敏感机器事实，然后将导入提示交给本地 Agent。Agent 读取后，应将稳定事实写入自身的持久记忆或长期指令层，并按照模板返回导入回执。

## 适用范围

本项目面向能够读取本地文件系统的本地 Agent。

本项目不提供：

- 云端同步
- 托管式记忆存储
- 远程 Web Agent 附件流程
- 凭据管理
- 基于数据库的记忆服务

本项目的唯一可信源始终是本地 `.agents` 目录。

## 环境要求

- Git
- PowerShell 7 或更高版本，并可通过 `pwsh` 调用
- Node.js 18 或更高版本，仅在使用 `npx` 包装器时需要
- 能够读取目标机器本地文件的 Agent

## 快速开始

克隆仓库并初始化本地 `.agents` 目录：

```powershell
git clone https://github.com/s1oopX/agent-memory-workflow.git
cd agent-memory-workflow
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\init-agent-memory-workflow.ps1 -TargetRoot "$HOME\.agents"
```

验证生成后的工作流：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "$HOME\.agents\tools\verify-agent-memory-workflow.ps1"
```

编辑生成后的机器参考文件：

```text
$HOME\.agents\machine\MACHINE_ENVIRONMENT_MEMORY.md
$HOME\.agents\machine\AGENT_ENVIRONMENT_QUICK_REFERENCE.md
$HOME\.agents\machine\HOME_DIRECTORY_MAP.md
```

向本地 Agent 提供以下指令：

```text
Read $HOME\.agents\AGENT_MEMORY_IMPORT_PROMPT.md and import it into your local durable memory or persistent instruction layer.
```

Agent 应基于以下模板返回导入回执：

```text
$HOME\.agents\AGENT_MEMORY_IMPORT_RECEIPT_TEMPLATE.md
```

## npx 用法

仓库包含一个轻量级 Node.js 包装器，可用于初始化和验证：

```powershell
npx github:s1oopX/agent-memory-workflow init --target "$HOME\.agents"
npx github:s1oopX/agent-memory-workflow verify --root "$HOME\.agents"
```

该包装器会调用 `tools\` 中的 PowerShell 脚本。

## 仓库结构

```text
bin\
  agent-memory-workflow.js
tools\
  init-agent-memory-workflow.ps1
  verify-agent-memory-workflow.ps1
templates\
  AGENT_BOOTSTRAP.md
  AGENT_MEMORY_IMPORT_PROMPT.md
  AGENT_MEMORY_IMPORT_RECEIPT_TEMPLATE.md
  AGENT_MEMORY_WORKFLOW.md
  AGENT_MEMORY_WORKFLOW_MANIFEST.json
  AGENT_PLATFORM_ADAPTERS.md
  AGENT_WORKFLOW_REPLICATION_STRATEGY.md
  AGENT_WORKFLOW_OPEN_SOURCE_GUIDE.md
  imports\
  machine\
```

`templates\` 是公开模板源。初始化脚本会将这些文件复制到目标根目录，将占位符替换为本地值，安装工具脚本，并运行验证器。

## 工作流模型

1. 初始化本地 `.agents` 目录。
2. 填写非敏感机器事实。
3. 运行验证器。
4. 要求本地 Agent 读取 `AGENT_MEMORY_IMPORT_PROMPT.md`。
5. 将导入后的稳定记忆保存到该 Agent 自身的持久层。
6. 记录或审查 Agent 返回的导入回执。
7. 当工作流版本、清单、验证器或机器事实发生实质变化时重新导入。

## 安全模型

共享记忆文件不得包含凭据、令牌、密码、私钥、Cookie、服务密钥或私有会话日志。

适合记录的内容包括：

- 已验证的工具可用性
- 稳定的本地路径
- 非敏感环境说明
- 启动和执行偏好
- 维护策略
- 本地 Agent 导入状态

验证器会扫描常见敏感信息模式，但在发布或共享任何机器特定文件前，仍必须进行人工审查。

## 版本

当前工作流版本为 `workflow-v3`。版本标记保存在清单、导入提示、回执模板、工作流摘要和导入注册表中。

## 许可证

本项目基于 MIT License 发布。详见 [LICENSE](LICENSE)。
