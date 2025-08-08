import Foundation

public protocol TipLocalDataSourceProtocol {
    func getAllTips() async throws -> [Tip]
    func getFeaturedTips() async throws -> [Tip]
    func getTip(by id: UUID) async throws -> Tip?
    func getTips(by category: TipCategory) async throws -> [Tip]
}