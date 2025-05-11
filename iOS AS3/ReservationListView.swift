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
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Customer: \(reservation.customerName)")
                                .font(.headline)
                            Text("Time: \(reservation.reservationTime.formatted(date: .abbreviated, time: .shortened))")
                            Text("Guests: \(reservation.numberOfGuests)")
                            Text("Contact: \(reservation.contactInfo)")
                            if let seats = reservation.selectedSeats, !seats.isEmpty {
                                Text("Seats: \(seats.map { "T\($0.table)-S\($0.seat)" }.joined(separator: ", "))")
                                    .foregroundColor(.blue)
                            } else {
                                Text("Seats: None selected")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 4)
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

