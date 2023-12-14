// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Checkers {
    enum SquareState {
        Empty,
        Black,
        Red,
        BlackKing,
        RedKing
    }

    enum PlayerColor {
        Black,
        Red
    }

    address[2] public playerAddresses;
    mapping(address => uint) playerBalances;
    PlayerColor[2] public playerColors;
    uint public stake;

    bytes32 p1Commitment;
    uint128 p2Nonce;

    SquareState[8][8] board;
    uint8 public currentPlayer;
    uint32 public turnLength;
    uint public turnDeadline;
    bool public p2Joined;
    bool public started;
    bool public ended;

    uint8 public numBlackPieces;
    uint8 public numRedPieces;
    bool[8][8] blackJumps;
    bool[8][8] redJumps;
    uint8 numBlackJumps;
    uint8 numRedJumps;
    uint8[2] continuePiece;
    bool[2] public agreedToTie;

    modifier beforeTurnDeadline() {
        require(block.number <= turnDeadline, "Turn has expired, game over");
        _;
    }

    modifier gameNotOver() {
        require(!ended, "Game is over");
        _;
    }

    constructor(
        address opponent,
        uint32 _turnLength,
        bytes32 _p1Commitment
    ) payable {
        playerAddresses[0] = msg.sender;
        playerAddresses[1] = opponent;
        playerBalances[playerAddresses[0]] = msg.value;
        stake = msg.value;

        turnLength = _turnLength;
        turnDeadline = block.number + turnLength;
        p1Commitment = _p1Commitment;
    }

    function getSquareState(uint8 i, uint8 j) public view returns (uint8) {
        return uint8(board[i][j]);
    }

    function joinGame(uint128 _p2Nonce) public payable beforeTurnDeadline {
        require(msg.sender == playerAddresses[1], "Not your game");
        require(!p2Joined, "Already joined");
        require(msg.value >= stake, "Insufficient stake");

        playerBalances[playerAddresses[1]] = msg.value;
        p2Nonce = _p2Nonce;
        p2Joined = true;
        turnDeadline = block.number + turnLength;
    }

    function initBoard() internal {
        board[0][1] = SquareState.Red;
        board[0][3] = SquareState.Red;
        board[0][5] = SquareState.Red;
        board[0][7] = SquareState.Red;
        board[1][0] = SquareState.Red;
        board[1][2] = SquareState.Red;
        board[1][4] = SquareState.Red;
        board[1][6] = SquareState.Red;
        board[2][1] = SquareState.Red;
        board[2][3] = SquareState.Red;
        board[2][5] = SquareState.Red;
        board[2][7] = SquareState.Red;
        board[5][0] = SquareState.Black;
        board[5][2] = SquareState.Black;
        board[5][4] = SquareState.Black;
        board[5][6] = SquareState.Black;
        board[6][1] = SquareState.Black;
        board[6][3] = SquareState.Black;
        board[6][5] = SquareState.Black;
        board[6][7] = SquareState.Black;
        board[7][0] = SquareState.Black;
        board[7][2] = SquareState.Black;
        board[7][4] = SquareState.Black;
        board[7][6] = SquareState.Black;
    }

    function startGame(uint128 p1Nonce, uint secret) public beforeTurnDeadline {
        require(msg.sender == playerAddresses[0]);
        require(p2Joined, "Opponent has not joined");
        require(!started, "Game has already started");
        require(
            keccak256(abi.encode(p1Nonce, secret)) == p1Commitment,
            "Nonce does not check out"
        );

        started = true;
        initBoard();
        numBlackPieces = 12;
        numRedPieces = 12;
        continuePiece = [10, 10];
        currentPlayer = (uint8)((p1Nonce ^ p2Nonce) & 0x01);
        playerColors[currentPlayer] = PlayerColor.Black;
        playerColors[currentPlayer ^ 0x01] = PlayerColor.Red;
        turnDeadline = block.number + turnLength;
    }

    function isJumpable(
        int8 direction,
        uint8 i,
        uint8 j,
        PlayerColor playerColor
    ) internal view returns (bool) {
        int8 x = int8(i) + direction;
        int8 y1 = int8(j) - 1;
        int8 y2 = int8(j) + 1;
        int8 x_ = int8(i) + direction * 2;
        int8 y1_ = int8(j) - 2;
        int8 y2_ = int8(j) + 2;

        if (playerColor == PlayerColor.Black) {
            return (x >= 0 &&
                x <= 7 &&
                x_ >= 0 &&
                x_ <= 7 &&
                ((y1 >= 0 &&
                    y1 <= 7 &&
                    (board[uint8(x)][uint8(y1)] == SquareState.Red ||
                        board[uint8(x)][uint8(y1)] == SquareState.RedKing) &&
                    y1_ >= 0 &&
                    y1_ <= 7 &&
                    board[uint8(x_)][uint8(y1_)] == SquareState.Empty) ||
                    (y2 >= 0 &&
                        y2 <= 7 &&
                        (board[uint8(x)][uint8(y2)] == SquareState.Red ||
                            board[uint8(x)][uint8(y2)] ==
                            SquareState.RedKing) &&
                        y2_ >= 0 &&
                        y2_ <= 7 &&
                        board[uint8(x_)][uint8(y2_)] == SquareState.Empty)));
        } else {
            return (x >= 0 &&
                x <= 7 &&
                x_ >= 0 &&
                x_ <= 7 &&
                ((y1 >= 0 &&
                    y1 <= 7 &&
                    (board[uint8(x)][uint8(y1)] == SquareState.Black ||
                        board[uint8(x)][uint8(y1)] == SquareState.BlackKing) &&
                    y1_ >= 0 &&
                    y1_ <= 7 &&
                    board[uint8(x_)][uint8(y1_)] == SquareState.Empty) ||
                    (y2 >= 0 &&
                        y2 <= 7 &&
                        (board[uint8(x)][uint8(y2)] == SquareState.Black ||
                            board[uint8(x)][uint8(y2)] ==
                            SquareState.BlackKing) &&
                        y2_ >= 0 &&
                        y2_ <= 7 &&
                        board[uint8(x_)][uint8(y2_)] == SquareState.Empty)));
        }
    }

    function checkJumps(PlayerColor playerColor) internal {
        bool[8][8] memory jumps;
        uint8 numJumps;

        if (playerColor == PlayerColor.Black) {
            for (uint8 i = 0; i < 8; i++) {
                for (uint8 j = 0; j < 8; j++) {
                    if (
                        board[i][j] == SquareState.Black ||
                        board[i][j] == SquareState.BlackKing
                    ) {
                        if (isJumpable(-1, i, j, playerColor)) {
                            jumps[i][j] = true;
                            numJumps += 1;
                            continue;
                        }

                        if (board[i][j] == SquareState.BlackKing) {
                            jumps[i][j] = isJumpable(1, i, j, playerColor);
                            if (jumps[i][j]) {
                                numJumps += 1;
                            }
                        }
                    }
                }
            }

            blackJumps = jumps;
            numBlackJumps = numJumps;
        } else {
            for (uint8 i = 0; i < 8; i++) {
                for (uint8 j = 0; j < 8; j++) {
                    if (
                        board[i][j] == SquareState.Red ||
                        board[i][j] == SquareState.RedKing
                    ) {
                        if (isJumpable(1, i, j, playerColor)) {
                            jumps[i][j] = true;
                            numJumps += 1;
                            continue;
                        }

                        if (board[i][j] == SquareState.RedKing) {
                            jumps[i][j] = isJumpable(-1, i, j, playerColor);
                            if (jumps[i][j]) {
                                numJumps += 1;
                            }
                        }
                    }
                }
            }

            redJumps = jumps;
            numRedJumps = numJumps;
        }
    }

    function makeMove(
        uint8 fromX,
        uint8 fromY,
        uint8 toX,
        uint8 toY
    ) public beforeTurnDeadline gameNotOver {
        require(msg.sender == playerAddresses[currentPlayer], "Not your turn");
        require(started, "Game has not started");
        require(
            fromX <= 7 && fromY <= 7 && toX <= 7 && toY <= 7,
            "Out of bounds"
        );
        if (continuePiece[0] != 10 && continuePiece[1] != 10) {
            require(
                fromX == continuePiece[0] && fromY == continuePiece[1],
                "Must keep jumping with the previous piece"
            );
        }
        require(
            board[toX][toY] == SquareState.Empty,
            "Destination already occupied"
        );

        PlayerColor playerColor = playerColors[currentPlayer];
        SquareState piece = board[fromX][fromY];
        bool keepJumping = false;
        if (playerColor == PlayerColor.Black) {
            require(
                board[fromX][fromY] == SquareState.Black ||
                    board[fromX][fromY] == SquareState.BlackKing,
                "Invalid piece"
            );
            if (numBlackJumps == 0) {
                if (board[fromX][fromY] == SquareState.Black) {
                    require(
                        toX == fromX - 1 &&
                            (toY == fromY + 1 || toY == fromY - 1),
                        "Invalid move"
                    );
                } else {
                    require(
                        (toX == fromX + 1 || toX == fromX - 1) &&
                            (toY == fromY + 1 || toY == fromY - 1),
                        "Invalid move"
                    );
                }
            } else {
                require(
                    blackJumps[fromX][fromY] == true ||
                        (continuePiece[0] != 10 && continuePiece[1] != 10),
                    "Piece not jumpable"
                );
                board[(fromX + toX) / 2][(fromY + toY) / 2] = SquareState.Empty;
                numRedPieces -= 1;
                if (
                    isJumpable(-1, toX, toY, playerColor) ||
                    (piece == SquareState.BlackKing &&
                        isJumpable(1, toX, toY, playerColor))
                ) {
                    continuePiece = [toX, toY];
                    keepJumping = true;
                }
            }

            // Upgrade to King
            if (toX == 0) {
                piece = SquareState.BlackKing;
            }
        } else {
            require(
                board[fromX][fromY] == SquareState.Red ||
                    board[fromX][fromY] == SquareState.RedKing,
                "Invalid piece"
            );
            if (numRedJumps == 0) {
                if (board[fromX][fromY] == SquareState.Red) {
                    require(
                        toX == fromX + 1 &&
                            (toY == fromY + 1 || toY == fromY - 1),
                        "Invalid move"
                    );
                } else {
                    require(
                        (toX == fromX + 1 || toX == fromX - 1) &&
                            (toY == fromY + 1 || toY == fromY - 1),
                        "Invalid move"
                    );
                }
            } else {
                require(
                    redJumps[fromX][fromY] == true ||
                        (continuePiece[0] != 10 && continuePiece[1] != 10),
                    "Piece not jumpable"
                );
                board[(fromX + toX) / 2][(fromY + toY) / 2] = SquareState.Empty;
                numBlackPieces -= 1;
                if (
                    isJumpable(1, toX, toY, playerColor) ||
                    (piece == SquareState.RedKing &&
                        isJumpable(-1, toX, toY, playerColor))
                ) {
                    continuePiece = [toX, toY];
                    keepJumping = true;
                }
            }

            // Upgrade to King
            if (toX == 7) {
                piece = SquareState.RedKing;
            }
        }

        board[fromX][fromY] = SquareState.Empty;
        board[toX][toY] = piece;

        uint8 otherPlayer = currentPlayer ^ 0x01;
        if (numBlackPieces == 0 || numRedPieces == 0) {
            playerBalances[playerAddresses[currentPlayer]] += playerBalances[
                playerAddresses[otherPlayer]
            ];
            ended = true;
            return;
        }

        if (!keepJumping) {
            checkJumps(playerColors[otherPlayer]);
            currentPlayer ^= 0x01;
            continuePiece = [10, 10];
        }
        turnDeadline = block.number + turnLength;
    }

    function tie() public gameNotOver {
        if (msg.sender == playerAddresses[0]) {
            agreedToTie[0] = true;
        } else if (msg.sender == playerAddresses[1]) {
            agreedToTie[1] = true;
        }
    }

    function withdraw() public {
        require(
            msg.sender == playerAddresses[0] || msg.sender == playerAddresses[1]
        );
        require(
            !started ||
                ended ||
                (agreedToTie[0] && agreedToTie[1]) ||
                block.number > turnDeadline,
            "Game is not over"
        );

        if (started && !ended) {
            if (!(agreedToTie[0] && agreedToTie[1])) {
                playerBalances[
                    playerAddresses[currentPlayer ^ 0x01]
                ] += playerBalances[playerAddresses[currentPlayer]];
                playerBalances[playerAddresses[currentPlayer]] = 0;
            }
        }
        ended = true;

        uint amount = playerBalances[msg.sender];
        if (amount > 0) {
            playerBalances[msg.sender] = 0;

            if (!payable(msg.sender).send(amount)) {
                playerBalances[msg.sender] = amount;
            }
        }
    }
}