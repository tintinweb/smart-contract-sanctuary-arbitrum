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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

struct Milestone {
    uint256 priceOfPeg; ///@dev in terms of usdc
    uint256 usdcRaised; ///@dev usdc raised through usdc donations
    uint256 usdcOfPlsRaised; ///@dev amount of usdc raised through pls donations
    uint256 plsRaised; ///@dev number of pls tokens donated
    uint256 targetAmount; ///@dev total amount of usdc to raise
    uint256 totalUSDCRaised; ///@dev amount of usdc raised through both usdc and pls donations
    uint8 milestoneId;
    bool isCleared;
}

struct User {
    address user;
    uint256 plsDonations;
    uint256 usdcOfPlsDonations;
    uint256 usdcDonations;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { PriceCalculator } from "./library/PriceCalculator.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { ITGE } from "./interfaces/ITGE.sol";
import { User, Milestone } from "./Structs.sol";

contract TGE is ITGE, Ownable {
    using PriceCalculator for uint256;

    uint8 public constant MAX_MILESTONE = 10; ///@dev total milestones
    IERC20 public immutable usdcToken;
    IERC20 public immutable plsToken;

    enum DonationType {
        USDC,
        PLS
    }

    uint8 public currentMilestone;
    bool public hasStarted;
    bool public isPaused;

    mapping(uint8 => Milestone) public milestones;
    mapping(address => mapping(uint8 => bool)) public donatedInMilestone;
    mapping(address => mapping(uint8 => uint256 index)) public userIndex;
    mapping(uint8 => User[]) public users; ///@dev returns users who donated in a milestone
    mapping(address => bool) public userBlacklisted;

    event MilestoneAchieved(uint8 indexed milestone, uint256 indexed targetAchieved);
    event PausedDonation(bool isPaused);
    event SaleStarted(bool hasStarted);
    event USDCDonated(address indexed user, uint8 indexed milestone, uint256 amount);
    event PLSDonated(address user, uint8 indexed milestone, uint256 amount);
    event RefundedExcess(address indexed user, address indexed token, uint256 amountRefunded);

    constructor(address usdc, address pls) {
        usdcToken = IERC20(usdc);
        plsToken = IERC20(pls);

        currentMilestone = 1;

        milestones[1] = Milestone({
            priceOfPeg: 5e5,
            usdcRaised: 0,
            usdcOfPlsRaised: 0,
            plsRaised: 0,
            targetAmount: 200_000e6,
            totalUSDCRaised: 0,
            milestoneId: 1,
            isCleared: false
        });
    }

    function donateUSDC(uint256 amount) public override {
        require(hasStarted, "Too soon");
        require(!isPaused, "Paused");
        require(amount != 0, "Invalid amount");
        if (currentMilestone == MAX_MILESTONE && milestones[currentMilestone].isCleared) revert("Sold out");
        require(usdcToken.transferFrom(msg.sender, address(this), amount), "Transfer Failed");

        _donateUSDC(amount);
    }

    function donatePLS(uint256 amount) public override {
        require(hasStarted, "Too soon");
        require(!isPaused, "Paused");
        require(amount != 0, "Invalid amount");
        if (currentMilestone == MAX_MILESTONE && milestones[currentMilestone].isCleared) revert("Sold out");
        require(plsToken.transferFrom(msg.sender, address(this), amount), "Transfer Failed");

        _donatePLS(amount);
    }

    function _donateUSDC(uint256 amount) private {
        Milestone memory _currentMilestone = milestones[currentMilestone];

        if (_currentMilestone.totalUSDCRaised + amount > _currentMilestone.targetAmount) {
            uint256 amountToDonate = _currentMilestone.targetAmount - _currentMilestone.totalUSDCRaised;
            uint256 excessUSDC = (_currentMilestone.totalUSDCRaised + amount) - _currentMilestone.targetAmount;

            milestones[currentMilestone].usdcRaised += amountToDonate;
            milestones[currentMilestone].totalUSDCRaised += amountToDonate;

            updateUserDonations(DonationType.USDC, amountToDonate, 0);
            emit USDCDonated(msg.sender, currentMilestone, amountToDonate);

            updateMilestone();

            if (_currentMilestone.milestoneId == MAX_MILESTONE) {
                require(usdcToken.transfer(msg.sender, excessUSDC), "refund failed");
                emit RefundedExcess(msg.sender, address(usdcToken), excessUSDC);
            } else {
                _donateUSDC(excessUSDC);
            }
        } else {
            milestones[currentMilestone].usdcRaised += amount;
            milestones[currentMilestone].totalUSDCRaised += amount;

            updateUserDonations(DonationType.USDC, amount, 0);
            emit USDCDonated(msg.sender, currentMilestone, amount);

            updateMilestone();
        }
    }

    function _donatePLS(uint256 amount) private {
        uint256 amountInUSDC = amount.getPlsInUSDC();
        Milestone memory _currentMilestone = milestones[currentMilestone];

        if (_currentMilestone.totalUSDCRaised + amountInUSDC > _currentMilestone.targetAmount) {
            uint256 amountOfUsdcToDonate = _currentMilestone.targetAmount - _currentMilestone.totalUSDCRaised;
            uint256 amountOfPlsToDonate = (amountOfUsdcToDonate * amount) / amountInUSDC;
            uint256 excessPLS = amount - amountOfPlsToDonate;

            milestones[currentMilestone].usdcOfPlsRaised += amountOfUsdcToDonate;
            milestones[currentMilestone].totalUSDCRaised += amountOfUsdcToDonate;
            milestones[currentMilestone].plsRaised += amountOfPlsToDonate;

            updateUserDonations(DonationType.PLS, amountOfUsdcToDonate, amountOfPlsToDonate);
            emit PLSDonated(msg.sender, currentMilestone, amountOfPlsToDonate);

            updateMilestone();

            if (_currentMilestone.milestoneId == MAX_MILESTONE) {
                require(plsToken.transfer(msg.sender, excessPLS), "refund failed");
                emit RefundedExcess(msg.sender, address(plsToken), excessPLS);
            } else {
                _donatePLS(excessPLS);
            }
        } else {
            milestones[currentMilestone].usdcOfPlsRaised += amountInUSDC;
            milestones[currentMilestone].totalUSDCRaised += amountInUSDC;
            milestones[currentMilestone].plsRaised += amount;

            updateUserDonations(DonationType.PLS, amountInUSDC, amount);
            emit PLSDonated(msg.sender, currentMilestone, amount);

            updateMilestone();
        }
    }

    function updateMilestone() private {
        Milestone memory _currentMilestone = milestones[currentMilestone];
        if (_currentMilestone.totalUSDCRaised == _currentMilestone.targetAmount) {
            milestones[currentMilestone].isCleared = true;

            if (currentMilestone != MAX_MILESTONE) {
                uint8 previousMilestone = currentMilestone;
                uint8 newMilestoneId = ++currentMilestone;
                uint256 newMilestoneTarget = _currentMilestone.targetAmount + 40_000e6;

                milestones[newMilestoneId] = Milestone({
                    priceOfPeg: _currentMilestone.priceOfPeg + 1e5,
                    usdcRaised: 0,
                    usdcOfPlsRaised: 0,
                    plsRaised: 0,
                    targetAmount: newMilestoneTarget,
                    totalUSDCRaised: 0,
                    milestoneId: newMilestoneId,
                    isCleared: false
                });

                emit MilestoneAchieved(previousMilestone, _currentMilestone.totalUSDCRaised);
            }
        }
    }

    function updateUserDonations(DonationType donation, uint256 usdcAmount, uint256 plsAmount) private {
        if (donatedInMilestone[msg.sender][currentMilestone]) {
            uint256 index = userIndex[msg.sender][currentMilestone];

            if (donation == DonationType.USDC) {
                users[currentMilestone][index].usdcDonations += usdcAmount;
            } else {
                users[currentMilestone][index].usdcOfPlsDonations += usdcAmount;
                users[currentMilestone][index].plsDonations += plsAmount;
            }
        } else {
            donatedInMilestone[msg.sender][currentMilestone] = true;
            uint256 index = users[currentMilestone].length; //basically a push operation
            userIndex[msg.sender][currentMilestone] = index;

            if (donation == DonationType.USDC) {
                User memory newUser = User({
                    user: msg.sender,
                    plsDonations: 0,
                    usdcOfPlsDonations: 0,
                    usdcDonations: usdcAmount
                });

                users[currentMilestone].push(newUser);
            } else {
                User memory newUser = User({
                    user: msg.sender,
                    plsDonations: plsAmount,
                    usdcOfPlsDonations: usdcAmount,
                    usdcDonations: 0
                });
                users[currentMilestone].push(newUser);
            }
        }
    }

    function startSale() public override onlyOwner {
        hasStarted = true;

        emit SaleStarted(hasStarted);
    }

    function stopSale() public override onlyOwner {
        hasStarted = false;
        emit SaleStarted(hasStarted);
    }

    function pauseDonation() public override onlyOwner {
        isPaused = true;

        emit PausedDonation(isPaused);
    }

    function unPauseDonation() public override onlyOwner {
        if (isPaused) {
            isPaused = false;
        }
        emit PausedDonation(isPaused);
    }

    function getUserDetails(address user) public view override returns (User memory) {
        User memory userDetails;
        userDetails.user = user;
        for (uint8 i = 1; i <= currentMilestone; ++i) {
            if (donatedInMilestone[user][i]) {
                uint256 _userIndex = userIndex[user][i];
                User[] memory _users = users[i];
                User memory userWanted = _users[_userIndex];

                userDetails.plsDonations += userWanted.plsDonations;
                userDetails.usdcDonations += userWanted.usdcDonations;
                userDetails.usdcOfPlsDonations += userWanted.usdcOfPlsDonations;
            }
        }
        return userDetails;
    }

    function getUsersPerMilestone(uint8 milestone) public view override returns (User[] memory) {
        return users[milestone];
    }

    function withdrawUSDC() external override onlyOwner {
        uint256 usdcBalance = IERC20(usdcToken).balanceOf(address(this));
        require(usdcBalance != 0, "zero usdc balance");
        require(usdcToken.transfer(owner(), usdcBalance), "usdc withdrawal failed");
    }

    function withdrawPLS() external override onlyOwner {
        uint256 plsBalance = IERC20(plsToken).balanceOf(address(this));
        require(plsBalance != 0, "zero pls balance");
        require(plsToken.transfer(owner(), plsBalance), "pls withdrawal failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ICamelotFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface ICamelotPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);

    function getAmountOut(uint amountIn, address tokenIn) external view returns (uint);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { User, Milestone } from "../Structs.sol";

interface ITGE {
    function donateUSDC(uint256 amount) external;

    function donatePLS(uint256 amount) external;

    function startSale() external;

    function stopSale() external;

    function pauseDonation() external;

    function unPauseDonation() external;

    function withdrawUSDC() external;

    function withdrawPLS() external;

    function getUsersPerMilestone(uint8 milestone) external view returns (User[] memory);

    function getUserDetails(address user) external view returns (User memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC20, ICamelotFactory, ICamelotPair } from "../interfaces/CamelotInterfaces.sol";

library PriceCalculator {
    ICamelotFactory public constant factory = ICamelotFactory(0x6EcCab422D763aC031210895C81787E87B43A652);
    address public constant USDC_ADDRESS = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address public constant WETH_ADDRESS = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant PLS_ADDRESS = 0x51318B7D00db7ACc4026C88c3952B66278B6A67F;
    address public constant DAI_ADDRESS = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;

    function getPlsInUSDC(uint256 plsAmount) internal view returns (uint256) {
        address wethPlsAdd = factory.getPair(PLS_ADDRESS, WETH_ADDRESS);
        address usdcWethAdd = factory.getPair(WETH_ADDRESS, USDC_ADDRESS);
        ICamelotPair pairWethPls = ICamelotPair(wethPlsAdd);
        ICamelotPair pairUsdcWeth = ICamelotPair(usdcWethAdd);

        uint256 wethAmount = pairWethPls.getAmountOut(plsAmount, PLS_ADDRESS);

        return pairUsdcWeth.getAmountOut(wethAmount, WETH_ADDRESS);
    }
}