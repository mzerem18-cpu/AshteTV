import SwiftUI
import AVKit
import AVFoundation

// 1. مۆدێلی کەناڵ
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

// 2. دیزاینی سەرەکی ئەپەکە
struct ContentView: View {
    @State private var channels: [Channel] = []
    @State private var selectedChannel: Channel?
    @State private var searchText = ""
    @State private var selectedCategory = "All"

    var categories: [String] {
        var groups = ["All"]
        let uniqueGroups = Set(channels.map { $0.group })
        groups.append(contentsOf: Array(uniqueGroups).sorted())
        return groups
    }

    var filteredChannels: [Channel] {
        channels.filter { channel in
            let matchCategory = (selectedCategory == "All") || (channel.group == selectedCategory)
            let matchSearch = searchText.isEmpty || channel.name.lowercased().contains(searchText.lowercased())
            return matchCategory && matchSearch
        }
    }

    let adaptiveColumns: [GridItem] = [
        GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 15)
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.08, green: 0.08, blue: 0.08).ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 15) {
                    
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.gray)
                        TextField("Search for channels...", text: $searchText)
                            .foregroundColor(.white)
                    }
                    .padding(12)
                    .background(Color(red: 0.13, green: 0.13, blue: 0.13))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 10)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(categories, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category
                                }) {
                                    Text(category)
                                        .font(.system(size: 14, weight: .bold))
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == category ? Color.white : Color(red: 0.18, green: 0.18, blue: 0.18))
                                        .foregroundColor(selectedCategory == category ? .black : .white)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    ScrollView {
                        LazyVGrid(columns: adaptiveColumns, spacing: 15) {
                            ForEach(filteredChannels) { channel in
                                ChannelCardView(channel: channel)
                                    .onTapGesture {
                                        selectedChannel = channel
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(item: $selectedChannel) { channel in
                PlayerContainerView(url: channel.url, name: channel.name)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear(perform: loadData)
    }

    func loadData() {
        guard let url = URL(string: "https://raw.githubusercontent.com/mzerem18-cpu/AshteTV/main/channels.json") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                if let decoded = try? JSONDecoder().decode([Channel].self, from: data) {
                    DispatchQueue.main.async {
                        self.channels = decoded
                    }
                }
            }
        }.resume()
    }
}

// 3. دیزاینی کاردی کەناڵەکان
struct ChannelCardView: View {
    let channel: Channel
    
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: channel.logo)) { image in
                image.resizable().aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
            }
            .frame(width: 55, height: 55)
            .padding(8)
            .background(Color.white)
            .cornerRadius(15)
            
            Text(channel.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .padding(.top, 5)
            
            Text(channel.group)
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(Color(red: 0.13, green: 0.13, blue: 0.13))
        .cornerRadius(20)
    }
}

// 4. پلەیەری ڤیدیۆ
struct PlayerContainerView: View {
    let url: String
    let name: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(name).font(.headline).foregroundColor(.white)
                Spacer()
                Button("Done") { presentationMode.wrappedValue.dismiss() }
                    .foregroundColor(.red).fontWeight(.bold)
            }
            .padding()
            .background(Color.black)

            if let videoURL = URL(string: url) {
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .onAppear {
                        try? AVAudioSession.sharedInstance().setCategory(.playback)
                    }
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}
