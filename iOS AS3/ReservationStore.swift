import SwiftUI

class ReservationStore: ObservableObject {
    @Published var reservations: [Reservation] = []
    
    init() {
        // 示例数据
        addReservation(
            customerName: "张三",
            reservationTime: Date(),
            numberOfGuests: 2,
            contactInfo: "13800138000",
            selectedSeat: (1, 2)
        )
    }
    
    func addReservation(customerName: String, reservationTime: Date, numberOfGuests: Int, contactInfo: String, selectedSeat: (table: Int, seat: Int)? = nil) {
        let newReservation = Reservation(
            customerName: customerName,
            reservationTime: reservationTime,
            numberOfGuests: numberOfGuests,
            contactInfo: contactInfo,
            selectedSeat: selectedSeat
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
        return reservations.contains { $0.selectedSeat?.table == table && $0.selectedSeat?.seat == seat }
    }
}
