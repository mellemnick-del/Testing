import SwiftUI

struct MoodPicker: View {
    @Binding var mood: Mood

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Mood.allCases) { option in
                Button {
                    withAnimation(.snappy) { mood = option }
                } label: {
                    Text(option.emoji)
                        .font(.title2)
                        .frame(width: 48, height: 48)
                        .background(
                            Circle().fill(mood == option ? Theme.accent.opacity(0.18) : Theme.card)
                        )
                        .overlay(
                            Circle().strokeBorder(mood == option ? Theme.accent : .clear, lineWidth: 1.5)
                        )
                        .scaleEffect(mood == option ? 1.08 : 1)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.label)
                .accessibilityAddTraits(mood == option ? .isSelected : [])
            }
        }
    }
}
