//
//  ChartCreator.swift
//  Obj-C-SwiftCharts
//  Shukofukurou-IOS
//
//  Created by 千代田桃 on 9/25/21.
//  Copyright © 2022 MAL Updater OS X Group. All rights reserved.
//

#if canImport(Charts)
import SwiftUI
import Charts
#endif

struct Datapoint: Identifiable {
    var label: String
    var value: Double
    var id = UUID()
}

@objc public class ChartCreator: NSObject {
    @objc func generateBarChart(data: NSString, isScoreChart: Bool) -> UIViewController? {
        if #available(iOS 16, *) {
            let ndata : String = data as String
            if let data = ndata.data(using: .utf8) {
                do {
                    let parseddata = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Double]
                    let cdata = convertDataPoints(data: parseddata!, isScoreChart: isScoreChart)
                    let chart = Chart {
                        ForEach(cdata) { Datapoint in
                            BarMark(
                                x: .value("Label", Datapoint.label),
                                y: .value("Value", Datapoint.value)
                            )
                        }
                    }
                    return UIHostingController(rootView: chart)
                } catch {
                    print(error.localizedDescription)
                    return nil
                }
            }
        }
        return nil
        
    }
    
    func convertDataPoints(data : Dictionary<String, Double>, isScoreChart: Bool) -> Array<Datapoint> {
        var tarray = [Datapoint]()
        let sortedKeys = isScoreChart ? ["10", "9", "8", "7", "6", "5", "4", "3", "2", "1"] : Array(data.keys).sorted(by: <)
        sortedKeys.forEach { key in
            tarray.append(Datapoint.init(label: key, value: data[key] ?? 0))
        }
        return tarray
    }
}

