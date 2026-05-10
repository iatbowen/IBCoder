//
//  IBGroup3Controller15.m
//  MBCoder
//
//  Created by 叶修 on 2026/2/6.
//  Copyright © 2026 inke. All rights reserved.
//

#import "IBGroup3Controller15.h"

@interface IBGroup3Controller15 ()

@end

@implementation IBGroup3Controller15

- (void)viewDidLoad {
    [super viewDidLoad];
}

@end

/*

 ============================================================
 MCP / Skills / Rules — Cursor AI 开发模式 面试题总结
 ============================================================


 ============================================================
 一、MCP（Model Context Protocol）
 ============================================================

 【概念】
 Anthropic 提出的开放标准协议，旨在统一 LLM 与外部数据源、工具之间的通信接口。
 类比"AI 领域的 USB 接口"：工具侧实现 MCP Server，模型侧统一按协议调用，
 无需为每个工具单独编写适配代码。

 【解决的核心问题】
 在 MCP 之前：每个 Agent 框架/应用需为每种工具单独编写集成代码，
 重复工作量大、无法复用、维护成本高。
 MCP 之后：工具供应商实现一次 MCP Server，所有支持 MCP 的 Host 均可接入。

 【核心架构：Client-Server 模型】

 MCP Host（宿主应用）
   发起请求的 LLM 应用，如 Claude Desktop、Cursor、Zed 等。
   内部集成 MCP Client，管理与多个 MCP Server 的连接。

 MCP Client
   在 Host 程序内部运行，与单个 MCP Server 保持 1:1 的长连接。
   负责协议握手、能力协商（Capability Negotiation）、消息路由。

 MCP Server
   向 Client 暴露 Tools / Resources / Prompts 三类原语。
   可访问本地资源（文件系统、本地数据库）或远程资源（REST API、云服务）。

 【三类原语（Three Primitives）】

 Tools（工具）
   LLM 可主动调用的函数，每个 Tool 包含 name / description / inputSchema（JSON Schema）。
   执行后返回结果，LLM 将结果纳入上下文继续推理。
   示例：read_file、execute_sql、web_search、send_email

 Resources（资源）
   结构化数据，供 LLM 读取参考，但不触发执行逻辑。
   通过 URI 标识（如 file:///path/to/doc、db://table/users）。
   示例：文档内容、数据库表结构、配置文件

 Prompts（提示模板）
   服务器预定义的、可参数化的 Prompt 模板。
   Host 可将其注入到对话中，统一团队或应用的提示规范。
   示例：代码审查模板、错误分析引导模板

 【传输协议】

 stdio（标准输入/输出）
   Client 以子进程方式启动 Server，通过 stdin/stdout 交换 JSON-RPC 消息。
   适用：本地工具（文件系统、本地数据库、Shell 命令）
   优点：无网络开销，简单可靠；缺点：无法跨机器

 HTTP + SSE（Server-Sent Events）
   Client 通过 HTTP POST 发送请求，Server 通过 SSE 推送响应（流式支持）。
   适用：远程服务、云端部署、需要跨网络访问的工具
   优点：支持分布式部署；缺点：需要网络，实现复杂度较高

 Streamable HTTP（新版标准）
   HTTP POST 请求 + 流式响应，可替代 SSE，兼容性更好。
   MCP 规范 2025-03-26 版本起推荐。

 【安全机制】

 OAuth 2.1
   远程 MCP Server 的鉴权标准，授权特定 Client 访问特定资源/工具。
   遵循最小权限原则（Principle of Least Privilege）。

 Prompt Injection 防御
   恶意内容（如文档中嵌入的伪指令）可能劫持 Agent 行为。
   防御：工具返回结果与系统指令隔离；关键操作（删除/写入）需 Human-in-the-Loop 确认。

 工具权限隔离
   每个 MCP Server 只暴露必要工具，避免单一 Server 权限过大。

 【MCP 的局限】
 只解决"工具接入"（如何连接），不解决"工具编排"（如何组合使用）。
 不定义多步决策、状态机、分支、重试、审批等业务流程逻辑。
 复杂业务动作（如"报销审批"）仍需在 Agent 层或 Workflow 层自行编排。


 ============================================================
 二、Skills（技能）
 ============================================================

 【概念】
 将完成某类任务的完整经验打包为可复用的"能力扩展包"，供 Agent 按需加载。
 不只解决"工具能不能用"，还解决"工具怎么用好"。

 一个 Skill 封装了：
 - 该调用哪些工具（allowed_tools）
 - 按什么顺序调用（Workflow Steps）
 - 每步提示词怎么写（Examples / Best Practices）
 - 遇到错误如何处理（Error Handling）

 【渐进式披露（Progressive Disclosure）】
 核心设计原则：按需加载，最小化上下文占用。

 Layer 1 — 元数据层（启动时加载）
   内容：SKILL.md 的 Frontmatter（YAML），含 name / description / allowed_tools
   时机：Agent 启动时一次性扫描所有 Skill 的简介，判断哪些可能用得上
   占用：极少（通常几十个 Token）

 Layer 2 — 指令层（任务匹配时加载）
   内容：SKILL.md 正文，含 Workflow Steps / Examples / Best Practices
   时机：Agent 判断某 Skill 与当前任务相关后，读取完整指令
   占用：中等（数百至数千 Token）

 Layer 3 — 资源层（按需加载）
   内容：scripts/、references/、assets/ 下的脚本与数据文件
   时机：执行具体步骤时才读取，且仅读取所需文件
   占用：按需，理论上无上限

 对比 MCP 的一次性全量加载：Skills 的渐进式加载显著降低上下文开销，
 使 Agent 在 Context Window 有限的情况下支持更多能力。

 【推荐目录结构】
 .cursor/
 └── skills/
     └── deploy-app/
         ├── SKILL.md          ← 核心指令文件（含 Frontmatter）
         ├── scripts/
         │   ├── deploy.sh
         │   └── validate.py
         ├── references/
         │   └── REFERENCE.md  ← 背景知识、API 文档节选
         └── assets/
             └── config-template.json

 【SKILL.md 文件格式】
 YAML Frontmatter（元数据）：
   name: deploy-app
   description: 将应用部署到生产环境，包含构建、校验和发布步骤。
   allowed_tools: [Bash, Read, Write, WebSearch]

 Markdown 正文（指令）：
   ## 使用时机
   用户要求部署应用到线上、发布新版本时使用此 Skill。

   ## 步骤
   1. 运行 validate.py 校验配置
   2. 执行 deploy.sh 构建并上传
   3. 验证部署结果，失败时回滚


 ============================================================
 三、Rules（规则）
 ============================================================

 【概念】
 在 Cursor 中以 Markdown 文件（.cursor/rules/*.mdc）形式定义的持久化 AI 指导规范。
 告诉 Agent 在特定场景下"应该怎么做"，而非"要做什么任务"。

 【四种触发类型】

 Always（始终附加）
   每次对话都自动注入到系统 Prompt。
   适用：全局编码规范、项目技术栈约定、通用输出格式要求。

 Auto Attached（自动附加）
   通过 glob 模式匹配文件路径（如 *.swift），匹配时自动激活。
   适用：特定语言/框架的规范（Swift Style Guide、React 组件规范）。

 Agent（Agent 模式专用）
   仅在 Agent 模式（Composer Agent）下自动激活。
   适用：Agent 行为约束（禁止某些命令、必须先读文件再编辑）。

 Manual（手动引用）
   需要在对话中用 @rule-name 显式引用才生效。
   适用：不频繁使用但需要精准控制的规范（特殊场景的迁移指南）。


 ============================================================
 四、MCP vs Skills vs Rules 横向对比
 ============================================================

 MCP
   定义：标准化工具接入协议（连接层）
   解决：如何让模型访问外部工具和数据
   加载方式：工具列表在连接时一次性注册
   编写语言：任意（Python/Node/Go 等，需实现 MCP Server）
   安全性：高（OAuth 2.1、权限隔离）
   适用场景：数据库、搜索、API 等外部工具接入

 Skills
   定义：任务经验封装包（能力层）
   解决：如何把工具用好、完成特定任务
   加载方式：渐进式按需加载（三层结构）
   编写语言：Markdown + YAML（低成本）
   安全性：中（无标准鉴权，依赖 Host 沙箱）
   适用场景：复杂任务流程封装、团队经验共享

 Rules
   定义：持久化 AI 行为规范（约束层）
   解决：如何规范 Agent 的行为和输出风格
   加载方式：按触发类型注入 System Prompt
   编写语言：Markdown（极低成本）
   安全性：低（纯 Prompt 级别）
   适用场景：编码规范、项目约定、输出格式统一

 System Prompt（直接注入）
   定义：直接注入上下文的指令（最底层）
   解决：单次对话的行为控制
   加载方式：每次对话直接写入
   适用场景：一次性指令、测试


 ============================================================
 五、常见面试问题
 ============================================================

 Q：MCP 和 Function Calling 有什么区别？
 A：Function Calling 是 OpenAI 等厂商定义的 LLM 内置工具调用机制，
    解决"LLM 如何决定调用哪个工具、如何传参"，是模型能力层面的标准。
    MCP 是工具接入的传输层协议，解决"工具如何以统一方式暴露给任何 LLM Host"。
    两者互补：MCP Server 通过 MCP 协议暴露工具，Host 内部用 Function Calling 让 LLM 决策调用。

 Q：为什么 Skills 的渐进式加载比 MCP 的全量加载更适合复杂任务？
 A：LLM 的 Context Window 有限，如果一次性把所有工具定义和指令注入，
    会快速消耗 Token 配额，挤压有效任务内容的空间，还会干扰 LLM 的注意力。
    Skills 的三层结构让 Agent 在任务启动时只加载摘要（几十 Token），
    只有在确认需要某个 Skill 时才加载完整指令，真正用到脚本/数据时才读取文件，
    从而在有限的上下文中支持更多能力，且不同任务之间干扰更少。

 Q：Rules 和 Skills 有什么本质区别？何时用哪个？
 A：Rules 是"约束层"——告诉 Agent 写代码时遵守什么规范、输出用什么格式，
    始终生效，偏向静态约定，适合团队编码规范和项目约定。
    Skills 是"能力层"——告诉 Agent 如何完成某类任务，包含具体步骤和工具调用逻辑，
    按需激活，偏向动态经验，适合复杂业务流程的封装和复用。
    简单判断：要"约束行为风格"用 Rules，要"封装任务经验"用 Skills。

 Q：MCP 如何防御 Prompt Injection 攻击？
 A：Prompt Injection 指攻击者在工具返回的内容（如文件/网页）中嵌入伪指令，
    试图劫持 Agent 行为。MCP 层面的防御包括：
    1. 工具结果与系统指令在上下文中明确隔离（加标签区分来源）
    2. 敏感操作（文件删除、数据写入、外部 API 调用）需 Human-in-the-Loop 二次确认
    3. 每个 MCP Server 遵循最小权限原则，只暴露必要工具
    4. 输入净化：处理工具结果前过滤可能的控制字符和指令注入特征

 Q：什么场景下应该自己开发 MCP Server？
 A：当你有以下需求时，开发 MCP Server 是合适的选择：
    1. 需要让 AI 访问私有数据源（内部数据库、企业 API、私有文档库）
    2. 现有工具没有对应的 MCP Server 实现
    3. 需要将工具能力标准化后在多个 Agent/Host 中复用
    4. 需要对工具访问做精细的权限控制（OAuth 2.1）
    开发成本：Python 用 FastMCP、Node.js 用 @modelcontextprotocol/sdk，
    通常只需定义工具的 name/description/inputSchema 和对应的处理函数即可。

*/
