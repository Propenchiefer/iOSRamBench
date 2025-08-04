struct InfoSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("About RAMBench")
                        .font(.system(size: 22, weight: .bold))
                    
                    Text("RAMBench tests your device's RAM limits by allocating memory until it hits the system limit. Uses both virtual memory and malloc.")
                        .font(.body)
                    
                    Text("Thanks to:")
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.top, 16)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Button("Autumn") {
                                if let url = URL(string: "https://github.com/Propenchiefer") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                            Text("Creator")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Button("Stossy11") {
                                if let url = URL(string: "https://github.com/Stossy11") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                            Text("Memory allocation help & device detection")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Button("CycloKid") {
                                if let url = URL(string: "https://github.com/CycloKid") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                            Text("App icon & graphics")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("About RAMBench")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}