import Foundation

struct ClaudeCodeAdapter: AgentAdapter {
    let kind = AgentKind.claudeCode
    let projectSkillPath = ".claude/skills"
    let globalSkillPath = ".claude/skills"
}
