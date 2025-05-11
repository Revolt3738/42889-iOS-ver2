//
//  Reservation.swift
//  iOS AS3
//
//  Created by Cecilia Gao on 11/5/2025.
//

import Foundation

struct Reservation: Identifiable {
    let id = UUID()
    var customerName: String
    var reservationTime: Date
    var numberOfGuests: Int
    var contactInfo: String
    var selectedSeats: [(table: Int, seat: Int)]?
}
