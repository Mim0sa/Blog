import Foundation
import Publish
import Plot

// This type acts as the configuration for your website.
struct MyBlog: Website {
    enum SectionID: String, WebsiteSectionID {
        // Add the sections that you want your website to contain here:
        case posts
        case archive
        case about
    }

    struct ItemMetadata: WebsiteItemMetadata {
        // Add any site-specific metadata that you want to use here.
    }

    // Update these properties to configure your website:
    var url = URL(string: "https://your-website-url.com")!
    var name = "Mimosa's Blog"
    var description = "A description of Mimosa's Blog"
    var language: Language { .english }
    var imagePath: Path? { Path("Image") }
}

// This will generate your website using the built-in Foundation theme:
try MyBlog().publish(withTheme: .mimosa)
