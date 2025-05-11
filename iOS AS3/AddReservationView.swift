import SwiftUI

struct AddReservationView: View {
    @EnvironmentObject var reservationStore: ReservationStore
    @Binding var navigationPath: [NavigationTarget]
    @Environment(\.presentationMode) var presentationMode

    var existingReservationId: UUID? = nil

    @State private var customerName: String = ""
    @State private var reservationTime: Date = Date()
    @State private var numberOfGuests: Int = 1
    @State private var contactInfo: String = ""
    @State private var selectedSeats: [(table: Int, seat: Int)] = []
    @State private var originalValues: (name: String, time: Date, guests: Int, contact: String, seats: [(table: Int, seat: Int)])?

    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Information"
    @State private var showCancelAlert = false

    private var isEditing: Bool {
        existingReservationId != nil
    }

    var body: some View {
        Form {
            Section(header: Text("Customer Information").font(.headline)) {
                TextField("Name", text: $customerName)
                TextField("Contact Information (e.g. Phone Number)", text: $contactInfo)
                    .keyboardType(.phonePad)
            }

            Section(header: Text("Reservation Details").font(.headline)) {
                DatePicker("Reservation Time", selection: $reservationTime, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                Stepper("Number of Guests: \(numberOfGuests)", value: $numberOfGuests, in: 1...20)

                NavigationLink(destination: SelectSeatView(numberOfGuests: numberOfGuests, selectedSeats: $selectedSeats)) {
                    HStack {
                        Text("Select seat")
                        Spacer()
                        if selectedSeats.isEmpty {
                            Text("未选择")
                                .foregroundColor(.gray)
                        } else {
                            Text(selectedSeats.map { "\($0.table)-\($0.seat)" }.joined(separator: ", "))
                                .foregroundColor(.accentColor)
                                .bold()
                        }
                    }
                }
            }

            Button(action: saveReservation) {
                Text(isEditing ? "Update Reservation" : "Confirm Reservation")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.vertical)
            .listRowBackground(Color.accentColor)
            .foregroundColor(.white)
        }
        .navigationTitle(isEditing ? "Edit Reservation" : "Add Reservation")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    if hasChanges() {
                        showCancelAlert = true
                    } else {
                        if !navigationPath.isEmpty {
                            navigationPath.removeLast()
                        }
                    }
                }
            }
        }
        .onAppear {
            loadReservationData()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if alertMessage.contains("successfully") {
                        if !navigationPath.isEmpty {
                            navigationPath.removeLast()
                        }
                    }
                }
            )
        }
        .alert("Confirm Discard Changes", isPresented: $showCancelAlert) {
            Button("Continue Editing", role: .cancel) { }
            Button("Discard Changes", role: .destructive) {
                if let original = originalValues {
                    customerName = original.name
                    reservationTime = original.time
                    numberOfGuests = original.guests
                    contactInfo = original.contact
                    selectedSeats = original.seats
                }

                if !navigationPath.isEmpty {
                    navigationPath.removeLast()
                }
            }
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
    }

    private func loadReservationData() {
        if isEditing, let id = existingReservationId,
           let reservationToEdit = reservationStore.reservations.first(where: { $0.id == id }) {
            customerName = reservationToEdit.customerName
            reservationTime = reservationToEdit.reservationTime
            numberOfGuests = reservationToEdit.numberOfGuests
            contactInfo = reservationToEdit.contactInfo
            selectedSeats = reservationToEdit.selectedSeats ?? []

            originalValues = (
                name: reservationToEdit.customerName,
                time: reservationToEdit.reservationTime,
                guests: reservationToEdit.numberOfGuests,
                contact: reservationToEdit.contactInfo,
                seats: reservationToEdit.selectedSeats ?? []
            )
        }
    }

    private func hasChanges() -> Bool {
        guard let original = originalValues else { return true }

        return customerName != original.name ||
               !Calendar.current.isDate(reservationTime, equalTo: original.time, toGranularity: .minute) ||
               numberOfGuests != original.guests ||
               contactInfo != original.contact ||
        !areSeatArraysEqual(original.seats, selectedSeats)  // ✅ 改这行
    }

    private func seatSort(_ a: (table: Int, seat: Int), _ b: (table: Int, seat: Int)) -> Bool {
        if a.table != b.table { return a.table < b.table }
        return a.seat < b.seat
    }

    func saveReservation() {
        if customerName.isEmpty {
            alertTitle = "Input Error"
            alertMessage = "Please enter customer name."
            showAlert = true
            return
        }
        if contactInfo.isEmpty {
            alertTitle = "Input Error"
            alertMessage = "Please enter contact information."
            showAlert = true
            return
        }
        if selectedSeats.count != numberOfGuests {
            alertTitle = "Seat Selection"
            alertMessage = "Please select exactly \(numberOfGuests) seat(s)."
            showAlert = true
            return
        }

        if isEditing, let id = existingReservationId {
            if let index = reservationStore.reservations.firstIndex(where: { $0.id == id }) {
                reservationStore.reservations[index].customerName = customerName
                reservationStore.reservations[index].reservationTime = reservationTime
                reservationStore.reservations[index].numberOfGuests = numberOfGuests
                reservationStore.reservations[index].contactInfo = contactInfo
                reservationStore.reservations[index].selectedSeats = selectedSeats
            }


            alertTitle = "Success"
            alertMessage = "Reservation updated successfully!"
        } else {
            reservationStore.addReservation(
                customerName: customerName,
                reservationTime: reservationTime,
                numberOfGuests: numberOfGuests,
                contactInfo: contactInfo,
                selectedSeats: selectedSeats
            )

            alertTitle = "Success"
            alertMessage = "Reservation added successfully!"
        }

        showAlert = true
    }
}

func areSeatArraysEqual(_ a: [(table: Int, seat: Int)], _ b: [(table: Int, seat: Int)]) -> Bool {
    let sortedA = a.sorted { $0.table != $1.table ? $0.table < $1.table : $0.seat < $1.seat }
    let sortedB = b.sorted { $0.table != $1.table ? $0.table < $1.table : $0.seat < $1.seat }
    return sortedA.elementsEqual(sortedB, by: { $0.table == $1.table && $0.seat == $1.seat })
}
