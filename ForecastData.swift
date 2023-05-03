//
//  ForecastData.swift
//  DuongVincentFinalProject
//
//  Created by Vincent Duong on 5/1/23.
//

import Foundation


struct ForecastData: Codable {
    let forecast: Forecast

    struct Forecast: Codable {
        let forecastday: [Forecastday]
        
        struct Forecastday: Codable {
            let date: String
            let hour: [Hour]
            
            struct Hour: Codable {
                let timeEpoch: TimeInterval
                let tempF: Double

                enum CodingKeys: String, CodingKey {
                    case timeEpoch = "time_epoch"
                    case tempF = "temp_f"
                }
            }
        }
    }
}
