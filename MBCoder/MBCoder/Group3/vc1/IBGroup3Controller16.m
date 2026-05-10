//
//  IBGroup3Controller16.m
//  MBCoder
//
//  Created by 叶修 on 2026/2/9.
//  Copyright © 2026 inke. All rights reserved.
//

#import "IBGroup3Controller16.h"

@interface IBGroup3Controller16 ()

@end

@implementation IBGroup3Controller16

- (void)viewDidLoad {
    [super viewDidLoad];
}

@end

/*

 ============================================================
 规范驱动开发（SDD）与 OpenSpec / SpecKit 面试题总结
 ============================================================

 参考：https://jimmysong.io/zh/book/ai-handbook/sdd/openspec/


 ============================================================
 一、规范驱动开发（SDD，Spec-Driven Development）
 ============================================================

 【概念】
 在编写任何代码之前，先用结构化的规范文档（Spec）描述系统行为、接口契约和验收标准，
 再由人工或 AI Agent 按规范实施的开发方法论。

 核心理念："规范是唯一真相来源（Single Source of Truth）"
 所有设计决策、接口定义、数据模型均以文档化规范为准，代码是规范的产物而非反向文档。

 【传统开发 vs SDD】

 传统开发：
   需求 → 脑中设计 → 直接写代码 → 写文档（通常被跳过）
   问题：理解偏差在实现阶段才暴露、文档与代码脱节、AI 辅助代码质量不稳定

 SDD：
   需求 → 写规范（Spec）→ 人工/AI 审查对齐 → AI 按规范实现 → 归档更新 Spec
   优势：提前暴露设计问题、AI 有明确依据、规范始终与实现同步

 【AI 时代 SDD 的价值】
 为 AI Agent 提供明确的实现依据，避免 Agent "自由发挥"导致实现偏离设计。
 将模糊需求显式化，让需求对齐在编码前完成而非编码后修改。
 Spec 本身作为团队共识的沉淀，新成员、新 AI 均可快速上手。


 ============================================================
 二、OpenSpec 核心概念
 ============================================================

 【定义】
 OpenSpec 是一套面向 AI 辅助开发的规范管理协议，
 定义了如何组织、版本化和演进项目规范，
 以及 AI Agent 如何读取规范、理解变更意图、执行实现任务。

 【核心文件类型】

 project.md
   项目的全局上下文：技术栈、架构决策、团队约定、核心业务概念词汇表。
   AI 在处理任何任务前都会参考此文件，确保对项目有基础认知。

 spec.md（能力规范）
   描述某个功能模块/能力的详细行为规范：
   - 功能描述与边界（What it does / What it doesn't do）
   - 接口定义（API 契约、数据模型、输入输出）
   - 业务规则（约束、校验逻辑、状态转换）
   - 验收标准（Acceptance Criteria）

 design.md（设计文档）
   解释实现方案的"为什么"：
   - 架构选型理由（Why this approach）
   - 被否决的方案（Rejected Alternatives）及原因
   - 已知限制与 trade-off

 proposal.md（变更提案）
   发起变更时填写，说明：
   - 变更原因（Why this change）
   - 影响范围（What will change）
   - 验收标准（Definition of Done）

 tasks.md（任务清单）
   将变更分解为 AI 可逐步执行的原子任务，每条任务明确输入、输出、依赖关系。

 AGENTS.md
   根目录的 AI 行为约定文件，告知 AI Agent：
   - 如何读取和更新 OpenSpec 文件
   - 在哪些情况下需要暂停等待人工审查
   - 项目特有的规范遵守要求


 ============================================================
 三、三阶段核心工作流
 ============================================================

 【阶段一：草案（Draft）】
 目标：将模糊需求转化为结构化规范
 操作：在 openspec/changes/<change-id>/ 下创建：
   - proposal.md：变更背景、影响范围、验收标准
   - specs/ 子目录：只包含本次变更涉及的 delta 规范片段（非全量）
 参与者：开发者 + AI 共同起草（AI 可根据需求描述自动生成草案）
 产出：可供审查的变更提案文档

 【阶段二：审查与对齐（Review & Align）】
 目标：确保规范准确反映真实需求，消除歧义
 操作：
   - 团队成员审查 proposal.md 和 delta specs
   - AI 参与"规范自查"：检测冲突、遗漏的边界条件、不一致的接口定义
   - 生成 tasks.md：将规范分解为有序的实现任务列表
 通过标准：所有相关方对规范达成共识，tasks.md 经确认
 关键原则：实现前发现问题，而非代码审查时

 【阶段三：实施与归档（Implement & Archive）】
 目标：按规范实现功能，并将规范归入主线
 操作：
   - AI 按 tasks.md 顺序逐条执行任务（每步可独立验证）
   - 实现完成后，执行 Archive 命令：
     · 将 changes/<change-id>/specs/ 中的 delta 合并回 openspec/specs/
     · 将 change 目录移入归档区（如 changes/archived/）
     · 更新 project.md 中受影响的内容
   - 归档后 openspec/specs/ 始终代表当前系统的真实状态


 ============================================================
 四、目录结构
 ============================================================

 openspec/
 ├── AGENTS.md                   # AI 行为约定（如何读写 OpenSpec）
 ├── project.md                  # 项目全局上下文（技术栈、词汇表）
 ├── specs/                      # 当前事实（归档后的规范集合）
 │   └── <capability-name>/
 │       ├── spec.md             # 功能行为规范（What & How）
 │       └── design.md           # 设计决策文档（Why）
 └── changes/                    # 进行中的变更提案
     ├── <change-id>/            # 每个变更一个目录
     │   ├── proposal.md         # 变更说明与验收标准
     │   ├── tasks.md            # AI 可执行的任务清单
     │   └── specs/              # 仅含 delta（新增/修改/删除片段）
     └── archived/               # 已完成并归档的变更


 ============================================================
 五、SpecKit
 ============================================================

 【定义】
 SpecKit 是配套 OpenSpec 使用的工具集（CLI 或 SDK），
 提供规范管理的自动化能力，降低 SDD 工作流的人工操作成本。

 【核心功能】

 Init（初始化）
   在已有项目中生成 OpenSpec 目录结构和初始模板文件（AGENTS.md、project.md）。

 Draft（起草变更）
   根据需求描述（自然语言或 Issue 链接）自动生成 proposal.md 草案和 delta specs 框架。

 Validate（校验规范）
   检查规范文件的格式合规性、引用完整性、验收标准是否可测试、
   接口定义是否与现有 specs 存在冲突。

 Diff（规范差异对比）
   展示当前 changes/<change-id>/specs/ 与 openspec/specs/ 之间的差异，
   便于审查阶段快速理解变更范围。

 Archive（归档）
   将已完成变更的 delta specs 自动合并到 openspec/specs/，并清理 changes 目录。
   确保 specs/ 与实现代码保持同步。

 Generate（生成任务）
   将审查通过的 delta specs 自动分解为 tasks.md 中的有序实现任务列表。

 【与 CI/CD 集成】
 在 PR 流程中集成 SpecKit Validate，确保每次代码变更都伴随规范更新。
 归档操作可作为 merge 前的必要步骤，防止"代码改了但规范没更新"的情况。


 ============================================================
 六、OpenSpec 与 AI Agent 的协作模式
 ============================================================

 【Agent 如何使用 OpenSpec】

 任务启动
   Agent 首先读取 project.md 获取项目上下文，
   再读取当前 change 的 proposal.md 理解变更意图。

 实现阶段
   Agent 按 tasks.md 中的任务顺序逐步执行，
   每步完成后更新 tasks.md 中的状态（[ ] → [x]），
   遇到规范不明确时暂停并向用户提问（而非自行决策）。

 规范查阅
   实现过程中随时参考 openspec/specs/ 中的现有规范，
   确保新代码不破坏已有的接口契约和业务规则。

 【与 Cursor Rules/Skills 的关系】
 AGENTS.md 等同于 Cursor 的 Rules，定义 AI 行为规范（始终生效）。
 OpenSpec 的 tasks.md 等同于 Skills 的 Workflow Steps，定义执行步骤。
 三者组合：Rules（约束行为）+ Skills（封装经验）+ OpenSpec（规范依据）= 高质量 AI 辅助开发。


 ============================================================
 七、常见面试问题
 ============================================================

 Q：SDD 和 TDD（测试驱动开发）有什么区别和联系？
 A：TDD 以"测试先行"为核心，通过红-绿-重构循环驱动实现，粒度在函数/方法级别。
    SDD 以"规范先行"为核心，在系统/功能级别描述行为和接口契约，粒度更高。
    两者可以结合：Spec 中的验收标准可以直接转化为测试用例，SDD 的 Spec 为 TDD 的测试提供依据。

 Q：为什么 AI 辅助开发更需要 SDD？
 A：AI 在没有明确规范时会"自由发挥"，可能产生功能正确但架构不符合团队约定的代码。
    SDD 给 AI 提供明确的实现依据（What to build），减少 AI 自主决策的空间。
    规范文档也是 AI 的上下文补充，弥补 AI 不了解项目历史决策的不足。
    归档机制确保 AI 做的变更被显式记录，便于人工审查和回溯。

 Q：OpenSpec 的 delta specs 和全量 specs 的区别是什么？
 A：全量 specs（openspec/specs/）代表当前系统的完整事实状态，是权威的规范来源。
    delta specs（changes/<id>/specs/）只包含本次变更新增、修改或删除的规范片段，
    减少变更提案中不相关内容的干扰，使审查更聚焦。
    Archive 操作将 delta 合并回全量，保证 specs/ 始终最新。

 Q：如何处理规范与实现不一致的情况？
 A：原则上规范优先：如果发现代码偏离规范，应以规范为准修改代码，
    除非规范本身有问题（此时通过新的变更提案修改规范再更新代码）。
    在 CI/CD 中集成规范校验可以提前发现不一致。
    "代码改了但规范没更新"是最危险的状态，需要通过流程强制要求同步。

*/
