import SwiftUI

struct ReservationListView: View {
    @EnvironmentObject var reservationStore: ReservationStore

    var body: some View {
        VStack {
            if reservationStore.reservations.isEmpty {
                Text("No reservations available")
                    .font(.headline)
                    .foregroundColor(.gray)
            } else {
                List {
                    ForEach(reservationStore.reservations) { reservation in
                        VStack(alignment: .leading) {
                            Text("Customer: \(reservation.customerName)")
                                .font(.headline)
                            Text("Time: \(reservation.reservationTime.formatted(date: .abbreviated, time: .shortened))")
                            Text("Guests: \(reservation.numberOfGuests)")
                            Text("Contact: \(reservation.contactInfo)")
                            if let seat = reservation.selectedSeat {
                                Text("Table \(seat.table) - Seat \(seat.seat)")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Reservation List")
    }
}

struct ReservationListView_Previews: PreviewProvider {
    static var previews: some View {
        let store = ReservationStore()
        return NavigationView {
            ReservationListView()
                .environmentObject(store)
        }
    }
}
