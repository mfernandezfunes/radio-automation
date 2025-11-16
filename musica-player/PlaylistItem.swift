//
//  PlaylistItem.swift
//  musica-player
//
//  Created by Martin Fernandez on 16/11/2025.
//

import Foundation

enum PlaylistItem: Identifiable, Codable {
    case song(Song)
    case command(PlaylistCommand)
    
    var id: UUID {
        switch self {
        case .song(let song):
            return song.id
        case .command(let cmd):
            return cmd.id
        }
    }
    
    var isCommand: Bool {
        if case .command = self {
            return true
        }
        return false
    }
    
    var song: Song? {
        if case .song(let s) = self {
            return s
        }
        return nil
    }
    
    var command: PlaylistCommand? {
        if case .command(let c) = self {
            return c
        }
        return nil
    }
    
    // Codable implementation
    enum CodingKeys: String, CodingKey {
        case type, song, command
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "song":
            let song = try container.decode(Song.self, forKey: .song)
            self = .song(song)
        case "command":
            let command = try container.decode(PlaylistCommand.self, forKey: .command)
            self = .command(command)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .song(let song):
            try container.encode("song", forKey: .type)
            try container.encode(song, forKey: .song)
        case .command(let command):
            try container.encode("command", forKey: .type)
            try container.encode(command, forKey: .command)
        }
    }
}

