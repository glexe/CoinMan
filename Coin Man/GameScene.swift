//
//  GameScene.swift
//  Coin Man
//
//  Created by Ilya Gladyshev on 10/6/24.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private var coinMan: SKSpriteNode?
    private var coinTimer: Timer?
    private var bombTimer: Timer?
    private var ground: SKSpriteNode?
    private var ceil: SKSpriteNode?
    private var scoreLabel: SKLabelNode?
    private var yourScoreLabelShadow: SKLabelNode?
    private var yourScoreLabel: SKLabelNode?
    private var collectedScoreLabelShadow: SKLabelNode?
    private var collectedScoreLabel: SKLabelNode?
    
    private var score = 0
    
    private let coinManCategory: UInt32 = 0x1 << 1
    private let coinCategory: UInt32 = 0x1 << 2
    private let bombCategory: UInt32 = 0x1 << 3
    private let groundAndCeilCategory: UInt32 = 0x1 << 4
    
    override func didMove(to view: SKView) {
        setupPhysics()
        setupBackground()
        setupCoinMan()
        setupGroundAndCeil()
        scoreLabel = childNode(withName: "scoreLabel") as? SKLabelNode
        startTimers()
        createGrass()
    }
    
    private func setupPhysics() {
        physicsWorld.contactDelegate = self
    }
    
    
    private func setupBackground() {
        let background = SKSpriteNode(imageNamed: "background")
        background.physicsBody?.collisionBitMask = 0
        background.physicsBody?.contactTestBitMask = 0
        background.zPosition = -3
        let aspectRatio = background.size.width / background.size.height
        let newHeight = self.size.height
        let newWidth = newHeight * aspectRatio
        background.size = CGSize(width: newWidth, height: newHeight)
        addChild(background)
    }
    
    
    private func setupCoinMan() {
        coinMan = childNode(withName: "coinMan") as? SKSpriteNode
        coinMan?.physicsBody?.categoryBitMask = coinManCategory
        coinMan?.physicsBody?.contactTestBitMask = coinCategory | bombCategory
        coinMan?.physicsBody?.collisionBitMask = groundAndCeilCategory
        coinMan?.zPosition = -2
        
        let coinManRun = (1...5).map { SKTexture(imageNamed: "frame-\($0)") }
        let runAction = SKAction.repeatForever(SKAction.animate(with: coinManRun, timePerFrame: 0.09))
        coinMan?.run(runAction)
    }
    
    private func setupGroundAndCeil() {
        ground = setupPhysicsBody(for: "ground", category: groundAndCeilCategory)
        ceil = setupPhysicsBody(for: "ceil", category: groundAndCeilCategory)
    }
    
    private func setupPhysicsBody(for name: String, category: UInt32) -> SKSpriteNode? {
        guard let node = childNode(withName: name) as? SKSpriteNode else { return nil }
        node.physicsBody?.categoryBitMask = category
        node.physicsBody?.contactTestBitMask = coinManCategory
        return node
    }
    
    private func startTimers() {
        coinTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in self.createCoin() }
        bombTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in self.createBomb() }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let location = touches.first?.location(in: self) {
            handleTouch(at: location)
        }
    }
    
    private func handleTouch(at location: CGPoint) {
        if scene?.isPaused == false {
            coinMan?.physicsBody?.applyForce(CGVector(dx: 0, dy: 10_000))
        }
        
        nodes(at: location).forEach { node in
            if node.name == "playButton" {
                resetGame()
            }
        }
    }
    
    private func resetGame() {
        score = 0
        scene?.isPaused = false
        scoreLabel?.text = "Score: \(score)"
        removeUIElements()
        startTimers()
    }
    
    private func removeUIElements() {
        childNode(withName: "playButton")?.removeFromParent()
        
        [yourScoreLabelShadow, yourScoreLabel, collectedScoreLabelShadow, collectedScoreLabel].forEach {
            $0?.removeFromParent()
        }
    }
    
    private func createGrass() {
        let numberOfGrass = Int(size.width / 250) + 1
        
        for number in 0..<numberOfGrass {
            let grass = createGrassNode()
            grass.position = CGPoint(x: -size.width / 2 + grass.size.width / 2 + grass.size.width * CGFloat(number),
                                     y: -size.height / 2 + grass.size.height / 2 - 100)
            addChild(grass)
            
            let firstMoveLeft = SKAction.moveBy(x: -grass.size.width - grass.size.width * (CGFloat(number)), y: 0, duration: TimeInterval(grass.size.width + grass.size.width * CGFloat(number)) / 100.0)
            let resetGrass = SKAction.moveBy(x: size.width + grass.size.width, y: 0, duration: 0)
            let grassFullMove = SKAction.moveBy(x: -size.width - grass.size.width, y: 0, duration: TimeInterval(size.width + grass.size.width) / 100)
            let grassMovingForever = SKAction.repeatForever(SKAction.sequence([grassFullMove, resetGrass]))
            
            
            grass.run(SKAction.sequence([firstMoveLeft, resetGrass, grassMovingForever]))
        }
    }
    
    private func createGrassNode() -> SKSpriteNode {
        let grass = SKSpriteNode(imageNamed: "grass")
        grass.physicsBody = SKPhysicsBody(rectangleOf: grass.size)
        grass.physicsBody?.affectedByGravity = false
        grass.physicsBody?.isDynamic = false
        grass.physicsBody?.categoryBitMask = 0
        grass.size.width = 250
        grass.size.height = 250
        
        let shouldFlipHorizontally = Bool.random()
        if shouldFlipHorizontally {
            grass.xScale = -1
        }
        return grass
    }
    
    private func createCoin() {
        let coin = createItem(named: "coin", size: CGSize(width: 50, height: 50), category: coinCategory)
        coin.position = CGPoint(x: size.width / 2 + coin.size.width, y: randomYPosition(for: coin.size.height))
        addChild(coin)
        
        let rotateAction = SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 1))
        let moveAndRemove = SKAction.sequence([SKAction.moveBy(x: -size.width - coin.size.width, y: 0, duration: 4), SKAction.removeFromParent()])
        coin.run(SKAction.group([rotateAction, moveAndRemove]))
    }
    
    private func createBomb() {
        let bomb = createItem(named: "bomb", size: CGSize(width: 80, height: 80), category: bombCategory)
        bomb.position = CGPoint(x: size.width / 2 + bomb.size.width, y: randomYPosition(for: bomb.size.height))
        addChild(bomb)
        
        let flashSequence = SKAction.sequence([SKAction.colorize(with: .red, colorBlendFactor: 1.0, duration: 0.2),
                                               SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.2)])
        let moveAndRemove = SKAction.sequence([SKAction.moveBy(x: -size.width - bomb.size.width, y: 0, duration: 4), SKAction.removeFromParent()])
        bomb.run(SKAction.group([SKAction.repeatForever(flashSequence), moveAndRemove]))
    }
    
    private func createItem(named name: String, size: CGSize, category: UInt32) -> SKSpriteNode {
        let item = SKSpriteNode(imageNamed: name)
        item.size = size
        item.physicsBody = SKPhysicsBody(rectangleOf: size)
        item.physicsBody?.categoryBitMask = category
        item.physicsBody?.affectedByGravity = false
        item.physicsBody?.collisionBitMask = 0
        return item
    }
    
    private func randomYPosition(for height: CGFloat) -> CGFloat {
        let maxY = size.height / 2 - height / 2
        let minY = -size.height / 2 + height / 2 + 107
        return maxY - CGFloat(arc4random_uniform(UInt32(maxY - minY)))
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == coinCategory || contact.bodyB.categoryBitMask == coinCategory {
            handleCoinContact(contact)
        } else if contact.bodyA.categoryBitMask == bombCategory || contact.bodyB.categoryBitMask == bombCategory {
            contact.bodyB.node?.removeFromParent()
            handleBombContact()
            
        }
    }
    
    private func handleCoinContact(_ contact: SKPhysicsContact) {
        (contact.bodyA.categoryBitMask == coinCategory ? contact.bodyA.node : contact.bodyB.node)?.removeFromParent()
        score += 1
        scoreLabel?.text = "Score: \(score)"
    }
    
    private func handleBombContact() {
        coinTimer?.invalidate()
        bombTimer?.invalidate()
        scene?.isPaused = true
        displayGameOver()
    }
    
    private func displayGameOver() {
        addGameOverLabels()
        addPlayButton()
    }
    
    private func addGameOverLabels() {
        yourScoreLabelShadow = createLabel(text: "Your score: ", position: CGPoint(x: 2, y: 198), fontSize: 100, color: .black, zPosition: -1)
        yourScoreLabel = createLabel(text: "Your score: ", position: CGPoint(x: 0, y: 200), fontSize: 100)
        collectedScoreLabelShadow = createLabel(text: "\(score)", position: CGPoint(x: 2, y: -2), fontSize: 200, color: .black, zPosition: -1)
        collectedScoreLabel = createLabel(text: "\(score)", position: CGPoint(x: 0, y: 0), fontSize: 200)
    }
    
    private func createLabel(text: String, position: CGPoint, fontSize: CGFloat, color: UIColor = .white, zPosition: CGFloat = 0) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.position = position
        label.fontSize = fontSize
        label.fontColor = color
        label.zPosition = zPosition
        addChild(label)
        return label
    }
    
    private func addPlayButton() {
        let playButton = SKSpriteNode(imageNamed: "playButton")
        playButton.position = CGPoint(x: 0, y: -200)
        playButton.size = CGSize(width: 200, height: 200)
        playButton.name = "playButton"
        addChild(playButton)
    }
}
