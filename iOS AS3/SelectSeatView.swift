import SwiftUI

struct Seat: Identifiable, Equatable {
    let id = UUID()
    let seatNumber: Int
    var isSelected: Bool = false
    var isOccupied: Bool = false
}

struct Table: Identifiable {
    let id = UUID()
    let tableNumber: Int
    var seats: [Seat]
}

struct SelectSeatView: View {
    @EnvironmentObject var reservationStore: ReservationStore
    @Environment(\.dismiss) private var dismiss
    @State private var tables: [Table] = []
    @Binding var selectedSeats: [(table: Int, seat: Int)]
    let numberOfGuests: Int

    init(numberOfGuests: Int, selectedSeats: Binding<[(table: Int, seat: Int)]>) {
        self.numberOfGuests = numberOfGuests
        self._selectedSeats = selectedSeats
        
        var tempTables: [Table] = []
        for tableNum in 1...10 {
            var seats: [Seat] = []
            for seatNum in 1...4 {
                seats.append(Seat(seatNumber: seatNum))
            }
            tempTables.append(Table(tableNumber: tableNum, seats: seats))
        }
        _tables = State(initialValue: tempTables)
    }

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    private var selectedCount: Int {
        tables.reduce(0) { $0 + $1.seats.filter { $0.isSelected }.count }
    }

    private var remainingSeats: Int {
        numberOfGuests - selectedCount
    }

    private var canConfirm: Bool {
        selectedCount == numberOfGuests
    }

    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 30) {
                    ForEach(tables.indices, id: \.self) { index in
                        TableView(table: $tables[index], reservationStore: reservationStore, selectedCount: selectedCount, maxSelection: numberOfGuests)
                    }
                }
                .padding()
            }

            Button(action: confirmSelection) {
                Text(remainingSeats > 0 ?
                     "Select \(remainingSeats) more seat(s)" :
                     "Confirm")
                    .foregroundColor(.white)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canConfirm ? Color.accentColor : Color.gray)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
            .disabled(!canConfirm)
        }
        .onAppear {
            checkOccupiedSeats()
        }
    }

    private func checkOccupiedSeats() {
        for tableIndex in tables.indices {
            for seatIndex in tables[tableIndex].seats.indices {
                let tableNum = tables[tableIndex].tableNumber
                let seatNum = tables[tableIndex].seats[seatIndex].seatNumber
                tables[tableIndex].seats[seatIndex].isOccupied = reservationStore.isSeatOccupied(table: tableNum, seat: seatNum)

                if selectedSeats.contains(where: { $0.table == tableNum && $0.seat == seatNum }) {
                    tables[tableIndex].seats[seatIndex].isSelected = true
                }
            }
        }
    }

    private func confirmSelection() {
        selectedSeats = tables.flatMap { table in
            table.seats.filter { $0.isSelected }.map { (table.tableNumber, $0.seatNumber) }
        }
        dismiss()
    }
}

struct TableView: View {
    @Binding var table: Table
    @ObservedObject var reservationStore: ReservationStore
    let selectedCount: Int
    let maxSelection: Int

    var body: some View {
        VStack(spacing: 10) {
            Text("Table \(table.tableNumber)")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.fixed(40)), GridItem(.fixed(40))], spacing: 15) {
                ForEach(table.seats.indices, id: \.self) { seatIndex in
                    let seat = table.seats[seatIndex]
                    SeatView(seat: seat)
                        .onTapGesture {
                            if !seat.isOccupied {
                                if seat.isSelected {
                                    table.seats[seatIndex].isSelected = false
                                } else if selectedCount < maxSelection {
                                    table.seats[seatIndex].isSelected = true
                                }
                            }
                        }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct SeatView: View {
    let seat: Seat

    var body: some View {
        Circle()
            .fill(seat.isOccupied ? Color.red : (seat.isSelected ? Color.blue : Color.green))
            .frame(width: 40, height: 40)
            .overlay(
                Text("\(seat.seatNumber)")
                    .foregroundColor(.white)
                    .bold()
            )
            .opacity(seat.isOccupied ? 0.6 : 1)
            .animation(.easeInOut, value: seat.isSelected)
            .animation(.easeInOut, value: seat.isOccupied)
    }
}
