//
//  PlaylistCommand.swift
//  musica-player
//
//  Created by Martin Fernandez on 16/11/2025.
//

import Foundation

enum PlaylistCommandType: String, Codable {
    case stopPlayer1AndPlayNextInPlayer2
    case stopPlayer2AndPlayNextInPlayer1
    case stopPlayer1
    case stopPlayer2
    case pausePlayer1
    case pausePlayer2
    case resumePlayer1
    case resumePlayer2
    
    var displayName: String {
        switch self {
        case .stopPlayer1AndPlayNextInPlayer2:
            return "Parar Player 1 → Siguiente en Player 2"
        case .stopPlayer2AndPlayNextInPlayer1:
            return "Parar Player 2 → Siguiente en Player 1"
        case .stopPlayer1:
            return "Parar Player 1"
        case .stopPlayer2:
            return "Parar Player 2"
        case .pausePlayer1:
            return "Pausar Player 1"
        case .pausePlayer2:
            return "Pausar Player 2"
        case .resumePlayer1:
            return "Reanudar Player 1"
        case .resumePlayer2:
            return "Reanudar Player 2"
        }
    }
    
    var icon: String {
        switch self {
        case .stopPlayer1AndPlayNextInPlayer2, .stopPlayer2AndPlayNextInPlayer1:
            return "arrow.triangle.2.circlepath"
        case .stopPlayer1, .stopPlayer2:
            return "stop.fill"
        case .pausePlayer1, .pausePlayer2:
            return "pause.fill"
        case .resumePlayer1, .resumePlayer2:
            return "play.fill"
        }
    }
}

struct PlaylistCommand: Identifiable, Codable {
    let id: UUID
    let commandType: PlaylistCommandType
    
    init(id: UUID = UUID(), commandType: PlaylistCommandType) {
        self.id = id
        self.commandType = commandType
    }
}

