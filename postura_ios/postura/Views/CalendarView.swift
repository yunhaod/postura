//
//  CalendarView.swift
//  postura
//
//  Created by YunHao Dong on 12/29/25.
//
import SwiftUI

struct CalendarSheetView: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {

            // Drag indicator
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            // Header
            HStack {
                Text("Select Date")
                    .font(.headline)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .fontWeight(.semibold)
            }
            .padding(.horizontal)

            // Calendar
            DatePicker(
                "",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .padding(.horizontal)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondary.opacity(0.1))
            )
            .padding(.horizontal)

            Spacer()
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}
