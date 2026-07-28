import Foundation

struct AgentsStandardAdapter: AgentAdapter {
    let kind = AgentKind.agentsStandard
    let projectSkillPath = ".agents/skills"
    let globalSkillPath = ".agents/skills"
}
