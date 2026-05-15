import SwiftUI
import AVKit

// مۆدێلی کەناڵ
struct Channel: Codable, Identifiable {
    var id = UUID()
    let name: String
    let url: String
    let logo: String
    let group: String
    
    enum CodingKeys: String, CodingKey {
        case name, url, logo, group
    }
}

struct ContentView: View {
    @State private var channels: [Channel] = []
    @State private var selectedChannel: Channel?
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.08, green: 0.08, blue: 0.08).ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    searchBar
                    
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            ForEach(filteredChannels) { channel in
                                ChannelCard(channel: channel)
                                    .onTapGesture { selectedChannel = channel }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(item: $selectedChannel) { channel in
                PlayerView(channel: channel)
            }
        }
        .onAppear(perform: loadData)
    }

    var filteredChannels: [Channel] {
        if searchText.isEmpty { return channels }
        return channels.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }

    var headerSection: some View {
        VStack(alignment: .leading) {
            Text("TODAY").font(.caption).fontWeight(.bold).foregroundColor(.gray)
            Text("Discover").font(.largeTitle).fontWeight(.black).foregroundColor(.white)
        }.padding(.horizontal)
    }

    var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.gray)
            TextField("Search channels...", text: $searchText).foregroundColor(.white)
        }
        .padding().background(Color(red: 0.13, green: 0.13, blue: 0.13)).cornerRadius(15).padding(.horizontal)
    }

    func loadData() {
        // لینکی Raw ی فایلی channels.json لێرە دابنێ
        guard let url = URL(string: "https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/channels.json") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let decoded = try? JSONDecoder().decode([Channel].self, from: data) {
                DispatchQueue.main.async { self.channels = decoded }
            }
        }.resume()
    }
}

struct ChannelCard: View {
    let channel: Channel
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: channel.logo)) { img in img.resizable().aspectRatio(contentMode: .fit) }
            placeholder: { ProgressView() }
            .frame(width: 60, height: 60).background(Color.white).cornerRadius(12)
            
            Text(channel.name).font(.headline).foregroundColor(.white).lineLimit(1)
            Text(channel.group).font(.caption).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity).padding().background(Color(red: 0.13, green: 0.13, blue: 0.13)).cornerRadius(20)
    }
}

struct PlayerView: View {
    let channel: Channel
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(channel.name).fontWeight(.bold).foregroundColor(.white)
                Spacer()
                Button("Done") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.red)
            }.padding().background(Color.black)
            
            VideoPlayer(player: AVPlayer(url: URL(string: channel.url)!))
                .onAppear { try? AVAudioSession.sharedInstance().setCategory(.playback) }
        }.background(Color.black.ignoresSafeArea())
    }
}
