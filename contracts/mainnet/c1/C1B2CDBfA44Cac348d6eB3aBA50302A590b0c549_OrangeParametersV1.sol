// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

library ErrorsV1 {
    //General Errors
    string public constant ZERO_ADDRESS = "001";
    string public constant ZERO_INTEGER = "002";

    //OrangeAlphaVault
    string public constant ONLY_HELPER = "101";
    string public constant ONLY_STRATEGISTS = "103";
    string public constant ONLY_CALLBACK_CALLER = "104";
    string public constant INVALID_TICKS = "105";
    string public constant INVALID_AMOUNT = "106";
    string public constant INVALID_DEPOSIT_AMOUNT = "107";
    string public constant SURPLUS_ZERO = "108";
    string public constant LESS_AMOUNT = "109";
    string public constant LESS_LIQUIDITY = "110";
    string public constant HIGH_SLIPPAGE = "111";
    string public constant EQUAL_COLLATERAL_OR_DEBT = "112";
    string public constant NO_NEED_FLASH = "113";
    string public constant ONLY_BALANCER_VAULT = "114";
    string public constant INVALID_FLASHLOAN_HASH = "115";
    string public constant LESS_MAX_ASSETS = "116";
    string public constant ONLY_VAULT = "117";

    //OrangeValidationChecker
    string public constant MERKLE_ALLOWLISTED = "201";
    string public constant CAPOVER = "202";
    string public constant LOCKUP = "203";

    //OrangeStrategyImplV1

    //OrangeAlphaParameters
    string public constant INVALID_PARAM = "301";
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import {Ownable} from "../libs/Ownable.sol";
import {ErrorsV1} from "./ErrorsV1.sol";
import {IOrangeParametersV1} from "../interfaces/IOrangeParametersV1.sol";

contract OrangeParametersV1 is IOrangeParametersV1, Ownable {
    /* ========== CONSTANTS ========== */
    uint256 private constant MAGIC_SCALE_1E8 = 1e8; //for computing ltv
    uint16 private constant MAGIC_SCALE_1E4 = 10000; //for slippage

    /* ========== PARAMETERS ========== */
    uint16 public slippageBPS;
    uint24 public tickSlippageBPS;
    uint32 public twapSlippageInterval;
    uint32 public maxLtv;
    bool public allowlistEnabled;
    bytes32 public merkleRoot;
    uint256 public depositCap;
    uint256 public minDepositAmount;
    address public helper;
    address public strategyImpl;

    /* ========== CONSTRUCTOR ========== */
    constructor() {
        slippageBPS = 500; // default: 5% slippage
        tickSlippageBPS = 10;
        twapSlippageInterval = 5 minutes;
        maxLtv = 80000000; //80%
        allowlistEnabled = true;
    }

    /**
     * @notice Set parameters of slippage
     * @param _slippageBPS Slippage BPS
     * @param _tickSlippageBPS Check ticks BPS
     */
    function setSlippage(uint16 _slippageBPS, uint24 _tickSlippageBPS) external onlyOwner {
        if (_tickSlippageBPS == 0) revert(ErrorsV1.ZERO_INTEGER);

        if (_slippageBPS > MAGIC_SCALE_1E4) {
            revert(ErrorsV1.INVALID_PARAM);
        }
        slippageBPS = _slippageBPS;
        tickSlippageBPS = _tickSlippageBPS;
    }

    /**
     * @notice Set parameters of twap slippage
     * @param _twapSlippageInterval TWAP slippage interval
     */
    function setTwapSlippageInterval(uint32 _twapSlippageInterval) external onlyOwner {
        if (_twapSlippageInterval == 0) revert(ErrorsV1.ZERO_INTEGER);
        twapSlippageInterval = _twapSlippageInterval;
    }

    /**
     * @notice Set parameters of max LTV
     * @param _maxLtv Max LTV
     */
    function setMaxLtv(uint32 _maxLtv) external onlyOwner {
        if (_maxLtv > MAGIC_SCALE_1E8) {
            revert(ErrorsV1.INVALID_PARAM);
        }
        maxLtv = _maxLtv;
    }

    /**
     * @notice Set parameters of allowlist
     * @param _allowlistEnabled true or false
     */
    function setAllowlistEnabled(bool _allowlistEnabled) external onlyOwner {
        allowlistEnabled = _allowlistEnabled;
    }

    /**
     * @notice Set parameters of merkle root
     * @param _merkleRoot Merkle root
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Set parameters of depositCap
     * @param _depositCap Deposit cap of each accounts
     */
    function setDepositCap(uint256 _depositCap) external onlyOwner {
        if (_depositCap == 0) revert(ErrorsV1.ZERO_INTEGER);
        depositCap = _depositCap;
    }

    /**
     * @notice Set parameters of minDepositAmount
     * @param _minDepositAmount Min deposit amount
     */
    function setMinDepositAmount(uint256 _minDepositAmount) external onlyOwner {
        if (_minDepositAmount == 0) revert(ErrorsV1.ZERO_INTEGER);
        minDepositAmount = _minDepositAmount;
    }

    /**
     * @notice Set parameters of Rebalancer
     * @param _helper Helper
     */
    function setHelper(address _helper) external onlyOwner {
        if (_helper == address(0)) revert(ErrorsV1.ZERO_ADDRESS);

        helper = _helper;
    }

    /**
     * @notice Set parameters of strategyImpl
     * @param _strategyImpl strategyImpl
     */
    function setStrategyImpl(address _strategyImpl) external onlyOwner {
        if (_strategyImpl == address(0)) revert(ErrorsV1.ZERO_ADDRESS);

        strategyImpl = _strategyImpl;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IOrangeParametersV1 {
    /// @notice Get the slippage tolerance
    function slippageBPS() external view returns (uint16);

    /// @notice Get the slippage tolerance of tick
    function tickSlippageBPS() external view returns (uint24);

    /// @notice Get the slippage interval of twap
    function twapSlippageInterval() external view returns (uint32);

    /// @notice Get the maximum LTV
    function maxLtv() external view returns (uint32);

    /// @notice Get true/false of allowlist
    function allowlistEnabled() external view returns (bool);

    /// @notice Get the merkle root
    function merkleRoot() external view returns (bytes32);

    /// @notice Get the total amount of USDC deposited by the user
    function depositCap() external view returns (uint256 assets);

    /// @notice Get the minimum amount of USDC to deposit at only initial deposit
    function minDepositAmount() external view returns (uint256 minDepositAmount);

    /// @notice Get true/false of strategist
    function helper() external view returns (address);

    /// @notice Get the strategy implementation contract
    function strategyImpl() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view {
        if (_owner != msg.sender) revert("Ownable");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert("Ownable");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}