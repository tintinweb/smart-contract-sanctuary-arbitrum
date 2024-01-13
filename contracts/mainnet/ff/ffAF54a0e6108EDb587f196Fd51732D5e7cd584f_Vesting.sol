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

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IERC20 {
    function decimals() external view returns (uint256);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IVesting {

    event RegisterUser(uint256 totalTokens, address userAddress, uint8 choice);
    
    event ClaimedToken(
        address userAddress,
        uint256 claimedAmount,
        uint32 timestamp,
        uint8 claimCount,
        uint8 choice
    );
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./utils/ReentrancyGuard.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IVesting.sol";

contract Vesting is Ownable, IVesting, ReentrancyGuard {
    address public receiverAddress = 0xC660d57E7947342bE10f0EB7d72E5B9ae30Efe7d;

    address public constant ECOSYSTEM = 0x868D998E80377404D916734d6D533be6F8D38eD0;
    address public constant EXCHANGE = 0x0693e544eDf88fa1D20DB9C53c7ACEFeDa9c0538;
    address public constant TREASURY = 0x9d87e32893c34b50555007b1c9FAF54860592677;
    address public constant TEAM = 0xc025b6AdE2c4880a5d12CD2d877edd243D6ed39A;
    address public constant MARKETING = 0x98150F2e21837719fa5B2522b48bB115058a599E;
    address public constant ADVISORS_COMMITTEE =
        0xB9018e4fB60565eDc69766aE8B594Bc268A5e08F;
    address public constant STRATEGIC_INITIATIVES =
        0x254FDCA420A465d94C383e3FeFEF2e6eb1E240Ca;

    /**
     * User Data Structure for users info like:-
     * Users total amount for claim.
     * Users claimed amount that is till claimed.
     * Users claim for how many times user claims the amount.
     * The Categories are:-
     *      ECOSYSTEM = 1
     *      EXCHANGE = 2
     *      TREASURY = 3
     *      TEAM = 4
     *      MARKETING = 5
     *      ADVISORS_COMMITTEE = 6
     *      STRATEGIC_INITIATIVES = 7
     */
    struct UserData {
        uint256 totalAmount;
        uint256 claimedAmount;
        uint8 claims;
    }

    struct VestingInfo {
        uint32 startTime;
        uint8 claims;
    }

    /* Users Mapping for Users Info. */
    mapping(address => mapping(uint8 => UserData)) public userMapping;

    /*  Time Mapping for Vesting Category to Start.
     */
    mapping(uint8 => VestingInfo) public vestingInfoMapping;
    mapping(uint8 => uint256[]) public percentageArray;

    IERC20 public token; /* Altranium token instance */

    constructor(
        address _tokenAddress
    ) {
        token = IERC20(_tokenAddress);

        percentageArray[1] = [1000];
        percentageArray[2] = [10000];
        percentageArray[3] = [1000];
        percentageArray[4] = [1000];
        percentageArray[5] = [1000, 1500, 1500, 1500, 1500, 1500, 1500];
        percentageArray[6] = [1000];
        percentageArray[7] = [10000];

        uint32 publicSaleEndTime = 1707609599; // end of public sale time

        /* Setting the Vesting time and claims of Categories */
        setVestingCategory(publicSaleEndTime + 90 days, 1, 10); // 90 days
        setVestingCategory(publicSaleEndTime, 2, 1); // ico end time
        setVestingCategory(publicSaleEndTime + 90 days, 3, 10); // 90 days
        setVestingCategory(publicSaleEndTime + 90 days, 4, 10); // 90 days
        setVestingCategory(1706054399, 5, 7); //end of seed sale
        setVestingCategory(publicSaleEndTime + 90 days, 6, 10); // 90 days
        setVestingCategory(uint32(block.timestamp), 7, 1); // ico end time

        /* setup the vesting amount */
        registerUser((1_000_000_000 * (10 ** token.decimals())), 1, ECOSYSTEM);
        registerUser((500_000_000 * (10 ** token.decimals())), 2, EXCHANGE);
        registerUser((800_000_000 * (10 ** token.decimals())), 3, TREASURY);
        registerUser((500_000_000 * (10 ** token.decimals())), 4, TEAM);
        registerUser((1_500_000_000 * (10 ** token.decimals())), 5, MARKETING);
        registerUser(
            (400_000_000 * (10 ** token.decimals())),
            6,
            ADVISORS_COMMITTEE
        );
        registerUser(
            (3_900_000_000 * (10 ** token.decimals())),
            7,
            STRATEGIC_INITIATIVES
        );
    }

    /* Receive Function */
    receive() external payable {
        /* Sending deposited currency to the receiver address */
        TransferHelper.safeTransferETH(receiverAddress, msg.value);
    }

    /* =============== Set Vesting Time and Claims ===============*/
    function setVestingCategory(
        uint32 _time,
        uint8 _choice,
        uint8 _claims
    ) internal {
        VestingInfo storage phase = vestingInfoMapping[_choice];
        phase.startTime = _time;
        phase.claims = _claims;
    }

    /* =============== Register The Address For Claiming ===============*/

    /**
     * Register User for Vesting
     * _amount for Total Claimable Amount
     * _choice for Vesting Category
     * _to for User's Address
     */
    function registerUser(
        uint256 _amount,
        uint8 _choice,
        address _to
    ) internal returns (bool) {
        UserData storage user = userMapping[_to][_choice];

        user.totalAmount += _amount;

        emit RegisterUser(_amount, _to, _choice);

        return (true);
    }

    /* =============== Token Claiming Functions =============== */
    /**
     * User can claim the tokens with claimTokens function.
     * after start the vesting for that particular vesting category.
     */
    function claimTokens(uint8 _choice) external nonReentrant {
        address _msgSender = msg.sender;
        require(
            userMapping[_msgSender][_choice].totalAmount > 0,
            "User is not registered with this vesting."
        );

        (uint256 _amount, uint8 _claimCount) = tokensToBeClaimed(
            _msgSender,
            _choice
        );

        require(_amount > 0, "Nothing to claim right now.");

        UserData storage user = userMapping[_msgSender][_choice];
        user.claimedAmount += _amount;
        user.claims = _claimCount;

        TransferHelper.safeTransfer(address(token), _msgSender, _amount);

        uint8 claims = uint8(vestingInfoMapping[_choice].claims);
        if (claims == _claimCount) {
            delete userMapping[_msgSender][_choice];
        }

        emit ClaimedToken(
            _msgSender,
            _amount,
            uint32(block.timestamp),
            _claimCount,
            _choice
        );
    }

    /* =============== Tokens to be claimed =============== */
    /**
     * tokensToBeClaimed function can be used for checking the claimable amount of the user.
     */
    function tokensToBeClaimed(
        address _to,
        uint8 _choice
    ) public view returns (uint256 _toBeTransfer, uint8 _claimCount) {
        UserData memory user = userMapping[_to][_choice];
        if (
            (block.timestamp < (vestingInfoMapping[_choice].startTime)) ||
            (user.totalAmount == 0)
        ) {
            return (0, 0);
        }

        if (user.totalAmount == user.claimedAmount) {
            return (0, 0);
        }

        uint32 _time = uint32(
            block.timestamp - (vestingInfoMapping[_choice].startTime)
        );
        /* Claim in Ever Month 30 days for main net and 1 minutes for the test */
        _claimCount = uint8((_time / 30 days) + 1);
        uint8 claims = uint8(vestingInfoMapping[_choice].claims);

        if (_claimCount > claims) {
            _claimCount = claims;
        }

        if (_claimCount <= user.claims) {
            return (0, _claimCount);
        }
        if (_claimCount == claims) {
            _toBeTransfer = user.totalAmount - user.claimedAmount;
        } else {
            _toBeTransfer = vestingCalulations(
                user.totalAmount,
                _claimCount,
                user.claims,
                _choice
            );
        }
        return (_toBeTransfer, _claimCount);
    }

    /* =============== Vesting Calculations =============== */
    /**
     * vestingCalulations function is used for calculating the amount of token for claim
     */
    function vestingCalulations(
        uint256 _userTotalAmount,
        uint8 _claimCount,
        uint8 _userClaimCount,
        uint8 _choice
    ) internal view returns (uint256) {
        uint256 amount;

        for (uint8 i = _userClaimCount; i < _claimCount; ++i) {
            if ((percentageArray[_choice]).length == 1) {
                amount +=
                    (_userTotalAmount * (percentageArray[_choice][0])) /
                    10000;
            } else {
                amount +=
                    (_userTotalAmount * (percentageArray[_choice][i])) /
                    10000;
            }
        }

        return amount;
    }

    /* ================ OTHER FUNCTIONS SECTION ================ */
    /* Updates Receiver Address */
    function updateReceiverAddress(
        address _receiverAddress
    ) external onlyOwner {
        require(_receiverAddress != address(0), "Zero address passed.");
        receiverAddress = _receiverAddress;
    }
}