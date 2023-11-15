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
pragma solidity 0.8.13;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IMinter {
    function update_period() external returns (uint);
    function check() external view returns(bool);
    function period() external view returns(uint);
    function active_period() external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IRewardsDistributor {
    function claim(uint _tokenId) external returns(uint);
    function checkpoint_token() external;
    function voting_escrow() external view returns(address);
    function checkpoint_total_supply() external;
    function claimable(uint _tokenId) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IVotingEscrow {

    struct Point {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    struct LockedBalance {
        int128 amount;
        uint end;
    }

    function create_lock(uint _value, uint _lock_duration) external returns (uint);
    function create_lock_for(uint _value, uint _lock_duration, address _to) external returns (uint);
    function merge(uint _from, uint _to) external;
    function increase_amount(uint _tokenId, uint _value) external;
    function increase_unlock_time(uint _tokenId, uint _lock_duration) external;
    function split(uint[] memory amounts, uint _tokenId) external;
    function withdraw(uint _tokenId) external;
    function setApprovalForAll(address _operator, bool _approved) external;

    function locked(uint id) external view returns(LockedBalance memory);
    function tokenOfOwnerByIndex(address _owner, uint _tokenIndex) external view returns (uint);

    function token() external view returns (address);
    function team() external returns (address);
    function epoch() external view returns (uint);
    function point_history(uint loc) external view returns (Point memory);
    function user_point_history(uint tokenId, uint loc) external view returns (Point memory);
    function user_point_epoch(uint tokenId) external view returns (uint);

    function ownerOf(uint) external view returns (address);
    function isApprovedOrOwner(address, uint) external view returns (bool);
    function transferFrom(address, address, uint) external;
    function safeTransferFrom(
        address _from,
        address _to,
        uint _tokenId
    ) external;

    function voted(uint) external view returns (bool);
    function attachments(uint) external view returns (uint);
    function voting(uint tokenId) external;
    function abstain(uint tokenId) external;
    function attach(uint tokenId) external;
    function detach(uint tokenId) external;

    function checkpoint() external;
    function deposit_for(uint tokenId, uint value) external;

    function balanceOfNFT(uint _id) external view returns (uint);
    function balanceOf(address _owner) external view returns (uint);
    function totalSupply() external view returns (uint);
    function supply() external view returns (uint);
    function balanceOfNFTAt(uint _tokenId, uint _t) external view returns (uint);
    function balanceOfAtNFT(uint _tokenId, uint _t) external view returns (uint);



    function decimals() external view returns(uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library Math {
    function max(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
    function cbrt(uint256 n) internal pure returns (uint256) { unchecked {
        uint256 x = 0;
        for (uint256 y = 1 << 255; y > 0; y >>= 3) {
            x <<= 1;
            uint256 z = 3 * x * (x + 1) + 1;
            if (n / y >= z) {
                n -= y * z;
                x += 1;
            }
        }
        return x;
    }}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import './libraries/Math.sol';
import './interfaces/IERC20.sol';
import './interfaces/IRewardsDistributor.sol';
import './interfaces/IVotingEscrow.sol';
import './interfaces/IMinter.sol';

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/*

@title Curve Fee Distribution modified for ve(3,3) emissions
@author Thena Finance, Prometheus
@license MIT

*/

contract RewardsDistributorV2 is ReentrancyGuard, IRewardsDistributor {

    event CheckpointToken(
        uint time,
        uint tokens
    );

    event Claimed(
        uint tokenId,
        uint amount,
        uint claim_epoch, //timestamp
        uint max_epoch
    );

    uint constant WEEK = 7 * 86400;

    uint public start_time;
    uint public last_token_time;
    uint public last_week;
    uint public total_distributed;
    uint public token_claimed;
    uint public time_cursor;


    uint[1000000000000000] public tokens_per_week;
    uint[1000000000000000] public ve_supply;

    address public owner;
    address public voting_escrow;
    address public token;
    address public depositor;
    bool public permissionedClaims = true;

    
    mapping(uint => uint) public time_cursor_of;
    mapping(uint => uint) internal time_to_block;

  

    constructor(address _voting_escrow, address _minter) {
        uint _t = block.timestamp / WEEK * WEEK;
        last_token_time = _t;
        time_cursor = _t;
        
        address _token = IVotingEscrow(_voting_escrow).token();
        token = _token;

        voting_escrow = _voting_escrow;

        depositor = _minter;
        start_time = _t;

        owner = msg.sender;

        require(IERC20(_token).approve(_voting_escrow, type(uint).max));
    }

    function timestamp() public view returns (uint) {
        return block.timestamp / WEEK * WEEK;
    }

    // checkpoint the total supply at the current timestamp. Called by depositor
    function checkpoint_total_supply() external {
        assert(msg.sender == depositor || msg.sender == owner);
        _checkpoint_total_supply();
    }
    function _checkpoint_total_supply() internal {
        address ve = voting_escrow;
        uint t = time_cursor;
        uint rounded_timestamp = block.timestamp / WEEK * WEEK;
        IVotingEscrow(ve).checkpoint();

        for (uint i = 0; i < 20; i++) {
            if (t > rounded_timestamp) {
                break;
            } else {
                uint epoch = _find_timestamp_epoch(ve, t);
                IVotingEscrow.Point memory pt = IVotingEscrow(ve).point_history(epoch);
                int128 dt = 0;
                if (t > pt.ts) {
                    dt = int128(int256(t - pt.ts));
                }
                ve_supply[t] = Math.max(uint(int256(pt.bias - pt.slope * dt)), 0);
            }
            t += WEEK;
        }

        time_cursor = t;
    }

    
    function _find_timestamp_epoch(address ve, uint _timestamp) internal view returns (uint) {
        uint _min = 0;
        uint _max = IVotingEscrow(ve).epoch();
        for (uint i = 0; i < 128; i++) {
            if (_min >= _max) break;
            uint _mid = (_min + _max + 2) / 2;
            IVotingEscrow.Point memory pt = IVotingEscrow(ve).point_history(_mid);
            if (pt.ts <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }



    // checkpoint the token to distribute for the last epoch
    function checkpoint_token() external {
        assert(msg.sender == depositor || msg.sender == owner);
        _checkpoint_token();
    }

    function _checkpoint_token() internal {

        last_week = block.timestamp / WEEK * WEEK;
        time_to_block[last_week] = block.number;
        last_token_time = block.timestamp;
        
        uint token_balance = IERC20(token).balanceOf(address(this));
        uint diff = total_distributed - token_claimed;
        uint to_distribute = token_balance - diff;
        
        tokens_per_week[last_week] += to_distribute;
        total_distributed += to_distribute;

        emit CheckpointToken(block.timestamp, to_distribute);
    }
  

    
    function claimable(uint _tokenId) external view returns(uint) {
        uint t = time_cursor_of[_tokenId];
        if(t == 0) t = start_time;
        uint _last_week = last_week;
        uint to_claim = 0;
        for(uint i = 0; i < 100; i++){
            if(t > _last_week) break;
            to_claim += _toClaim(_tokenId, t);
            t += WEEK;
        }        
        return to_claim;
    }
        

    function claim_many(uint[] memory tokenIds) external nonReentrant returns(bool) {
        require(tokenIds.length <= 25);
        for(uint i = 0; i < tokenIds.length; i++){
            _claim(tokenIds[i]);
        }
        return true;
    }

    function claim(uint _tokenId) external nonReentrant returns(uint){
        return _claim(_tokenId);
    }

    function _claim(uint _tokenId) internal returns (uint) {
        if(permissionedClaims){
            require(IVotingEscrow(voting_escrow).isApprovedOrOwner(msg.sender, _tokenId), 'not approved');
        }

        IVotingEscrow.LockedBalance memory _locked = IVotingEscrow(voting_escrow).locked(_tokenId);
        require(_locked.amount > 0, 'No existing lock found');
        require(_locked.end > block.timestamp, 'Cannot add to expired lock. Withdraw');

        uint t = time_cursor_of[_tokenId];
        if(t < start_time) t = start_time;
        uint _last_week = last_week;
        uint to_claim = 0;

        for(uint i = 0; i < 100; i++){
            if(t > _last_week) break;
            to_claim += _toClaim(_tokenId, t);
            t += WEEK;
        }        

        if(to_claim > 0) IVotingEscrow(voting_escrow).deposit_for(_tokenId, to_claim);
        time_cursor_of[_tokenId] = t;
        token_claimed += to_claim;

        emit Claimed(_tokenId, to_claim, last_week, _find_timestamp_epoch(voting_escrow, last_week));

        return to_claim;
    }

    function _toClaim(uint id, uint t) internal view returns(uint to_claim) {

        IVotingEscrow.Point memory userData = IVotingEscrow(voting_escrow).user_point_history(id,1);

        if(ve_supply[t] == 0) return 0;
        if(tokens_per_week[t] == 0) return 0;
        if(userData.ts > t) return 0;

        //uint id_bal = IVotingEscrow(voting_escrow).balanceOfNFTAt(id, t);
        uint id_bal = IVotingEscrow(voting_escrow).balanceOfAtNFT(id, time_to_block[t]);
        uint share =  id_bal * 1e18 / ve_supply[t];
        
        to_claim = share * tokens_per_week[t] / 1e18;
    }

    /*  Owner Functions */

    function setDepositor(address _depositor) external {
        require(msg.sender == owner);
        depositor = _depositor;
    }

    function setPermissionedClaims(bool value) external {
        require(msg.sender == owner);
        permissionedClaims = value;
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner);
        owner = _owner;
    }

    function increaseOrRemoveAllowances(bool what) external {
        require(msg.sender == owner);
        what == true ? IERC20(token).approve(voting_escrow, type(uint).max) : IERC20(token).approve(voting_escrow, 0);
    }

    function withdrawERC20(address _token) external {
        require(msg.sender == owner);
        require(_token != address(0));
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, _balance);
    }


}