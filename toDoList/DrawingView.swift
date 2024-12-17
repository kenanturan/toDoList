import SwiftUI
import PencilKit

struct DrawingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @ObservedObject var item: Item
    
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var drawing = PKDrawing()
    
    var body: some View {
        NavigationView {
            CanvasView(canvasView: $canvasView, drawing: $drawing, toolPicker: toolPicker)
                .navigationTitle("Çizim")
                .navigationBarItems(
                    leading: Button("İptal") {
                        dismiss()
                    },
                    trailing: Button("Kaydet") {
                        saveDrawing()
                    }
                )
                .onAppear {
                    toolPicker.setVisible(true, forFirstResponder: canvasView)
                    toolPicker.addObserver(canvasView)
                    canvasView.becomeFirstResponder()
                    
                    // Eğer önceden kaydedilmiş çizim varsa onu yükle
                    if let drawingData = item.drawingData,
                       let savedDrawing = try? PKDrawing(data: drawingData) {
                        drawing = savedDrawing
                        canvasView.drawing = savedDrawing
                    }
                }
        }
    }
    
    private func saveDrawing() {
        let drawingData = drawing.dataRepresentation()
        item.drawingData = drawingData
        try? viewContext.save()
        dismiss()
    }
}

struct CanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var drawing: PKDrawing
    var toolPicker: PKToolPicker
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawing = drawing
        canvasView.drawingPolicy = .anyInput
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        canvasView.drawing = drawing
    }
} 
