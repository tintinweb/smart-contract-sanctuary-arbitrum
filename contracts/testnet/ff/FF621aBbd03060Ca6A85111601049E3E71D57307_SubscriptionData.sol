//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IStaking.sol";
import "./utils/GovernanceOwnable.sol";
import "./utils/MultiOwnable.sol";

contract SubscriptionData is GovernanceOwnable {

    using SafeERC20 for IERC20;
    // name => price
    mapping(string => uint256) public priceData;
    // paramName => paramStatus
    mapping(string => bool) public availableParams;

    string[] public params;

    // address of escrow
    address public escrow;

    // interface for for staking manager
    IStaking public stakingManager;

    //erc20 used for staking
    IERC20 public stakedToken;

    // would be true if discounts needs to be deducted
    bool public discountsEnabled;
    //Data for discounts
    struct Discount {
        uint256 amount;
        uint256 percent;
    }
    Discount[] public discountSlabs;

    //Accepted tokens
    struct Token {
        string symbol;
        uint128 decimals;
        address tokenAddress;
        bool accepted;
        bool isChainLinkFeed;
        address priceFeedAddress;
        uint128 priceFeedPrecision;
    }

    //mapping of accpeted tokens
    mapping(address => Token) public acceptedTokens;
    //mapping of bool for accepted tokens

    mapping(address => bool) public isAcceptedToken;

    // list of accepted tokens
    address[] public tokens;

    uint256 public constant MAX_NUMBER = 30;

    //values prcision, it will be in USD, like USDPRICE * 10 **18
    uint128 public usdPricePrecision;

    event SubscriptionParameter(uint256 indexed price, string param);
    event DeletedParameter(string param);
    event TokenAdded(
        address indexed tokenAddress,
        uint128 indexed decimals,
        address indexed priceFeedAddress,
        string symbol,
        bool isChainLinkFeed,
        uint128 priceFeedPrecision
    );
    event TokenRemoved(address indexed tokenAddress);
    event UpdateEscrow(address indexed _escrow);

    /**
     * @notice initialise the contract
     * @param _params array of name of subscription parameter
     * @param _prices array of prices of subscription parameters
     * @param _escrow escrow address for payments
     * @param slabAmounts_ array of amounts that seperates different slabs of discount
     * @param slabPercents_ array of percent of discount user will get
     * @param _stakedToken address of staked token
     */

    constructor(
        string[] memory _params,
        uint256[] memory _prices,
        address _escrow,
        uint256[] memory slabAmounts_,
        uint256[] memory slabPercents_,
        address _stakedToken
    ) {
        require(
            _params.length == _prices.length,
            "unequal length of array"
        );
        require(
            _escrow != address(0),
            "Invalid escrow address"
        );
        require(
            _stakedToken != address(0),
            "Invalid stake address"
        );
        require(
            slabAmounts_.length == slabPercents_.length,
            "unequal length of array"
        );
        require(_params.length > 0, "Invalid params");
        require(_prices.length > 0, "Invalid prices");
        for (uint256 i = 0; i < _params.length; i = unsafeInc(i)) {
            require(!availableParams[_params[i]], "Parameter already exists");
            string memory name = _params[i];
            uint256 price = _prices[i];
            priceData[name] = price;
            availableParams[name] = true;
            params.push(name);
            emit SubscriptionParameter(price, name);
        }
        stakedToken = IERC20(_stakedToken);
        escrow = _escrow;
        for (uint256 i = 0; i < slabAmounts_.length; i = unsafeInc(i)) {
            require(slabAmounts_[i] > 0, "discount slab amount can not be zero");
            require(slabPercents_[i] > 0, "discount slab percent can not be zero");
            Discount memory _discount = Discount(
                slabAmounts_[i],
                slabPercents_[i]
            );
            discountSlabs.push(_discount);
        }
        usdPricePrecision = 18;
    }

    // unchecked iterator increment for gas optimization
    function unsafeInc(uint x) private pure returns (uint) {
        unchecked { return x + 1;}
    }

    function isIncremental(uint256[] memory _nnn) public pure returns (bool) {
        bool incremental = true;
        for (uint256 i = 0; i < _nnn.length - 1; i++) {
            if (_nnn[i] > _nnn[i+1]) {
                incremental = false;
                break;
            }
        }
        return incremental;
    }

    /**
     * @notice update parameters
     * @param _params names of all the parameters to add or update
     * @param _prices list of prices of parameters index matched with _params
     */
    function updateParams(string[] memory _params, uint256[] memory _prices)
        external
        onlyManager
    {
        require(_params.length > 0, "No parameters provided");
        require(_prices.length > 0, "No prices provided");
        require(
            _params.length == _prices.length,
            "Subscription Data: unequal length of array"
        );
        for (uint256 i = 0; i < _params.length; i = unsafeInc(i)) {
            string memory name = _params[i];
            require(_prices[i] > 0, "Price of parameter can not be zero");
            uint256 price = _prices[i];
            priceData[name] = price;
            if (!availableParams[name]) {
                availableParams[name] = true;
                params.push(name);
            }
            emit SubscriptionParameter(price, name);
        }
    }

    /**
     * @notice delete parameters
     * @param _params names of all the parameters to be deleted
     */

    function deleteParams(string[] memory _params) external onlyManager {
        require(_params.length != 0, "empty array");
        require(_params.length <= MAX_NUMBER, "too much parameters");

        for (uint256 i = 0; i < _params.length; i = unsafeInc(i)) {
            string memory name = _params[i];
            priceData[name] = 0;
            if (availableParams[name]) {
                availableParams[name] = false;
                for (uint256 j = 0; j < params.length; j = unsafeInc(j)) {
                    if (
                        keccak256(abi.encodePacked(params[j])) ==
                        keccak256(abi.encodePacked(name))
                    ) {
                        params[j] = params[params.length - 1];
                        params.pop();
                        break;
                    }
                }
                emit DeletedParameter(name);
            }
        }
    }

    /**
     * @notice update escrow address
     * @param _escrow address for new escrow
     */

    function updateEscrow(address _escrow) external onlyManager {
        require(escrow != address(0), "Subscription Data: Escrow address can not be zero address");
        escrow = _escrow;
        emit UpdateEscrow(_escrow);
    }

    /**
     * @notice returns discount slabs array
     */

    function slabs() external view returns(uint256[] memory) {
        uint256[] memory _slabs  = new uint256[](discountSlabs.length);
        for(uint256 i = 0 ; i< discountSlabs.length; i = unsafeInc(i)){
            _slabs[i] = discountSlabs[i].amount;
        }
        return _slabs;
    }

    /**
     * @notice returns discount percents matched with slabs array
     */

    function discountPercents() external view returns(uint256[] memory) {
        uint256[] memory _percent  = new uint256[](discountSlabs.length);
        for(uint256 i = 0 ; i< discountSlabs.length; i = unsafeInc(i)){
            _percent[i] = discountSlabs[i].percent;
        }
        return _percent;
    }

    /**
     * @notice delete previously set discount slabs and input new discount slabs
     * @param slabAmounts_ array of amounts that seperates different slabs of discount
     * @param slabPercents_ array of percent of discount user will get
     */

    function updateDiscountSlabs(
        uint256[] memory slabAmounts_,
        uint256[] memory slabPercents_
    ) public onlyGovernanceAddress {
        require(
            slabAmounts_.length == slabPercents_.length,
            "discount slabs array and discount amount array have different size"
        );
        require(
            slabPercents_.length <= MAX_NUMBER,
            "discount slabs array can not be more than 10"
        );
        delete discountSlabs;
        require(isIncremental(slabAmounts_), "discount slabs array is not incremental");
        require(isIncremental(slabPercents_), "discount percent array is not incremental");
        for (uint256 i = 0; i < slabAmounts_.length; i = unsafeInc(i)) {
            require(slabAmounts_[i] > 0, "discount slab amount can not be zero");
            require(slabPercents_[i] > 0, "discount slab percent can not be zero");
            Discount memory _discount = Discount(
                slabAmounts_[i],
                slabPercents_[i]
            );
            discountSlabs.push(_discount);
        }
    }

    /**
     * @notice enable discounts for users.
     * @param s address of staking manager
     */
    function enableDiscounts(address s) external onlyManager {
        require(
            s != address(0),
            "staking manager address can not be zero address"
        );
        discountsEnabled = true;
        stakingManager = IStaking(s);
    }

    /**
     * @notice add new token for payments
     * @param _symbols token symbols
     * @param _tokens token address
     * @param _decimals token decimals
     * @param isChainLinkFeed_ if price feed chain link feed
     * @param priceFeedAddress_ address of price feed
     * @param priceFeedPrecision_ precision of price feed
     */
    function addNewToken(
        string memory _symbols,
        address _tokens,
        uint128 _decimals,
        bool isChainLinkFeed_,
        address priceFeedAddress_,
        uint128 priceFeedPrecision_
    ) external onlyGovernanceAddress {
        
        require(!acceptedTokens[_tokens].accepted, "token already added");
        require(_tokens != address(0), "token address can not be zero address");
        require(_decimals > 0, "token decimal can not be zero");
        bytes memory tempEmptyStringTest = bytes(_symbols);
        require(tempEmptyStringTest.length != 0, "token symbol can not be empty");
        Token memory token = Token(
            _symbols,
            _decimals,
            _tokens,
            true,
            isChainLinkFeed_,
            priceFeedAddress_,
            priceFeedPrecision_
        );
        acceptedTokens[_tokens] = token;
        tokens.push(_tokens);
        isAcceptedToken[_tokens] = true;
        emit TokenAdded(
            _tokens,
            _decimals,
            priceFeedAddress_,
            _symbols,
            isChainLinkFeed_,
            priceFeedPrecision_
        );
    }

    /**
     * @notice remove tokens for payment
     * @param t token address
     */
    function removeTokens(address[] memory t) external onlyGovernanceAddress {
        require(t.length > 0, "array length cannot be zero");
        require(t.length <= MAX_NUMBER, "too many tokens to remove");
        for (uint256 i = 0; i < t.length; i = unsafeInc(i)) {
            require(t[i] != address(0), "token address can not be zero address");
            if (acceptedTokens[t[i]].accepted) {
                require(tokens.length > 1, "Cannot remove all payment tokens");
                for (uint256 j = 0; j < tokens.length; j = unsafeInc(j)) {
                    if (tokens[j] == t[i]) {
                        tokens[j] = tokens[tokens.length - 1];
                        tokens.pop();
                        acceptedTokens[t[i]].accepted = false;
                        emit TokenRemoved(t[i]);
                    }
                }
                isAcceptedToken[t[i]] = false;

            }
        }
    }
    /**
     * @notice disable discounts for users
     */
    function disableDiscounts() external onlyManager {
        discountsEnabled = false;
    }
    /**
     * @notice change precision of USD value
     * @param p new precision value
     */
    function changeUsdPrecision(uint128 p) external onlyManager {
        require(p != 0, "USD to precision can not be zero");
        usdPricePrecision = p;
    }

    /**
     * @notice update staked token address
     * @param s new staked token address
     */
    function updateStakedToken(address s) external onlyGovernanceAddress {
        require(
            s != address(0),
            "staked token address can not be zero address"
        );
        stakedToken = IERC20(s);
    }

    /**
     * @notice trim or add number for certain precision as required
     * @param a amount/number that needs to be modded
     * @param p older precision
     * @param n new desired precision
     * @return price of underlying token in usd
     */
    function _toPrecision(
        uint256 a,
        uint128 p,
        uint128 n
    ) internal pure returns (uint256) {
        int128 decimalFactor = int128(p) - int128(n);
        if (decimalFactor > 0) {
            a = a / (10**uint128(decimalFactor));
        } else if (decimalFactor < 0) {
            a = a * (10**uint128(-1 * decimalFactor));
        }
        return a;
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IStaking {
    function getEpochId(uint256 timestamp) external view returns (uint256); // get epoch id

    function getEpochUserBalance(
        address user,
        address token,
        uint128 epoch
    ) external view returns (uint256);

    function getEpochPoolSize(address token, uint128 epoch)
        external
        view
        returns (uint256);

    function depositFor(
        address tokenAddress,
        address userAddress,
        uint256 amount
    ) external;

    function epoch1Start() external view returns (uint256);

    function epochDuration() external view returns (uint256);

    function balanceOf(address user, address token)
        external
        view
        returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./MultiOwnable.sol";

contract GovernanceOwnable is MultiOwnable {
    address public governanceAddress;

    modifier onlyGovernanceAddress() {
        require(
            msg.sender == governanceAddress,
            "Caller is not the governance contract"
        );
        _;
    }

    /**
     * @dev GovernanceOwnable constructor sets the governance address
     * @param g address of governance contract
     */
    function setGovernanceAddress(address g) public onlyOwner {
        require(g != address(0), "Address cannot be zero address");
        governanceAddress = g;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract MultiOwnable {
    address public owner; // address used to set owners
    address[] public managers;
    mapping(address => bool) public managerByAddress;

    event SetManagers(address[] managers);

    event RemoveManagers(address[] managers);

    event ChangeOwner(address indexed owner);

    modifier onlyManager() {
        require(
            managerByAddress[msg.sender] == true || msg.sender == owner,
            "Only manager and owner can call this function"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    /**
     * @dev MultiOwnable constructor sets the owner
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Function to set managers
     * @param m list of addresses that are to be added as managers
     */
    function setManagers(address[] memory m) public onlyOwner {
        require(m.length > 0, "At least one manager must be set");
        _setManagers(m);
    }

    /**
     * @dev Function to remove managers
     * @param m list of addresses that are to be removed from managers
     */
    function removeManagers(address[] memory m) public onlyOwner {
        _removeManagers(m);
    }

    /**
     * @dev Function to set managers
     * @param m list of addresses that are to be added  as manager
     */
    function _setManagers(address[] memory m) internal {
        for (uint256 j = 0; j < m.length; j++) {
            require(m[j] != address(0), "Address cannot be zero address");
            if (!managerByAddress[m[j]]) {
                managerByAddress[m[j]] = true;
                managers.push(m[j]);
            }
        }
        emit SetManagers(m);
    }

    /**
     * @dev internal helper function to remove managers
     * @param m list of addresses that are to be removed from managers
     */
    function _removeManagers(address[] memory m) internal {
        require(m.length > 0, "At least one manager must be removed");
        for (uint256 j = 0; j < m.length; j++) {
            if (managerByAddress[m[j]]) {
                for (uint256 k = 0; k < managers.length; k++) {
                    if (managers[k] == m[j]) {
                        managers[k] = managers[managers.length - 1];
                        managers.pop();
                    }
                }
                managerByAddress[m[j]] = false;
            }
        }

        emit RemoveManagers(m);
    }

    /**
     * @dev change owner of the contract
     * @param o address of new owner
     */
    function changeOwner(address o) external onlyOwner {
        require(o != address(0), "New owner cannot be zero address");
        owner = o;
        emit ChangeOwner(o);
    }

    /**
     * @dev get list of all managers
     * @return list of all managers
     */
    function getManagers() external view returns (address[] memory) {
        return managers;
    }

    /**
     * @dev get list of all managers
     * @return list of all managers
     */

    function isManager(address addr) public view returns (bool) {
        if(managerByAddress[addr] == true || addr == owner) {
            return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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