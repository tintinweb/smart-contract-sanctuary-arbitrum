// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IReserveFreeVester {
    function depositForAccount(address _account, uint256 _amount) external;
    function claimForAccount(address _account, address _receiver) external returns (uint256);
    function getMaxVestableAmount(address _account) external view returns (uint256);
    function usedAmounts(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IVester {
    function rewardTracker() external view returns (address);

    function claimForAccount(address _account, address _receiver) external returns (uint256);

    function claimable(address _account) external view returns (uint256);
    function cumulativeClaimAmounts(address _account) external view returns (uint256);
    function claimedAmounts(address _account) external view returns (uint256);
    function pairAmounts(address _account) external view returns (uint256);
    function getVestedAmount(address _account) external view returns (uint256);
    function transferredAverageStakedAmounts(address _account) external view returns (uint256);
    function transferredCumulativeRewards(address _account) external view returns (uint256);
    function cumulativeRewardDeductions(address _account) external view returns (uint256);
    function bonusRewards(address _account) external view returns (uint256);

    function transferStakeValues(address _sender, address _receiver) external;
    function setTransferredAverageStakedAmounts(address _account, uint256 _amount) external;
    function setTransferredCumulativeRewards(address _account, uint256 _amount) external;
    function setCumulativeRewardDeductions(address _account, uint256 _amount) external;
    function setBonusRewards(address _account, uint256 _amount) external;
    function depositForAccount(address _account, uint256 _amount) external;
    function getMaxVestableAmount(address _account) external view returns (uint256);
    function getCombinedAverageStakedAmount(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {Governable} from "../libraries/Governable.sol";
import {IVester} from "./interfaces/IVester.sol";
import {IReserveFreeVester} from "./interfaces/IReserveFreeVester.sol";

contract VesterRouter is ReentrancyGuard, Governable {
    address public immutable vesterNeu;
    address public immutable reserveFreeVester;

    mapping(address => bool) public isHandler;

    event Claim(address receiver, uint256 amount);
    event Deposit(address account, uint256 amount);
    event Withdraw(address account, uint256 claimedAmount, uint256 balance);

    constructor(
        address _vesterNeu,
        address _reserveFreeVester
    ) {
        vesterNeu = _vesterNeu;
        reserveFreeVester = _reserveFreeVester;
    }

    function setHandler(address _handler, bool _isActive) external onlyGov {
        isHandler[_handler] = _isActive;
    }

    function setHandlers(address[] memory _handler, bool[] memory _isActive) external onlyGov {
        for(uint256 i = 0; i < _handler.length; i++){
            isHandler[_handler[i]] = _isActive[i];
        }
    }

    function depositForAccountVesterNeu(address _account, uint256 _amount) external nonReentrant {
        _validateHandler();

        _deposit(_account, _amount);
    }

    function depositVesterNeu(uint256 _amount) external nonReentrant {
        _deposit(msg.sender, _amount);
    }

    function claimVesterNeu() external nonReentrant returns (uint256) {
        return _claim(msg.sender, msg.sender);
    }

    function claimForAccountVesterNeu(address _account, address _receiver) external nonReentrant returns (uint256) {
        _validateHandler();

        return _claim(_account, _receiver);
    }

    function _deposit(address _account, uint256 _amount) private {
        uint256 vestableAmount = IReserveFreeVester(reserveFreeVester).getMaxVestableAmount(_account);
        uint256 usedAmount = IReserveFreeVester(reserveFreeVester).usedAmounts(_account);

        uint256 availableReserveFreeAmount = vestableAmount - usedAmount;

        if (availableReserveFreeAmount == 0) {
            IVester(vesterNeu).depositForAccount(_account, _amount);
            return;
        }

        if(availableReserveFreeAmount >= _amount) {
            IReserveFreeVester(reserveFreeVester).depositForAccount(_account, _amount);
        } else {
            uint256 diff = _amount - availableReserveFreeAmount;

            IReserveFreeVester(reserveFreeVester).depositForAccount(_account, availableReserveFreeAmount);
            IVester(vesterNeu).depositForAccount(_account, diff);
        }
    }

    function _claim(address _account, address _receiver) private returns (uint256) {
        uint256 reserveFreeVesterAmount = IReserveFreeVester(reserveFreeVester).claimForAccount(_account, _receiver);
        uint256 neuVesterAmount = IVester(vesterNeu).claimForAccount(_account, _receiver);

        return reserveFreeVesterAmount + neuVesterAmount;
    }

    function _validateHandler() private view {
        require(isHandler[msg.sender], "Vester: forbidden");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract Governable {
    address public gov;

    constructor() {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        require(_gov != address(0), "Governable: invalid address");
        gov = _gov;
    }
}