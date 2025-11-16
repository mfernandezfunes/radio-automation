//
//  Song.swift
//  musica-player
//
//  Created by Martin Fernandez on 16/11/2025.
//

import Foundation

struct Song: Identifiable, Codable {
    let id: UUID
    let title: String
    let artist: String
    let url: URL
    let securityScopedBookmark: Data?
    
    init(id: UUID = UUID(), title: String, artist: String, url: URL, securityScopedBookmark: Data? = nil) {
        self.id = id
        self.title = title
        self.artist = artist
        self.url = url
        self.securityScopedBookmark = securityScopedBookmark
    }
    
    // Get an accessible URL using the security bookmark
    func accessibleURL() -> URL? {
        guard let bookmark = securityScopedBookmark else {
            // If no bookmark, try to use URL directly
            return url
        }
        
        var isStale = false
        guard let resolvedURL = try? URL(
            resolvingBookmarkData: bookmark,
            options: .withoutUI,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return url
        }
        
        if isStale {
            // Bookmark is stale, try to create a new one
            return url
        }
        
        return resolvedURL
    }
}

