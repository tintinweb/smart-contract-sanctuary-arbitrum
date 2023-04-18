// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import {Ownable} from "../libs/Ownable.sol";
import {GelatoOps} from "../libs/GelatoOps.sol";
import {Errors} from "../libs/Errors.sol";
import {IOrangeAlphaParameters} from "../interfaces/IOrangeAlphaParameters.sol";

// import "forge-std/console2.sol";

contract OrangeAlphaParameters is IOrangeAlphaParameters, Ownable {
    /* ========== CONSTANTS ========== */
    uint256 constant MAGIC_SCALE_1E8 = 1e8; //for computing ltv
    uint16 constant MAGIC_SCALE_1E4 = 10000; //for slippage

    /* ========== PARAMETERS ========== */
    uint256 public depositCap;
    uint256 public totalDepositCap;
    uint256 public minDepositAmount;
    uint16 public slippageBPS;
    uint24 public tickSlippageBPS;
    uint32 public twapSlippageInterval;
    uint32 public maxLtv;
    uint40 public lockupPeriod;
    mapping(address => bool) public strategists;
    bool public allowlistEnabled;
    bytes32 public merkleRoot;
    address public gelatoExecutor;
    address public periphery;

    /* ========== CONSTRUCTOR ========== */
    constructor() {
        // these variables can be udpated by the manager
        depositCap = 1_000_000 * 1e6;
        totalDepositCap = 1_000_000 * 1e6;
        minDepositAmount = 100 * 1e6;
        slippageBPS = 500; // default: 5% slippage
        tickSlippageBPS = 10;
        twapSlippageInterval = 5 minutes;
        maxLtv = 80000000; //80%
        lockupPeriod = 7 days;
        strategists[msg.sender] = true;
        allowlistEnabled = true;
        _setGelato(msg.sender);
    }

    /**
     * @notice Set parameters of depositCap
     * @param _depositCap Deposit cap of each accounts
     * @param _totalDepositCap Total deposit cap
     */
    function setDepositCap(uint256 _depositCap, uint256 _totalDepositCap) external onlyOwner {
        if (_depositCap > _totalDepositCap) {
            revert(Errors.INVALID_PARAM);
        }
        depositCap = _depositCap;
        totalDepositCap = _totalDepositCap;
    }

    /**
     * @notice Set parameters of minDepositAmount
     * @param _minDepositAmount Min deposit amount
     */
    function setMinDepositAmount(uint256 _minDepositAmount) external onlyOwner {
        minDepositAmount = _minDepositAmount;
    }

    /**
     * @notice Set parameters of slippage
     * @param _slippageBPS Slippage BPS
     * @param _tickSlippageBPS Check ticks BPS
     */
    function setSlippage(uint16 _slippageBPS, uint24 _tickSlippageBPS) external onlyOwner {
        if (_slippageBPS > MAGIC_SCALE_1E4) {
            revert(Errors.INVALID_PARAM);
        }
        slippageBPS = _slippageBPS;
        tickSlippageBPS = _tickSlippageBPS;
    }

    /**
     * @notice Set parameters of lockup period
     * @param _twapSlippageInterval TWAP slippage interval
     */
    function setTwapSlippageInterval(uint32 _twapSlippageInterval) external onlyOwner {
        twapSlippageInterval = _twapSlippageInterval;
    }

    /**
     * @notice Set parameters of max LTV
     * @param _maxLtv Max LTV
     */
    function setMaxLtv(uint32 _maxLtv) external onlyOwner {
        if (_maxLtv > MAGIC_SCALE_1E8) {
            revert(Errors.INVALID_PARAM);
        }
        maxLtv = _maxLtv;
    }

    /**
     * @notice Set parameters of lockup period
     * @param _lockupPeriod Lockup period
     */
    function setLockupPeriod(uint40 _lockupPeriod) external onlyOwner {
        lockupPeriod = _lockupPeriod;
    }

    /**
     * @notice Set parameters of Rebalancer
     * @param _strategist Strategist
     * @param _is true or false
     */
    function setStrategist(address _strategist, bool _is) external onlyOwner {
        strategists[_strategist] = _is;
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
     * @notice Set parameters of gelato
     * @param _gelatoAdmin Gelato admin
     */
    function setGelato(address _gelatoAdmin) external onlyOwner {
        _setGelato(_gelatoAdmin);
    }

    function _setGelato(address _gelatoAdmin) internal {
        gelatoExecutor = GelatoOps.getDedicatedMsgSender(_gelatoAdmin);
    }

    /**
     * @notice Set parameters of periphery
     * @param _periphery Periphery
     */
    function setPeriphery(address _periphery) external onlyOwner {
        periphery = _periphery;
    }
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
        require(_owner == msg.sender, "Ownable");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable");
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

// SPDX-License-Identifier: UNLICENSED
//forked and minimize from https://github.com/gelatodigital/ops/blob/f6c45c81971c36e414afc31276481c47e202bdbf/contracts/integrations/OpsReady.sol
pragma solidity ^0.8.16;

interface IOpsProxyFactory {
    function getProxyOf(address account) external view returns (address, bool);
}

/**
 * @dev Inherit this contract to allow your smart contract to
 * - Make synchronous fee payments.
 * - Have call restrictions for functions to be automated.
 */
library GelatoOps {
    address private constant OPS_PROXY_FACTORY = 0xC815dB16D4be6ddf2685C201937905aBf338F5D7;

    function getDedicatedMsgSender(address msgSender) external view returns (address dedicatedMsgSender) {
        (dedicatedMsgSender, ) = IOpsProxyFactory(OPS_PROXY_FACTORY).getProxyOf(msgSender);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

library Errors {
    //OrangeAlphaVault
    string public constant ONLY_PERIPHERY = "101";
    string public constant ONLY_STRATEGISTS_OR_GELATO = "102";
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
    string public constant LESS_FINAL_BALANCE = "113";
    string public constant NO_NEED_FLASH = "114";
    string public constant ONLY_BALANCER_VAULT = "115";
    string public constant FLASHLOAN_LACK_OF_BALANCE = "116";

    //OrangeAlphaPeriphery
    string public constant MERKLE_ALLOWLISTED = "201";
    string public constant CAPOVER = "202";
    string public constant LOCKUP = "203";
    //OrangeAlphaParameters
    string public constant INVALID_PARAM = "301";
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IOrangeAlphaParameters {
    /// @notice Get the total amount of USDC deposited by the user
    function depositCap() external view returns (uint256 assets);

    /// @notice Get the total amount of USDC deposited by all users
    function totalDepositCap() external view returns (uint256 assets);

    /// @notice Get the minimum amount of USDC to deposit at only initial deposit
    function minDepositAmount() external view returns (uint256 minDepositAmount);

    /// @notice Get the slippage tolerance
    function slippageBPS() external view returns (uint16);

    /// @notice Get the slippage tolerance of tick
    function tickSlippageBPS() external view returns (uint24);

    /// @notice Get the slippage interval of twap
    function twapSlippageInterval() external view returns (uint32);

    /// @notice Get the maximum LTV
    function maxLtv() external view returns (uint32);

    /// @notice Get the lockup period
    function lockupPeriod() external view returns (uint40);

    /// @notice Get true/false of strategist
    function strategists(address) external view returns (bool);

    /// @notice Get true/false of allowlist
    function allowlistEnabled() external view returns (bool);

    /// @notice Get the merkle root
    function merkleRoot() external view returns (bytes32);

    /// @notice Get the gelato executor
    function gelatoExecutor() external view returns (address);

    /// @notice Get the periphery contract
    function periphery() external view returns (address);
}