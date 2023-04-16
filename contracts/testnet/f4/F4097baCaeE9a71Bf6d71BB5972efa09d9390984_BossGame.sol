// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BossGame {

    enum GameState {
        IN_PROGRESS,
        FINISHED,
        WIN,
        LOSE
    }

    struct Deposit {
        uint256 amount;
        bool claimed;
    }

    IERC20 public dibToken;
    uint256 public bossHp;
    uint256 public gameDuration;
    uint256 public endTime;
    uint256 public totalDeposits;
    mapping(address => Deposit) public deposits;

    address public factory;
    GameState public gameState;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 public rewardPerShare;

    modifier onlyInGameState(GameState _state) {
        require(gameState == _state, "wrong game state");
        _;
    }

    modifier onlyFactory {
        require(msg.sender == factory, "not factory");
        _;
    }

    function init(
        IERC20 _dibToken,
        uint256 _gameDuration,
        uint256 _bossHp
    ) external {
        require(address(dibToken) == address(0), "already initialized");
        require(address(_dibToken) != address(0), "zero dib address");
        require(_gameDuration > 0, "zero game duration");
        require(_bossHp > 0, "zero boss hp");
        _dibToken.balanceOf(address(this)); //safety check
        gameDuration = _gameDuration;
        dibToken = _dibToken;
        bossHp = _bossHp;

        endTime = block.timestamp + _gameDuration;

        gameState = GameState.IN_PROGRESS;
        factory = msg.sender;
    }

    function reward() external view returns (uint256) {
        return dibToken.balanceOf(address(this)) - totalDeposits;
    }

    function stake(uint256 _amount) external onlyInGameState(GameState.IN_PROGRESS) {
        require(block.timestamp <= endTime, "finished");
        dibToken.transferFrom(msg.sender, address(this), _amount);
        deposits[msg.sender].amount += _amount;
        totalDeposits += _amount;
    }

    function claimRewards() external onlyInGameState(GameState.WIN) {
        require(!deposits[msg.sender].claimed, "already claimed");
        uint256 claimableAmount = (rewardPerShare * deposits[msg.sender].amount) / 1e18;
        deposits[msg.sender].claimed = true;
        dibToken.transfer(msg.sender, claimableAmount);
    }

    function endGame() external onlyFactory {
        gameState = GameState.FINISHED;
    }

    function finishGame(uint256 _randomNumber) external onlyInGameState(GameState.FINISHED) onlyFactory {
        require(block.timestamp > endTime, "not yet");

        if (_randomNumber <= calculateWinThreshold(totalDeposits, bossHp) && totalDeposits > 0) {
            gameState = GameState.WIN;
            rewardPerShare = (dibToken.balanceOf(address(this)) * 1e18) / totalDeposits;
        } else {
            gameState = GameState.LOSE;
            dibToken.transfer(DEAD, dibToken.balanceOf(address(this)));
        }
    }

    function calculateWinThreshold(
        uint256 _totalDeposits,
        uint256 _bossHp
    ) public pure returns (uint256) {
        return (type(uint256).max / (_totalDeposits + _bossHp)) * _totalDeposits;
    }

}