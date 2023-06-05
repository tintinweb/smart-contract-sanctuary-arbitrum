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

// SPDX-License-Identifier: MIT
// Copied and adjusted from OpenZeppelin
// Adjustments:
// - modifications to support ERC-677
// - removed require messages to save space
// - removed unnecessary require statements
// - removed GSN Context
// - upgraded to 0.8 to drop SafeMath
// - let name() and symbol() be implemented by subclass
// - infinite allowance support, with 2^255 and above considered infinite

pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC677Receiver } from "./IERC677Receiver.sol";

/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * transferAndCall
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 */
abstract contract ConcreteERC20 is IERC20 {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    uint8 public immutable decimals;

    constructor(uint8 _decimals) {
        decimals = _decimals;
    }

    // Optional functions
    function name() external view virtual returns (string memory);

    function symbol() external view virtual returns (string memory);

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance < (1 << 255)) {
            // Only decrease the allowance if it was not set to 'infinite'
            require(currentAllowance >= amount, "approval not enough");
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(recipient != address(0));
        require(_balances[sender] >= amount, "balance not enough");
        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    // ERC-677 functionality, can be useful for swapping and wrapping tokens
    function transferAndCall(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        bool success = transfer(recipient, amount);
        if (success) {
            success = IERC677Receiver(recipient).onTokenTransfer(msg.sender, amount, data);
        }
        return success;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address recipient, uint256 amount) internal virtual {
        require(recipient != address(0));

        _beforeTokenTransfer(address(0), recipient, amount);

        _totalSupply += amount;
        _balances[recipient] += amount;
        emit Transfer(address(0), recipient, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        _beforeTokenTransfer(account, address(0), amount);

        _totalSupply -= amount;
        _balances[account] -= amount;
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ConcreteERC20 } from "./ConcreteERC20.sol";
import { Equity } from "./Equity.sol";
import { ID8XCoin } from "./ID8XCoin.sol";

contract D8XCoin is Equity {
    event PortalTraversal(
        bool isLeaving,
        uint256 amount,
        address wallet,
        uint256 totalAmountTraversedOut,
        uint256 totalSupply
    );
    event ChangeInitiated(string name, address from, address to);
    event ChangeExecuted(string name, address from, address to);
    address public portal;
    address public janusGuardian;
    address public newGuardian;
    address public newPortal;
    uint32 public timeLockStart;
    uint32 public immutable timeLockSeconds;
    uint256 public constant TOTALAMOUNT = 10000000_000_000_000_000_000_000;

    /**
     *
     * @param _epochDurationSec    epoch duration in seconds; e.g.,
     *                             7*24*60*60 ~ 7 days
     * @param _portal              address of portal contract
     * @param _timeLockSeconds     time lock for changes
     * @param _homeChain           if homechain, then mint
     */
    constructor(
        uint256 _epochDurationSec,
        address _portal,
        uint32 _timeLockSeconds,
        uint256 _homeChain
    ) Equity(_epochDurationSec) {
        janusGuardian = msg.sender;
        portal = _portal;
        timeLockSeconds = _timeLockSeconds;
        if (block.chainid != _homeChain) {
            // nothing minted on this chain
            // amount available is zero
            _totalLeftThroughPortal = TOTALAMOUNT;
            _totalSupply = TOTALAMOUNT;
        } else {
            // total amount is available on homechain
            _mint(msg.sender, TOTALAMOUNT);
        }
    }

    function name() external pure override returns (string memory) {
        return "D8X V1";
    }

    function symbol() external pure override returns (string memory) {
        return "D8X";
    }

    /**
     * Portal in some amount. Only portals can execute
     * From-address is generated by portal contract and
     * encodes chain-id in hex format (left zero padded)
     * @param _amount amount to be transferred
     * @param _from id for emitting chain in address-format
     * @param _wallet token receiver address
     */
    function portalIn(uint256 _amount, address _from, address _wallet) external {
        require(msg.sender == portal, "only portal");
        _beforeTokenTransfer(address(0), _wallet, _amount);
        _totalLeftThroughPortal -= _amount;
        _balances[_wallet] += _amount;
        emit Transfer(_from, _wallet, _amount);
    }

    /**
     * Portal out some amount, only portals can execute
     * To-address is generated by portal contract and
     * encodes chain-id in hex format (left zero padded)
     * @param _amount amount to be transferred
     * @param _wallet origination wallet
     * @param _to id for receiving chain in address-format
     */
    function portalOut(uint256 _amount, address _wallet, address _to) external {
        require(msg.sender == portal, "only portal");
        require(_balances[_wallet] >= _amount, "amt not available");
        _beforeTokenTransfer(_wallet, address(0), _amount);
        _balances[_wallet] -= _amount;
        _totalLeftThroughPortal += _amount;
        emit Transfer(_wallet, _to, _amount);
    }

    function changeOfTheGuard(address _newGuardian) external {
        require(msg.sender == janusGuardian, "only guardian");
        require(timeLockStart == 0, "change queued");
        require(_newGuardian != address(0), "zero addr");
        newGuardian = _newGuardian;
        timeLockStart = uint32(block.timestamp);
        emit ChangeInitiated("guardian", janusGuardian, _newGuardian);
    }

    function replacePortal(address _newPortal) external {
        require(msg.sender == janusGuardian, "only guardian");
        if (_newPortal == address(0)) {
            // emergency halt
            emit ChangeExecuted("portal", portal, newPortal);
            portal = _newPortal;
            return;
        }
        require(timeLockStart == 0, "change queued");
        newPortal = _newPortal;
        emit ChangeInitiated("portal", portal, _newPortal);
    }

    function executeTimeLocked() external {
        require(block.timestamp - timeLockStart >= timeLockSeconds, "timelock");
        if (newGuardian != address(0)) {
            emit ChangeExecuted("guardian", janusGuardian, newGuardian);
            janusGuardian = newGuardian;
            newGuardian = address(0);
        } else {
            emit ChangeExecuted("portal", portal, newPortal);
            portal = newPortal;
            newPortal = address(0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC677Receiver } from "./IERC677Receiver.sol";
import { ID8XCoin } from "./ID8XCoin.sol";
import { ConcreteERC20 } from "./ConcreteERC20.sol";

/**
 * @title Equity contract manages the voting power
 * The voting power system is an adoption of Frankencoin
 */
abstract contract Equity is ID8XCoin, ConcreteERC20 {
    uint64 private totalVotesAnchorTime;
    uint192 private totalVotesAtAnchor;
    uint256 public immutable epochDurationSec; //604_800=7*24*60*60 = 7 days
    uint256 internal _totalLeftThroughPortal; //amount locked that left to other chains

    mapping(address => address) public delegates;
    mapping(address => uint64) private voteAnchor;

    event Delegation(address indexed from, address indexed to);

    /**
     * Constructor
     * @param _epochDurationInSeconds epoch duration in seconds
     */
    constructor(uint256 _epochDurationInSeconds) ConcreteERC20(18) {
        epochDurationSec = _epochDurationInSeconds;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
        if (amount > 0) {
            uint256 roundingLoss = _adjustRecipientVoteAnchor(to, amount);
            _adjustTotalVotes(from, amount, roundingLoss);
        }
    }

    function universalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() external view override returns (uint256) {
        return _onChainTotalSupply();
    }

    function _onChainTotalSupply() internal view returns (uint256) {
        return _totalSupply - _totalLeftThroughPortal;
    }

    /**
     * External: Get the current epoch (block timestamp / epochDuration)
     */
    function epoch() external view returns (uint64) {
        return _epoch();
    }

    /**
     * Get the current epoch (block timestamp / epochDuration)
     */
    function _epoch() internal view returns (uint64) {
        return uint64(block.timestamp / epochDurationSec);
    }

    /**
     * @notice Decrease the total votes anchor when tokens lose their voting power due to being moved
     * @param from  sender
     * @param amount    amount to be sent
     * @param roundingLoss  amount of votes lost due to rounding errors
     */
    function _adjustTotalVotes(address from, uint256 amount, uint256 roundingLoss) internal {
        uint256 lostVotes = from == address(0x0) ? 0 : (_epoch() - voteAnchor[from]) * amount;
        totalVotesAtAnchor = uint192(totalVotes() - roundingLoss - lostVotes);
        totalVotesAnchorTime = _epoch();
    }

    /**
     * @notice the vote anchor of the recipient is moved forward such that the number of calculated
     * votes does not change despite the higher balance.
     * @notice slither warning disabled weak-prng
     * @param to        receiver address
     * @param amount    amount to be received
     * @return the number of votes lost due to rounding errors
     */
    function _adjustRecipientVoteAnchor(address to, uint256 amount) internal returns (uint256) {
        if (to != address(0x0)) {
            uint256 recipientVotes = votes(to); // for example 21 if 7 shares were held for 3 epochs
            uint256 newbalance = balanceOf(to) + amount; // for example 11 if 4 shares are added
            voteAnchor[to] = _epoch() - uint64(recipientVotes / newbalance); // new example anchor is only 21 / 11 = 1 epochs in the past
            // slither-disable-next-line weak-prng
            return recipientVotes % newbalance; // we have lost 21 % 11 = 10 votes
        } else {
            // optimization for burn, vote anchor of null address does not matter
            return 0;
        }
    }

    /**
     * Get the votes of an address (address voting power)
     * @param holder address for which number of votes are returned
     */
    function votes(address holder) public view returns (uint256) {
        return balanceOf(holder) * (_epoch() - voteAnchor[holder]);
    }

    /**
     * @notice Get total votes
     */
    function totalVotes() public view returns (uint256) {
        return totalVotesAtAnchor + _onChainTotalSupply() * (_epoch() - totalVotesAnchorTime);
    }

    /**
     * @notice Get whether the sender plus potential delegates have sufficient voting power
     * to propose an initiative that requires a minimum amount of votes to be proposed
     * @param sender address of sender
     * @param _percentageBps minimum amount of votes required (in basis points)
     * @param helpers addresses of delegates
     */
    function isQualified(
        address sender,
        uint16 _percentageBps,
        address[] calldata helpers
    ) external view returns (bool) {
        uint256 _votes = votes(sender);
        for (uint i = 0; i < helpers.length; i++) {
            address current = helpers[i];
            require(current != sender, "dlgt is sndr");
            require(_canVoteFor(sender, current), "wrong dlgt");
            for (uint j = i + 1; j < helpers.length; j++) {
                require(current != helpers[j], "dlgt added twice");
            }
            _votes += votes(current);
        }
        return _votes * 10000 >= _percentageBps * totalVotes();
    }

    /**
     * @notice Delegate votes to a delegate
     * @param delegate address of delegate
     */
    function delegateVoteTo(address delegate) external override {
        delegates[msg.sender] = delegate;
        if (delegate == msg.sender) {
            delete delegates[msg.sender];
        }
        emit Delegation(msg.sender, delegate);
    }

    /**
     * Check if an address is the delegate of another address
     * @param delegate address to which votes have been delegated to
     * @param owner address that delegated the votes
     */
    function canVoteFor(address delegate, address owner) external view override returns (bool) {
        return _canVoteFor(delegate, owner);
    }

    function _canVoteFor(address delegate, address owner) internal view returns (bool) {
        if (owner == delegate) {
            return true;
        } else if (owner == address(0x0)) {
            return false;
        } else {
            return _canVoteFor(delegate, delegates[owner]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ID8XCoin {
    function votes(address holder) external view returns (uint256);

    function canVoteFor(address delegate, address owner) external view returns (bool);

    function totalVotes() external view returns (uint256);

    function delegateVoteTo(address delegate) external;

    function epochDurationSec() external returns (uint256);

    function isQualified(
        address sender,
        uint16 _percentageBps,
        address[] calldata helpers
    ) external view returns (bool);

    // functions related to multi-chain capability
    function portalIn(uint256 _amount, address _from, address _wallet) external;

    function portalOut(uint256 _amount, address _wallet, address _to) external;

    function changeOfTheGuard(address _newGuardian) external;

    function replacePortal(address _newPortal) external;

    function executeTimeLocked() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC677Receiver {
    function onTokenTransfer(
        address from,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}