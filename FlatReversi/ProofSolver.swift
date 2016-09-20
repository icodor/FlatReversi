//
//  ProofSolver.swift
//  FlatReversi
//
//  Created by Kodama Yoshinori on 10/29/14.
//  Copyright (c) 2014 Yoshinori Kodama. All rights reserved.
//

import Foundation

enum Proofs {
    case blackWin, whiteWin, draw, undefined

    func toString() -> String {
        switch self {
        case .blackWin:
            return "Black Win"
        case .whiteWin:
            return "White Win"
        case .draw:
            return "Draw"
        case .undefined:
            return "Undefined"
        }
    }
}

class ProofAnswer {
    var proof: Proofs
    var moves: [(Int, Int)]

    init(proof: Proofs, moves: [(Int, Int)]) {
        self.proof = proof
        self.moves = moves
    }

    func toString() -> String {
        let pf = proof.toString()
        return pf + "\(moves)"
    }
}

class ProofSolver {
    func solve(_ boardRepresentation: BoardRepresentation, forPlayer: Pieces) -> ProofAnswer {
        return ProofAnswer(proof: .undefined, moves: [])
    }

}
