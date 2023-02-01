/**
 *Submitted for verification at Arbiscan on 2023-01-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// 
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)
/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// 
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// 
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// 
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// 
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)
/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// 
interface ISTLRSettingsV1 {
    function STLR() external view returns (address);
    function USDC() external view returns (address);

    function dao() external view returns (address);
    function manager() external view returns (address);
    function treasury() external view returns (address);
    function helper() external view returns (address);
    function presale() external view returns (address);
    function oracle() external view returns (address);
    function paused() external view returns (bool);

    function isOperator(address) external view returns (bool);
    function isExemptFromFee(address) external view returns (bool);
    function isMarketPair(address) external view returns (bool);

    function rewardFeePercentage() external view returns (uint);
    function maxRewardFee() external view returns (uint);
    function claimFee() external view returns (uint);
    function claimCooldown() external view returns (uint);
    function interestRate() external view returns (uint);
    function maxRotCount() external view returns (uint);
    function rotDeduction() external view returns (uint);
    function farmingClaimCooldown() external view returns (uint);
    function farmingWithdrawDelay() external view returns (uint);

    function transferLimit() external view returns (uint);
    function walletMax() external view returns (uint);
    function feeOnTransfer() external view returns (bool);

    function REWARD_FREQUENCY() external view returns (uint);
    function BASE_DENOMINATOR() external view returns (uint);
    function MAX_SETTLEMENTS() external view returns (uint);
    function LOCKED_PERCENT() external view returns (uint);
    function SELL_FEE() external view returns (uint);
}

// 
contract SettleverseDaoV1 is Ownable {
    uint public counter;
    ISTLRSettingsV1 public settings;
    IERC20Metadata public immutable stlr;
    IERC20Metadata public immutable usdc;

    struct SettlementType {
        bool active;
        uint multiplier;
        uint stlr;
        uint usdc;
    }

    struct Settlement {
        bool active;
        uint settlementType;
        address account;
        uint boost;
        uint paidOut;
        uint lastClaimed;
        uint skin;
        uint createdAt;
        uint id;
    }

    struct Account {
        bool exists;
        uint faction;
        uint score;
        uint boost;
        uint count;
        uint paidOut;
        uint claimedAt;
    }

    mapping(address => Account) public accounts;
    mapping(uint => SettlementType) public settlementTypes;
    mapping(uint => Settlement) public settlements;
    mapping(address => uint[]) public userSettlements;

    mapping(uint => bool) private factions;
    mapping(uint => address[]) public factionUsers;

    uint public settCount;

    constructor(
        address _settings
    ) {
        settings = ISTLRSettingsV1(_settings);
        stlr = IERC20Metadata(settings.STLR());
        usdc = IERC20Metadata(settings.USDC());

        settlementTypes[0] = SettlementType(true, 35, 50, 50); // Hamlet
        settlementTypes[1] = SettlementType(true, 100, 125, 125); // Village
        settlementTypes[2] = SettlementType(true, 325, 350, 350); // Town
        settlementTypes[3] = SettlementType(true, 1200, 1000, 1000); // City
        settlementTypes[4] = SettlementType(true, 7500, 4500, 4500); // Metropolis
        settCount = 5;

        factions[0] = true; // Humans
        factions[1] = true; // Dwarves
        factions[2] = true; // Elves
    }

    /** VIEW FUNCTIONS */

    function treasury(
    ) 
        external 
        view 
        returns (address) 
    {
        return settings.treasury();
    }

    function getTotalSettlements(
    ) 
        external 
        view 
        returns (uint) 
    {
        return counter;
    }

    function getFactionCount(
        uint _faction
    ) 
        external 
        view 
        returns (uint) 
    {
        return factionUsers[_faction].length;
    }

    function getSettlements(
        address _account
    ) 
        public 
        view 
        returns (Settlement[] memory, uint) 
    {
        uint count = accounts[_account].count;
        Settlement[] memory _settlements = new Settlement[](count);
        for (uint256 index = 0; index < count; index++) {
            Settlement memory sett = settlements[userSettlements[_account][index]];
            _settlements[index] = sett;
        }

        return (_settlements, count);
    }

    function rewardsOfId(
        uint id
    ) 
        public 
        view 
        returns (uint) 
    {
        uint frequency = settings.REWARD_FREQUENCY();
        uint denominator = settings.BASE_DENOMINATOR();
        uint interval = uint(block.timestamp / frequency);
        Settlement memory sett = settlements[id];
        if (!sett.active) return 0;
        SettlementType memory settlementType = settlementTypes[sett.settlementType];
        if (!settlementType.active) return 0;
        uint period = interval - sett.lastClaimed;
        if (period == 0) return 0;
        uint rate = ((settlementType.multiplier * 10 ** 18 / (86400 * denominator / frequency)) * settings.interestRate() * (denominator + sett.boost)) / (denominator * 100);
        uint rewards = period * rate;
        if (sett.paidOut > settlementType.stlr) {
            uint rot = uint(sett.paidOut / settlementType.stlr);
            if (rot > settings.maxRotCount()) rot = settings.maxRotCount();
            rewards = rewards * (denominator - (rot * settings.rotDeduction())) / denominator;
        }

        uint boost = accounts[sett.account].boost;
        if (boost > 0) {
            rewards = rewards * (denominator + boost) / denominator;
        }

        return rewards;
    }

    function earned(
        address _account
    ) 
        external 
        view 
        returns (uint rewards) 
    {
        (Settlement[] memory _settlements, uint count) = getSettlements(_account);

        for (uint256 index = 0; index < count; index++) {
            uint id = _settlements[index].id;
            rewards += rewardsOfId(id);
        }
    }

    /** INTERNAL FUNCTIONS */

    function _remove(
        address _account, 
        uint id
    ) 
        internal 
    {
        uint index;
        for (uint i = 0; i < userSettlements[_account].length; i++) {
            if (settlements[userSettlements[_account][i]].id == id) {
                index = i;
                break;
            }
        }

        userSettlements[_account][index] = userSettlements[_account][userSettlements[_account].length - 1];
        userSettlements[_account].pop();
    }

    function _create(
        address _account, 
        uint _settlementType, 
        uint count
    ) 
        internal 
        whenNotPaused 
    {
        require(_settlementType >= 0 && _settlementType < settCount, 'Invalid settlement type');
        require(settlementTypes[_settlementType].active, 'Settlement type is inactive');
        require(accounts[_account].exists, 'Account does not exist yet');
        require(userSettlements[_account].length + count <= settings.MAX_SETTLEMENTS(), 'Max settlements per account reached');

        Account memory account = accounts[_account];
        SettlementType memory settlementType = settlementTypes[_settlementType];

        uint day = uint(block.timestamp / settings.REWARD_FREQUENCY());

        for (uint index = 0; index < count; index++) {
            uint current = counter + index;
            settlements[current] = Settlement(true, _settlementType, _account, 0, 0, day, 0, block.timestamp, current);
            account.score += settlementType.multiplier;
            userSettlements[_account].push(current);
        }

        counter += count;
        account.count += count;
        if (account.claimedAt == 0) account.claimedAt = block.timestamp;
        accounts[_account] = account;
        emit Settle(_account, _settlementType, count);
    }

    function _claim(
        address _account, 
        bool _compound
    ) 
        internal 
        returns (uint256 rewards) 
    {
        require(_account != address(0), 'Null address is not allowed');
        require(accounts[_account].exists, 'Account does not exist yet');
        require(block.timestamp - accounts[_account].claimedAt > settings.claimCooldown(), 'Claim still on cooldown');
    
        Account memory account = accounts[_account];
        (Settlement[] memory _settlements, uint count) = getSettlements(_account);

        uint interval = uint(block.timestamp / settings.REWARD_FREQUENCY());
        for (uint256 index = 0; index < count; index++) {
            Settlement memory sett = _settlements[index];
            uint reward = rewardsOfId(sett.id);
            rewards += reward;

            sett.paidOut += reward;
            sett.lastClaimed = interval;
            settlements[sett.id] = sett;
        }

        if (rewards > 0) {
            if (!_compound) {
                uint fee = rewards * settings.claimFee() / 10000;
                rewards = rewards - fee;
                stlr.transfer(settings.treasury(), fee);
                stlr.transfer(_account, rewards);
            }

            account.paidOut += rewards;
            account.claimedAt = block.timestamp;

            accounts[_account] = account;
        }
    }

    /** EXTERNAL FUNCTIONS */

    function declare(
        address account,
        uint _faction
    ) 
        external 
        onlyManager
    {
        require(factions[_faction], 'Faction does not exist');
        require(!accounts[account].exists, 'Account already exists');
        accounts[account] = Account(true, _faction, 0, 0, 0, 0, 0);
        factionUsers[_faction].push(account);
    }

    function settle(
        address account,
        uint _settlementType, 
        uint count
    ) 
        external 
        onlyManager
    {
        _create(account, _settlementType, count);
    }

    function claim(
        address account,
        bool _compound
    ) 
        external 
        onlyManager
        returns (uint rewards)
    {
        rewards = _claim(account, _compound);
    }

    function compound(
        address account,
        uint _settlementType,
        uint count,
        uint fee,
        uint refund
    )
        external
        onlyManager
    {
        _create(account, _settlementType, count);
        if (fee > 0) stlr.transfer(settings.treasury(), fee);
        if (refund > 0) stlr.transfer(account, refund);
    }

    /** RESTRICTED FUNCTIONS */

    function setSettlementSkin(
        address _account,
        uint id,
        uint skin
    )
        external
        onlyOperator(msg.sender)
    {
        require(accounts[_account].exists, 'Account does not exist');
        require(settlements[id].account == _account, 'Accounts do not match');
        Settlement memory settlement = settlements[id];
        settlement.skin = skin;
        settlements[id] = settlement;
    }

    function setSettlementBoost(
        address _account, 
        uint id, 
        uint boost
    ) 
        external 
        onlyOperator(msg.sender) 
    {
        require(id < counter, 'Invalid id');
        require(settlements[id].account == _account, 'Accounts do not match');
        Settlement memory settlement = settlements[id];
        settlement.boost = boost;
        settlements[id] = settlement;
    }

    function setAccountBoost(
        address _account, 
        uint boost
    ) 
        external 
        onlyOperator(msg.sender) 
    {
        require(accounts[_account].exists, 'Account does not exist');
        Account memory account = accounts[_account];
        account.boost = boost;
        accounts[_account] = account;
    }

    function transferSettlement(
        uint id, 
        address _sender, 
        address _recipient
    ) 
        external 
        onlyOperator(msg.sender) 
    {
        require(accounts[_sender].exists && accounts[_recipient].exists, 'Accounts do not exist');
        require(_sender != _recipient, 'Invalid recipient');
        require(id < counter, 'Invalid id');
        require(settlements[id].account == _sender, 'Accounts do not match');
        require(userSettlements[_recipient].length + 1 <= settings.MAX_SETTLEMENTS(), 'Max settlements per account reached');
        Account memory sender = accounts[_sender];
        Account memory recipient = accounts[_recipient];
        Settlement memory settlement = settlements[id];
        uint multiplier = settlementTypes[settlement.settlementType].multiplier;
        settlement.account = _recipient;
        sender.count -= 1;
        sender.score -= multiplier;
        recipient.count += 1;
        recipient.score += multiplier;
        userSettlements[_recipient].push(id);
        _remove(_sender, id);
        settlements[id] = settlement;
        accounts[_sender] = sender;
        accounts[_recipient] = recipient;
        emit Transfer(_sender, _recipient, id);
    }

    function mint(
        address _account, 
        uint _settlementType, 
        uint count
    ) 
        external 
        onlyOperator(msg.sender) 
    {
        _create(_account, _settlementType, count);
    }

    /** OWNER FUNCTIONS */

    function setSettlementType(
        uint index, 
        bool _active, 
        uint _multiplier, 
        uint _stlr, 
        uint _usdc
    ) 
        external 
        onlyOwner 
    {
        require(index >= 0 && index <= settCount, 'Invalid settlement type');
        settlementTypes[index] = SettlementType(_active, _multiplier, _stlr, _usdc);
        if (index == settCount) {
            settCount = index + 1;
        }
    }

    function setSettings(
        address _settings
    ) 
        external 
        onlyOwner 
    {
        require(_settings != address(0), 'Settings is null address');
        settings = ISTLRSettingsV1(_settings);
    }

    function transfer(
        address token, 
        uint amount
    ) 
        external 
        onlyOwner 
    {
        require(settings.treasury() != address(0), 'Treasury is null address');
        IERC20(token).transfer(settings.treasury(), amount);
    }

    /** MODIFIERS */

    modifier whenNotPaused(
    ) {
        require(!settings.paused(), 'Contract is paused');

        _;
    }

    modifier onlyOperator(
        address operator
    ) {
        require(settings.isOperator(operator), 'NOT_OPERATOR');

        _;
    }

    modifier onlyManager(
    ) {
        require(msg.sender == settings.manager(), 'NOT_MANAGER');

        _;
    }

    /** EVENTS */

    event Settle(address account, uint settlementType, uint count);
    event Transfer(address sender, address recipient, uint id);
}