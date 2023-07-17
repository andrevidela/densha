//
//  TrainData.swift
//  Train charts
//
//  Created by avidela on 30/06/2023.
//

import Foundation

import SwiftUI
import Charts
import CodableCSV
import CoreLocation

struct DataRow: Identifiable, Codable {
    let date: String
    let time: String
    let elapsed: Int
    let distance: Double
    let speed: Double
    let lat: CLLocationDegrees
    let lon: CLLocationDegrees
    let accuracy: CLLocationAccuracy
    let altitude: CLLocationDistance
    var id = UUID()
    
    private enum CodingKeys: String, CodingKey {
        case date = "Date"
        case time = "Time"
        case elapsed = "Elapsed time (sec)"
        case distance = "Distance (km)"
        case speed = "Speed (km/h)"
        case lat = "Latitude"
        case lon = "Longitude"
        case accuracy = "Accuracy (meters)"
        case altitude = "Altitude (meters)"
    }
}

struct ContentLoader {
    enum Error: Swift.Error {
        case fileNotFound(name: String)
        case fileDecodingFailed(name: String, Swift.Error)
    }

    static func loadBundledContent(fromFileNamed name: String) throws -> [DataRow] {
        guard let url = Bundle.main.url(
            forResource: name,
            withExtension: "csv"
        ) else {
            throw Error.fileNotFound(name: name)
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = CSVDecoder {
                $0.headerStrategy = .firstLine
                $0.delimiters = (", ", "\n")
            }
            let decoded = try decoder.decode([DataRow].self, from: data)
            print("decoded \(decoded)")
            return decoded
        } catch {
            throw Error.fileDecodingFailed(name: name, error)
        }
    }
}

func cleanEmpty(rows: [DataRow]) -> [DataRow] {
    return rows.drop { $0.speed < 1 }.reversed().drop { $0.speed < 1 }.reversed()
}

struct BarChart: View {
    
    @State private var selectedElapsedTime: Int? = nil
    
    let data = {
        switch Result(catching: { try ContentLoader.loadBundledContent(fromFileNamed: "speed_tracker_30_Jun_2023_16_47_04") }) {
        case .success(let v): return cleanEmpty(rows: v)
        case .failure(let err): print(err); return []
    }
    }()
    
    var valueSelectionPopover = SelectionView()
    
    var body: some View {
        Chart {
            ForEach(data) { shape in
                LineMark(
                    x: .value("time", shape.elapsed),
                    y: .value("distance", shape.distance)
                )
            }
            if let selectedElapsedTime {
                RuleMark(x: PlottableValue.value("Selected", selectedElapsedTime))
                    .foregroundStyle(Color.gray.opacity(0.3))
                    .zIndex(-1)
                    .annotation(position: AnnotationPosition.overlay, alignment: Alignment.center, spacing: 0) {
                        SelectionView(name: "Hello")
                    }

            }
//                RuleMark(
//                  x: .value("Selected", selectedDate, unit: .day)
//                )
//                .foregroundStyle(Color.gray.opacity(0.3))
//                .offset(yStart: -10)
//                .zIndex(-1)
//                .annotation(
//                  position: .top, spacing: 0,
//                  overflowResolution: .init(
//                    x: .fit(to: .chart),
//                    y: .disabled
//                  )
//                ) {
//                  valueSelectionPopover
//                }
//              }
        }
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: 10 * 60)
        .chartXSelection(value: $selectedElapsedTime)
        .chartOverlay { (chartProxy: ChartProxy) in
            Color.clear
                .onContinuousHover { hoverPhase in
                    switch hoverPhase {
                    case .active(let hoverLocation):
                        selectedElapsedTime = chartProxy.value(
                            atX: hoverLocation.x, as: Int.self
                        )
                    case .ended:
                        selectedElapsedTime = nil
                    }
                }
        }
        
    }
}
