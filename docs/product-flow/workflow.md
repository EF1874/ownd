# Product Workflow

> 中文说明：这是项目标准流程定义文件。阶段名保持稳定，内容可按中文维护。

## Stages

1. Discovery
2. Requirements
3. Architecture
4. Technology Selection
5. UX And UI
6. Planning
7. Implementation
8. Acceptance And Release

## Stage Rules

### Discovery

中文阶段名：想法澄清

Inputs:

- initial idea
- known constraints

Outputs:

- problem statement
- target users
- MVP boundary

Gate:

- direction is confirmed

### Requirements

中文阶段名：需求定义

Inputs:

- discovery notes

Outputs:

- approved `prd.md`
- MVP acceptance criteria

Gate:

- PRD is approved

### Architecture

中文阶段名：架构设计

Inputs:

- approved PRD

Outputs:

- approved `architecture.md`
- durable decisions in `decisions.md`

Gate:

- architecture direction is approved

### Technology Selection

中文阶段名：技术选型

Inputs:

- approved architecture

Outputs:

- approved `tech-stack.md`
- stack and skill decisions recorded in `decisions.md`

Gate:

- selected technologies are approved
- required skills are identified
- installation plan is approved

### UX And UI

中文阶段名：交互与界面设计

Inputs:

- approved PRD
- architecture constraints
- selected stack constraints when relevant

Outputs:

- approved `ux-ui.md`

Gate:

- primary flows and design direction are approved

### Planning

中文阶段名：实施规划

Inputs:

- approved product, architecture, UX, and stack artifacts

Outputs:

- approved `implementation-plan.md`
- sequenced `backlog.md`

Gate:

- implementation target is explicit

### Implementation

中文阶段名：开发实施

Inputs:

- approved plan
- approved stack and available skills

Outputs:

- code and updated delivery state

Gate:

- milestone goal is met

### Acceptance And Release

中文阶段名：验收与发布

Inputs:

- completed implementation milestone

Outputs:

- `acceptance.md`
- release recommendation

Gate:

- verification is complete
