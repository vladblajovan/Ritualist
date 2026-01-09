//
//  AsyncMapSnapshot.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 04.11.2025.
//

import SwiftUI
import MapKit

/// Asynchronously loads and displays a map snapshot without blocking the UI thread.
/// Follows the same pattern as SwiftUI's AsyncImage.
struct AsyncMapSnapshot: View {
    let coordinate: CLLocationCoordinate2D
    let radius: Double
    let locationLabel: String?
    let onTap: () -> Void

    @State private var snapshot: UIImage?
    @State private var isLoading = true
    @State private var loadError: Error?

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if let snapshot = snapshot {
                    // Display the loaded snapshot
                    Image(uiImage: snapshot)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(alignment: .topTrailing) {
                            // Location name overlay
                            if let label = locationLabel {
                                Text(label)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.black.opacity(0.6))
                                    )
                                    .padding(.top, 12)
                                    .padding(.trailing, 12)
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                } else if loadError != nil {
                    // Error state - show placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .aspectRatio(2.0, contentMode: .fit)

                        VStack(spacing: 8) {
                            Image(systemName: "map")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text(Strings.Location.tapToViewMap)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                } else {
                    // Loading state - show placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .aspectRatio(2.0, contentMode: .fit)

                        ProgressView()
                            .scaleEffect(1.5)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                }
            }
        }
        .buttonStyle(.plain)
        .task {
            await loadSnapshot()
        }
    }

    /// Loads the map snapshot asynchronously on a background thread
    private func loadSnapshot() async {
        do {
            // Calculate map region
            let span = calculateMapSpan(for: radius)
            let region = MKCoordinateRegion(center: coordinate, span: span)

            // Configure snapshot options
            let options = MKMapSnapshotter.Options()
            options.region = region
            options.size = CGSize(width: 400, height: 200) // Higher resolution
            options.scale = UIScreen.main.scale // Use device scale
            options.mapType = .standard

            // Create snapshotter (this is lightweight)
            let snapshotter = MKMapSnapshotter(options: options)

            // Generate snapshot on background thread - THIS IS THE KEY
            let snapshot = try await snapshotter.start()

            // Draw annotations on the snapshot
            let finalImage = await drawAnnotations(on: snapshot.image, snapshot: snapshot)

            // Update UI on main thread
            await MainActor.run {
                self.snapshot = finalImage
                self.isLoading = false
            }
        } catch {
            // Handle error
            await MainActor.run {
                self.loadError = error
                self.isLoading = false
            }
        }
    }

    /// Draws the pin and radius circle on the snapshot image
    private func drawAnnotations(on image: UIImage, snapshot: MKMapSnapshotter.Snapshot) async -> UIImage {
        await withCheckedContinuation { continuation in
            // Use image renderer to draw annotations
            let format = UIGraphicsImageRendererFormat()
            format.scale = image.scale

            let renderer = UIGraphicsImageRenderer(size: image.size, format: format)

            let annotatedImage = renderer.image { context in
                // Draw the map snapshot
                image.draw(at: .zero)

                let cgContext = context.cgContext

                // Draw radius circle
                let point = snapshot.point(for: coordinate)
                let radiusInPoints = metersToPoints(radius, at: coordinate, snapshot: snapshot)

                // Circle fill
                cgContext.setFillColor(UIColor.blue.withAlphaComponent(0.2).cgColor)
                cgContext.fillEllipse(in: CGRect(
                    x: point.x - radiusInPoints,
                    y: point.y - radiusInPoints,
                    width: radiusInPoints * 2,
                    height: radiusInPoints * 2
                ))

                // Circle stroke
                cgContext.setStrokeColor(UIColor.blue.cgColor)
                cgContext.setLineWidth(1)
                cgContext.strokeEllipse(in: CGRect(
                    x: point.x - radiusInPoints,
                    y: point.y - radiusInPoints,
                    width: radiusInPoints * 2,
                    height: radiusInPoints * 2
                ))

                // Draw pin marker (same as MapLocationPickerView)
                let pinSize: CGFloat = 30
                let pinRect = CGRect(
                    x: point.x - pinSize / 2,
                    y: point.y - pinSize / 2,
                    width: pinSize,
                    height: pinSize
                )

                // Draw red circle background
                cgContext.setFillColor(UIColor.red.cgColor)
                cgContext.fillEllipse(in: pinRect)

                // Draw mappin.circle.fill icon on top
                if let pinIcon = UIImage(systemName: "mappin.circle.fill",
                                         withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))?.withTintColor(.white, renderingMode: .alwaysOriginal) {
                    let iconRect = CGRect(
                        x: point.x - 10,
                        y: point.y - 10,
                        width: 20,
                        height: 20
                    )
                    pinIcon.draw(in: iconRect)
                }
            }

            continuation.resume(returning: annotatedImage)
        }
    }

    /// Converts meters to points at the given coordinate
    private func metersToPoints(_ meters: Double, at coordinate: CLLocationCoordinate2D, snapshot: MKMapSnapshotter.Snapshot) -> CGFloat {
        // Calculate a point slightly offset by the radius in meters
        let offsetCoordinate = coordinate.offsetBy(meters: meters)

        let centerPoint = snapshot.point(for: coordinate)
        let offsetPoint = snapshot.point(for: offsetCoordinate)

        let distance = sqrt(
            pow(offsetPoint.x - centerPoint.x, 2) +
            pow(offsetPoint.y - centerPoint.y, 2)
        )

        return distance
    }

    /// Calculates the map span to fit the radius nicely in view
    private func calculateMapSpan(for radius: Double) -> MKCoordinateSpan {
        // Show 4x the radius (2x on each side)
        let displayRadius = radius * 4
        let delta = displayRadius / 111_000.0 // 1 degree latitude ≈ 111,000 meters
        return MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
    }
}

// MARK: - CLLocationCoordinate2D Extension

private extension CLLocationCoordinate2D {
    /// Returns a coordinate offset by the given distance in meters
    func offsetBy(meters: Double) -> CLLocationCoordinate2D {
        let metersPerDegree = 111_000.0
        let latitudeOffset = meters / metersPerDegree

        return CLLocationCoordinate2D(
            latitude: latitude + latitudeOffset,
            longitude: longitude
        )
    }
}
