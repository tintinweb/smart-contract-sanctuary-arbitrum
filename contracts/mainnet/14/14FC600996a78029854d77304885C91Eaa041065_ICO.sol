// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/IICO.sol";
import "./utils/ReentrancyGuard.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/OracleWrapper.sol";

contract ICO is Ownable, ReentrancyGuard, IICO {
    uint256 public tokensToBeSold;
    uint256 public totalTokenSold;
    uint256 public totalUSDRaised;
    uint256 public tokenDecimal;
    uint256 public minTokensBuy = (100 * (10 ** 18));
    uint32 public lockingingPeriod = 180 days;
    uint8 public defaultPhase = 1;
    uint8 public totalPhases;

    address public receiverAddress = 0xC660d57E7947342bE10f0EB7d72E5B9ae30Efe7d;

    /* ================ STRUCT SECTION ================ */
    /* Stores phases */
    struct Phases {
        uint256 tokenSold;
        uint256 tokenLimit;
        uint32 startTime;
        uint32 expirationTimestamp;
        uint32 price /* 10 ** 8 */;
        bool isComplete;
    }

    struct userVesting {
        uint256 vestingClaimedAmount;
        uint256 vestingPendingAmount;
        uint32 purchaseDate;
        bool isClaimed;
    }

    mapping(uint256 => Phases) public phaseInfo;
    mapping(address => mapping(uint256 => userVesting)) public userVestingInfo;
    mapping(address => uint256) userCounter;

    IERC20Metadata public tokenInstance; /* Altranium token instance */
    IERC20Metadata public arbInstance; /* ARB token instance */
    IERC20Metadata public usdtInstance; /* USDT token instance */
    IERC20Metadata public usdcInstance; /* USDC token instance */
    IERC20Metadata public wethInstance; /* WETH token instance */

    OracleWrapper public ARBOracle =
        OracleWrapper(0xb2A824043730FE05F3DA2efaFa1CBbe83fa548D6);
    OracleWrapper public USDTOracle =
        OracleWrapper(0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7);
    OracleWrapper public USDCOracle =
        OracleWrapper(0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3);
    OracleWrapper public WETHOracle =
        OracleWrapper(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);
    OracleWrapper public ETHOracle =
        OracleWrapper(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);

    /* ================ CONSTRUCTOR SECTION ================ */
    constructor(
        address _tokenAddress
    ) {
        tokenInstance = IERC20Metadata(_tokenAddress);
        arbInstance = IERC20Metadata(0x912CE59144191C1204E64559FE8253a0e49E6548);
        usdtInstance = IERC20Metadata(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
        usdcInstance = IERC20Metadata(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
        wethInstance = IERC20Metadata(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

        totalPhases = 2;
        tokenDecimal = uint256(10 ** tokenInstance.decimals());
        tokensToBeSold = 1_400_000_000 * tokenDecimal;

        phaseInfo[1] = Phases({
            tokenLimit: 300_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: uint32(block.timestamp),
            expirationTimestamp: 1706054399, //23 jan 2024
            price: 20000 /* 0.0002 */,
            isComplete: false
        });
        phaseInfo[2] = Phases({
            tokenLimit: 1_100_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: 1706227200,// 26th jan 2023
            expirationTimestamp: 1707609599, //10th feb 2024
            isComplete: false,
            price: 100000 /* 0.0010 */
        });
    }

    /* ================ BUYING TOKENS SECTION ================ */

    /* Receive Function */
    receive() external payable {
        /* Sending deposited currency to the receiver address */
        TransferHelper.safeTransferETH(receiverAddress, msg.value);
    }

    /** Function lets user buy ALTR tokens || Type 1 = BNB or ETH,
     * Type = 2 for ARB,
     * Type = 3 for USDT,
     * Type = 4 for USDC,
     * Type = 5 for WETH
     */
    function buyTokens(
        uint8 _type,
        uint256 _usdtAmount
    ) external payable override nonReentrant {
        address _msgSender = msg.sender;
        uint8 _phase = getCurrentPhase();
        require(
            block.timestamp >= phaseInfo[_phase].startTime,
            "Phase has not started yet."
        );
        require(
            block.timestamp < phaseInfo[(totalPhases)].expirationTimestamp,
            "Buying phases are over."
        );

        uint256 _buyAmount;
        IERC20Metadata _instance;
        /* If type == 1 */
        if (_type == 1) {
            _buyAmount = msg.value;
        }
        /* If type == 2 */
        else {
            _buyAmount = _usdtAmount;
            /* Balance Check */

            if (_type == 2) {
                _instance = arbInstance;
            } else if (_type == 3) {
                _instance = usdtInstance;
            } else if (_type == 4) {
                _instance = usdcInstance;
            } else {
                _instance = wethInstance;
            }
            require(
                _instance.balanceOf(_msgSender) >= _buyAmount,
                "User doesn't have enough balance."
            );

            /* Allowance Check */
            require(
                _instance.allowance(_msgSender, address(this)) >= _buyAmount,
                "Allowance provided is low."
            );
        }
        require(_buyAmount > 0, "Please enter value more than 0.");

        /* Token calculation */
        (
            uint256 _tokenAmount,
            uint8 _phaseNo,
            uint256 _amountToUSD
        ) = calculateTokens(_buyAmount, 0, defaultPhase, _type);

        require(
            _tokenAmount >= minTokensBuy,
            "Please buy more then minimum value"
        );

        /* Setup for vesting in vesting contract */
        require(_tokenAmount > 0, "Token amount should be more then zero.");

        uint256 _vestingAmount;
        if (_phaseNo == 1) {
            ++userCounter[_msgSender];
            _vestingAmount = (_tokenAmount * 8000) / 10000;
            userVestingInfo[_msgSender][userCounter[_msgSender]]
                .vestingPendingAmount += _vestingAmount;
            userVestingInfo[_msgSender][userCounter[_msgSender]]
                .purchaseDate = uint32(block.timestamp);

            emit VestingDetails(
                _vestingAmount,
                userCounter[_msgSender],
                uint32(block.timestamp),
                _msgSender
            );
        }

        /* Phase info setting */
        setPhaseInfo(_tokenAmount, defaultPhase);

        /* Update Phase number and add token amount */
        defaultPhase = _phaseNo;

        totalTokenSold += _tokenAmount;
        totalUSDRaised += _amountToUSD;

        if (_type == 1) {
            /* Sending deposited currency to the receiver address */
            TransferHelper.safeTransferETH(receiverAddress, _buyAmount);
        } else {
            /* Sending deposited currency to the receiver address */
            TransferHelper.safeTransferFrom(
                address(_instance),
                _msgSender,
                receiverAddress,
                _buyAmount
            );
        }
        uint256 _sendingAmount = (_tokenAmount - _vestingAmount);
        TransferHelper.safeTransfer(
            address(tokenInstance),
            _msgSender,
            _sendingAmount
        );
        /* Emits event */



        emit BuyTokenDetail(
            _buyAmount,
            _tokenAmount,
            uint32(block.timestamp),
            _type,
            _phaseNo,
            _msgSender
        );
    }

    function getCurrentPhase() public view returns (uint8) {
        uint32 _time = uint32(block.timestamp);

        Phases memory pInfoFirst = phaseInfo[1];
        Phases memory pInfoLast = phaseInfo[2];

        if (pInfoLast.expirationTimestamp >= _time) {
            if (pInfoFirst.expirationTimestamp >= _time) {
                return 1;
            } else {
                return 2;
            }
        } else {
            return 0;
        }
    }

    /* Function calculates ETH, USDT according to user's given amount */
    function calculateETHorUSDT(
        uint256 _amount,
        uint256 _previousTokens,
        uint8 _phaseNo,
        uint8 _type
    ) public view returns (uint256) {
        /* Phases cannot exceed totalPhases */
        require(
            _phaseNo <= totalPhases,
            "Not enough tokens in the contract or phase expired."
        );
        Phases memory pInfo = phaseInfo[_phaseNo];
        /* If phase is still going on */
        if (block.timestamp < pInfo.expirationTimestamp) {
            uint256 _amountToUSD = ((_amount * pInfo.price) / tokenDecimal);
            (uint256 _cryptoUSDAmount, uint256 _decimals) = cryptoValues(_type);
            uint256 _tokensLeftToSell = (pInfo.tokenLimit + _previousTokens) -
                pInfo.tokenSold;
            require(
                _tokensLeftToSell >= _amount,
                "Insufficient tokens available in phase."
            );
            return ((_amountToUSD * _decimals) / _cryptoUSDAmount);
        }
        /* In case the phase is expired. New will begin after sending the left tokens to the next phase */
        else {
            uint256 _remainingTokens = pInfo.tokenLimit - pInfo.tokenSold;

            return
                calculateETHorUSDT(
                    _amount,
                    _remainingTokens + _previousTokens,
                    _phaseNo + 1,
                    _type
                );
        }
    }

    /* Internal function to calculate tokens */
    function calculateTokens(
        uint256 _amount,
        uint256 _previousTokens,
        uint8 _phaseNo,
        uint8 _type
    ) public view returns (uint256, uint8, uint256) {
        /* Phases cannot exceed totalPhases */
        require(
            _phaseNo <= totalPhases,
            "Not enough tokens in the contract or Phase expired."
        );
        Phases memory pInfo = phaseInfo[_phaseNo];
        /* If phase is still going on */
        if (block.timestamp < pInfo.expirationTimestamp) {
            (uint256 _amountToUSD, uint256 _typeDecimal) = cryptoValues(_type);
            uint256 _amountGivenInUsd = ((_amount * _amountToUSD) /
                _typeDecimal);

            /* If phase is still going on */
            uint256 _tokensAmount = tokensUserWillGet(
                _amountGivenInUsd,
                pInfo.price
            );
            uint256 _tokensLeftToSell = (pInfo.tokenLimit + _previousTokens) -
                pInfo.tokenSold;
            require(
                _tokensLeftToSell >= _tokensAmount,
                "Insufficient tokens available in phase."
            );
            return (_tokensAmount, _phaseNo, _amountGivenInUsd);
        }
        /*  In case the phase is expired. New will begin after sending the left tokens to the next phase */
        else {
            uint256 _remainingTokens = pInfo.tokenLimit - pInfo.tokenSold;

            return
                calculateTokens(
                    _amount,
                    _remainingTokens + _previousTokens,
                    _phaseNo + 1,
                    _type
                );
        }
    }

    /* Tokens user will get according to the price */
    function tokensUserWillGet(
        uint256 _amount,
        uint32 _price
    ) internal view returns (uint256) {
        return ((_amount * tokenDecimal * (10 ** 8)) /
            ((10 ** 8) * uint256(_price)));
    }

    /* Returns the crypto values used */
    function cryptoValues(
        uint8 _type
    ) internal view returns (uint256, uint256) {
        uint256 _amountToUSD;
        uint256 _typeDecimal;
        OracleWrapper _oracle;
        IERC20Metadata _instance;

        if (_type == 1) {
            _amountToUSD = ETHOracle.latestAnswer();
            _typeDecimal = 10 ** 18;
        } else {
            if (_type == 2) {
                _instance = arbInstance;
                _oracle = ARBOracle;
            } else if (_type == 3) {
                _instance = usdtInstance;
                _oracle = USDTOracle;
            } else if (_type == 4) {
                _instance = usdcInstance;
                _oracle = USDCOracle;
            } else {
                _instance = wethInstance;
                _oracle = WETHOracle;
            }
            _amountToUSD = _oracle.latestAnswer();
            _typeDecimal = uint256(10 ** _instance.decimals());
        }
        return (_amountToUSD, _typeDecimal);
    }

    /* Sets phase info according to the tokens bought */
    function setPhaseInfo(uint256 _tokensUserWillGet, uint8 _phaseNo) internal {
        require(_phaseNo <= totalPhases, "All tokens have been exhausted.");

        Phases storage pInfo = phaseInfo[_phaseNo];

        if (block.timestamp < pInfo.expirationTimestamp) {
            /* when phase has more tokens than reuired */
            if ((pInfo.tokenLimit - pInfo.tokenSold) > _tokensUserWillGet) {
                pInfo.tokenSold += _tokensUserWillGet;
            }
            /* when  phase has equal tokens as reuired */
            else if (
                (pInfo.tokenLimit - pInfo.tokenSold) == _tokensUserWillGet
            ) {
                pInfo.tokenSold = pInfo.tokenLimit;
                pInfo.isComplete = true;
            }
            /*  when tokens required are more than left tokens in phase */
            else {
                revert("Phase doesn't have enough tokens.");
            }
        }
        /* if tokens left in phase afterb completion of expiration time */
        else {
            uint256 remainingTokens = pInfo.tokenLimit - pInfo.tokenSold;
            pInfo.tokenLimit = pInfo.tokenSold;
            pInfo.isComplete = true;

            phaseInfo[_phaseNo + 1].tokenLimit += remainingTokens;
            setPhaseInfo(_tokensUserWillGet, _phaseNo + 1);
        }
    }

    function claimTokens(uint256 _choice) public nonReentrant {
        address _user = msg.sender;

        userVesting storage userInfo = userVestingInfo[_user][_choice];
        require(
            userInfo.vestingPendingAmount > 0,
            "You have no pending amount to be claimed."
        );
        require(
            block.timestamp > userInfo.purchaseDate + lockingingPeriod,
            "You can claim after vesting period ends."
        );

        uint256 _amount = userInfo.vestingPendingAmount;

        userInfo.vestingClaimedAmount += userInfo.vestingPendingAmount;
        userInfo.vestingPendingAmount = 0;
        userInfo.isClaimed = true;

        require(
            _amount <= tokenInstance.balanceOf(address(this)),
            "Contract doesn't have enough tokens left."
        );

        TransferHelper.safeTransfer(
            address(tokenInstance),
            _user,
            userInfo.vestingClaimedAmount
        );

        emit ClaimedToken(_amount, _choice, uint32(block.timestamp), _user);
    }

    function sendLeftoverTokens() external onlyOwner {
        require(
            phaseInfo[2].expirationTimestamp < block.timestamp,
            "ICO is not over yet."
        );
        uint256 _balance = tokensToBeSold - totalTokenSold;
        require(_balance > 0, "No tokens left to send.");

        TransferHelper.safeTransfer(
            address(tokenInstance),
            receiverAddress,
            _balance
        );
    }

    /* ================ OTHER FUNCTIONS SECTION ================ */
    /* Updates Receiver Address */
    function updateReceiverAddress(
        address _receiverAddress
    ) external onlyOwner {
        require(_receiverAddress != address(0), "Zero address passed.");
        receiverAddress = _receiverAddress;
    }

    function updateMinimumTokensBuyAmount(
        uint256 _minTokensBuy
    ) external onlyOwner {
        minTokensBuy = _minTokensBuy;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IICO {
    event BuyTokenDetail(
        uint256 buyAmount,
        uint256 tokenAmount,
        uint32 timestamp,
        uint8 buyType,
        uint8 phaseNo,
        address userAddress
    );

    event VestingDetails(
        uint256 vestingAmount,
        uint256 userCounter,
        uint32 timestamp,
        address userAddress
    );

    event ClaimedToken(
        uint256 claimedAmount,
        uint256 claimId,
        uint32 claimedTimestamp,
        address userAddress
    );

    event UserKYC(address[] userAddress, bool success);

    function buyTokens(
        uint8 _type,
        uint256 _usdtAmount
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface OracleWrapper {
    function latestAnswer() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

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

    constructor () {
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