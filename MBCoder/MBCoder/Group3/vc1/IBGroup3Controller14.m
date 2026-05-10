//
//  IBGroup3Controller14.m
//  MBCoder
//
//  Created by 叶修 on 2026/2/6.
//  Copyright © 2026 inke. All rights reserved.
//

#import "IBGroup3Controller14.h"

@interface IBGroup3Controller14 ()

@end

@implementation IBGroup3Controller14

- (void)viewDidLoad {
    [super viewDidLoad];
}

@end

/*

 ============================================================
 AI Agent 原理与实践 面试题总结
 ============================================================

 【核心公式】
 Agent = LLM + Memory + Planning + Tools + Execution

 AI Agent：以大模型（LLM）为核心大脑，在目标驱动下自主完成
 "感知/理解 → 规划 → 行动 → 观察反馈"闭环的智能系统。


 ============================================================
 一、核心组件
 ============================================================

 【1. 大脑 — LLM（Large Language Model）】
 Agent 的认知核心，负责推理、决策、生成。
 关键能力：
 - 指令遵循（Instruction Following）：准确理解并执行复杂指令
 - 推理与规划（Reasoning & Planning）：分解任务、制定步骤
 - 知识整合：结合预训练知识与上下文信息做综合判断
 - 工具调用决策：判断何时、调用哪个工具、传入什么参数

 常见 LLM：GPT-4o、Claude 3.5 Sonnet、Gemini 1.5 Pro、Llama 3、Qwen 等

 【2. 记忆模块（Memory）】
 短期记忆（In-Context Memory）
   当前会话的上下文窗口（Context Window），存储对话历史、中间推理过程
   受 Token 限制，超出后需压缩/摘要或使用 Sliding Window

 长期记忆（External Memory）
   跨会话持久化存储，通过向量数据库实现语义检索
   常见向量数据库：Pinecone / Weaviate / Chroma / Qdrant / Milvus
   实现：将文本 Embedding（向量化）后存入数据库，查询时用语义相似度（余弦相似度/点积）检索

 工作记忆（Working Memory）
   任务执行过程中的中间结果暂存（Scratchpad），ReAct 的 Thought/Observation 即为此

 实体记忆（Entity Memory）
   存储命名实体（人名、组织、概念）及其关系，用于多轮对话的人物/事件追踪

 【3. 规划模块（Planning）】
 将高层目标分解为可执行的子任务序列。
 任务分解策略：
 - 顺序分解：线性步骤（Step 1 → Step 2 → ...）
 - 层次分解：将复杂任务递归拆分为子任务树
 - 依赖分析：识别并行可执行的子任务，提高效率
 反思与修正：执行中评估中间结果，检测偏差并动态调整计划（Self-Reflection）

 【4. 工具（Tools）】
 Agent 与外部世界交互的接口，突破 LLM 纯语言生成的能力边界。
 - 信息获取类：网络搜索（Tavily/SerpAPI）、RAG 检索、数据库查询
 - 代码执行类：Python 解释器、终端命令、SQL 执行
 - API 调用类：第三方 REST API、业务系统（CRM/ERP）
 - 文件操作类：读写文件、图片/PDF 解析
 - 感知类：视觉理解（GPT-4V）、语音识别（Whisper）

 【5. 执行引擎（Execution Engine）】
 根据 LLM 的决策具体调用工具、处理返回结果，并将结果反馈给 LLM 进行下一轮推理，形成闭环。


 ============================================================
 二、推理与规划范式
 ============================================================

 【Chain-of-Thought（CoT，思维链）】
 在 Prompt 中引导 LLM 逐步输出推理过程，而非直接给答案。
 效果：显著提升复杂推理（数学、逻辑）的准确率。
 变体：
 - Zero-shot CoT：在 Prompt 末尾加 "Let's think step by step"
 - Few-shot CoT ：提供带有推理步骤的示例（示范 → 模型模仿）

 【Tree of Thoughts（ToT，思维树）】
 将推理过程建模为树形搜索：LLM 在每个节点生成多个候选思考步骤，
 通过评估函数选择最优分支，支持回溯。
 优点：解决需要探索多种可能路径的复杂问题
 缺点：Token 消耗大，推理成本高

 【ReAct（Reasoning + Acting）】
 将推理和行动交错进行，形成"思考 → 行动 → 观察"迭代循环：
 Thought  ：分析当前状态，决定下一步
 Action   ：选择工具并执行（如 search["query"]）
 Observation：获取工具结果
 → 循环直至任务完成或达到最大步数

 优点：思路透明，易于调试
 缺点：可能陷入循环，依赖单次推理质量，多步累积误差

 【Plan-and-Execute（规划-执行分离）】
 阶段一 规划：生成完整的任务计划（所有步骤）
 阶段二 执行：按计划逐步执行，每步调用工具
 优点：适合长周期复杂任务，目标感强，整体一致性好
 缺点：早期规划错误影响全局，缺乏中途调整灵活性

 【Reflexion（反思自我纠错）】
 Agent 在每次行动后对结果进行自我评估，将失败经验存入记忆，
 下次尝试时利用历史经验避免重蹈覆辙。
 本质：将试错经验转化为语言形式的"学习"。


 ============================================================
 三、Function Calling（工具调用机制）
 ============================================================

 【概念】
 LLM 厂商提供的标准化工具调用接口：开发者定义工具的名称、描述和参数 Schema（JSON Schema），
 LLM 在需要时输出结构化的工具调用请求，而非普通文本。

 【工作流程】
 1. 开发者在 API 请求中传入 tools 列表（每个工具含 name/description/parameters）
 2. LLM 分析用户请求，决定是否需要调用工具
 3. 若需要，LLM 输出 tool_call（含 function_name 和 arguments JSON）
 4. 应用程序解析 tool_call，调用对应函数，获取结果
 5. 将结果作为 tool_result 传回 LLM
 6. LLM 结合工具结果生成最终回复

 【并行工具调用（Parallel Tool Calls）】
 支持在一次推理中输出多个 tool_call，并行执行多个工具，
 提高效率（如同时查询天气和日历）。

 【支持 Function Calling 的模型】
 OpenAI GPT-4o / GPT-4 Turbo、Claude 3（tool_use）、
 Gemini 1.5、通义千问（qwen-max）等


 ============================================================
 四、RAG（Retrieval-Augmented Generation，检索增强生成）
 ============================================================

 【概念】
 在 LLM 生成回答前，先从外部知识库检索相关文档，
 将检索内容作为上下文（Context）注入 Prompt，
 使 LLM 回答基于最新/私有知识，而非仅依赖训练参数。

 解决的问题：
 - 知识截止（Training Cutoff）：LLM 无法获取训练后的新信息
 - 幻觉（Hallucination）：凭空生成不实内容
 - 私有数据：企业内部文档无法训练到 LLM 中

 【RAG 完整流程】

 离线索引阶段（Indexing）：
 1. 文档加载（PDF/Word/网页/数据库）
 2. 文档分块（Chunking）：按固定大小或语义切分（Chunk Size 通常 512~1024 Token）
 3. 向量化（Embedding）：用 Embedding 模型（text-embedding-3、BGE 等）将每块转为向量
 4. 存入向量数据库（Pinecone/Chroma/Milvus）

 在线检索阶段（Retrieval）：
 5. 用户 Query 同样向量化
 6. 在向量数据库中做 ANN（近似最近邻）搜索，取 Top-K 相似文档块
 7. 可选：重排序（Reranker，如 Cohere Rerank / BGE-Reranker）提升精度

 生成阶段（Generation）：
 8. 将检索到的文档块 + 用户 Query 组合为 Prompt
 9. LLM 基于 Prompt 生成回答

 【RAG vs Fine-tuning 对比】
 RAG        ：动态知识更新，私有数据安全，可溯源，推理成本较高
 Fine-tuning：知识固化在权重中，推理快，但更新需重新训练，成本高

 【高级 RAG 优化】
 - HyDE（Hypothetical Document Embeddings）：先让 LLM 生成假设答案，用假设答案向量检索
 - 多查询检索（Multi-Query Retrieval）：从不同角度生成多个查询扩大召回
 - 混合检索（Hybrid Search）：向量相似度 + BM25 关键词检索结合
 - 查询重写（Query Rewriting）：优化原始查询提升检索质量


 ============================================================
 五、MCP（Model Context Protocol）
 ============================================================

 【概念】
 Anthropic 提出的开放标准协议，统一 AI 模型与外部工具/数据源的交互接口。
 类似"AI 领域的 USB 接口"——一次接入，处处可用。

 【解决的问题】
 在 MCP 之前，每个 Agent 框架需为每个工具单独编写适配代码，
 工具与 LLM 之间没有统一标准，维护成本高且不可复用。
 MCP 定义了通用的 Client-Server 协议，任何支持 MCP 的模型都能使用任何 MCP Server。

 【架构】
 MCP Host（如 Claude Desktop / Cursor）：宿主应用，集成 MCP Client
 MCP Client：与 MCP Server 建立连接，转发工具调用请求
 MCP Server：实现具体工具能力（文件系统/数据库/API/搜索等）

 【MCP 提供三类原语】
 Tools（工具） ：可被 LLM 调用的函数（如 read_file / execute_sql）
 Resources（资源）：结构化数据，LLM 可读取但不执行（如文件内容/数据库表数据）
 Prompts（提示） ：预定义的 Prompt 模板，支持参数化

 【传输协议】
 - stdio：本地进程通信（适合本地 MCP Server）
 - HTTP + SSE：远程服务（适合云端部署的 MCP Server）


 ============================================================
 六、多 Agent 协作
 ============================================================

 【协作模式】

 角色扮演（Role-Playing）
   分配不同专长角色：Researcher（搜索信息）/ Coder（写代码）/ Critic（审查结果）
   各 Agent 专注自身职责，协同解决单 Agent 难以胜任的复杂问题

 流水线（Pipeline）
   一个 Agent 的输出作为下一个 Agent 的输入
   适合线性的多阶段任务（如：搜索 → 总结 → 翻译 → 存储）

 分层（Hierarchical）
   Orchestrator Agent 管理多个 Worker Agent
   Orchestrator 负责分解任务和协调，Worker 专注执行具体子任务
   代表框架：LangGraph（支持有状态的 DAG/循环流程）

 辩论（Debate）
   多个 Agent 持不同立场，互相质疑和反驳，最终得出更可靠的结论
   适合事实验证、方案评估等需要多角度分析的场景

 【主流框架】
 LangChain   ：最广泛使用，提供 Chain/Agent/Tool 抽象，生态丰富
 LangGraph   ：LangChain 的有状态图框架，适合复杂多步 Agent 流程
 AutoGen     ：Microsoft 出品，专注多 Agent 对话协作
 CrewAI      ：角色扮演多 Agent 框架，定义 Crew/Agent/Task
 LlamaIndex  ：专注 RAG 和知识库构建
 Dify        ：低代码 Agent 平台，可视化编排流程


 ============================================================
 七、挑战与局限
 ============================================================

 幻觉（Hallucination）
   LLM 可能生成听起来合理但实际不正确的内容。
   缓解：RAG 提供事实依据、输出验证、多 Agent 交叉验证

 长上下文管理
   任务步骤增多后 Context Window 可能溢出，历史信息被截断。
   缓解：记忆压缩/摘要、向量记忆检索

 工具调用可靠性
   LLM 可能调用错误工具、传入错误参数，或在循环中反复失败。
   缓解：工具描述要精确、增加参数校验、设置最大步数限制

 成本与延迟
   多步 Agent 每步都调用 LLM，Token 消耗和响应延迟成倍增加。
   缓解：使用小模型做路由、缓存中间结果、并行执行独立子任务

 安全与可控性
   Agent 具有执行代码、调用 API 的能力，存在提示注入（Prompt Injection）风险。
   缓解：沙箱执行、权限最小化、关键操作人工确认（Human-in-the-Loop）


 ============================================================
 八、常见面试问题
 ============================================================

 Q：Agent 和普通 LLM 对话有什么区别？
 A：普通 LLM 对话是单轮或多轮的被动问答，无状态、无工具，只能生成文本。
    Agent 是主动的目标导向系统：可以自主规划多步骤计划、调用外部工具获取信息或执行操作、
    通过观察反馈迭代修正，直到完成任务。核心区别是"行动能力"和"自主循环"。

 Q：RAG 和 Fine-tuning 应该如何选择？
 A：知识频繁更新、私有数据敏感、需要可溯源引用 → 优先 RAG
    需要改变模型行为/风格/格式、任务高度特定 → Fine-tuning
    大多数企业知识库场景选 RAG，两者也可结合（先 Fine-tune 再 RAG）

 Q：ReAct 和 Plan-and-Execute 的核心区别？
 A：ReAct 是边想边做，每步推理后立即执行，动态适应中间结果，灵活但易累积误差。
    Plan-and-Execute 先完整规划再执行，目标一致性强，适合长任务，
    但计划错误影响全局，且不能根据执行结果动态调整计划。

 Q：什么是 Prompt Injection？如何防御？
 A：攻击者通过构造恶意输入（如嵌入在工具结果或用户输入中的指令），
    试图覆盖系统 Prompt，让 Agent 执行攻击者意图的操作。
    防御：输入内容与系统指令隔离、工具结果做净化处理、关键操作需二次确认、
    最小权限原则（Agent 只能访问必要的工具和数据）。

 Q：如何评估一个 Agent 的质量？
 A：任务完成率（Task Success Rate）：最终完成目标的比例
    步骤效率：完成任务所需的平均步骤数（越少越好）
    工具调用准确率：工具选择是否正确，参数是否准确
    幻觉率：生成内容中不实信息的比例
    延迟和成本：平均响应时间、Token 消耗
    基准测试：AgentBench、WebArena、HumanEval（代码能力）等

*/
