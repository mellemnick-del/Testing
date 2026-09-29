import SwiftUI
import SwiftData

/// Chores, a weekly scoreboard, and rewards for the whole household.
struct FamilyView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FamilyMember.createdAt) private var members: [FamilyMember]
    @Query private var reminders: [Reminder]
    @Query private var completions: [TaskCompletion]
    @Query(sort: \Reward.startedAt, order: .reverse) private var rewards: [Reward]

    @State private var sheet: Sheet?

    private enum Sheet: Identifiable {
        case chore(FamilyMember?), reward, newMember, editMember(FamilyMember), editReward(Reward)
        var id: String {
            switch self {
            case .chore(let member): "chore-\(member?.memberID ?? "me")"
            case .reward: "reward"
            case .newMember: "newMember"
            case .editMember(let member): "member-\(member.memberID)"
            case .editReward(let reward): "reward-\(reward.persistentModelID.hashValue)"
            }
        }
    }

    private var weekStart: Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
    }

    private func weekPoints(for memberID: String?) -> Int {
        completions
            .filter { $0.completedAt >= weekStart && $0.assigneeID == memberID }
            .reduce(0) { $0 + $1.points }
    }

    private var familyWeekTotal: Int {
        completions.filter { $0.completedAt >= weekStart }.reduce(0) { $0 + $1.points }
    }

    private func chores(for member: FamilyMember) -> [Reminder] {
        reminders
            .filter { $0.assigneeID == member.memberID && ($0.isScheduledToday || $0.isOverdue || ($0.dueDate == nil && !$0.isDone)) }
            .sorted {
                if $0.isDone != $1.isDone { return !$0.isDone }
                return $0.minuteOfDay < $1.minuteOfDay
            }
    }

    var body: some View {
        NavigationStack {
            Group {
                if members.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            scoreboard
                            choresSection
                            rewardsSection
                        }
                        .padding()
                    }
                }
            }
            .paperBackground()
            .navigationTitle("Family")
            .toolbar {
                if !members.isEmpty {
                    Menu {
                        Button("New chore", systemImage: "checklist") { sheet = .chore(members.first) }
                        Button("New reward", systemImage: "gift") { sheet = .reward }
                        Button("Add family member", systemImage: "person.badge.plus") { sheet = .newMember }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add")
                }
            }
            .sheet(item: $sheet) { sheet in
                switch sheet {
                case .chore(let member):
                    ReminderEditorView(category: .family, assigneeID: member?.memberID)
                case .reward: RewardEditorView()
                case .editReward(let reward): RewardEditorView(reward: reward)
                case .newMember: MemberEditorView()
                case .editMember(let member): MemberEditorView(member: member)
                }
            }
        }
    }

    // MARK: Sections

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Chores that count", systemImage: "figure.2.and.child.holdinghands")
                .font(Theme.serif(.title2, weight: .semibold))
        } description: {
            Text("Add your family, give chores points, and set rewards like \"100 points = pizza night.\"")
        } actions: {
            Button("Add a family member") { sheet = .newMember }
                .buttonStyle(.borderedProminent)
        }
    }

    private struct ScoreEntry: Identifiable {
        let member: FamilyMember?
        let points: Int
        var id: String { member?.memberID ?? "you" }
    }

    private var scoreboard: some View {
        let everyone: [FamilyMember?] = [nil] + members.map { Optional($0) }
        let rows = everyone.map { ScoreEntry(member: $0, points: weekPoints(for: $0?.memberID)) }
        let leader = rows.map(\.points).max() ?? 0

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("This week")
                    .font(Theme.serif(.title3, weight: .semibold))
                Spacer()
                Text("\(familyWeekTotal) family points")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Theme.accent)
            }
            VStack(spacing: 14) {
                ForEach(rows) { row in
                    ScoreRow(member: row.member, points: row.points, leader: leader)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let member = row.member { sheet = .editMember(member) }
                        }
                }
            }
            .card()
        }
    }

    private var choresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's chores")
                .font(Theme.serif(.title3, weight: .semibold))
            ForEach(members) { member in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        MemberAvatar(member: member, size: 26)
                        Text(member.name).font(.headline)
                        Spacer()
                        Button {
                            sheet = .chore(member)
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                        .accessibilityLabel("New chore for \(member.name)")
                    }
                    let list = chores(for: member)
                    if list.isEmpty {
                        Text("Nothing assigned today.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 6)
                    } else {
                        ForEach(list) { chore in
                            ReminderRow(reminder: chore)
                            if chore.id != list.last?.id { Divider() }
                        }
                    }
                }
                .card()
            }
        }
    }

    private var rewardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Rewards")
                    .font(Theme.serif(.title3, weight: .semibold))
                Spacer()
                Button("Add", systemImage: "plus") { sheet = .reward }
                    .labelStyle(.iconOnly)
            }
            if rewards.isEmpty {
                Button {
                    sheet = .reward
                } label: {
                    Label("Set a reward, like \"100 points = pizza night\"", systemImage: "gift")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.accent)
                .card()
            } else {
                ForEach(rewards) { reward in
                    RewardCard(
                        reward: reward,
                        member: members.first { $0.memberID == reward.memberID },
                        earned: reward.progress(from: completions)
                    )
                    .onTapGesture { sheet = .editReward(reward) }
                }
            }
        }
    }
}

// MARK: - Pieces

private struct ScoreRow: View {
    let member: FamilyMember?
    let points: Int
    let leader: Int

    var body: some View {
        HStack(spacing: 12) {
            MemberAvatar(member: member)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(member?.name ?? "You").font(.subheadline.weight(.medium))
                    if points > 0 && points == leader {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .accessibilityLabel("Leading this week")
                    }
                    Spacer()
                    Text("\(points)")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                }
                GeometryReader { proxy in
                    Capsule()
                        .fill(Color.secondary.opacity(0.12))
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(member?.color.color ?? Theme.accent)
                                .frame(width: leader > 0 ? proxy.size.width * CGFloat(points) / CGFloat(leader) : 0)
                        }
                }
                .frame(height: 6)
            }
        }
        .animation(.snappy, value: points)
    }
}

private struct RewardCard: View {
    @Environment(\.modelContext) private var context
    let reward: Reward
    let member: FamilyMember?
    let earned: Int

    private var reached: Bool { earned >= reward.cost }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Image(systemName: reward.isClaimed ? "gift.fill" : "gift")
                    .foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(reward.title).font(.body.weight(.medium))
                    Text(member.map { "For \($0.name)" } ?? "Whole family")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(min(earned, reward.cost)) / \(reward.cost)")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(min(earned, reward.cost)), total: Double(reward.cost))
                .tint(member?.color.color ?? Theme.accent)

            if reward.isClaimed {
                HStack {
                    Label("Claimed \(reward.claimedAt?.formatted(.relative(presentation: .named)) ?? "")", systemImage: "checkmark.seal.fill")
                        .font(.footnote)
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    Button("Start again") { withAnimation { reward.restart() } }
                        .font(.footnote.weight(.semibold))
                }
            } else if reached {
                Button {
                    withAnimation { reward.claimedAt = .now }
                } label: {
                    Label("Earned! Claim reward", systemImage: "party.popper")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .sensoryFeedback(.success, trigger: reward.isClaimed)
            }
        }
        .card()
    }
}

#Preview {
    FamilyView()
        .modelContainer(PreviewData.container)
}
