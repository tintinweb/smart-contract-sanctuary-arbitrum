//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;
import "./interfaces/ISubscriptionData.sol";
import "./interfaces/IStaking.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./utils/ERC2771Context.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IDiaOracle.sol";

contract SubscriptionDePay is ReentrancyGuard, ERC2771Context {

    using SafeERC20 for IERC20;
    address public treasury;
    address public company;
    address public pendingCompany;

    struct UserData {
        uint256 deposit;
        uint256 balance;
    }
    // struct UserSub {
    //     string[] params;
    //     uint256[] values;
    //     bool subscribed;
    // }

    // mapping(address => UserSub) public userSub;    

    // (user => (token => UserData))
    mapping(address => mapping(address => UserData)) public userData;

    uint256 public constant TIMESTAP_GAP = 21600;
    
    // to temporarily pause the deposit and withdrawal function

    bool public pauseDeposit;
    bool public pauseWithdrawal;

    //For improved precision
    uint256 constant PRECISION = 10**25;
    uint256 constant PERCENT = 100 * PRECISION;
    
    mapping(address => uint256) public totalDeposit; //(token => amount)
    mapping(address => uint256) public totalCharges; //(token => amount)
    mapping(address => uint256) public totalWithdraws; //(token => amount)
    mapping(address => uint256) public companyRevenue; //(token => amount)

    event UserCharged(address indexed user, address indexed token, uint256 fee);
    event UserDeposit(address indexed user, address indexed token, uint256 deposit);
    event UserWithdraw(address indexed user, address indexed token, uint256 amount);
    event CompanyWithdraw(address indexed token, uint256 amount);
    event TreasurySet(address indexed _treasury);
    event CompanySet(address indexed _company);
    event CompanyPendingSet(address indexed _company);
    event DataContractUpdated(address indexed _dataContract);
    event DepositStatusChanged(bool _status);
    event WithdrawalStatusChanged(bool _status);
    // event UserSubscribed(address indexed user, string[] params, uint256[] values);
    constructor(address _treasury, address _company, address _data, address _trustedForwarder) ERC2771Context(_trustedForwarder, _data) {
        require(
            _treasury != address(0),
            "SpheronSubscriptionPayments: Invalid address for treasury"
        );
        require(
            _company != address(0),
            "SpheronSubscriptionPayments: Invalid address for company"
        );
        require(
            _data != address(0),
            "SpheronSubscriptionPayments: Invalid address of subscription data contract"
        );
        subscriptionData = ISubscriptionData(_data);
        treasury = _treasury;
        company = _company;
        
    }
    // ROLES
    // Manager - limited to only contract data and does not have access to any funds. responsible for changing deposit and withdrawal status, adding tokens, updating params and other contract data.
    // Treasury - It would be a Mulitisg acocunt, mostly handled by the company or a governance or DAO
    // Company - It would be out account with mulitisig
    // Owner - owner of the contract, responsible for setting the treasury and company address and other core functions that involves users funds.
    /**
     * @notice only manager modifier
     *
     */
    modifier onlyOwnerOrManager() {
        bool hasAccess = subscriptionData.isManager(_msgSender());
        require(
            hasAccess,
            "Only manager and owner can call this function"
        );
        _;
    }
    /**
     * @notice only company modifier
     *
     */
    modifier onlyCompany() {
        require(
            _msgSender() == company || subscriptionData.isManager(_msgSender()),
            "Only company and managers can call this function"
        );
        _;
    }
    /**
     * @notice unchecked iterator increment for gas optimization
        * @param x uint256
     */
    function unsafeInc(uint x) private pure returns (uint) {
        unchecked { return x + 1;}
    }
    /**
     * @notice set address of the treasury
     * @param _treasury treasury address
     */
    function setTreasury(address _treasury) external onlyOwnerOrManager {
        require(
            _treasury != address(0),
            "SpheronSubscriptionPayments: Invalid address for treasury"
        );
        treasury = _treasury;
        emit TreasurySet(treasury);
    }
    /**
     * @notice set address of the company
     * @param _company company address
     */
    function setCompany(address _company) external onlyCompany {
        require(
            _company != address(0),
            "SpheronSubscriptionPayments: Invalid address for company"
        );
        pendingCompany = _company;
        emit CompanyPendingSet(pendingCompany);
    }

    /**
     * @notice approve pending company address
     */

    function approveSetCompany(address _pendingCompany) external onlyOwnerOrManager {
        require(
            pendingCompany != address(0),
            "SpheronSubscriptionPayments: Invalid address for company"
        );
        require(
            _pendingCompany != address(0) && _pendingCompany == pendingCompany,
            "");
        company = pendingCompany;
        pendingCompany = address(0);
        emit CompanySet(company);
    }
    /**
     * @notice deposit one of the accepted erc20 to the treasury
     * @param _token address of erc20 token
     * @param _amount amount of tokens to deposit to treasury
     */

    function userDeposit(address _token, uint _amount) external nonReentrant {
        require(!pauseDeposit, "Deposit is paused");
        require(
            subscriptionData.isAcceptedToken(_token),
            "SpheronSubscriptionPayments: Token not accepted"
        );
        require(
            _amount > 0,
            "SpheronSubscriptionPayments: Deposit must be greater than zero"
        );
        IERC20 erc20 = IERC20(_token);
        require(
            erc20.allowance(_msgSender(), address(this)) >= _amount,
            "SpheronPayments: Insufficient allowance"
        );
        erc20.safeTransferFrom(_msgSender(), treasury, _amount);
        totalDeposit[_token] += _amount;
        userData[_msgSender()][_token].deposit += _amount;
        userData[_msgSender()][_token].balance += _amount;
        emit UserDeposit(_msgSender(), _token, _amount); 
    }
    /**
     * @notice user token withdrawal one of the accepted erc20 to the treasury
     * @param _token address of erc20 token
     * @param _amount amount of tokens to be withdrawn from treasury
     */
    function userWithdraw(address _token, uint _amount) external nonReentrant {
        require(!pauseWithdrawal, "Withdrawal is paused");
        require(
            _amount > 0,
            "SpheronSubscriptionPayments: Amount must be greater than zero"
        );
        require(
            _amount <= userData[_msgSender()][_token].balance,
            "SpheronSubscriptionPayments: Amount must be less than or equal to user balance"
        );
        IERC20 erc20 = IERC20(_token);
        require(
            erc20.allowance(treasury, address(this)) >= _amount,
            "SpheronPayments: Insufficient allowance"
        );
        userData[_msgSender()][_token].balance -= _amount;
        totalWithdraws[_token] += _amount;
        erc20.safeTransferFrom(treasury, _msgSender(), _amount);
        emit UserWithdraw(_msgSender(), _token, _amount); 
    }
    /**
     * @notice company token withdrawal of one of the accepted erc20 from the treasury
     * @param _token address of erc20 token
     * @param _amount amount of tokens to be withdrawn from treasury
     */
    function companyWithdraw(address _token, uint _amount) public nonReentrant {
        require(
            _msgSender() == company,
            "Only callable by company"
        );
        require(
            _amount > 0,
            "SpheronPayments: Amount must be greater than zero"
        );
        require(
            _amount <= companyRevenue[_token],
            "SpheronSubscriptionPayments: Balance must be less than or equal to company balance"
        );
        IERC20 erc20 = IERC20(_token);
        require(
            erc20.allowance(treasury, address(this)) >= _amount,
            "SpheronPayments: Insufficient allowance"
        );
        companyRevenue[_token] -= _amount;
        erc20.safeTransferFrom(treasury, company, _amount);
        emit UserWithdraw(_msgSender(), _token, _amount); 
    }

    /**
     * @notice charge user for one time charges
     * @param _user user address
     * @param _parameters list for subscription payment
     * @param _values value list for subscription payment
     * @param _token address of token contract
     */
    function chargeUser(
        address _user,
        string[] memory _parameters,
        uint256[] memory _values,
        address _token
    ) external onlyOwnerOrManager {
        require(_user != address(0), "SpheronSubscriptionPayments: Invalid user address");
        require(_token != address(0), "SpheronSubscriptionPayments: Invalid token address");
        require(
            _parameters.length > 0, "SpheronSubscriptionPayments: No params"
        );
        require(
            _values.length > 0, "SpheronSubscriptionPayments: No values"
        );
        require(
            _parameters.length == _values.length,
            "SpheronSubscriptionPayments: unequal length of array"
        );
        require(
            subscriptionData.isAcceptedToken(_token),
            "SpheronSubscriptionPayments: Token not accepted"
        );

        uint256 fee = 0;

        for (uint256 i = 0; i < _parameters.length; i = unsafeInc(i)) {
            fee += _values[i] * subscriptionData.priceData(_parameters[i]);
        }
        uint256 discountedFee = fee - _calculateDiscount(_user, fee);
        uint256 underlying = _calculatePriceInToken(discountedFee, _token);
        require(
            underlying <= userData[_user][_token].balance,
            "SpheronSubscriptionPayments: Balance must be less than or equal to amount charged"
        );
        userData[_user][_token].balance -= underlying;
        totalCharges[_token] += underlying;
        companyRevenue[_token] += underlying;
        emit UserCharged(_user, _token, underlying);
    }

    /**
     * @notice set params for recurring sub by user
     * @param _params parameters for subscription
     * @param _values list for subscription
     */
    // function setUserSub(
    //     string[] memory _params,
    //     uint256[] memory _values) external {
    //     require(_params.length > 0, "SpheronSubscriptionPayments: No params");
    //     require(
    //         _params.length == _values.length,
    //         "SpheronSubscriptionPayments: unequal length of array"
    //     );
    //     for(uint256 i = 0; i < _values.length; i = unsafeInc(i)) {
    //         require(_values[i] > 0, "SpheronSubscriptionPayments: Invalid value");
    //     }
    //     userSub[_msgSender()].params = _params;
    //     userSub[_msgSender()].values = _values;
    //     userSub[_msgSender()].subscribed = true;
    //     emit UserSubscribed(_msgSender(), _params, _values);
    // }

    /**
     * @notice charge user for subscription
     * @param _user user address
     * @param _token address of token contract
     */
    // function chargeUserSub(
    //     address _user,
    //     address _token
    // ) external onlyOwnerOrManager {

    //     require(
    //         userSub[_user].subscribed, 
    //         "SpheronSubscriptionPayments: User not subscribed"
    //     );
        
    //     require(
    //         subscriptionData.isAcceptedToken(_token),
    //         "SpheronSubscriptionPayments: Token not accepted"
    //     );
    //     string[] memory p = userSub[_user].params;
    //     uint256[] memory v = userSub[_user].values;
    //     uint256 fee = 0;


    //     for (uint256 i = 0; i < p.length; i = unsafeInc(i)) {
    //         fee += v[i] * subscriptionData.priceData(p[i]);
    //     }
    //     uint256 discountedFee = fee - _calculateDiscount(_user, fee);
    //     uint256 underlying = _calculatePriceInToken(discountedFee, _token);
    //     require(
    //         underlying <= userData[_user][_token].balance,
    //         "SpheronSubscriptionPayments: Balance must be less than or equal to amount charged"
    //     );
    //     userData[_user][_token].balance -= underlying;
    //     totalCharges[_token] += underlying;
    //     companyRevenue[_token] += underlying;
    //     emit UserCharged(_user, _token, underlying);
    // }

    /**
     * @notice change status for user deposit. On or off
     */
    function changeDepositStatus() public onlyOwnerOrManager {
        pauseDeposit = !pauseDeposit;
        emit DepositStatusChanged(pauseDeposit);
    }

    /**
     * @notice change status for user deposit. On or off
     */
    function changeWithdrawalStatus() public onlyOwnerOrManager {
        pauseWithdrawal = !pauseWithdrawal;
        emit WithdrawalStatusChanged(pauseWithdrawal);
    }
    /**
     * @notice update subscriptionDataContract
     * @param d data contract address
     */
    function updateDataContract(address d) external onlyOwnerOrManager {
        require(
            d != address(0),
            "SpheronSubscriptionPayments: data contract address can not be zero address"
        );
        subscriptionData = ISubscriptionData(d);
        emit DataContractUpdated(d);
    }

    /**
     * @dev calculate discount that user gets for staking
     * @param u address of user that needs to be charged
     * @param a amount the user will pay without discount
     */
    function _calculateDiscount(address u, uint256 a)
        internal
        view
        returns (uint256)
    {
        if (!subscriptionData.discountsEnabled()) return 0;
        IStaking stakingManager = IStaking(subscriptionData.stakingManager());
        uint256 stake = stakingManager.balanceOf(
            u,
            address(subscriptionData.stakedToken())
        );
        uint256[] memory discountSlabs = subscriptionData.slabs();
        uint256[] memory discountPercents = subscriptionData.discountPercents();
        uint256 length = discountSlabs.length;
        uint256 percent = 0;
        for (uint256 i = 0; i < length; i = unsafeInc(i)) {
            if (stake >= discountSlabs[i]) {
                percent = discountPercents[i];
            } else {
                break;
            }
        }
        return (a * percent * PRECISION) / PERCENT;
    }
    /**
     * @notice get price of underlying token
     * @param t underlying token address
     * @return underlyingPrice of underlying token in usd
     * @return timestamp of underlying token in usd
     */
    function getUnderlyingPrice(address t) public view returns (uint256 underlyingPrice, uint256 timestamp) {
        (string memory symbol,
        uint128 decimals,
        ,
        bool accepted,
        bool isChainLinkFeed,
        address priceFeedAddress,
        uint128 priceFeedPrecision) = subscriptionData.acceptedTokens(t);
        require(accepted, "Token is not accepted");
        uint256 _price;
        uint256 _timestamp;
        if (isChainLinkFeed) {
            AggregatorV3Interface chainlinkFeed = AggregatorV3Interface(
                priceFeedAddress
            );
            (
                uint80 roundID,
                int256 price,
                uint256 startedAt,
                uint256 timeStamp,
                uint80 answeredInRound
            ) = chainlinkFeed.latestRoundData();
            _price = uint256(price);
            _timestamp = uint256(timeStamp);
        } else {
            IDiaOracle priceFeed = IDiaOracle(priceFeedAddress);
            (uint128 price, uint128 timeStamp) = priceFeed.getValue(
                symbol
            );
            _price = price;
            _timestamp = timeStamp;
        }
        uint256 price = _toPrecision(
            uint256(_price),
            priceFeedPrecision,
            decimals
        );
        return (price, _timestamp);
    }
    /**
     * @dev calculate price in Spheron
     * @notice ensure that price is within 6 hour window
     * @param a total amount in USD
     * @return price
     */
    function _calculatePriceInToken(uint256 a, address t)
        internal
        returns (uint256)
    {
        (, uint128 decimals, , , , , ) = subscriptionData.acceptedTokens(t);
        uint256 precision = 10**decimals;
        a = _toPrecision(a, subscriptionData.usdPricePrecision(), decimals);
        (
            uint256 underlyingPrice,
            uint256 timestamp
        ) = getUnderlyingPrice(t);
        // require((block.timestamp - timestamp) <= TIMESTAP_GAP, "SpheronSubscriptionPayments: underlying price not updated");
        return (a * precision) / underlyingPrice;
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
    /**
     * @notice Return user data
     * @param _token address of deposit ERC20 token
     * @param _user address of the user
     */
    function getUserData(address _user, address _token) public view returns (UserData memory) {
        return userData[_user][_token];
    }
    /**
     * @notice Return total deposits of all users for a token
     */
    function getTotalDeposit(address t) public view returns (uint256) {
        return totalDeposit[t];
    }
    /**
     * @notice Return total withdrawals of all users for a token
     */
    function getTotalWithdraws(address t) public view returns (uint256) {
        return totalWithdraws[t];
    }
    /**
     * @notice Return total charges of all users for a token
     */
    function getTotalCharges(address t) public view returns (uint256) {
        return totalCharges[t];
    }
    function _msgSender() internal view override(ERC2771Context)
      returns (address sender) {
      sender = ERC2771Context._msgSender();
    }
    function _msgData() internal view override(ERC2771Context)
      returns (bytes calldata) {
      return ERC2771Context._msgData();
    }

}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISubscriptionData {
    function priceData(string memory name) external view returns (uint256);

    function availableParams(string memory name) external view returns (bool);

    function params(uint256 name) external view returns (bool);

    function managerByAddress(address user) external view returns (bool);

    function discountsEnabled() external view returns (bool);

    function stakingManager() external view returns (address);

    function stakedToken() external view returns (address);

    function getUnderlyingPrice(address t) external view returns (uint256);

    function escrow() external view returns (address);

    function slabs() external view returns (uint256[] memory);

    function discountPercents() external view returns (uint256[] memory);

    function addNewTokens(
        string[] memory s,
        address[] memory t,
        uint128[] memory d,
        bool[] memory isChainLinkFeed_,
        address[] memory priceFeedAddress_,
        uint128[] memory priceFeedPrecision_
    ) external;

    function removeTokens(address[] memory t) external;

    function usdPricePrecision() external returns (uint128);
    
    function changeUsdPrecision(uint128 p) external;

    function acceptedTokens(address token)
        external view
        returns (
            string memory symbol,
            uint128 decimals,
            address tokenAddress,
            bool accepted,
            bool isChainLinkFeed,
            address priceFeedAddress,
            uint128 priceFeedPrecision
        );
    function isAcceptedToken(address token) external returns (bool);

    function isManager(address user) external returns (bool);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./../interfaces/ISubscriptionData.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    address private _trustedForwarder;
    event ChangeTrustedForwarder(address indexed trustedForwarder);
    ISubscriptionData public subscriptionData;

    constructor(address trustedForwarder, address _data) {
        _trustedForwarder = trustedForwarder;
        subscriptionData = ISubscriptionData(_data);
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    function setTrustedForwarder(address forwarder) public virtual {
        require(forwarder != address(0), "Forwarder cannot be zero address");
        require(subscriptionData.isManager(msg.sender), "Only manager can call this function");
        _trustedForwarder = forwarder;
        emit ChangeTrustedForwarder(forwarder);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDiaOracle {
	function setValue(string memory key, uint128 value, uint128 timestamp) external;

	function updateOracleUpdaterAddress(address newOracleUpdaterAddress) external;
    
	function getValue(string memory key) external view returns (uint128, uint128);

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