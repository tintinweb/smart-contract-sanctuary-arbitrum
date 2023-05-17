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

//SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

/**
 * @title   Modified Compound's InterestRateModel Interface
 * @author  Honey Labs Inc.
 * @custom:coauthor BowTiedPickle
 * @custom:contributor m4rio
 */
interface InterestRateModelI {
  /**
   * @notice Calculates the current borrow rate per block
   * @param cash_ The amount of cash in the market
   * @param borrows_ The amount of borrows in the market
   * @param reserves_ The amount of reserves in the market
   * @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
   */
  function getBorrowRate(uint256 cash_, uint256 borrows_, uint256 reserves_) external view returns (uint256);

  /**
   * @notice Calculates the current supply rate per block
   * @param cash_ The amount of cash in the market
   * @param borrows_ The amount of borrows in the market
   * @param reserves_ The amount of reserves in the market
   * @param reserveFactorMantissa_ The current reserve factor for the market
   * @return The supply rate percentage per block as a mantissa (scaled by 1e18)
   */
  function getSupplyRate(
    uint256 cash_,
    uint256 borrows_,
    uint256 reserves_,
    uint256 reserveFactorMantissa_
  ) external view returns (uint256);

  /**
   * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
   * @param cash_ The amount of cash in the market
   * @param borrows_ The amount of borrows in the market
   * @param reserves_ The amount of reserves in the market
   * @return The utilization rate as a mantissa between [0, 1e18]
   */
  function utilizationRate(uint256 cash_, uint256 borrows_, uint256 reserves_) external pure returns (uint256);

  /**
   *
   * @param interfaceId_ The interface identifier, as specified in ERC-165
   */
  function supportsInterface(bytes4 interfaceId_) external view returns (bool);

  /*//////////////////////////////////////////////////////////////
                                GETTERS
  //////////////////////////////////////////////////////////////*/
  function baseRatePerBlock() external view returns (uint256);

  function multiplierPerBlock() external view returns (uint256);

  function jumpMultiplierPerBlock1() external view returns (uint256);

  function jumpMultiplierPerBlock2() external view returns (uint256);

  function kink1() external view returns (uint256);

  function kink2() external view returns (uint256);

  function blocksPerYear() external view returns (uint256);
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/InterestRateModelI.sol";

/**
 * @title   Double Jump Rate Interest Model
 * @author  Honey Labs Inc.
 * @notice  Implements a base rate and three linear interest rate curves anchored by two kink points
 * @custom:coauthor     BowTiedPickle
 * @custom:coauthor     m4rio
 */
abstract contract BaseDoubleJumpRateModel is Ownable, InterestRateModelI {
  /**
   * @notice  The approximate number of blocks per year that is assumed by the interest rate model
   */
  uint256 private immutable _blocksPerYear;

  /**
   * @notice The multiplier of utilization rate that gives the slope of the interest rate
   */
  uint256 private _multiplierPerBlock;

  /**
   * @notice The base interest rate which is the y-intercept when utilization rate is 0
   */
  uint256 private _baseRatePerBlock;

  /**
   * @notice The _multiplierPerBlock after hitting a specified utilization point
   */
  uint256 private _jumpMultiplierPerBlock1;

  /**
   * @notice The _multiplierPerBlock after hitting a specified utilization point
   */
  uint256 private _jumpMultiplierPerBlock2;

  /**
   * @notice The utilization point at which the 1st jump multiplier is applied
   */
  uint256 private _kink1;

  /**
   * @notice The utilization point at which the 2nd jump multiplier is applied
   */
  uint256 private _kink2;

  constructor(uint256 blocksPerYear_) {
    _blocksPerYear = blocksPerYear_;
  }

  event NewInterestParams(
    uint256 _baseRatePerBlock,
    uint256 multiplierPerBlock,
    uint256 _jumpMultiplierPerBlock1,
    uint256 _kink1,
    uint256 _kink2
  );

  /**
   * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
   * @param cash_ The amount of cash in the market
   * @param borrows_ The amount of borrows in the market
   * @param reserves_ The amount of reserves in the market
   * @return The utilization rate as a mantissa between [0, 1e18]
   */
  function utilizationRate(uint256 cash_, uint256 borrows_, uint256 reserves_) public pure override returns (uint256) {
    // Utilization rate is 0 when there are no borrows
    if (borrows_ == 0) {
      return 0;
    }

    return (borrows_ * 1e18) / (cash_ + borrows_ - reserves_);
  }

  /**
   * @notice Calculates the current supply rate per block
   * @param cash_ The amount of cash in the market
   * @param borrows_ The amount of borrows in the market
   * @param reserves_ The amount of reserves in the market
   * @param reserveFactorMantissa_ The current reserve factor for the market
   * @return The supply rate percentage per block as a mantissa (scaled by 1e18)
   */
  function getSupplyRate(
    uint256 cash_,
    uint256 borrows_,
    uint256 reserves_,
    uint256 reserveFactorMantissa_
  ) external view override returns (uint256) {
    uint256 oneMinusReserveFactor = uint256(1e18) - reserveFactorMantissa_;
    uint256 borrowRate = getBorrowRateInternal(cash_, borrows_, reserves_);
    uint256 rateToPool = (borrowRate * oneMinusReserveFactor) / 1e18;
    uint256 supplyRate = (utilizationRate(cash_, borrows_, reserves_) * rateToPool) / 1e18;
    return supplyRate;
  }

  /**
   * @notice  Update the parameters of the interest rate model (only callable by owner, i.e. Timelock)
   * @dev     The sum of the rates should equal the desired APR at 100% utilization
   * @param   baseRatePerYear_          The approximate target base APR, as a mantissa (scaled by 1e18)
   * @param   multiplierPerYear_        The mantissa-formatted total additional APR applied by the first curve
   * @param   jumpMultiplierPerYear1_   The mantissa-formatted total additional APR applied by the second curve
   * @param   jumpMultiplierPerYear2_   The mantissa-formatted total additional APR applied by the third curve
   * @param   kink1_                    The utilization point at which the first jump multiplier is applied
   * @param   kink2_                    The utilization point at which the second jump multiplier is applied
   */
  function govUpdateJumpRateModel(
    uint256 baseRatePerYear_,
    uint256 multiplierPerYear_,
    uint256 jumpMultiplierPerYear1_,
    uint256 jumpMultiplierPerYear2_,
    uint256 kink1_,
    uint256 kink2_
  ) public onlyOwner {
    require(1e18 > kink2_ && kink2_ > kink1_ && kink1_ > 0, "Invalid kinks");
    uint256 newBaseRatePerBlock = baseRatePerYear_ / _blocksPerYear;
    uint256 newMultiplierPerBlock = (multiplierPerYear_ * 1e18) / (_blocksPerYear * kink1_);
    uint256 newjumpMultiplierPerBlock1 = (jumpMultiplierPerYear1_ * 1e18) / (_blocksPerYear * (kink2_ - kink1_));
    uint256 newjumpMultiplierPerBlock2 = (jumpMultiplierPerYear2_ * 1e18) / (_blocksPerYear * (1e18 - kink2_));
    _baseRatePerBlock = newBaseRatePerBlock;
    _multiplierPerBlock = newMultiplierPerBlock;
    _jumpMultiplierPerBlock1 = newjumpMultiplierPerBlock1;
    _jumpMultiplierPerBlock2 = newjumpMultiplierPerBlock2;
    _kink1 = kink1_;
    _kink2 = kink2_;

    emit NewInterestParams(newBaseRatePerBlock, newMultiplierPerBlock, newjumpMultiplierPerBlock1, kink1_, kink2_);
  }

  /**
   * @notice Calculates the current borrow rate per block, with the error code expected by the market
   * @param cash_ The amount of cash in the market
   * @param borrows_ The amount of borrows in the market
   * @param reserves_ The amount of reserves in the market
   * @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
   */
  function getBorrowRateInternal(uint256 cash_, uint256 borrows_, uint256 reserves_) internal view returns (uint256) {
    uint256 util = utilizationRate(cash_, borrows_, reserves_);
    uint256 cachedkink1 = _kink1;
    uint256 cachedkink2 = _kink2;

    if (util <= cachedkink1) {
      return ((util * _multiplierPerBlock) / 1e18) + _baseRatePerBlock;
    } else if (util <= cachedkink2) {
      uint256 normalRate = ((cachedkink1 * _multiplierPerBlock) / 1e18) + _baseRatePerBlock;
      uint256 excessUtil;
      unchecked {
        excessUtil = util - cachedkink1;
      }
      return ((excessUtil * _jumpMultiplierPerBlock1) / 1e18) + normalRate;
    } else {
      uint256 normalRate = ((cachedkink1 * _multiplierPerBlock) / 1e18) + _baseRatePerBlock;
      uint256 kink1Rate = ((cachedkink2 - cachedkink1) * _jumpMultiplierPerBlock1) / 1e18;
      uint256 excessUtil;
      unchecked {
        excessUtil = util - cachedkink2;
      }
      return ((excessUtil * _jumpMultiplierPerBlock2) / 1e18) + kink1Rate + normalRate;
    }
  }

  /**
   * @notice Calculates the current borrow rate per block
   * @param cash_ The amount of cash in the market
   * @param borrows_ The amount of borrows in the market
   * @param reserves_ The amount of reserves in the market
   */
  function getBorrowRate(
    uint256 cash_,
    uint256 borrows_,
    uint256 reserves_
  ) external view virtual override returns (uint256);

  function supportsInterface(bytes4 interfaceId_) public view virtual override returns (bool) {
    return interfaceId_ == type(InterestRateModelI).interfaceId;
  }

  /*//////////////////////////////////////////////////////////////
                                GETTERS
  //////////////////////////////////////////////////////////////*/
  function baseRatePerBlock() external view override returns (uint256) {
    return _baseRatePerBlock;
  }

  function multiplierPerBlock() external view override returns (uint256) {
    return _multiplierPerBlock;
  }

  function jumpMultiplierPerBlock1() external view override returns (uint256) {
    return _jumpMultiplierPerBlock1;
  }

  function jumpMultiplierPerBlock2() external view override returns (uint256) {
    return _jumpMultiplierPerBlock2;
  }

  function kink1() external view override returns (uint256) {
    return _kink1;
  }

  function kink2() external view override returns (uint256) {
    return _kink2;
  }

  function blocksPerYear() external view override returns (uint256) {
    return _blocksPerYear;
  }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.15;

import "./BaseDoubleJumpRateModel.sol";

/**
 * @title   Interest rate model with two rate kinks
 * @author  Honey Labs Inc.
 * @custom:coauthor     BowTiedPickle
 * @custom:contributor  m4rio
 */
contract DoubleJumpRateModel is BaseDoubleJumpRateModel {
  /// @notice this corresponds to 1.0.0
  uint256 public constant version = 1_000_001;

  /**
   * @notice Calculates the current borrow rate per block
   * @param _cash The amount of cash in the market
   * @param _borrows The amount of borrows in the market
   * @param _reserves The amount of reserves in the market
   * @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
   */
  function getBorrowRate(uint256 _cash, uint256 _borrows, uint256 _reserves) external view override returns (uint256) {
    return getBorrowRateInternal(_cash, _borrows, _reserves);
  }

  /**
   * @notice Construct an interest rate model
   * @param baseRatePerYear_ The approximate target base APR, as a mantissa (scaled by 1e18)
   * @param multiplierPerYear_ The rate of increase in interest rate wrt utilization (scaled by 1e18)
   * @param jumpMultiplierPerYear1_ The _jumpMultiplierPerYear1 after hitting a specified utilization point
   * @param jumpMultiplierPerYear2_ The _jumpMultiplierPerYear2 after hitting a specified utilization point
   * @param kink1_ The utilization point at which the jump multiplier 1 is applied
   * @param kink2_ The utilization point at which the jump multiplier 2 is applied
   * @param blocksPerYear_ Approximation of blocks per year based on the chain's block time
   */
  constructor(
    uint256 baseRatePerYear_,
    uint256 multiplierPerYear_,
    uint256 jumpMultiplierPerYear1_,
    uint256 jumpMultiplierPerYear2_,
    uint256 kink1_,
    uint256 kink2_,
    uint256 blocksPerYear_
  ) BaseDoubleJumpRateModel(blocksPerYear_) {
    govUpdateJumpRateModel(
      baseRatePerYear_,
      multiplierPerYear_,
      jumpMultiplierPerYear1_,
      jumpMultiplierPerYear2_,
      kink1_,
      kink2_
    );
  }
}