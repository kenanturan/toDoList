import SwiftUI
import CoreData
import UserNotifications
import PhotosUI
import PencilKit

struct DetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var item: Item
    @State private var note: String = ""
    @State private var reminderDate = Date()
    @State private var isReminderEnabled = false
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingDrawingView = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Not Alanı
                TextEditor(text: $note)
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                // Çizim Alanı
                if let drawingData = item.drawingData,
                   let drawing = try? PKDrawing(data: drawingData) {
                    VStack {
                        Image(uiImage: drawing.image(from: drawing.bounds, scale: 1.0))
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(radius: 3)
                        
                        HStack {
                            Button("Düzenle") {
                                showingDrawingView = true
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Sil") {
                                withAnimation {
                                    item.drawingData = nil
                                    try? viewContext.save()
                                }
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Fotoğraf Alanı
                if let imageData = item.imageData,
                   let uiImage = UIImage(data: imageData) {
                    VStack {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(radius: 3)
                        
                        Button("Sil") {
                            withAnimation {
                                item.imageData = nil
                                try? viewContext.save()
                            }
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                }
                
                // Araç Butonları
                HStack(spacing: 20) {
                    if item.drawingData == nil {
                        Button(action: { showingDrawingView = true }) {
                            VStack {
                                Image(systemName: "pencil.tip")
                                Text("Çizim")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    
                    if item.imageData == nil {
                        Button(action: { showingImagePicker = true }) {
                            VStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text("Fotoğraf")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    
                    Button(action: { isReminderEnabled.toggle() }) {
                        VStack {
                            Image(systemName: isReminderEnabled ? "bell.fill" : "bell")
                            Text("Hatırlatıcı")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                // Hatırlatıcı Seçici (sadece aktifse göster)
                if isReminderEnabled {
                    DatePicker("", selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .padding(.horizontal)
                }
                
                // Paylaş Butonu
                Button(action: shareNote) {
                    Label("Paylaş", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(item.title ?? "Not")
        .navigationBarItems(trailing: Button("Kaydet") {
            saveNote()
        })
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .sheet(isPresented: $showingDrawingView) {
            DrawingView(item: item)
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                if let imageData = image.jpegData(compressionQuality: 0.7) {
                    item.imageData = imageData
                    try? viewContext.save()
                }
            }
        }
        .onAppear {
            note = item.note ?? ""
            if let reminder = item.reminderDate {
                reminderDate = reminder
                isReminderEnabled = true
            }
        }
    }
    
    private func saveNote() {
        item.note = note
        
        // Hatırlatıcı ayarlama
        if isReminderEnabled {
            item.reminderDate = reminderDate
            scheduleNotification()
        } else {
            item.reminderDate = nil
            // Varolan hatırlatıcıyı iptal et
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.objectID.description])
        }
        
        try? viewContext.save()
        dismiss()
    }
    
    private func scheduleNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                let content = UNMutableNotificationContent()
                content.title = item.title ?? "Hatırlatıcı"
                content.body = item.note ?? ""
                content.sound = UNNotificationSound.default
                
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                
                let request = UNNotificationRequest(identifier: item.objectID.description, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
    
    private func shareNote() {
        var itemsToShare: [Any] = []
        
        // Not metnini ekle
        let noteText = """
        \(item.title ?? "Not")
        
        \(note)
        """
        itemsToShare.append(noteText)
        
        // Fotoğraf varsa ekle
        if let imageData = item.imageData,
           let image = UIImage(data: imageData) {
            itemsToShare.append(image)
        }
        
        let av = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            av.popoverPresentationController?.sourceView = rootVC.view
            av.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            av.popoverPresentationController?.permittedArrowDirections = []
            rootVC.present(av, animated: true)
        }
    }
}

// ImagePicker yapısı
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}
