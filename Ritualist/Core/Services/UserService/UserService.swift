// Re-export UserService implementations from RitualistCore
import Foundation
import RitualistCore

// Re-export protocols from RitualistCore
public typealias UserService = RitualistCore.UserService
public typealias UserBusinessService = RitualistCore.UserBusinessService

// Re-export implementations from RitualistCore
public typealias MockUserService = RitualistCore.MockUserService
public typealias ICloudUserService = RitualistCore.ICloudUserService
public typealias NoOpUserService = RitualistCore.NoOpUserService
public typealias MockUserBusinessService = RitualistCore.MockUserBusinessService
public typealias ICloudUserBusinessService = RitualistCore.ICloudUserBusinessService
