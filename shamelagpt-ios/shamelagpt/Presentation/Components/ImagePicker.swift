//
//  ImagePicker.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI
import UIKit

/// Enum representing the source type for image selection
enum ImageSourceType {
    case camera
    case photoLibrary
}

/// A SwiftUI wrapper for image picking functionality (iOS 15 compatible)
struct ImagePicker: UIViewControllerRepresentable {

    // MARK: - Properties

    @Binding var selectedImage: UIImage?
    let sourceType: ImageSourceType
    @Environment(\.dismiss) private var dismiss

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType == .camera ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No update needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Camera Picker Representable (Legacy, kept for compatibility)

/// UIImagePickerController wrapper for camera functionality
struct CameraPickerRepresentable: UIViewControllerRepresentable {

    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No update needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerRepresentable

        init(_ parent: CameraPickerRepresentable) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.isPresented = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

// MARK: - Image Source Selection Sheet

/// A sheet that allows users to choose between camera and photo library
struct ImageSourceSelectionSheet: View {

    // MARK: - Properties

    let onCameraSelected: () -> Void
    let onPhotoLibrarySelected: () -> Void
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    onCameraSelected()
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .foregroundColor(AppTheme.Colors.primary)
                            .frame(width: 30)
                        Text(LocalizationKeys.imagePickerTakePhoto.localizedKey)
                            .foregroundColor(AppTheme.Colors.primaryText)
                    }
                }

                Button(action: {
                    onPhotoLibrarySelected()
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "photo.fill")
                            .foregroundColor(AppTheme.Colors.primary)
                            .frame(width: 30)
                        Text(LocalizationKeys.imagePickerChooseFromLibrary.localizedKey)
                            .foregroundColor(AppTheme.Colors.primaryText)
                    }
                }
            }
            .navigationTitle(LocalizationKeys.imagePickerAddImage.localizedKey)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationKeys.cancel.localizedKey) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ImageSourceSelectionSheet_Previews: PreviewProvider {
    static var previews: some View {
        ImageSourceSelectionSheet(
            onCameraSelected: {},
            onPhotoLibrarySelected: {}
        )
        .previewDisplayName("Source Selection")
    }
}
