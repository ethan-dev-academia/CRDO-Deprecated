import SwiftUI
import UIKit

struct CRDOCityView: View {
    var onClose: (() -> Void)? = nil
    @State private var showMenu = false
    @State private var showCollections = false
    @State private var isBuildMode = false
    @State private var buildBuilding: CollectionBuilding? = nil
    @State private var buildPos: (x: Int, y: Int)? = nil
    @State private var buildScreenPos: CGPoint? = nil
    @State private var showConfirm: Bool = false
    let gridSize = 30
    @State private var placedBuildings: [(building: CollectionBuilding, mapPos: CGPoint)] = []
    let tileSize: CGFloat = 32
    let zoom: CGFloat = 0.6 // Fixed zoomed-out scale

    @State private var pan: CGSize = .zero
    @State private var lastPan: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                Color(UIColor.systemGray6).ignoresSafeArea()
                // Draw the isometric grid
                IsometricGrid(
                    visibleTiles: computeVisibleTiles(gridSize: gridSize),
                    tileSize: tileSize,
                    gridSize: gridSize
                )
                .frame(width: geo.size.width, height: geo.size.height)
                .scaleEffect(zoom)
                .offset(pan)
                // Render all placed buildings
                ForEach(0..<placedBuildings.count, id: \.self) { idx in
                    let placed = placedBuildings[idx]
                    // Convert map position to screen position
                    let screenX = (placed.mapPos.x - geo.size.width / 2) * zoom + geo.size.width / 2 + pan.width
                    let screenY = (placed.mapPos.y - geo.size.height / 2) * zoom + geo.size.height / 2 + pan.height
                    placed.building.art
                        .frame(width: tileSize * 1.5, height: tileSize * 1.5)
                        .position(x: screenX, y: screenY)
                }
                // Build mode overlay: show building following drag
                if isBuildMode, let building = buildBuilding, let screenPos = buildScreenPos {
                    building.art
                        .frame(width: tileSize * 1.5, height: tileSize * 1.5)
                        .position(screenPos)
                    if showConfirm {
                        Button(action: {
                            // Convert screenPos to mapPos
                            let mapX = (screenPos.x - pan.width - geo.size.width / 2) / zoom + geo.size.width / 2
                            let mapY = (screenPos.y - pan.height - geo.size.height / 2) / zoom + geo.size.height / 2
                            let mapPos = CGPoint(x: mapX, y: mapY)
                            placedBuildings.append((building: building, mapPos: mapPos))
                            // Persist to UserDefaults
                            let saveArray = placedBuildings.map { ["name": $0.building.name, "x": $0.mapPos.x, "y": $0.mapPos.y] }
                            UserDefaults.standard.set(saveArray, forKey: "placedBuildings")
                            isBuildMode = false
                            buildBuilding = nil
                            buildScreenPos = nil
                            showConfirm = false
                        }) {
                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.green)
                                .shadow(radius: 8)
                        }
                        .position(x: screenPos.x + tileSize, y: screenPos.y)
                    }
                }
                // Menu and exit button
                VStack(alignment: .leading, spacing: 10) {
                    if showMenu {
                        Button(action: { showCollections = true }) {
                            HStack {
                                Image(systemName: "square.grid.2x2")
                                    .resizable()
                                    .frame(width: 22, height: 22)
                                    .foregroundColor(.purple)
                                Text("Collections")
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.white.opacity(0.95))
                            .cornerRadius(16)
                            .shadow(radius: 3)
                        }
                        if let onClose = onClose {
                            Button(action: { onClose() }) {
                                HStack {
                                    Image(systemName: "door.left.hand.open")
                                        .resizable()
                                        .frame(width: 22, height: 22)
                                        .foregroundColor(.blue)
                                    Text("Exit")
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(.black)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.white.opacity(0.95))
                                .cornerRadius(16)
                                .shadow(radius: 3)
                            }
                        }
                    }
                    Button(action: { showMenu.toggle() }) {
                        Image(systemName: "line.3.horizontal")
                            .resizable()
                            .frame(width: 28, height: 16)
                            .foregroundColor(.black)
                            .padding(8)
                            .background(Color.white.opacity(0.95))
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                }
                .padding([.leading, .bottom], 24)
                // Collections popup
                if showCollections {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        VStack(spacing: 20) {
                            Text("Collections")
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(.purple)
                            LazyVGrid(columns: [GridItem(.flexible())], spacing: 24) {
                                ForEach(collectionBuildings) { building in
                                    VStack(spacing: 8) {
                                        building.art
                                            .frame(width: 64, height: 64)
                                            .onLongPressGesture {
                                                showCollections = false
                                                isBuildMode = true
                                                buildBuilding = building
                                                buildPos = (gridSize/2, gridSize/2)
                                            }
                                        Text(building.name)
                                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                                            .foregroundColor(.black)
                                    }
                                }
                            }
                            Button(action: { showCollections = false }) {
                                Text("Close")
                                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 30)
                                    .background(Color.purple)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(40)
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(radius: 10)
                    }
                }
            }
            // Attach gestures to the ZStack (entire screen)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if isBuildMode {
                            // Move building overlay to finger position (screen coordinates)
                            buildScreenPos = value.location
                        } else {
                            pan = CGSize(
                                width: lastPan.width + value.translation.width,
                                height: lastPan.height + value.translation.height
                            )
                        }
                    }
                    .onEnded { _ in
                        lastPan = pan
                    }
            )
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("CRDO City")
    }
}

struct IsometricTile: View {
    let x: Int
    let y: Int
    let tileSize: CGFloat
    let gridSize: Int

    var body: some View {
        let isoX = (CGFloat(x - y) * tileSize / 2) + CGFloat(gridSize) * tileSize / 2
        let isoY = (CGFloat(x + y) * tileSize / 4)
        return Rectangle()
            .fill(Color.gray.opacity(0.15))
            .frame(width: tileSize, height: tileSize / 2)
            .rotationEffect(.degrees(45))
            .overlay(
                Rectangle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    .rotationEffect(.degrees(45))
            )
            .position(x: isoX, y: isoY)
    }
}

// Add this shape for isometric tile highlight
struct IsometricTileShape: Shape {
    let tileSize: CGFloat
    func path(in rect: CGRect) -> Path {
        let w = tileSize
        let h = tileSize / 2
        var path = Path()
        path.move(to: CGPoint(x: w/2, y: 0))
        path.addLine(to: CGPoint(x: w, y: h/2))
        path.addLine(to: CGPoint(x: w/2, y: h))
        path.addLine(to: CGPoint(x: 0, y: h/2))
        path.closeSubpath()
        return path
    }
}

// Add this before IsometricTileGlow
enum TileGlowColor { case green, red }

// Update IsometricTileGlow to use IsometricTileShape
struct IsometricTileGlow: View {
    let tileSize: CGFloat
    let color: TileGlowColor
    var body: some View {
        let glow = color == .green ? Color.green : Color.red
        ZStack {
            IsometricTileShape(tileSize: tileSize)
                .fill(glow.opacity(0.25))
                .frame(width: tileSize, height: tileSize / 2)
                .overlay(
                    IsometricTileShape(tileSize: tileSize)
                        .stroke(glow, lineWidth: 3)
                        .shadow(color: glow, radius: 12)
                        .frame(width: tileSize, height: tileSize / 2)
                )
        }
    }
}

// Add this subview for a single tile:
struct IsometricGridTile: View {
    let x: Int
    let y: Int
    let tileSize: CGFloat
    let gridSize: Int
    var body: some View {
        IsometricTile(x: x, y: y, tileSize: tileSize, gridSize: gridSize)
    }
}

// Add this struct for grid tile identity:
struct GridTile: Hashable, Identifiable {
    let x: Int
    let y: Int
    var id: String { "\(x)-\(y)" }
}

// Add this struct for visible tiles:
struct VisibleTile: Identifiable {
    let x: Int
    let y: Int
    var id: String { "\(x)-\(y)" }
}

// Add this function to compute visible tiles (for now, returns all tiles):
func computeVisibleTiles(gridSize: Int) -> [VisibleTile] {
    (0..<gridSize).flatMap { x in (0..<gridSize).map { y in VisibleTile(x: x, y: y) } }
}

// Update IsometricGrid to take visibleTiles:
struct IsometricGrid: View {
    let visibleTiles: [VisibleTile]
    let tileSize: CGFloat
    let gridSize: Int
    var body: some View {
        ForEach(visibleTiles) { tile in
            IsometricGridTile(
                x: tile.x, y: tile.y,
                tileSize: tileSize,
                gridSize: gridSize
            )
        }
    }
}

#Preview {
    CRDOCityView()
}

struct CollectionBuilding: Identifiable {
    let id = UUID()
    let name: String
    let art: AnyView
}

// Remove the loadDevAssetImages function and dynamic loader.
// Replace with a static collectionBuildings array for the asset catalog image.
let collectionBuildings: [CollectionBuilding] = [
    CollectionBuilding(name: "Basic House", art: AnyView(
        Image("Basic_House")
            .resizable()
            .aspectRatio(contentMode: .fit)
    ))
] 
