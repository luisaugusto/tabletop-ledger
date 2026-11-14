import SwiftUI

@main struct GameJournalApp: App {
    @State private var store = JournalStore()
    var body: some Scene {
        WindowGroup {
            LaunchExperience {
            TabView {
                HistoryView().tabItem { Label("History", systemImage: "calendar") }
                PlayersView().tabItem { Label("Players", systemImage: "person.2") }
                ProfileView().tabItem { Label("Me", systemImage: "person.crop.circle") }
            }
            }.environment(store).tint(Theme.forest).preferredColorScheme(.light)
                .alert("Journal unavailable", isPresented: Binding(get: { store.error != nil }, set: { _ in })) { Button("OK") {} } message: { Text(store.error ?? "") }
        }
    }
}
struct HistoryView: View {
    @Environment(JournalStore.self) var store
    @State private var editing: GameSession?
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    GeometryReader { proxy in
                        let offset = proxy.frame(in: .named("journalScroll")).minY
                        let stretch = max(0, offset)
                        ForestHeader(stretch: stretch)
                            .frame(height: 165 + stretch)
                            .offset(y: offset > 0 ? -offset : -offset * 0.28)
                    }.frame(height: 165)
                    VStack(spacing: 20) {
                    StatsCard(player: store.me).padding(.horizontal, 20)
                    HStack { Text("Recent sessions").font(.title2.bold()); Spacer(); Text("\(store.data.sessions.count) logged").font(.caption).foregroundStyle(.secondary) }.padding(.horizontal, 22)
                    if store.data.sessions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "dice").font(.system(size: 44)).foregroundStyle(Theme.forest)
                            Text("Your next game night starts here").font(.headline)
                            Text("Keep the scores, the stories, and the people who made it memorable.").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        }.padding(28)
                    }
                    ForEach(store.data.sessions.sorted { $0.date > $1.date }) { session in
                        NavigationLink { SessionDetail(sessionID: session.id) } label: { SessionCard(session: session) }.buttonStyle(.plain).padding(.horizontal, 20)
                    }
                }.padding(.top, 14).padding(.bottom, 20)
                    .frame(maxWidth: .infinity)
                    .background(Theme.cream, in: Theme.sheetShape)
                    .padding(.top, -26)
                }
            }.coordinateSpace(name: "journalScroll").scrollBounceBehavior(.always).background(Theme.cream).toolbar(.hidden, for: .navigationBar)
                .safeAreaInset(edge: .bottom) { Button { editing = GameSession(entries: [Entry(playerID: store.me.id)]) } label: { Label("Log game", systemImage: "plus").font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity).frame(minHeight: 44).background(Theme.rust, in: RoundedRectangle(cornerRadius: 14)) }.padding(.horizontal, 20).padding(.vertical, 6).background(Theme.cream.opacity(0.96)) }
                .sheet(item: $editing) { draft in NavigationStack { SessionEditor(session: draft, players: store.data.players) } }
        }
    }
}
struct StatsCard: View {
    @Environment(JournalStore.self) var store
    var player: Player
    var body: some View {
        let stats = PlayerStats.calculate(player.id, sessions: store.data.sessions)
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading) { Text(player.isMe ? "Your stats" : "\(player.name)’s stats").font(.headline); Text("All time").font(.caption).opacity(0.8) }
            HStack(spacing: 0) {
                metric("dice.fill", "\(stats.played)", "Games played")
                Rectangle().fill(Theme.cream.opacity(0.30)).frame(width: 1, height: 62)
                metric("person.2", "\(Set(store.data.sessions.filter { $0.entries.contains { $0.playerID == player.id } }.flatMap { $0.entries.map(\.playerID) }).subtracting([player.id]).count)", "Played with")
                Rectangle().fill(Theme.cream.opacity(0.30)).frame(width: 1, height: 62)
                metric("trophy", stats.rate, "Win rate")
            }
        }.padding(20).foregroundStyle(Theme.cream).background(LinearGradient(colors: [Theme.forest, Theme.forest.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 22))
    }
    func metric(_ icon: String, _ value: String, _ label: String) -> some View {
        VStack(spacing: 7) { Image(systemName: icon).font(.title2).foregroundStyle(Color(red: 0.91, green: 0.80, blue: 0.53)); Text(value).font(.title2.bold()); Text(label).font(.caption).lineLimit(1).minimumScaleFactor(0.8) }.frame(maxWidth: .infinity).multilineTextAlignment(.center)
    }
}
struct SessionCard: View {
    @Environment(JournalStore.self) var store
    var session: GameSession
    var body: some View {
        HStack(spacing: 13) {
            PhotoTile(data: session.photo).frame(width: 82, height: 100).clipShape(RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 6) {
                Text(session.game).font(.headline).foregroundStyle(Theme.forest)
                Text(session.date, format: .dateTime.month(.abbreviated).day().year()).font(.caption).foregroundStyle(.secondary)
                Label("\(session.entries.count) players", systemImage: "person.2").font(.caption)
                if session.rating > 0 { Stars(rating: session.rating).font(.caption) }
                let winners = session.entries.filter(\.isWinner)
                if !winners.isEmpty { Label(winners.map { store.name($0.playerID) }.joined(separator: ", "), systemImage: "trophy.fill").font(.caption2.bold()).foregroundStyle(Theme.forest).lineLimit(2) }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
        }.padding(12).background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 20)).overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.ink.opacity(0.07))).shadow(color: Theme.ink.opacity(0.06), radius: 3, y: 2)
    }
}
struct SessionDetail: View {
    @Environment(JournalStore.self) private var store
    let sessionID: UUID
    private var session: GameSession? { store.data.sessions.first { $0.id == sessionID } }
    var body: some View {
        Group {
            if let session {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if let photo = session.photo {
                            PhotoTile(data: photo).frame(height: 230).clipShape(RoundedRectangle(cornerRadius: 22))
                        }
                        VStack(alignment: .leading, spacing: 9) {
                            Text(session.game).font(.system(.largeTitle, design: .serif).bold()).foregroundStyle(Theme.forest)
                            Label(session.date.formatted(date: .long, time: .omitted), systemImage: "calendar").font(.subheadline).foregroundStyle(.secondary)
                            Label("\(session.entries.count) players", systemImage: "person.2").font(.subheadline).foregroundStyle(.secondary)
                        }
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Players & scores").font(.headline)
                            ForEach(session.entries) { entry in
                                HStack(spacing: 12) {
                                    Image(systemName: entry.isWinner ? "trophy.fill" : "person.crop.circle")
                                        .foregroundStyle(entry.isWinner ? Theme.gold : Theme.forest.opacity(0.6))
                                        .frame(width: 26)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(store.name(entry.playerID)).font(.body.weight(.medium))
                                        if entry.isWinner { Text("Winner").font(.caption).foregroundStyle(Theme.gold) }
                                    }
                                    Spacer()
                                    Text(entry.score.isEmpty ? "No score" : entry.score)
                                        .font(entry.score.isEmpty ? .caption : .title3.weight(.semibold))
                                        .foregroundStyle(entry.score.isEmpty ? .secondary : Theme.ink)
                                }
                                if entry.id != session.entries.last?.id { Divider() }
                            }
                            if !session.entries.contains(where: \.isWinner) {
                                Text("No winner recorded").font(.caption).foregroundStyle(.secondary)
                            }
                        }.padding(18).background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 20))
                        VStack(alignment: .leading, spacing: 9) {
                            Text("Session enjoyment").font(.headline)
                            if session.rating > 0 { Stars(rating: session.rating).font(.title3) }
                            else { Text("Not rated").foregroundStyle(.secondary) }
                        }
                        VStack(alignment: .leading, spacing: 9) {
                            Text("Notes").font(.headline)
                            Text(session.notes.isEmpty ? "No notes for this session." : session.notes)
                                .foregroundStyle(session.notes.isEmpty ? .secondary : Theme.ink)
                                .textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }.padding(22)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink("Edit") { SessionEditor(session: session, players: store.data.players) }
                    }
                }
            } else {
                ContentUnavailableView("Session unavailable", systemImage: "calendar.badge.exclamationmark")
            }
        }.background(Theme.cream).navigationTitle("Session").navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
    }
}
struct PlayersView: View {
    @Environment(JournalStore.self) var store
    var body: some View {
        NavigationStack {
            List(store.data.players.filter { !$0.isMe }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) { player in
                NavigationLink { PlayerDetail(player: player) } label: {
                    HStack { Image(systemName: "person.crop.circle.fill").font(.largeTitle).foregroundStyle(Theme.forest); VStack(alignment: .leading) { Text(player.name).font(.headline); Text("\(PlayerStats.calculate(player.id, sessions: store.data.sessions).played) games together").font(.caption).foregroundStyle(.secondary) } }
                }.listRowBackground(Color.white.opacity(0.55))
            }.scrollContentBackground(.hidden).background(Theme.cream).navigationTitle("Players")
                .overlay { if store.data.players.count <= 1 { ContentUnavailableView("Your gaming circle", systemImage: "person.2", description: Text("Add players while logging a session. They’ll appear here automatically.")) } }
        }
    }
}
struct PlayerDetail: View {
    @Environment(JournalStore.self) var store
    var player: Player
    @State private var editing: GameSession?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                StatsCard(player: player)
                Text("Win rates include sessions with a recorded winner. Ties and team wins count as wins for each selected winner.").font(.caption).foregroundStyle(.secondary)
                if !player.isMe {
                    let shared = store.data.sessions.filter { s in s.entries.contains { $0.playerID == player.id } && s.entries.contains { $0.playerID == store.me.id } }
                    let myWins = shared.filter { s in s.entries.contains { $0.playerID == store.me.id && $0.isWinner } && !s.entries.contains { $0.playerID == player.id && $0.isWinner } }.count
                    let theirWins = shared.filter { s in s.entries.contains { $0.playerID == player.id && $0.isWinner } && !s.entries.contains { $0.playerID == store.me.id && $0.isWinner } }.count
                    Text("Head-to-head").font(.headline)
                    Text("You won \(myWins) · \(player.name) won \(theirWins)").font(.subheadline)
                    Text(myWins + theirWins == 0 ? "No head-to-head results yet" : "Your head-to-head win rate: \(Int((Double(myWins) / Double(myWins + theirWins) * 100).rounded()))%") .font(.subheadline.bold())
                    Text("Shared wins and sessions without a winner are excluded. Team membership is not tracked in v1.").font(.caption).foregroundStyle(.secondary)
                }
                Text("Session history").font(.title2.bold())
                ForEach(store.data.sessions.filter { $0.entries.contains { $0.playerID == player.id } }.sorted { $0.date > $1.date }) { s in NavigationLink { SessionDetail(sessionID: s.id) } label: { SessionCard(session: s) }.buttonStyle(.plain) }
            }.padding(20)
        }.background(Theme.cream).navigationTitle(player.name)
    }
}
struct ProfileView: View {
    @Environment(JournalStore.self) var store
    @State private var name = ""
    @State private var renaming = false
    @State private var error: String?
    var body: some View {
        NavigationStack {
            PlayerDetail(player: store.me).toolbar { Button("Edit name") { name = store.me.name; renaming = true } }
                .alert("Your name", isPresented: $renaming) { TextField("Name", text: $name); Button("Cancel", role: .cancel) {}; Button("Save") { let clean = name.trimmingCharacters(in: .whitespacesAndNewlines); if !clean.isEmpty { do { try store.renameMe(clean) } catch { self.error = error.localizedDescription } } } }
                .alert("Couldn’t save", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK") { error = nil } } message: { Text(error ?? "") }
        }
    }
}
