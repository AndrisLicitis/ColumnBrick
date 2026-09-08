import SwiftUI

// MARK: - Constants

let boardWidth = 10
let boardHeight = 20

let pieceLength = 3
let matchLength = 3

// MARK: - Game State

struct GameState {
  var board: [[Int]]

  var currentPiece: [Int]
  var nextPiece: [Int]

  var pieceRow: Int
  var pieceColumn: Int

  var checkMatches: Bool
  var readyForNextPiece: Bool

  var score: Int

  var gameOver: Bool
  var paused: Bool

  var speedStep: Int
}
// ----------------------------------------------------
// MARK: - Score Entry
// ----------------------------------------------------
struct ScoreEntry: Codable {
  let name: String
  let score: Int
}

// MARK: - New Game
// ----------------------------------------------------
func newGame() -> GameState {

  let emptyBoard = Array(
    repeating: Array(repeating: 0, count: boardWidth),
    count: boardHeight
  )

  let difficulty =
    UserDefaults.standard.string(
      forKey: "difficulty"
    ) ?? "Hard"

  let speedStep: Int

  if difficulty == "Easy" {
    speedStep = 300
  } else if difficulty == "Medium" {
    speedStep = 150
  } else {
    speedStep = 15
  }

  return GameState(
    board: emptyBoard,

    currentPiece: [1, 2, 3],
    nextPiece: generateNextPiece(),

    pieceRow: 0,
    pieceColumn: boardWidth / 2,

    checkMatches: false,
    readyForNextPiece: false,

    score: 0,

    gameOver: false,
    paused: false,

    speedStep: speedStep
  )
}

// MARK: - Speed
// ----------------------------------------------------
func speed(
  for score: Int,
  speedStep: Int
) -> Int {

  return score / speedStep + 1
}

// MARK: - Fall Interval
// ----------------------------------------------------
func fallInterval(
  for score: Int,
  speedStep: Int
) -> Double {

  let currentSpeed =
    speed(
      for: score,
      speedStep: speedStep
    )

  return max(
    0.10,
    1.0 / Double(currentSpeed)
  )
}

// MARK: - Piece Generation
// ----------------------------------------------------
func generateNextPiece() -> [Int] {

  return [
    Int.random(in: 1...5),
    Int.random(in: 1...5),
    Int.random(in: 1...5),
  ]
}

// MARK: - Pause
// ----------------------------------------------------
func togglePause(
  _ state: GameState
) -> GameState {

  var newState = state

  newState.paused.toggle()

  return newState
}

// MARK: - Can Move Sideways
// ----------------------------------------------------
func canMoveSideways(
  _ state: GameState,
  direction: Int
) -> Bool {

  let newColumn =
    state.pieceColumn + direction

  if newColumn < 0 || newColumn >= boardWidth {

    return false
  }

  for i in 0..<pieceLength {

    let row =
      state.pieceRow + i

    if row < 0 || row >= boardHeight {

      return false
    }

    if state.board[row][newColumn] != 0 {
      return false
    }
  }

  return true
}

// MARK: - Move Left
// ----------------------------------------------------
func moveLeft(
  _ state: GameState
) -> GameState {

  if canMoveSideways(
    state,
    direction: -1
  ) {

    var newState = state

    newState.pieceColumn -= 1

    return newState
  }

  return state
}

// MARK: - Move Right
// ----------------------------------------------------
func moveRight(
  _ state: GameState
) -> GameState {

  if canMoveSideways(
    state,
    direction: 1
  ) {

    var newState = state

    newState.pieceColumn += 1

    return newState
  }

  return state
}

// MARK: - Can Move Down
// ----------------------------------------------------
func canMoveDown(
  _ state: GameState
) -> Bool {

  let nextRow =
    state.pieceRow + 1

  if nextRow + pieceLength - 1 >= boardHeight {
    return false
  }

  for i in 0..<pieceLength {

    let row =
      nextRow + i

    let column =
      state.pieceColumn

    if state.board[row][column] != 0 {
      return false
    }
  }

  return true
}

// MARK: - Move Down
// ----------------------------------------------------
func moveDown(
  _ state: GameState
) -> GameState {

  if state.checkMatches {
    return state
  }

  if canMoveDown(state) {

    var newState = state

    newState.pieceRow += 1

    return newState
  }

  let placedState =
    placePiece(state)

  return resolveBoard(placedState)
}

// MARK: - Rotate / Reorder Piece
// ----------------------------------------------------
func rotatePiece(
  _ state: GameState
) -> GameState {

  var newState = state

  guard !newState.currentPiece.isEmpty else {
    return state
  }

  let firstValue =
    newState.currentPiece.removeFirst()

  newState.currentPiece.append(firstValue)

  return newState
}

// MARK: - Place Piece
// ----------------------------------------------------
func placePiece(
  _ state: GameState
) -> GameState {

  var newState = state

  for i in 0..<pieceLength {

    let row =
      state.pieceRow + i

    let column =
      state.pieceColumn

    if row < 0 || row >= boardHeight {

      continue
    }

    newState.board[row][column] =
      state.currentPiece[i]
  }

  newState.checkMatches = true
  newState.readyForNextPiece = false

  return newState
}

// MARK: - Resolve Board
// ----------------------------------------------------
func resolveBoard(
  _ state: GameState
) -> GameState {

  var newState = state

  while true {

    let matches =
      findMatches(newState.board)

    if matches.isEmpty {

      newState.checkMatches = false
      newState.readyForNextPiece = true

      return startNextPiece(newState)
    }

    newState.score += matches.count

    newState.board =
      removeMatches(
        from: newState.board,
        positions: matches
      )

    newState.board =
      applyGravity(newState.board)
  }
}

// MARK: - Find Matches
// ----------------------------------------------------
func findMatches(
  _ board: [[Int]]
) -> Set<GridPosition> {

  var matches =
    Set<GridPosition>()

  let directions = [

    (row: 0, column: 1),
    (row: 1, column: 0),
    (row: 1, column: 1),
    (row: -1, column: 1),
  ]

  for row in 0..<boardHeight {

    for column in 0..<boardWidth {

      let value =
        board[row][column]

      if value == 0 {
        continue
      }

      for direction in directions {

        var positions = [
          GridPosition(
            row: row,
            column: column
          )
        ]

        var nextRow =
          row + direction.row

        var nextColumn =
          column + direction.column

        while isInsideBoard(
          row: nextRow,
          column: nextColumn
        ) {

          if board[nextRow][nextColumn] != value {
            break
          }

          positions.append(
            GridPosition(
              row: nextRow,
              column: nextColumn
            )
          )

          nextRow += direction.row
          nextColumn += direction.column
        }

        if positions.count >= matchLength {

          for position in positions {
            matches.insert(position)
          }
        }
      }
    }
  }

  return matches
}

// MARK: - Grid Position
// ----------------------------------------------------
struct GridPosition: Hashable {

  let row: Int
  let column: Int
}

// MARK: - Board Bounds
// ----------------------------------------------------
func isInsideBoard(
  row: Int,
  column: Int
) -> Bool {

  return row >= 0 && row < boardHeight && column >= 0 && column < boardWidth
}

// MARK: - Remove Matches
// ----------------------------------------------------
func removeMatches(
  from board: [[Int]],
  positions: Set<GridPosition>
) -> [[Int]] {

  var newBoard = board

  for position in positions {

    newBoard[position.row][position.column] = 0
  }

  return newBoard
}

// MARK: - Gravity
// ----------------------------------------------------
func applyGravity(
  _ board: [[Int]]
) -> [[Int]] {

  var newBoard = board

  for column in 0..<boardWidth {

    var values: [Int] = []

    for row in stride(
      from: boardHeight - 1,
      through: 0,
      by: -1
    ) {

      let value =
        board[row][column]

      if value != 0 {
        values.append(value)
      }
    }

    for row in 0..<boardHeight {
      newBoard[row][column] = 0
    }

    for (index, value) in values.enumerated() {

      let row =
        boardHeight - 1 - index

      newBoard[row][column] = value
    }
  }

  return newBoard
}

// MARK: - Start Next Piece
// ----------------------------------------------------
func startNextPiece(
  _ state: GameState
) -> GameState {

  var newState = state

  newState.currentPiece =
    state.nextPiece

  newState.nextPiece =
    generateNextPiece()

  newState.pieceRow = 0

  newState.pieceColumn =
    boardWidth / 2

  newState.checkMatches = false
  newState.readyForNextPiece = false

  if !canPlaceNewPiece(newState) {
    newState.gameOver = true
  }

  return newState
}

// MARK: - Can Place New Piece
// ----------------------------------------------------
func canPlaceNewPiece(
  _ state: GameState
) -> Bool {

  for i in 0..<pieceLength {

    let row =
      state.pieceRow + i

    let column =
      state.pieceColumn

    if row >= boardHeight {
      return false
    }

    if state.board[row][column] != 0 {
      return false
    }
  }

  return true
}

// MARK: - Visible Board
// ----------------------------------------------------
func visibleBoard(
  _ state: GameState,
  gameOverCells: Int
) -> [[Int]] {

  var result =
    state.board

  //---------

  if state.gameOver {

    let totalCells =
      min(
        gameOverCells,
        boardWidth * boardHeight
      )

    for index in 0..<totalCells {

      let rowFromBottom =
        index / boardWidth

      let column =
        index % boardWidth

      let row =
        boardHeight - 1 - rowFromBottom

      result[row][column] = 6
    }

    return result
  }
  //---------

  for i in 0..<pieceLength {

    let row =
      state.pieceRow + i

    let column =
      state.pieceColumn

    if row >= 0 && row < boardHeight && column >= 0 && column < boardWidth {

      result[row][column] =
        state.currentPiece[i]
    }
  }

  return result
}

// MARK: - Number Colors
// ----------------------------------------------------
func colorForValue(
  _ value: Int
) -> Color {

  switch value {

  case 1:
    return .red

  case 2:
    return .blue

  case 3:
    return .green

  case 4:
    return .orange

  case 5:
    return .purple

  case 6:
    return .white

  default:
    return .clear
  }
}

// MARK: - Content View
// ----------------------------------------------------
struct ContentView: View {

  @State private var game =
    newGame()

  @State private var gameOverCells = 0

  @State private var playerName = ""
  @State private var showNameInput = false
  @State private var showScores = false
  //----------

  var body: some View {

    VStack(spacing: 18) {

      // MARK: Score + Speed + New Game

      HStack(spacing: 30) {

        Text(
          "SCORE: \(game.score)"
        )

        let currentSpeed =
          speed(
            for: game.score,
            speedStep: game.speedStep
          )

        Text(
          "SPEED: \(currentSpeed)"
        )

        Button("NEW GAME") {

          gameOverCells = 0
          game = newGame()
        }
        .buttonStyle(.bordered)
      }
      .font(
        .system(
          size: 16,
          design: .monospaced
        )
      )

      // MARK: Game + Next

      HStack(
        alignment: .top,
        spacing: 28
      ) {

        gameBoard

        nextPieceView
      }
    }
    .padding(30)
    .background(.black)
    .focusable()
    .focusEffectDisabled()

    // MARK: Automatic Falling

    .task {

      while !Task.isCancelled {

        if game.gameOver {

          try? await Task.sleep(
            for: .milliseconds(100)
          )

          continue
        }

        if game.paused {

          try? await Task.sleep(
            for: .milliseconds(100)
          )

          continue
        }

        let interval =
          fallInterval(
            for: game.score,
            speedStep: game.speedStep
          )

        do {

          try await Task.sleep(
            for: .seconds(interval)
          )

        } catch {

          return
        }

        if !game.gameOver && !game.paused {

          game = moveDown(game)
        }
      }
    }

    // MARK: - Game Over Animation

    .task(id: game.gameOver) {

      if game.gameOver {

        gameOverCells = 0

        for index in 0..<(boardWidth * boardHeight) {

          try? await Task.sleep(
            for: .milliseconds(35)
          )

          if !game.gameOver {
            return
          }

          gameOverCells = index + 1
        }

        //-----------*********
        showNameInput = true
      }
    }

    // MARK: Pause - P

    .onKeyPress("p") {

      if !game.gameOver {
        game = togglePause(game)
      }

      return .handled
    }
    /******************************/
    .sheet(isPresented: $showScores) {
      ScoresView()
    }
    //*******************************
    .alert(
      "GAME OVER",
      isPresented: $showNameInput
    ) {

      TextField(
        "Your name",
        text: $playerName
      )
      .onChange(of: playerName) {
        if playerName.count > 15 {
          playerName = String(
            playerName.prefix(15)
          )
        }
      }

      Button("OK") {
        saveScore()
      }

    } message: {

      Text("Enter your name")
    }
    //*******************************

    // MARK: Left

    .onKeyPress(.leftArrow) {

      if !game.gameOver && !game.paused {

        game = moveLeft(game)
      }

      return .handled
    }

    // MARK: Right

    .onKeyPress(.rightArrow) {

      if !game.gameOver && !game.paused {

        game = moveRight(game)
      }

      return .handled
    }

    // MARK: Down

    .onKeyPress(.downArrow) {

      if !game.gameOver && !game.paused {

        game = moveDown(game)
      }

      return .handled
    }

    // MARK: Space

    .onKeyPress(.space) {

      if !game.gameOver && !game.paused {

        game = rotatePiece(game)
      }

      return .handled
    }

    // MARK: Up

    .onKeyPress(.upArrow) {

      if !game.gameOver && !game.paused {

        game = rotatePiece(game)
      }

      return .handled
    }

    //------
    .sheet(isPresented: $showScores) {
      ScoresView()
    }

    .alert(
      "GAME OVER",
      isPresented: $showNameInput
    ) {

      TextField(
        "Your name",
        text: $playerName
      )
      .onChange(of: playerName) {
        if playerName.count > 15 {
          playerName =
            String(
              playerName.prefix(15)
            )
        }
      }

      Button("OK") {
        saveScore()
      }

    } message: {

      Text("Enter your name")
    }
    //------
  }

  // MARK: - Save Score

  private func saveScore() {

    let name =
      playerName
      .trimmingCharacters(
        in: .whitespacesAndNewlines
      )

    guard !name.isEmpty else {
      return
    }

    let limitedName =
      String(name.prefix(15))

    let defaults =
      UserDefaults.standard

    var scores: [ScoreEntry] = []

    if let data =
      defaults.data(forKey: "scores")
    {

      scores =
        (try? JSONDecoder().decode(
          [ScoreEntry].self,
          from: data
        )) ?? []
    }

    scores.append(
      ScoreEntry(
        name: limitedName,
        score: game.score
      )
    )

    scores.sort {
      $0.score > $1.score
    }

    // Only TOP 10
    scores =
      Array(
        scores.prefix(10)
      )

    if let data =
      try? JSONEncoder().encode(scores)
    {

      defaults.set(
        data,
        forKey: "scores"
      )
    }

    playerName = ""
    showScores = true
  }

  // MARK: - Game Board

  private var gameBoard: some View {

    let board =
      visibleBoard(
        game,
        gameOverCells: gameOverCells
      )

    let cellSize: CGFloat = 26

    let width =
      CGFloat(boardWidth) * cellSize

    let height =
      CGFloat(boardHeight) * cellSize

    return Canvas { context, size in

      // Background

      context.fill(
        Path(
          CGRect(
            x: 0,
            y: 0,
            width: width,
            height: height
          )
        ),
        with: .color(.black)
      )

      // Board grid

      for column in 0...boardWidth {

        let x =
          CGFloat(column) * cellSize

        var path = Path()

        path.move(
          to: CGPoint(
            x: x,
            y: 0
          )
        )

        path.addLine(
          to: CGPoint(
            x: x,
            y: height
          )
        )

        context.stroke(
          path,
          with: .color(
            .gray.opacity(0.45)
          ),
          lineWidth: 0.7
        )
      }

      for row in 0...boardHeight {

        let y =
          CGFloat(row) * cellSize

        var path = Path()

        path.move(
          to: CGPoint(
            x: 0,
            y: y
          )
        )

        path.addLine(
          to: CGPoint(
            x: width,
            y: y
          )
        )

        context.stroke(
          path,
          with: .color(
            .gray.opacity(0.45)
          ),
          lineWidth: 0.7
        )
      }

      // Blocks

      for row in 0..<boardHeight {

        for column in 0..<boardWidth {

          let value =
            board[row][column]

          if value == 0 {
            continue
          }

          drawBlock(
            value: value,
            row: row,
            column: column,
            cellSize: cellSize,
            context: &context
          )
        }
      }
    }
    .frame(
      width: width,
      height: height
    )
    .padding(12)
    .background(.black)
    .overlay {

      Rectangle()
        .stroke(
          .gray,
          lineWidth: 2
        )
        .padding(3)

      Rectangle()
        .stroke(
          .gray,
          lineWidth: 2
        )
        .padding(8)
    }
  }

  // MARK: - Draw Block

  private func drawBlock(
    value: Int,
    row: Int,
    column: Int,
    cellSize: CGFloat,
    context: inout GraphicsContext
  ) {

    let blockColor =
      colorForValue(value)

    let x =
      CGFloat(column) * cellSize

    let y =
      CGFloat(row) * cellSize

    let blockRect =
      CGRect(
        x: x + 2,
        y: y + 2,
        width: cellSize - 4,
        height: cellSize - 4
      )

    // Main block

    context.fill(
      Path(blockRect),
      with: .color(blockColor)
    )

    // Fine checker texture

    let textureSize: CGFloat = 1.35

    for textureRow in 0..<16 {

      for textureColumn in 0..<16 {

        if (textureRow + textureColumn) % 2 == 0 {
          continue
        }

        let tx =
          blockRect.minX + CGFloat(textureColumn) * textureSize

        let ty =
          blockRect.minY + CGFloat(textureRow) * textureSize

        let textureRect =
          CGRect(
            x: tx,
            y: ty,
            width: textureSize,
            height: textureSize
          )

        context.fill(
          Path(textureRect),
          with: .color(.black)
        )
      }
    }

    // Individual block border

    context.stroke(
      Path(blockRect),
      with: .color(.black),
      lineWidth: 1
    )
  }

  // MARK: - Next Piece

  private var nextPieceView: some View {

    VStack(spacing: 0) {

      Text("NEXT")
        .font(
          .system(
            size: 16,
            design: .monospaced
          )
        )
        .foregroundStyle(.gray)
        .padding(.bottom, 8)

      Canvas { context, size in

        let cellSize: CGFloat = 26

        let width = cellSize

        let height =
          CGFloat(pieceLength) * cellSize

        // Background

        context.fill(
          Path(
            CGRect(
              x: 0,
              y: 0,
              width: width,
              height: height
            )
          ),
          with: .color(.black)
        )

        // Grid

        for row in 0...pieceLength {

          let y =
            CGFloat(row) * cellSize

          var path = Path()

          path.move(
            to: CGPoint(
              x: 0,
              y: y
            )
          )

          path.addLine(
            to: CGPoint(
              x: width,
              y: y
            )
          )

          context.stroke(
            path,
            with: .color(
              .gray.opacity(0.45)
            ),
            lineWidth: 0.7
          )
        }

        // Next blocks

        for row in 0..<pieceLength {

          let value =
            game.nextPiece[row]

          let blockRect =
            CGRect(
              x: 2,
              y: CGFloat(row) * cellSize + 2,
              width: cellSize - 4,
              height: cellSize - 4
            )

          let blockColor =
            colorForValue(value)

          context.fill(
            Path(blockRect),
            with: .color(blockColor)
          )

          // Fine checker texture

          let textureSize: CGFloat = 1.35

          for textureRow in 0..<16 {

            for textureColumn in 0..<16 {

              if (textureRow + textureColumn) % 2 == 0 {
                continue
              }

              let tx =
                blockRect.minX + CGFloat(textureColumn) * textureSize

              let ty =
                blockRect.minY + CGFloat(textureRow) * textureSize

              context.fill(
                Path(
                  CGRect(
                    x: tx,
                    y: ty,
                    width: textureSize,
                    height: textureSize
                  )
                ),
                with: .color(.black)
              )
            }
          }

          // Individual block border

          context.stroke(
            Path(blockRect),
            with: .color(.black),
            lineWidth: 1
          )
        }
      }
      .frame(
        width: 26,
        height: 78
      )
      .padding(12)
      .background(.black)
      .overlay {

        Rectangle()
          .stroke(
            .gray,
            lineWidth: 2
          )
          .padding(3)

        Rectangle()
          .stroke(
            .gray,
            lineWidth: 2
          )
          .padding(8)
      }
    }
  }
}

struct ScoresView: View {

  @Environment(\.dismiss)
  private var dismiss

  private var scores: [ScoreEntry] {

    guard
      let data =
        UserDefaults.standard.data(
          forKey: "scores"
        )
    else {
      return []
    }

    return
      (try? JSONDecoder().decode(
        [ScoreEntry].self,
        from: data
      )) ?? []
  }

  var body: some View {

    VStack(spacing: 16) {

      Text("SCORES")
        .font(
          .system(
            size: 20,
            design: .monospaced
          )
        )

      HStack {

        Text("NAME")
          .frame(
            maxWidth: .infinity,
            alignment: .leading
          )

        Text("POINTS")
          .frame(
            width: 80,
            alignment: .trailing
          )
      }
      .font(
        .system(
          size: 14,
          design: .monospaced
        )
      )

      ForEach(
        Array(scores.enumerated()),
        id: \.offset
      ) { _, entry in

        HStack {

          Text(entry.name)
            .frame(
              maxWidth: .infinity,
              alignment: .leading
            )

          Text("\(entry.score)")
            .frame(
              width: 80,
              alignment: .trailing
            )
        }
        .font(
          .system(
            size: 14,
            design: .monospaced
          )
        )
      }

      Button("OK") {
        dismiss()
      }
      .buttonStyle(.bordered)
    }
    .padding(30)
    .frame(
      width: 350,
      height: 460
    )
  }
}
