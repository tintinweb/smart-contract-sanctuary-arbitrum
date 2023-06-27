// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeadManSwitch {
    struct Switch {
        uint32 id;
        uint256 switchExpireTime;
        address[] whitelisted;
        mapping(address => uint256) ethBalance;
        mapping(address => uint256) erc20Balance;
    }

    mapping(address => Switch) public switches;

    uint256 public defaultTimer = 1687867630;
    uint32 private currentId = 1;

    /**
     * @dev Creates a new dead man's switch with a specified timer and a list of whitelisted addresses.
     *
     * @param _timer The duration of the timer in seconds.
     * @param _whitelisted The addresses that are allowed to claim the assets after the timer expires.
     */
    function createSwitch(uint256 _timer, address[] memory _whitelisted) external {
        Switch storage dms = switches[msg.sender];
        require(dms.switchExpireTime == 0, "Switch already exists");

        dms.id = currentId;
        dms.switchExpireTime = _timer;
        dms.whitelisted = _whitelisted;
        currentId += 1;
    }

    /**
     * @dev Resets the timer for the dead man's switch of the message sender.
     */
    function resetTimer() external {
        Switch storage dms = switches[msg.sender];
        require(dms.switchExpireTime > 0, "Switch does not exist");

        dms.switchExpireTime = block.timestamp + defaultTimer;
    }

    /**
     * @dev Allows the message sender to deposit ether into their dead man's switch.
     */
    function depositEther() external payable {
        Switch storage dms = switches[msg.sender];
        require(dms.switchExpireTime > 0, "Switch does not exist");

        dms.ethBalance[address(0)] += msg.value;
    }

    /**
     * @dev Allows the message sender to deposit ERC20 tokens into their dead man's switch.
     *
     * @param _token The address of the ERC20 token to deposit.
     * @param _amount The amount of tokens to deposit.
     */
    function depositERC20(IERC20 _token, uint256 _amount) external {
        Switch storage dms = switches[msg.sender];
        require(dms.switchExpireTime > 0, "Switch does not exist");

        _token.transferFrom(msg.sender, address(this), _amount);
        dms.erc20Balance[address(_token)] += _amount;
    }

    /**
     * @dev Allows a whitelisted address to claim the assets from a dead man's switch after the timer expires.
     *
     * @param _from The address of the dead man's switch.
     * @param _token The address of the asset to claim. Use the zero address for ether.
     */
    function claim(address _from, address _token) external {
        Switch storage dms = switches[_from];
        require(dms.switchExpireTime > 0, "Switch does not exist");
        require(dms.switchExpireTime <= block.timestamp, "Timer has not expired");
        require(isWhitelisted(_from, msg.sender), "Not whitelisted");

        uint256 balance = dms.erc20Balance[_token];
        require(balance > 0, "No balance");

        // We use the 0x0 address to distinguish between ETH and ERC20 claims.
        if (_token == address(0)) {
            payable(msg.sender).transfer(balance);
        } else {
            IERC20(_token).transfer(msg.sender, balance);
        }

        dms.erc20Balance[_token] = 0;
    }

    /**
     * @dev Checks whether an address is whitelisted for a DMS.
     *
     * @param _switch The address of the dead man's switch.
     * @param _addr The address to check.
     * @return True if the address is whitelisted, false otherwise.
     */
    function isWhitelisted(address _switch, address _addr) public view returns (bool) {
        Switch storage dms = switches[_switch];

        for (uint256 i = 0; i < dms.whitelisted.length; i++) {
            if (dms.whitelisted[i] == _addr) {
                return true;
            }
        }

        return false;
    }
}

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