// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

contract VotingEscrowStateOracle {
    struct LockedBalance {
        int256 amount;
        uint256 end;
    }

    struct Point {
        int256 bias;
        int256 slope;
        uint256 ts;
        uint256 blk;
    }

    uint256 public constant _DAY = 86400; // all future times are rounded by week
    uint256 public constant WEEK = 7 * _DAY; // all future times are rounded by week

    address public immutable ANYCALL;

    mapping(address => LockedBalance) public locked;

    //everytime user deposit/withdraw/change_locktime, these values will be updated;
    uint256 public epoch;
    mapping(uint256 => Point) public supplyPointHistory; // epoch -> unsigned point.
    mapping(address => mapping(uint256 => Point)) public userPointHistory; // user -> Point[user_epoch]
    mapping(address => uint256) public userPointEpoch;
    mapping(uint256 => int256) public slopeChanges; // time -> signed slope change

    constructor(address _anycall) {
        ANYCALL = _anycall;
        supplyPointHistory[0] = Point({bias: 0, slope: 0, ts: block.timestamp, blk: block.number});
    }

    function balanceOf(address _user) external view returns (uint256) {
        return balanceOf(_user, block.timestamp);
    }

    function balanceOf(address _user, uint256 _timestamp) public view returns (uint256) {
        uint256 _epoch = userPointEpoch[_user];
        if (_epoch == 0) {
            return 0;
        }
        Point memory lastPoint = userPointHistory[_user][_epoch];
        lastPoint.bias -= lastPoint.slope * abi.decode(abi.encode(_timestamp - lastPoint.ts), (int128));
        if (lastPoint.bias < 0) {
            return 0;
        }
        return abi.decode(abi.encode(lastPoint.bias), (uint256));
    }

    function totalSupply() external view returns (uint256) {
        return totalSupply(block.timestamp);
    }

    function totalSupply(uint256 _timestamp) public view returns (uint256) {
        Point memory lastPoint = supplyPointHistory[epoch];
        uint256 t_i = (lastPoint.ts / WEEK) * WEEK; // value in the past
        for (uint256 i = 0; i < 255; i++) {
            t_i += WEEK; // + week
            int256 dSlope = 0;
            if (t_i > _timestamp) {
                t_i = _timestamp;
            } else {
                dSlope = slopeChanges[t_i];
                if (dSlope == 0) {
                    break;
                }
            }
            lastPoint.bias -= lastPoint.slope * abi.decode(abi.encode(t_i - lastPoint.ts), (int128));
            if (t_i == _timestamp) {
                break;
            }
            lastPoint.slope += dSlope;
            lastPoint.ts = t_i;
        }

        if (lastPoint.bias < 0) {
            return 0;
        }
        return abi.decode(abi.encode(lastPoint.bias), (uint256));
    }

    function submitState(
        address _user,
        uint256 _epoch,
        uint256 _userPointEpoch,
        LockedBalance calldata _locked,
        Point calldata _supplyPoint,
        Point calldata _userPoint
    ) external {
        require(msg.sender == ANYCALL, "Only callable by AnyCall.");
        locked[_user] = _locked;
        supplyPointHistory[_epoch] = _supplyPoint;
        userPointHistory[_user][_userPointEpoch] = _userPoint;
    }
}