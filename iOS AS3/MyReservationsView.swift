import SwiftUI

struct MyReservationsView: View {
    @EnvironmentObject var reservationStore: ReservationStore
    @Binding var navigationPath: [NavigationTarget]
    
    let customerNameFilter: String
    @State private var showDeleteConfirmation = false
    @State private var reservationToDelete: UUID? = nil

    private var filteredReservations: [Reservation] {
        if customerNameFilter.isEmpty {
            return reservationStore.reservations
        }
        return reservationStore.reservations.filter {
            $0.customerName.localizedCaseInsensitiveContains(customerNameFilter)
        }
    }

    var body: some View {
        VStack {
            if filteredReservations.isEmpty {
                Text("No reservations found")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(filteredReservations) { reservation in
                            ReservationCard(
                                reservation: reservation,
                                onEdit: {
                                    navigationPath.append(.editReservation(reservationId: reservation.id))
                                },
                                onDelete: {
                                    reservationToDelete = reservation.id
                                    showDeleteConfirmation = true
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(customerNameFilter.isEmpty ? "All Reservations" : "My Reservations")
        .alert("Confirm Cancellation", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                reservationToDelete = nil
            }
            Button("Confirm", role: .destructive) {
                if let id = reservationToDelete {
                    reservationStore.deleteReservation(withId: id)
                }
            }
        } message: {
            Text("Are you sure you want to cancel this reservation?")
        }
    }
}

struct ReservationCard: View {
    let reservation: Reservation
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onEdit) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(reservation.customerName)
                            .font(.headline)
                        Spacer()
                        Text(isUpcoming(date: reservation.reservationTime) ? "Upcoming" : "Past")
                            .font(.caption)
                            .padding(5)
                            .background(isUpcoming(date: reservation.reservationTime) ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                            .cornerRadius(5)
                    }
                    
                    Text("Time: \(reservation.reservationTime.formatted())")
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
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 2)
            }
            
            HStack {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Label("Cancel", systemImage: "trash")
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
        .padding(.horizontal)
    }
    
    private func isUpcoming(date: Date) -> Bool {
        return date > Date()
    }
}

struct MyReservationsView_Previews: PreviewProvider {
    static var previews: some View {
        let store = ReservationStore()
        return NavigationStack {
            MyReservationsView(navigationPath: .constant([]), customerNameFilter: "")
                .environmentObject(store)
        }
    }
}
