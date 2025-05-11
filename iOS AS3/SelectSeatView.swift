import SwiftUI

struct Seat: Identifiable {
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
    @Binding var selectedSeat: (table: Int, seat: Int)?
    let numberOfGuests: Int
    
    init(numberOfGuests: Int, selectedSeat: Binding<(table: Int, seat: Int)?>) {
        self.numberOfGuests = numberOfGuests
        self._selectedSeat = selectedSeat
        
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
                        TableView(table: $tables[index], reservationStore: reservationStore)
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
                
                // 如果这是之前选择的座位，标记为已选
                if let selected = selectedSeat, selected.table == tableNum && selected.seat == seatNum {
                    tables[tableIndex].seats[seatIndex].isSelected = true
                }
            }
        }
    }
    
    private func confirmSelection() {
        for table in tables {
            for seat in table.seats where seat.isSelected {
                selectedSeat = (table.tableNumber, seat.seatNumber)
                break
            }
        }
        dismiss()
    }
}

struct TableView: View {
    @Binding var table: Table
    @ObservedObject var reservationStore: ReservationStore
    
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
                                // 切换选择状态
                                table.seats[seatIndex].isSelected.toggle()
                                
                                // 确保同一时间只选择一个座位
                                if table.seats[seatIndex].isSelected {
                                    for otherIndex in table.seats.indices where otherIndex != seatIndex {
                                        table.seats[otherIndex].isSelected = false
                                    }
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
