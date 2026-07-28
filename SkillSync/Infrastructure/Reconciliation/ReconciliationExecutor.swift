import Foundation

actor ReconciliationExecutor {
    private let fileSystem: SkillFileSystem

    init(fileSystem: SkillFileSystem) {
        self.fileSystem = fileSystem
    }

    func apply(_ plan: ReconciliationPlan) async throws -> OperationReceipt {
        var applied: [PlannedOperation] = []
        var reversals: [PlannedOperation] = []

        do {
            for operation in plan.operations {
                switch operation {
                case let .createDirectory(url):
                    if await !fileSystem.directoryExists(at: url) {
                        try await fileSystem.createDirectory(at: url)
                        applied.append(operation)
                    }
                case let .move(source, destination):
                    try await fileSystem.moveItem(from: source, to: destination)
                    applied.append(operation)
                    reversals.insert(.move(source: destination, destination: source), at: 0)
                case let .backup(source, destination):
                    try await fileSystem.moveItem(from: source, to: destination)
                    applied.append(operation)
                    reversals.insert(.move(source: destination, destination: source), at: 0)
                case let .createSymbolicLink(link, destination):
                    try await fileSystem.createRelativeSymbolicLink(
                        at: link,
                        destination: destination
                    )
                    applied.append(operation)
                }
            }
        } catch {
            await rollback(applied: applied, reversals: reversals)
            throw error
        }

        return OperationReceipt(
            id: UUID(),
            planID: plan.id,
            completedAt: .now,
            appliedOperations: applied,
            reversalOperations: reversals
        )
    }

    func undo(_ receipt: OperationReceipt) async throws {
        for operation in receipt.appliedOperations.reversed() {
            if case let .createSymbolicLink(link, _) = operation,
                await fileSystem.itemExists(at: link)
            {
                try await fileSystem.removeItem(at: link)
            }
        }
        for reversal in receipt.reversalOperations {
            if case let .move(source, destination) = reversal {
                try await fileSystem.moveItem(from: source, to: destination)
            }
        }
    }

    private func rollback(applied: [PlannedOperation], reversals: [PlannedOperation]) async {
        for operation in applied.reversed() {
            if case let .createSymbolicLink(link, _) = operation {
                try? await fileSystem.removeItem(at: link)
            }
        }
        for reversal in reversals {
            if case let .move(source, destination) = reversal {
                try? await fileSystem.moveItem(from: source, to: destination)
            }
        }
    }
}
