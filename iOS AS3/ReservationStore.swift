import SwiftUI

class ReservationStore: ObservableObject {
    @Published var reservations: [Reservation] = []

    init() {
        addReservation(
            customerName: "张三",
            reservationTime: Date(),
            numberOfGuests: 2,
            contactInfo: "13800138000",
            selectedSeats: [(1, 2), (1, 3)]
        )
    }

    func addReservation(customerName: String, reservationTime: Date, numberOfGuests: Int, contactInfo: String, selectedSeats: [(table: Int, seat: Int)]) {
        let newReservation = Reservation(
            customerName: customerName,
            reservationTime: reservationTime,
            numberOfGuests: numberOfGuests,
            contactInfo: contactInfo,
            selectedSeats: selectedSeats
        )
        reservations.append(newReservation)
    }

    func deleteReservation(withId id: UUID) {
        reservations.removeAll { $0.id == id }
    }

    func updateReservation(_ updatedReservation: Reservation) {
        if let index = reservations.firstIndex(where: { $0.id == updatedReservation.id }) {
            reservations[index] = updatedReservation
            objectWillChange.send()
        }
    }

    func isSeatOccupied(table: Int, seat: Int) -> Bool {
        for reservation in reservations {
            if let seats = reservation.selectedSeats {
                if seats.contains(where: { $0.table == table && $0.seat == seat }) {
                    return true
                }
            }
        }
        return false
    }
}
