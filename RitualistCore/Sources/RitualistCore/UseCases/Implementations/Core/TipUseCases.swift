import Foundation

// MARK: - Tip Use Case Implementations

public final class GetAllTips: GetAllTipsUseCase {
    private let repo: TipRepository
    public init(repo: TipRepository) { self.repo = repo }
    public func execute() async throws -> [Tip] { try await repo.getAllTips() }
}

public final class GetFeaturedTips: GetFeaturedTipsUseCase {
    private let repo: TipRepository
    public init(repo: TipRepository) { self.repo = repo }
    public func execute() async throws -> [Tip] {
        // Business logic: Get featured tips and sort by order
        let featuredTips = try await repo.getFeaturedTips()
        return featuredTips.sorted { $0.order < $1.order }
    }
}

public final class GetTipById: GetTipByIdUseCase {
    private let repo: TipRepository
    public init(repo: TipRepository) { self.repo = repo }
    public func execute(id: UUID) async throws -> Tip? { try await repo.getTip(by: id) }
}

public final class GetTipsByCategory: GetTipsByCategoryUseCase {
    private let repo: TipRepository
    public init(repo: TipRepository) { self.repo = repo }
    public func execute(category: TipCategory) async throws -> [Tip] { try await repo.getTips(by: category) }
}