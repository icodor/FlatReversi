//
//  GameScene.swift
//  MyFirstSpriteKit
//
//  Created by Kodama Yoshinori on 10/11/14.
//  Copyright (c) 2014 Yoshinori Kodama. All rights reserved.
//

import SpriteKit

class UpdateBoardViewContext {
    var boardMediator : BoardMediator
    var changes:[(Int, Int)]
    var put: [(Int, Int)]
    var showPuttables: Bool
    var showAnimation: Bool
    var blackEval: Double
    var whiteEval: Double
    var debugString: String

    init(boardMediator : BoardMediator, changes:[(Int, Int)], put: [(Int, Int)], showPuttables: Bool, showAnimation: Bool, blackEval: Double, whiteEval: Double, debugString: String) {
        self.boardMediator = boardMediator
        self.changes = changes
        self.put = put
        self.showPuttables = showPuttables
        self.showAnimation = showAnimation
        self.blackEval = blackEval
        self.whiteEval = whiteEval
        self.debugString = debugString
    }
}

class GameScene: SKScene, GameViewScene {
    var blackComputerLevel: Int = 0
    var whiteComputerLevel: Int = 1

    var gameSettings = GameSettings()
    var gameManager = GameManager()
    var gameViewModel: GameViewModel?

    var boardSprites: [[SKShapeNode?]] = []
    var lastPut: SKShapeNode? = nil

    //
    var numPiecesBlackCircle: SKShapeNode? = nil
    var numPiecesWhiteCircle: SKShapeNode? = nil
    var numPiecesBlack: SKLabelNode? = nil
    var numPiecesWhite: SKLabelNode? = nil
    var numBlackEval: SKLabelNode? = nil
    var numWhiteEval: SKLabelNode? = nil

    var debugLabel: SKLabelNode? = nil

    //
    var gameOverFrame: SKShapeNode? = nil
    var gameOverLabel: SKLabelNode? = nil
    var playAgainButtonFrame: SKShapeNode? = nil
    var playAgainButtonLabel: SKLabelNode? = nil
    var nextPlayButtonFrame: SKShapeNode? = nil
    var nextPlayButtonLabel: SKLabelNode? = nil

    var showGuides = true

    var time:CFTimeInterval = 0
    var timeCounterOn = false
    var lastUpdatedTime:CFTimeInterval = 0

    var topYOffset: CGFloat = 0
    var statusBarHeight: CGFloat = 20

    var tintColor: UIColor = UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)

    let lock = NSLock()

    var drawCount = 0

    var updateBoardViewQueue: Queue<UpdateBoardViewContext>? = nil

    // Colors
    var boardFontColor = SKColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
    var boardGridColor = SKColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 0.6)

    var boardBackgroundColor = SKColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1)

    var boardBlackPieceFillColor = SKColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
    var boardBlackPieceStrokeColor = SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
    var boardWhitePieceFillColor = SKColor(red: 1, green: 1, blue: 1, alpha: 1)
    var boardWhitePieceStrokeColor = SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
    var boardGuidePieceFillColor = SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)

    var boardPopupFillColor = SKColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.5)
    var boardPopupFontColor = SKColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0)

    func loadColors() {
        let colorPalette = AppearanceManager.load()

        tintColor = colorPalette.uiColorTint

        boardFontColor = colorPalette.boardFontColor
        boardGridColor = colorPalette.boardGridColor

        boardBackgroundColor = colorPalette.boardBackgroundColor

        boardBlackPieceFillColor = colorPalette.boardBlackPieceFillColor
        boardBlackPieceStrokeColor = colorPalette.boardBlackPieceStrokeColor
        boardWhitePieceFillColor = colorPalette.boardWhitePieceFillColor
        boardWhitePieceStrokeColor = colorPalette.boardWhitePieceStrokeColor
        boardGuidePieceFillColor = colorPalette.boardGuidePieceFillColor

        boardPopupFillColor = colorPalette.boardPopupFillColor
        boardPopupFontColor = colorPalette.boardPopupFontColor

        drawBoard()
    }

    var boardLinesH: [SKShapeNode] = []
    var boardLinesV: [SKShapeNode] = []
    var boardDots: [SKShapeNode] = []

    func drawBoard() {
        for shape in boardLinesH { shape.removeFromParent() }
        for shape in boardLinesV { shape.removeFromParent() }
        for shape in boardDots { shape.removeFromParent() }

        /* Setup your scene here */
        let boardView = self.childNodeWithName("Board") as! SKSpriteNode
        boardView.color = boardBackgroundColor
        let width : CGFloat = boardView.size.width
        let piece_width = width / 8
        let line_width : CGFloat = 2.0
        let color = boardGridColor

        // Horizontal lines
        for var by : CGFloat = 0; by <= width; by += piece_width {
            let sprite = SKShapeNode(rect: screenRectFromVritualRect(CGRectMake(0, by, width, line_width)))
            sprite.fillColor = color
            sprite.strokeColor = SKColor(white: 0, alpha: 0)
            boardView.addChild(sprite)
            boardLinesH.append(sprite)
        }
        // Vertical lines
        for var bx : CGFloat = 0; bx <= width; bx += piece_width {
            let rect = screenRectFromVritualRect(CGRectMake(bx, 0, line_width, width))
            let sprite = SKShapeNode(rect: rect)
            sprite.fillColor = color
            sprite.strokeColor = SKColor(white: 0, alpha: 0)
            boardView.addChild(sprite)
            boardLinesV.append(sprite)
        }

        // 4 dots
        let dotsUL = SKShapeNode(circleOfRadius: line_width * 3)
        dotsUL.position = self.screenPointFromVirtualPoint(CGPointMake(piece_width * 2, piece_width * 2))
        dotsUL.fillColor = color
        boardView.addChild(dotsUL)
        boardDots.append(dotsUL)
        let dotsUR = SKShapeNode(circleOfRadius: line_width * 3)
        dotsUR.position = self.screenPointFromVirtualPoint(CGPointMake(piece_width * 2, piece_width * 6))
        dotsUR.fillColor = color
        boardView.addChild(dotsUR)
        boardDots.append(dotsUR)
        let dotsDL = SKShapeNode(circleOfRadius: line_width * 3)
        dotsDL.position = self.screenPointFromVirtualPoint(CGPointMake(piece_width * 6, piece_width * 2))
        dotsDL.fillColor = color
        boardView.addChild(dotsDL)
        boardDots.append(dotsDL)
        let dotsDR = SKShapeNode(circleOfRadius: line_width * 3)
        dotsDR.position = self.screenPointFromVirtualPoint(CGPointMake(piece_width * 6, piece_width * 6))
        dotsDR.fillColor = color
        boardView.addChild(dotsDR)
        boardDots.append(dotsDR)
    }

    override func didMoveToView(view: SKView) {
        let boardView = self.childNodeWithName("Board") as! SKSpriteNode
        let width : CGFloat = boardView.size.width
        let piece_width = width / 8
        topYOffset += piece_width / 2

        updateBoardViewQueue = Queue<UpdateBoardViewContext>()

        drawBoard()
        showNumPieces(0, white: 0, blackEval: 0.0, whiteEval: 0.0, debugString: "")

        startGame()
        NSLog("\n" + gameManager.toString())
    }

    private func clearPieces() {
        for row in boardSprites {
            for cell in row {
                cell?.removeAllActions()
                cell?.removeFromParent()
            }
        }

        drawCount = 0

        boardSprites = []
        for var y = 0; y < gameManager.boardMediator?.height(); y += 1 {
            boardSprites.append([nil, nil, nil, nil, nil, nil, nil, nil])
        }

        lastPut?.removeFromParent()
        lastPut = nil
    }

    private func showNumPieces(black: Int, white: Int, blackEval: Double, whiteEval: Double, debugString: String) {
        let debug = true
        let boardView = self.childNodeWithName("Board") as! SKSpriteNode
        let width : CGFloat = boardView.size.width
//        var height : CGFloat = boardView.size.height
        let piece_width = width / 8
//        var line_width : CGFloat = 2.0

        let yPosOffset = width + 3 * statusBarHeight

        // Number of pieces
        numPiecesBlack?.removeFromParent()
        numPiecesWhite?.removeFromParent()

        numPiecesBlack = SKLabelNode(text: "\(black)")
        numPiecesBlack?.name = "blackNum"
        numPiecesBlack?.fontColor = boardFontColor
        numPiecesBlack?.fontSize = 50
        numPiecesBlack?.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Right
        numPiecesBlack?.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
        numPiecesBlack?.position = self.screenPointFromVirtualPoint(CGPointMake(width / 2 - piece_width - 20, yPosOffset))
        boardView.addChild(numPiecesBlack!)

        numPiecesWhite = SKLabelNode(text: "\(white)")
        numPiecesBlack?.name = "whiteNum"
        numPiecesWhite?.fontColor = boardFontColor
        numPiecesWhite?.fontSize = 50
        numPiecesWhite?.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        numPiecesWhite?.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
        numPiecesWhite?.position = self.screenPointFromVirtualPoint(CGPointMake(width / 2 + piece_width + 20, yPosOffset))
        boardView.addChild(numPiecesWhite!)

        // Evaluation
        numBlackEval?.removeFromParent()
        numWhiteEval?.removeFromParent()
        if debug {
            numBlackEval = SKLabelNode(text: "\(blackEval)")
            numBlackEval?.name = "blackEval"
            numBlackEval?.fontColor = boardFontColor
            numBlackEval?.fontSize = 30
            numBlackEval?.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Right
            numBlackEval?.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
            numBlackEval?.position = self.screenPointFromVirtualPoint(CGPointMake(width / 2 - piece_width - 20 - 80, yPosOffset))
            boardView.addChild(numBlackEval!)

            numWhiteEval = SKLabelNode(text: "\(whiteEval)")
            numWhiteEval?.name = "blackEval"
            numWhiteEval?.fontColor = boardFontColor
            numWhiteEval?.fontSize = 30
            numWhiteEval?.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
            numWhiteEval?.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
            numWhiteEval?.position = self.screenPointFromVirtualPoint(CGPointMake(width / 2 + piece_width + 20 + 80, yPosOffset))
            boardView.addChild(numWhiteEval!)
        }

        // Show Result
        debugLabel?.removeFromParent()
        if debug {
            debugLabel = SKLabelNode(text: "\(debugString)")
            debugLabel?.name = "blackEval"
            debugLabel?.fontColor = boardFontColor
            debugLabel?.fontSize = 30
            debugLabel?.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
            debugLabel?.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
            debugLabel?.position = self.screenPointFromVirtualPoint(CGPointMake(width / 2, yPosOffset + piece_width))
            boardView.addChild(debugLabel!)
        }

        //
        let radius = width / 8 / 2 * 0.8

        numPiecesBlackCircle?.removeFromParent()
        numPiecesWhiteCircle?.removeFromParent()

        numPiecesBlackCircle = SKShapeNode(circleOfRadius: radius)
        numPiecesBlackCircle?.fillColor = boardBlackPieceFillColor
        numPiecesBlackCircle?.position = self.screenPointFromVirtualPoint(CGPointMake(width / 2 - piece_width / 2 - 5, yPosOffset))
        numPiecesBlackCircle?.strokeColor = boardBlackPieceStrokeColor
        numPiecesBlackCircle?.lineWidth = 2
        boardView.addChild(numPiecesBlackCircle!)

        numPiecesWhiteCircle = SKShapeNode(circleOfRadius: radius)
        numPiecesWhiteCircle?.fillColor = boardWhitePieceFillColor
        numPiecesWhiteCircle?.position = self.screenPointFromVirtualPoint(CGPointMake(width / 2 + piece_width / 2 + 5, yPosOffset))
        numPiecesWhiteCircle?.strokeColor = boardWhitePieceStrokeColor
        numPiecesWhiteCircle?.lineWidth = 2
        boardView.addChild(numPiecesWhiteCircle!)
    }

    func startGame() {
        gameSettings.loadFromUserDefaults()
        if let unwrappedGVM = gameViewModel {
            gameManager.initialize(unwrappedGVM, gameSettings: gameSettings)
        } else {
            gameViewModel = GameViewModel(gameManager: gameManager, view: self)
            gameManager.initialize(gameViewModel!, gameSettings: gameSettings)
        }
        clearPieces()
        updateView(gameManager.boardMediator!, changes: [], put: [], showPuttables: gameManager.isCurrentTurnHuman() && gameSettings.showPossibleMoves, showAnimation: gameSettings.showAnimation, blackEval: 0.0, whiteEval: 0.0, debugString: "")
        time = 0
        lastUpdatedTime = 0
        timeCounterOn = false
        dispatch_async_global({self.gameManager.startGame()})
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */

        for touch: AnyObject in touches {
            let boardView = self.childNodeWithName("Board") as! SKSpriteNode
            let width : CGFloat = boardView.size.width
            let location_boardView = touch.locationInNode(boardView)
            let piece_width = width / 8
            let (ex, ey) = coordFromTouch(location_boardView.x, y: location_boardView.y, piece_width: piece_width)
            NSLog("Touched \(ex), \(ey)")

            if let hUI = gameManager.getHumanUserInput() {
                hUI.put(ex, y: ey)
            }
        }
    }

    private func coordFromTouch(x: CGFloat, y: CGFloat, piece_width: CGFloat) -> (Int, Int) {
        let pos_x = Int(floor(virtualXFromScreenX(x) / piece_width))
        let pos_y = Int(floor(virtualYFromScreenY(y) / piece_width))
        NSLog("%f, %f -> %f, %f", x.native, y.native, virtualXFromScreenX(x).native, virtualYFromScreenY(y).native)

        return (pos_x, pos_y)
    }

    func updateView(bd : BoardMediator, changes:[(Int, Int)], put: [(Int, Int)], showPuttables: Bool, showAnimation: Bool, blackEval: Double, whiteEval: Double, debugString: String) {
        if let q = updateBoardViewQueue {
            let ubvc = UpdateBoardViewContext(boardMediator: bd, changes: changes, put: put, showPuttables: showPuttables, showAnimation: showAnimation, blackEval: blackEval, whiteEval: whiteEval, debugString: debugString)
            q.enqueue(ubvc)
        }
    }

    func isUpdateBoardViewQueueEmpty() -> Bool {
        if let q = updateBoardViewQueue {
            return q.isEmpty
        }
        return true
    }

    func processUpdateBoardViewQueue() {
        if let q = self.updateBoardViewQueue {
            let deq = q.peek()
            if deq != nil {
                if self.processUpdateBoardViewContext(deq!) {
                    q.dequeue()
                }
            }
        }

    }

    func processUpdateBoardViewContext(context: UpdateBoardViewContext) -> Bool {
        return addChildrenFromBoard(context.boardMediator, changes: context.changes, put: context.put, showPuttables: context.showPuttables, showAnimation: context.showAnimation, blackEval: context.blackEval, whiteEval: context.whiteEval, debugString: context.debugString)
    }

    func addChildrenFromBoard(bd : BoardMediator, changes:[(Int, Int)], put: [(Int, Int)], showPuttables: Bool, showAnimation: Bool, blackEval: Double, whiteEval: Double, debugString: String) -> Bool {
        if(self.drawCount > 0) {
            return false
        }
        synchronized(lock) {
            for y in 0..<bd.height() {
                for x in 0..<bd.width() {
                    let turn = bd.get(x, y: y)

                    if(turn == Pieces.Empty) {
                        let sp = self.boardSprites[y][x]
                        sp?.removeAllActions()
                        sp?.removeFromParent()
                        self.boardSprites[y][x] = nil
                        continue
                    }

                    let boardView = self.childNodeWithName("Board") as! SKSpriteNode
                    let width : CGFloat = boardView.size.width
                    let radius = width / 8 / 2 * 0.8

                    var flipAnimation = false
                    var putAnimation = false
                    var sprite = self.boardSprites[y][x]
                    if(sprite == nil && (turn == Pieces.Black || turn == Pieces.White)) {
                        sprite = SKShapeNode(circleOfRadius: radius)
                        boardView.addChild(sprite!)
                    } else if(turn == Pieces.Guide) {
                        // Erase current sprite
                        sprite?.removeAllActions()
                        sprite?.removeFromParent()
                        self.boardSprites[y][x] = nil
                        // And update with guide
                        if(showPuttables) {
                            sprite = SKShapeNode(circleOfRadius: radius / 4)
                            self.boardSprites[y][x] = sprite
                            boardView.addChild(sprite!)
                        } else {
                            continue
                        }
                    } else if(turn == Pieces.Black || turn == Pieces.White) {
                        for (cx, cy) in changes {
                            if(cx == x && cy == y) {
                                flipAnimation = true
                                break
                            }
                        }
                        if(put.count > 0 && put[0].0 == x && put[0].1 == y) {
                            // Delete Guide
                            sprite?.removeAllActions()
                            sprite?.removeFromParent()
                            self.boardSprites[y][x] = nil
                            // Put piece
                            sprite = SKShapeNode(circleOfRadius: radius)
                            boardView.addChild(sprite!)
                            putAnimation = true
                        }
                    }

                    if let spriteUnwrapped = sprite {
                        var colorTo = self.boardGuidePieceFillColor
                        if(turn == Pieces.White) {
                            colorTo = self.boardWhitePieceFillColor
                        } else if (turn == Pieces.Black) {
                            colorTo = self.boardBlackPieceFillColor
                        } else if (turn == Pieces.Guide && self.showGuides) {
                            colorTo = self.boardGuidePieceFillColor
                        } else {
                            assertionFailure("Should not reach this code!")
                        }

                        self.drawCount+=1
                        if(putAnimation && showAnimation) {
                            let fadeOut = SKAction.fadeAlphaTo(1.0, duration: 0.05)
                            let colorChange = SKAction.runBlock({() in spriteUnwrapped.strokeColor = self.tintColor})
                            let fadeIn = SKAction.fadeAlphaTo(1.0, duration: 0.05)
                            let fadeOut2 = SKAction.fadeAlphaTo(0.0, duration: 0.1)
                            let colorChange2 = SKAction.runBlock({() in spriteUnwrapped.fillColor = colorTo; spriteUnwrapped.strokeColor = self.boardGuidePieceFillColor})
                            let fadeIn2 = SKAction.fadeAlphaTo(1.0, duration: 0.1)


                            let sequenceActions = SKAction.sequence([
                                fadeOut, colorChange, fadeIn,
                                fadeOut2, colorChange2, fadeIn2,
                                ])

                            spriteUnwrapped.runAction(sequenceActions, completion: {() in spriteUnwrapped.fillColor = colorTo; spriteUnwrapped.alpha = 1.0; self.drawCount-=1})
                        } else if(flipAnimation && showAnimation) {
                            let fadeOut = SKAction.fadeAlphaTo(0.0, duration: 0.2)
                            let colorChange = SKAction.runBlock({() in spriteUnwrapped.fillColor = colorTo})
                            let fadeIn = SKAction.fadeAlphaTo(1.0, duration: 0.2)

                            let sequenceActions = SKAction.sequence([fadeOut, colorChange, fadeIn])

                            spriteUnwrapped.runAction(sequenceActions, completion: {() in spriteUnwrapped.fillColor = colorTo; spriteUnwrapped.alpha = 1.0; self.drawCount-=1})
                        } else {
                            spriteUnwrapped.fillColor = colorTo
                            self.drawCount-=1
                        }
                        spriteUnwrapped.strokeColor = self.boardGuidePieceFillColor
                        spriteUnwrapped.lineWidth = 2

                        // Align the piece to boardView
                        let piece_width = width / 8
                        let px = CGFloat(x) * piece_width + piece_width / 2
                        let py = (CGFloat(y) * piece_width) + piece_width / 2
                        spriteUnwrapped.position = self.screenPointFromVirtualPoint(CGPointMake(px, py))

                        // Add
                        self.boardSprites[y][x] = spriteUnwrapped

                    } // if let spriteUnwrapped = sprite
                } // for x
            } // for y

            // Hilight put position
            if(put.count > 0) {
                let (x, y) = put[0]
                let boardView = self.childNodeWithName("Board") as! SKSpriteNode
                let piece_width = boardView.size.width / 8
                self.lastPut?.removeFromParent()
                self.lastPut = SKShapeNode(rect: self.screenRectFromVritualRect(CGRectMake(CGFloat(x) * piece_width, CGFloat(y) * piece_width, piece_width, piece_width)))
                self.lastPut?.strokeColor = self.tintColor
                boardView.addChild(self.lastPut!)
            }

            // Play information
            // piece_width + width + statusBarHeight
            self.showNumPieces(bd.getNumBlack(), white: bd.getNumWhite(), blackEval: blackEval, whiteEval: whiteEval, debugString: debugString)
        } // synchronized
//        NSLog("!syncend!")
        return true
    }

    func showPasses() {
        let boardView = self.childNodeWithName("Board") as! SKSpriteNode
        let width : CGFloat = boardView.size.width
//        var piece_width = width / 8

        let rectWidth = width * 0.65
        let rectHeight = rectWidth / 3 * 2
        let ox = width / 2 - rectWidth / 2
        let oy = width / 2 - rectHeight / 2

        let rect = CGRectMake(ox, oy, rectWidth, rectHeight)
        let rectNormalized = self.screenRectFromVritualRect(rect)

        let rectanble = SKShapeNode(rect: rectNormalized, cornerRadius: 15)
        rectanble.fillColor = boardPopupFillColor
        boardView.addChild(rectanble)

        let passLabel = SKLabelNode(text: "Pass")
        passLabel.name = "labelPass"
        passLabel.fontColor = boardPopupFontColor
        passLabel.fontSize = 100
        passLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        passLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
        passLabel.position = self.screenPointFromVirtualPoint(CGPointMake(width / 2, width / 2))
        boardView.addChild(passLabel)

        let fadeInFrame = SKAction.fadeAlphaTo(0.5, duration: 0.3)
        let fadeInLabel = SKAction.fadeAlphaTo(1, duration: 0.3)
        let fadeOut = SKAction.fadeAlphaTo(0.0, duration: 0.6)
        passLabel.runAction(SKAction.sequence([fadeInLabel, fadeOut]), completion: {() in passLabel.removeFromParent()})
        rectanble.runAction(SKAction.sequence([fadeInFrame, fadeOut]), completion: {() in rectanble.removeFromParent()})
    }

    func showGameOver(title: String, message: String, showNext: Bool, nextLabel: String) {
        //
        let viewController = self.view?.window?.rootViewController as! GameViewController
        var actions: [UIAlertAction] = []

        actions.append(UIAlertAction(title: "Again", style: .Default, handler: {
            action in NSLog("Retry!")
        }))

        if(showNext) {
            actions.append(UIAlertAction(title: nextLabel, style: .Default, handler: {
                action in
                self.gameSettings.loadFromUserDefaults()
                let lc: LevelController = LevelController()
                if let nextChallengeLevel = lc.getNextLevel(self.gameManager.challengeLevelId) {
                    switch (self.gameManager.challengeModeComputer()) {
                    case Pieces.Black:
                        self.gameSettings.blackPlayerComputerLevelId = nextChallengeLevel.levelId
                        self.gameSettings.saveToUserDefaults()
                    case Pieces.White:
                        self.gameSettings.whitePlayerComputerLevelId = nextChallengeLevel.levelId
                        self.gameSettings.saveToUserDefaults()
                    default:
                        NSLog("No challenge mode")
                    }
                }
            }))
        }

        viewController.updateNavBarTitle("Game Set")
        viewController.popupAlert(title, message: message, actions: actions)
    }

    private func screenXFromVirtualX(x: CGFloat) -> CGFloat {
        return x - 320
    }

    private func screenYFromVirtualY(y: CGFloat) -> CGFloat {
        return 1136 - y - topYOffset
    }

    private func virtualXFromScreenX(x: CGFloat) -> CGFloat {
        return x + 320
    }

    private func virtualYFromScreenY(y: CGFloat) -> CGFloat {
        return 1136 - y - topYOffset
    }

    private func screenPointFromVirtualPoint(point: CGPoint) -> CGPoint {
        return CGPointMake(screenXFromVirtualX(point.x), screenYFromVirtualY(point.y))
    }

    private func screenRectFromVritualRect(rect: CGRect) -> CGRect {
        return CGRectMake(screenXFromVirtualX(rect.origin.x), screenYFromVirtualY(rect.origin.y), rect.width, -rect.height)
    }
    
    override func update(currentTime: CFTimeInterval) {
        if(!self.paused) {
            processUpdateBoardViewQueue()

            /* Called before each frame is rendered */
            let viewController = self.view?.window?.rootViewController as! GameViewController

            var title = ""
            if self.gameManager.isGameOver() {
                title = "Game set"
            } else if self.gameManager.isCurrentTurnHuman() {
                title = "Your turn"
            } else {
                title = "Computer is thinking..."
            }
            viewController.updateNavBarTitle(title)
        }
    }
}
