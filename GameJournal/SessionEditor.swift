import SwiftUI
import PhotosUI
import AVFoundation

struct SessionEditor: View {
    @Environment(JournalStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State var session: GameSession
    @State var players: [Player]
    @State private var newPlayer = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var error: String?
    @State private var importing = false
    @State private var discard = false
    var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    section("Game name") { TextField("e.g. Everdell", text: $session.game).textInputAutocapitalization(.words).padding(13).background(fieldBackground) }
                    section("Date") { DatePicker("Played on", selection: $session.date, displayedComponents: .date).datePickerStyle(.compact) }
                    section("Session photo · optional") {
                        if session.photo != nil { PhotoTile(data: session.photo).frame(height: 170).clipShape(RoundedRectangle(cornerRadius: 16)); Button("Remove photo", role: .destructive) { session.photo = nil; photoItem = nil }.font(.caption) }
                        HStack {
                            PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) { Label("Choose photo", systemImage: "photo") }
                            Spacer()
                            if UIImagePickerController.isSourceTypeAvailable(.camera) { Button { requestCamera() } label: { Label("Take photo", systemImage: "camera") } }
                        }.font(.subheadline.bold())
                        if importing { ProgressView("Preparing photo…") }
                        Text("Photos stay on this device with your journal.").font(.caption).foregroundStyle(.secondary)
                    }
                    section("Players & scores") {
                        Text("Scores are optional. Tap a trophy to mark each winner.").font(.caption).foregroundStyle(.secondary)
                        ForEach($session.entries) { $entry in
                            HStack(spacing: 8) {
                                Text(players.first { $0.id == entry.playerID }?.name ?? "Player").font(.subheadline).frame(maxWidth: .infinity, alignment: .leading)
                                TextField("Score", text: $entry.score).keyboardType(.numbersAndPunctuation).multilineTextAlignment(.center).frame(width: 66).padding(10).background(fieldBackground).accessibilityLabel("Score for \(playerName(entry.playerID))")
                                Button { entry.isWinner.toggle() } label: { Image(systemName: entry.isWinner ? "trophy.fill" : "trophy").font(.title3).foregroundStyle(entry.isWinner ? Theme.gold : .secondary).frame(width: 44, height: 44) }.accessibilityLabel("\(playerName(entry.playerID)), \(entry.isWinner ? "winner" : "not a winner")").accessibilityHint("Double tap to change winner status")
                                Button { session.entries.removeAll { $0.id == entry.id } } label: { Image(systemName: "minus.circle.fill").foregroundStyle(.secondary).frame(width: 30, height: 44) }.accessibilityLabel("Remove \(playerName(entry.playerID))")
                            }
                        }
                        Menu {
                            ForEach(players.filter { p in !session.entries.contains { $0.playerID == p.id } }) { p in Button(p.name) { session.entries.append(Entry(playerID: p.id)) } }
                        } label: { Label("Add existing player", systemImage: "person.badge.plus").frame(maxWidth: .infinity).padding(12).background(Theme.sage, in: RoundedRectangle(cornerRadius: 10)) }.disabled(players.allSatisfy { p in session.entries.contains { $0.playerID == p.id } })
                        HStack { TextField("New player’s name", text: $newPlayer).textInputAutocapitalization(.words).padding(12).background(fieldBackground); Button("Add") { addPlayer() }.disabled(newPlayer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
                        Text("Select multiple winners for a tie or team victory, or leave all unselected when there’s no recorded winner.").font(.caption).foregroundStyle(.secondary)
                    }
                    section("Session enjoyment") {
                        HStack(spacing: 13) { ForEach(1...5, id: \.self) { i in Button { session.rating = session.rating == i ? 0 : i } label: { Image(systemName: i <= session.rating ? "star.fill" : "star").font(.system(size: 30)).foregroundStyle(Theme.gold).frame(minHeight: 44) }.accessibilityLabel("\(i) stars").accessibilityAddTraits(session.rating == i ? .isSelected : []) } }.frame(maxWidth: .infinity)
                    }
                    section("Notes · optional") { TextField("The highlights, the rivalries, the rematch…", text: $session.notes, axis: .vertical).lineLimit(4...8).padding(13).background(fieldBackground) }
                    Button { save() } label: { Text("Save session").modifier(PrimaryButton()) }.disabled(session.game.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || session.entries.isEmpty || importing)
                }.padding(22)
            }.background(Theme.cream).foregroundStyle(Theme.ink).navigationTitle(store.data.sessions.contains { $0.id == session.id } ? "Edit session" : "Log a game").navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar(.visible, for: .navigationBar)
                .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { discard = true } } }
                .interactiveDismissDisabled()
                .confirmationDialog("Discard unsaved changes?", isPresented: $discard, titleVisibility: .visible) { Button("Discard changes", role: .destructive) { dismiss() }; Button("Keep editing", role: .cancel) {} }
                .alert("Couldn’t complete that", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK") { error = nil } } message: { Text(error ?? "") }
                .sheet(isPresented: $showCamera) { CameraPicker { image in if let image { session.photo = resized(image) }; showCamera = false } }
                .task(id: photoItem) {
                    guard let photoItem else { return }
                    importing = true
                    defer { importing = false }
                    do {
                        guard let data = try await photoItem.loadTransferable(type: Data.self), let image = UIImage(data: data) else { throw CocoaError(.fileReadCorruptFile) }
                        guard !Task.isCancelled else { return }
                        session.photo = resized(image)
                    } catch { if !Task.isCancelled { self.error = "That photo couldn’t be loaded. Try another photo." } }
                }
    }
    private var fieldBackground: some View { RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.35)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.ink.opacity(0.2))) }
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View { VStack(alignment: .leading, spacing: 10) { Text(title).font(.headline); content() } }
    private func playerName(_ id: UUID) -> String { players.first { $0.id == id }?.name ?? "Player" }
    private func addPlayer() {
        let name = newPlayer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let player = players.first { $0.name.caseInsensitiveCompare(name) == .orderedSame } ?? Player(name: name)
        if !players.contains(where: { $0.id == player.id }) { players.append(player) }
        if !session.entries.contains(where: { $0.playerID == player.id }) { session.entries.append(Entry(playerID: player.id)) }
        newPlayer = ""
    }
    private func save() {
        session.game = session.game.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !session.game.isEmpty, !session.entries.isEmpty else { return }
        do { try store.save(session, players: players.filter { p in session.entries.contains { $0.playerID == p.id } }); dismiss() }
        catch { self.error = "Your session was not saved. \(error.localizedDescription)" }
    }
    private func requestCamera() {
        Task { let granted = await AVCaptureDevice.requestAccess(for: .video); if granted { showCamera = true } else { error = "Camera access is disabled. You can enable it in Settings or choose a photo instead." } }
    }
    private func resized(_ image: UIImage) -> Data? {
        let scale = min(1, 1600 / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }.jpegData(compressionQuality: 0.8)
    }
}
struct CameraPicker: UIViewControllerRepresentable {
    var completion: (UIImage?) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }
    func makeUIViewController(context: Context) -> UIImagePickerController { let picker = UIImagePickerController(); picker.sourceType = .camera; picker.delegate = context.coordinator; return picker }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var completion: (UIImage?) -> Void
        init(completion: @escaping (UIImage?) -> Void) { self.completion = completion }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { completion(nil) }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) { completion(info[.originalImage] as? UIImage) }
    }
}
