//

import SwiftUI


typealias Action = () -> Void

struct ThumbnailImageView: View {
    let image: UIImage
    let localId: String
    let shareAction: Action
    
    
    @State private var showOutputModal = false

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .gesture(TapGesture().onEnded({_ in
                print("Tapped Image with id: \(localId)")
                self.showOutputModal.toggle()
//                onTapAction()
            }))
            .sheet(isPresented: $showOutputModal) {
                OutputHandlerView(showModal: $showOutputModal, uiImage: image, photoLocalId: localId)
            }
        // .animation(.spring())
    }
}

// Empty view also has no actions associated with it
struct ThumbnailEmptyView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .frame(width: 60, height: 60, alignment: .center)
            .foregroundColor(.yellow)
    }
}

struct ThumbnailView: View {
    
    let photo: Photo?
    let localId: String?
    let shareAction: Action
    
    var body: some View {
        Group {
            
            if photo?.image != nil {
                let photoLocalId = localId ?? ""
                ThumbnailImageView(image: photo!.image!, localId: photoLocalId, shareAction: shareAction)
////                Image(uiImage: image)
////                    .resizable()
////                    .aspectRatio(contentMode: .fill)
////                    .frame(width: 60, height: 60)
////                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
////                    .gesture(TapGesture().onEnded({_ in
////                        print("Tapped Image")
////                        model.withPhoto(completion: ShareViewController.shareCompletion)
////                    }))
////                // .animation(.spring())
//
            } else {
                ThumbnailEmptyView()
////                RoundedRectangle(cornerRadius: 10)
////                    .frame(width: 60, height: 60, alignment: .center)
////                    .foregroundColor(.yellow)
            }
        }
    }
}

struct ThumbnailView_Previews: PreviewProvider {
    static var previews: some View {
        ThumbnailView(photo: nil, localId: "AppIcon", shareAction: {})
    }
}
