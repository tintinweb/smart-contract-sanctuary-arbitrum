// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Nuon/Pools/ICollateralHub.sol



pragma solidity 0.8.7;

interface ICollateralHub {
    function setCollatGMUOracle(address _collateralGMUOracleAddress) external;

    function setPoolParameters(uint256 newCeiling, uint256 newRedemptionDelay)
        external;

    function setTimelock(address newTimelock) external;

    function setOwner(address ownerAddress) external;

    function mint(
        uint256 collateralAmount,
        uint256 USXOutMin,
        uint256 cid
    ) external returns (uint256);

    function redeem(
        uint256 USXAmount,
        uint256 collateralOutMin,
        uint256 cid
    ) external;

    function collectRedemption(uint256 cid) external;

    function getGlobalCR() external view returns (uint256);

    function getCollateralPrice() external view returns (uint256);

    function getAvailableExcessCollateralDV()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function collateralGMUOracleAddress() external view returns (address);

    function viewCollateralPrice() external view returns (uint256);

    function getNUONPrice() external view returns (uint256);
}

// File: contracts/Nuon/interfaces/ITruflation.sol


pragma solidity ^0.8.7;

interface ITruflation {
    function getNuonTargetPeg() external view returns (uint256);
}

// File: contracts/Nuon/interfaces/IIncentive.sol



pragma solidity 0.8.7;

/// @title incentive contract interface
/// @author Fei Protocol
/// @notice Called by FEI token contract when transferring with an incentivized address
/// @dev should be appointed as a Minter or Burner as needed
interface IIncentiveController {
    /// @notice apply incentives on transfer
    /// @param sender the sender address of the FEI
    /// @param receiver the receiver address of the FEI
    /// @param operator the operator (msg.sender) of the transfer
    /// @param amount the amount of FEI transferred
    function incentivize(
        address sender,
        address receiver,
        address operator,
        uint256 amount
    ) external;
}

// File: contracts/utils/token/IAnyswapV4Token.sol



pragma solidity 0.8.7;

interface IAnyswapV4Token {
    function approveAndCall(
        address spender,
        uint256 value,
        bytes calldata data
    ) external returns (bool);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool);

    function transferWithPermit(
        address target,
        address to,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    function Swapin(
        bytes32 txhash,
        address account,
        uint256 amount
    ) external returns (bool);

    function Swapout(uint256 amount, address bindaddr) external returns (bool);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address target,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// File: contracts/Nuon/interfaces/INUON.sol



pragma solidity 0.8.7;




interface INUON is IERC20, IAnyswapV4Token {
    function mint(address who, uint256 amount) external;

    function setNUONController(address _controller) external;

    function burn(uint256 amount) external;
}

// File: contracts/utils/math/Math.sol



pragma solidity 0.8.7;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// File: contracts/Nuon/NuonController.sol



pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;









interface IUniswapPairOracle {
    function update() external;

    function consult(address token, uint256 amountIn)
        external
        view
        returns (uint256 amountOut);

    function canUpdate() external view returns (bool);
}

/**
 * @title  NUON Controller.
 * @author Hash
 */
contract NUONController is Ownable {
    using SafeMath for uint256;

    IERC20 public NUON;
    address public TruflationOracle;

    address[] public NUONPoolsArray; // These collateral contracts are able to mint NUON.
    mapping(address => bool) public NUONPools;
    mapping(address => bool) public allowedToMintNUON;

    mapping(address => uint256) public mintingFee;
    mapping(address => uint256) public redeemFees;
    mapping(address => uint256) public maxCRATIO;
    mapping(address => int256) public flatInterestRate;
    mapping(address => int256) public safetyNet;
    mapping(address => int256) public maxOffPegPercentDownside;
    mapping(address => int256) public maxOffPegPercentUpside;
    mapping(address => int256) public baseCollateralRatio;
    mapping(address => int256) public collateralVolatilityBuffer;

    bool public mintPaused = false;
    bool public redeemPaused = false;

    /**
     * Constructor.
     */

    constructor(
        IERC20 _NUON
    ) {
        NUON = _NUON;
    }

    function setEcosystemParametersForCHUBS(
        address _CHUB, 
        int256 _maxOffPegPercentUpside,
        int256 _maxOffPegPercentDownside,
        int256 _safetyNet,
        int256 _flatInterestRate,
        int256 _baseCollateralRatio,
        int256 _collateralVolatilityBuffer,
        uint256 _maxCRATIO,
        uint256 _mintingFee,
        uint256 _redeemFees 
    ) public onlyOwner {
        require(_CHUB != address(0), "Please provide a valid CHUB address");
        require(_mintingFee < 10e18 && _redeemFees < 10e18, 'Madlad admin');
        require(!NUONPools[_CHUB], 'NUONController: address present');
        maxOffPegPercentUpside[_CHUB] = _maxOffPegPercentUpside;
        maxOffPegPercentDownside[_CHUB] = _maxOffPegPercentDownside;
        safetyNet[_CHUB] = _safetyNet;
        flatInterestRate[_CHUB] = _flatInterestRate;
        baseCollateralRatio[_CHUB] = _baseCollateralRatio;
        collateralVolatilityBuffer[_CHUB] = _collateralVolatilityBuffer;
        maxCRATIO[_CHUB] = _maxCRATIO;
        mintingFee[_CHUB] = _mintingFee;
        redeemFees[_CHUB] = _redeemFees;
        _addPool(_CHUB);
    }
    
    function setMaxOffPegPercentUpside(address _CHUB, int256 _maxOffPegPercentUpside) public onlyOwner {
        require(NUONPools[_CHUB],'NUONController: not registered as CHUB');
        maxOffPegPercentUpside[_CHUB] = _maxOffPegPercentUpside;
    }

    function setMaxOffPegPercentDownside(address _CHUB, int256 _maxOffPegPercentDownside) public onlyOwner {
        require(NUONPools[_CHUB],'NUONController: not registered as CHUB');
        maxOffPegPercentDownside[_CHUB] = _maxOffPegPercentDownside;
    }
    
    function setSafetyNet(address _CHUB, int256 _safetyNet) public onlyOwner {
        require(NUONPools[_CHUB],'NUONController: not registered as CHUB');
        safetyNet[_CHUB] = _safetyNet;
    }

    function setFlatInterestRate(address _CHUB, int256 _flatInterestRate) public onlyOwner {
        require(NUONPools[_CHUB],'NUONController: not registered as CHUB');
        flatInterestRate[_CHUB] = _flatInterestRate;
    }   

    function setBaseCollateralRatio(address _CHUB, int256 _baseCollateralRatio) public onlyOwner {
        require(NUONPools[_CHUB],'NUONController: not registered as CHUB');
        baseCollateralRatio[_CHUB] = _baseCollateralRatio;
    }

    function setCollateralVolatilityBuffer(address _CHUB, int256 _collateralVolatilityBuffer) public onlyOwner {
        require(NUONPools[_CHUB],'NUONController: not registered as CHUB');
        collateralVolatilityBuffer[_CHUB] = _collateralVolatilityBuffer;
        require(collateralVolatilityBuffer[_CHUB] < baseCollateralRatio[_CHUB], "Buffer has to be lower than base");
    }

    function setMaxCRATIO(address _CHUB, uint256 _maxCRATIO) public onlyOwner {
        require(NUONPools[_CHUB],'NUONController: not registered as CHUB');
        maxCRATIO[_CHUB] = _maxCRATIO;
    }

    function setMintingFee(address _CHUB, uint256 _mintingFee) public onlyOwner {
        require(NUONPools[_CHUB],'NUONController: not registered as CHUB');
        require(_mintingFee < 1e18, 'Madlad admin');
        mintingFee[_CHUB] = _mintingFee;
    }

    function setRedeemFees(address _CHUB, uint256 _redeemFees) public onlyOwner {
        require(NUONPools[_CHUB],'NUONController: not registered as CHUB');
        require(_redeemFees < 1e18, 'Madlad admin');
        redeemFees[_CHUB] = _redeemFees;
    }

    function setTruflationOracle(address _truflationOracle) public onlyOwner {
        require(_truflationOracle != address(0));
        TruflationOracle = _truflationOracle;
    }

    // Set Functions //
    function _addNUONMinter(address _minter) internal {
        require(!allowedToMintNUON[_minter], 'Already a minter');
        allowedToMintNUON[_minter] = true;
    }

    function _removeNUONMinter(address _minter) internal {
        require(allowedToMintNUON[_minter], 'Not a minter');
        allowedToMintNUON[_minter] = false;
    }

    function getPools() public view returns (address[] memory) {
        return NUONPoolsArray;
    }

    function _addPool(address poolAddress) internal {
        require(!NUONPools[poolAddress], 'NUONController: address present');

        NUONPools[poolAddress] = true;
        NUONPoolsArray.push(poolAddress);
        _addNUONMinter(poolAddress);
    }

    function removePool(address poolAddress) public onlyOwner {
        require(
            NUONPools[poolAddress],
            'NUONController: not registered as pool'
        );

        // Delete from the mapping.
        delete NUONPools[poolAddress];
        // Set the allowance to mint NUON to false for that pool.
	    _removeNUONMinter(poolAddress);
        uint256 noOfPools = NUONPoolsArray.length;
        // 'Delete' from the array by setting the address to 0x0
        for (uint256 i = 0; i < noOfPools; i++) {
            if (NUONPoolsArray[i] == poolAddress) {
                NUONPoolsArray[i] = address(0); // This will leave a null in the array and keep the indices the same.
                break;
            }
        }
    }

    function toggleMinting() public onlyOwner {
        mintPaused = !mintPaused;
    }

    function toggleRedeeming() public onlyOwner {
        redeemPaused = !redeemPaused;
    }

    // GET

    function isMintPaused() public view returns (bool) {
        return mintPaused;
    }

    function isRedeemPaused() public view returns (bool) {
        return redeemPaused;
    }

    function isPool(address pool) public view returns (bool) {
        return NUONPools[pool];
    }

    function isAllowedToMint(address _minter) public view returns (bool) {
        return allowedToMintNUON[_minter];
    }

    function getGlobalCollateralRatio(address _CHUB) public view returns (int) {
        int256 collateralRatio = baseCollateralRatio[_CHUB] - collateralVolatilityBuffer[_CHUB];
        int currentDPR = computeInterestRates(_CHUB);
        if (currentDPR > 0) {
            // we are over peg, so interest rate are lower (currentDPR will be positive)
            int  totalCollateralRatio = collateralRatio + currentDPR;
            // max discount until 100% collateral ratio
                if (totalCollateralRatio > baseCollateralRatio[_CHUB]) {
                totalCollateralRatio = baseCollateralRatio[_CHUB];
                }
            return totalCollateralRatio;
        } else {
            // we are under peg, so interest rate rise (currentDPR will be negative but +- is a sub)
            int totalCollateralRatio = collateralRatio + currentDPR;
            if (totalCollateralRatio < safetyNet[_CHUB]) {
                totalCollateralRatio = safetyNet[_CHUB];
            }
            return totalCollateralRatio;
        }
    }

    function getCollateralRatioInPercent(address _CHUB) public view returns (int256) {
        int256 rat = (1e18 * 1e18) / getGlobalCollateralRatio(_CHUB) * 100;
        return (rat);
    }

    function getCVBRatio(address _CHUB) public view returns (int256) {
        return (collateralVolatilityBuffer[_CHUB]);
    }

    function getMaxCratio(address _CHUB) public view returns (uint256) {
        return maxCRATIO[_CHUB];
    }

    function getRedeemFee(address _CHUB) public view returns (uint256) {
        return redeemFees[_CHUB];
    }

    function computeInterestRates(address _CHUB) public view returns (int) {

        int offPegVar = calculatePercentOffPeg();
        int DPR = offPegVar * flatInterestRate[_CHUB];
        if (DPR > maxOffPegPercentUpside[_CHUB]) {
            DPR = maxOffPegPercentUpside[_CHUB];
        } else if (DPR < maxOffPegPercentDownside[_CHUB]) {
            DPR = maxOffPegPercentDownside[_CHUB];
        }
        return (DPR);
    }

    function calculatePercentOffPeg() public view returns (int) {
        int256 NuonPrice = int(getNUONPrice());
        int256 targetPeg = int(getTruflationPeg());
        int v1minv2 = NuonPrice - targetPeg;
        int v1v2var = (v1minv2 * 1e18 ) / NuonPrice;
        //variance with 2 decimals
        int variance = v1v2var / 1e14;
        return (variance);
    }

    function getTruflationPeg() public view returns (uint256) {
        return ITruflation(TruflationOracle).getNuonTargetPeg();
    }

    function getNUONPrice()
        public
        view
        returns (uint256)
    {
        uint256 assetPrice = ICollateralHub(NUONPoolsArray[0]).getNUONPrice();
        return assetPrice;
    }

    function getGlobalCollateralValue() public view returns (uint256) {
        uint256 totalCollateralValueD18 = 0;

        uint256 noOfPools = NUONPoolsArray.length;
        for (uint256 i = 0; i < noOfPools; i++) {
            // Exclude null addresses.
            if (NUONPoolsArray[i] != address(0)) {
                totalCollateralValueD18 = totalCollateralValueD18.add(
                    ICollateralHub(NUONPoolsArray[i]).getCollateralPrice()
                );
            }
        }

        return totalCollateralValueD18;
    }

    function getNUONSupply() public view returns (uint256) {
        return NUON.totalSupply();
    }

    function getMintingFee(address _CHUB) public view returns (uint256) {
        return mintingFee[_CHUB];
    }

    function getNUONInfo(address _CHUB)
        public
        view
        returns (
            uint256,
            int256,
            uint256,
            uint256
        )
    {
        return (
            NUON.totalSupply(), // NUON total supply.
            getGlobalCollateralRatio(_CHUB), // Global collateralization ratio.
            getGlobalCollateralValue(), // Global collateral value.
            mintingFee[_CHUB] // Minting fee.
        );
    }
}