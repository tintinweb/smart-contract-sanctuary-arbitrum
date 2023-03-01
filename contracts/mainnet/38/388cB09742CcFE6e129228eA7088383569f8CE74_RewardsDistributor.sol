// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import "./libraries/Math.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IRewardsDistributor.sol";
import "./interfaces/IVotingEscrow.sol";

/*
@title Curve Fee Distribution modified for ve(3,3) emissions
@author Curve Finance, andrecronje
@license MIT
*/

contract RewardsDistributor is IRewardsDistributor {
    event CheckpointToken(uint256 time, uint256 tokens);

    event Claimed(
        uint256 tokenId,
        uint256 amount,
        uint256 claimEpoch,
        uint256 maxEpoch
    );

    uint256 constant WEEK = 7 * 86400;

    uint256 public startTime;
    uint256 public timeCursor;
    mapping(uint256 => uint256) public timeCursorOf;
    mapping(uint256 => uint256) public userEpochOf;

    uint256 public lastTokenTime;
    uint256[1000000000000000] public tokensPerWeek;
    uint256 public tokenLastBalance;
    uint256[1000000000000000] public veSupply;

    address public owner;
    address public votingEscrow;
    address public token;
    address public depositor;

    constructor(address _votingEscrow) {
        uint256 _t = (block.timestamp / WEEK) * WEEK;
        startTime = _t;
        lastTokenTime = _t;
        timeCursor = _t;
        address _token = IVotingEscrow(_votingEscrow).token();
        token = _token;
        votingEscrow = _votingEscrow;
        depositor = msg.sender;
        owner = msg.sender;
        require(IERC20(_token).approve(_votingEscrow, type(uint256).max));
    }

    function timestamp() external view returns (uint256) {
        return (block.timestamp / WEEK) * WEEK;
    }

    function _checkPointToken() internal {
        uint256 token_balance = IERC20(token).balanceOf(address(this));
        uint256 toDistribute = token_balance - tokenLastBalance;
        tokenLastBalance = token_balance;

        uint256 t = lastTokenTime;
        uint256 since_last = block.timestamp - t;
        lastTokenTime = block.timestamp;
        uint256 this_week = (t / WEEK) * WEEK;
        uint256 next_week = 0;

        for (uint256 i = 0; i < 20; i++) {
            next_week = this_week + WEEK;
            if (block.timestamp < next_week) {
                if (since_last == 0 && block.timestamp == t) {
                    tokensPerWeek[this_week] += toDistribute;
                } else {
                    tokensPerWeek[this_week] +=
                        (toDistribute * (block.timestamp - t)) /
                        since_last;
                }
                break;
            } else {
                if (since_last == 0 && next_week == t) {
                    tokensPerWeek[this_week] += toDistribute;
                } else {
                    tokensPerWeek[this_week] +=
                        (toDistribute * (next_week - t)) /
                        since_last;
                }
            }
            t = next_week;
            this_week = next_week;
        }
        emit CheckpointToken(block.timestamp, toDistribute);
    }

    function checkPointToken() external {
        assert(msg.sender == depositor);
        _checkPointToken();
    }

    function _find_timestamp_epoch(address ve, uint256 _timestamp)
        internal
        view
        returns (uint256)
    {
        uint256 _min = 0;
        uint256 _max = IVotingEscrow(ve).epoch();
        for (uint256 i = 0; i < 128; i++) {
            if (_min >= _max) break;
            uint256 _mid = (_min + _max + 2) / 2;
            IVotingEscrow.Point memory pt = IVotingEscrow(ve).pointHistory(
                _mid
            );
            if (pt.ts <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    function _findTimestampUserEpoch(
        address ve,
        uint256 tokenId,
        uint256 _timestamp,
        uint256 maxUserEpoch
    ) internal view returns (uint256) {
        uint256 _min = 0;
        uint256 _max = maxUserEpoch;
        for (uint256 i = 0; i < 128; i++) {
            if (_min >= _max) break;
            uint256 _mid = (_min + _max + 2) / 2;
            IVotingEscrow.Point memory pt = IVotingEscrow(ve).userPointHistory(
                tokenId,
                _mid
            );
            if (pt.ts <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    function ve_for_at(uint256 _tokenId, uint256 _timestamp)
        external
        view
        returns (uint256)
    {
        address ve = votingEscrow;
        uint256 maxUserEpoch = IVotingEscrow(ve).userPointEpoch(_tokenId);
        uint256 epoch = _findTimestampUserEpoch(
            ve,
            _tokenId,
            _timestamp,
            maxUserEpoch
        );
        IVotingEscrow.Point memory pt = IVotingEscrow(ve).userPointHistory(
            _tokenId,
            epoch
        );
        return
            Math.max(
                uint256(
                    int256(
                        pt.bias -
                            pt.slope *
                            (int128(int256(_timestamp - pt.ts)))
                    )
                ),
                0
            );
    }

    function _checkPointTotalSupply() internal {
        address ve = votingEscrow;
        uint256 t = timeCursor;
        uint256 rounded_timestamp = (block.timestamp / WEEK) * WEEK;
        IVotingEscrow(ve).checkpoint();

        for (uint256 i = 0; i < 20; i++) {
            if (t > rounded_timestamp) {
                break;
            } else {
                uint256 epoch = _find_timestamp_epoch(ve, t);
                IVotingEscrow.Point memory pt = IVotingEscrow(ve).pointHistory(
                    epoch
                );
                int128 dt = 0;
                if (t > pt.ts) {
                    dt = int128(int256(t - pt.ts));
                }
                veSupply[t] = Math.max(
                    uint256(int256(pt.bias - pt.slope * dt)),
                    0
                );
            }
            t += WEEK;
        }
        timeCursor = t;
    }

    function checkPointTotalSupply() external {
        _checkPointTotalSupply();
    }

    function _claim(
        uint256 _tokenId,
        address ve,
        uint256 _lastTokenTime
    ) internal returns (uint256) {
        uint256 userEpoch = 0;
        uint256 toDistribute = 0;

        uint256 maxUserEpoch = IVotingEscrow(ve).userPointEpoch(_tokenId);
        uint256 _startTime = startTime;

        if (maxUserEpoch == 0) return 0;

        uint256 weekCursor = timeCursorOf[_tokenId];
        if (weekCursor == 0) {
            userEpoch = _findTimestampUserEpoch(
                ve,
                _tokenId,
                _startTime,
                maxUserEpoch
            );
        } else {
            userEpoch = userEpochOf[_tokenId];
        }

        if (userEpoch == 0) userEpoch = 1;

        IVotingEscrow.Point memory user_point = IVotingEscrow(ve)
            .userPointHistory(_tokenId, userEpoch);

        if (weekCursor == 0)
            weekCursor = ((user_point.ts + WEEK - 1) / WEEK) * WEEK;
        if (weekCursor >= lastTokenTime) return 0;
        if (weekCursor < _startTime) weekCursor = _startTime;

        IVotingEscrow.Point memory oldUserPoint;

        for (uint256 i = 0; i < 50; i++) {
            if (weekCursor >= _lastTokenTime) break;

            if (weekCursor >= user_point.ts && userEpoch <= maxUserEpoch) {
                userEpoch += 1;
                oldUserPoint = user_point;
                if (userEpoch > maxUserEpoch) {
                    user_point = IVotingEscrow.Point(0, 0, 0, 0);
                } else {
                    user_point = IVotingEscrow(ve).userPointHistory(
                        _tokenId,
                        userEpoch
                    );
                }
            } else {
                int128 dt = int128(int256(weekCursor - oldUserPoint.ts));
                uint256 balance_of = Math.max(
                    uint256(
                        int256(oldUserPoint.bias - dt * oldUserPoint.slope)
                    ),
                    0
                );
                if (balance_of == 0 && userEpoch > maxUserEpoch) break;
                if (balance_of != 0) {
                    toDistribute +=
                        (balance_of * tokensPerWeek[weekCursor]) /
                        veSupply[weekCursor];
                }
                weekCursor += WEEK;
            }
        }

        userEpoch = Math.min(maxUserEpoch, userEpoch - 1);
        userEpochOf[_tokenId] = userEpoch;
        timeCursorOf[_tokenId] = weekCursor;

        emit Claimed(_tokenId, toDistribute, userEpoch, maxUserEpoch);

        return toDistribute;
    }

    function _claimable(
        uint256 _tokenId,
        address ve,
        uint256 _lastTokenTime
    ) internal view returns (uint256) {
        uint256 userEpoch = 0;
        uint256 toDistribute = 0;

        uint256 maxUserEpoch = IVotingEscrow(ve).userPointEpoch(_tokenId);
        uint256 _startTime = startTime;

        if (maxUserEpoch == 0) return 0;

        uint256 weekCursor = timeCursorOf[_tokenId];
        if (weekCursor == 0) {
            userEpoch = _findTimestampUserEpoch(
                ve,
                _tokenId,
                _startTime,
                maxUserEpoch
            );
        } else {
            userEpoch = userEpochOf[_tokenId];
        }

        if (userEpoch == 0) userEpoch = 1;

        IVotingEscrow.Point memory user_point = IVotingEscrow(ve)
            .userPointHistory(_tokenId, userEpoch);

        if (weekCursor == 0)
            weekCursor = ((user_point.ts + WEEK - 1) / WEEK) * WEEK;
        if (weekCursor >= lastTokenTime) return 0;
        if (weekCursor < _startTime) weekCursor = _startTime;

        IVotingEscrow.Point memory oldUserPoint;

        for (uint256 i = 0; i < 50; i++) {
            if (weekCursor >= _lastTokenTime) break;

            if (weekCursor >= user_point.ts && userEpoch <= maxUserEpoch) {
                userEpoch += 1;
                oldUserPoint = user_point;
                if (userEpoch > maxUserEpoch) {
                    user_point = IVotingEscrow.Point(0, 0, 0, 0);
                } else {
                    user_point = IVotingEscrow(ve).userPointHistory(
                        _tokenId,
                        userEpoch
                    );
                }
            } else {
                int128 dt = int128(int256(weekCursor - oldUserPoint.ts));
                uint256 balance_of = Math.max(
                    uint256(
                        int256(oldUserPoint.bias - dt * oldUserPoint.slope)
                    ),
                    0
                );
                if (balance_of == 0 && userEpoch > maxUserEpoch) break;
                if (balance_of != 0) {
                    toDistribute +=
                        (balance_of * tokensPerWeek[weekCursor]) /
                        veSupply[weekCursor];
                }
                weekCursor += WEEK;
            }
        }

        return toDistribute;
    }

    function claimable(uint256 _tokenId) external view returns (uint256) {
        uint256 _lastTokenTime = (lastTokenTime / WEEK) * WEEK;
        return _claimable(_tokenId, votingEscrow, _lastTokenTime);
    }

    function claim(uint256 _tokenId) external returns (uint256) {
        if (block.timestamp >= timeCursor) _checkPointTotalSupply();
        uint256 _lastTokenTime = lastTokenTime;
        _lastTokenTime = (_lastTokenTime / WEEK) * WEEK;
        uint256 amount = _claim(_tokenId, votingEscrow, _lastTokenTime);
        if (amount != 0) {
            // if locked.end then send directly
            IVotingEscrow.LockedBalance memory _locked = IVotingEscrow(
                votingEscrow
            ).locked(_tokenId);
            if (_locked.end < block.timestamp) {
                address _nftOwner = IVotingEscrow(votingEscrow).ownerOf(
                    _tokenId
                );
                IERC20(token).transfer(_nftOwner, amount);
            } else {
                IVotingEscrow(votingEscrow).depositFor(_tokenId, amount);
            }
            tokenLastBalance -= amount;
        }
        return amount;
    }

    function claimMany(uint256[] memory _tokenIds) external returns (bool) {
        if (block.timestamp >= timeCursor) _checkPointTotalSupply();
        uint256 _lastTokenTime = lastTokenTime;
        _lastTokenTime = (_lastTokenTime / WEEK) * WEEK;
        address _votingEscrow = votingEscrow;
        uint256 total = 0;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            if (_tokenId == 0) break;
            uint256 amount = _claim(_tokenId, _votingEscrow, _lastTokenTime);
            if (amount != 0) {
                // if locked.end then send directly
                IVotingEscrow.LockedBalance memory _locked = IVotingEscrow(
                    _votingEscrow
                ).locked(_tokenId);
                if (_locked.end < block.timestamp) {
                    address _nftOwner = IVotingEscrow(_votingEscrow).ownerOf(
                        _tokenId
                    );
                    IERC20(token).transfer(_nftOwner, amount);
                } else {
                    IVotingEscrow(_votingEscrow).depositFor(_tokenId, amount);
                }
                total += amount;
            }
        }
        if (total != 0) {
            tokenLastBalance -= total;
        }

        return true;
    }

    function setDepositor(address _depositor) external {
        require(msg.sender == owner);
        depositor = _depositor;
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner);
        owner = _owner;
    }

    function withdrawERC20(address _token) external {
        require(msg.sender == owner);
        require(_token != address(0));
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, _balance);
    }
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IRewardsDistributor {
    function checkPointToken() external;

    function votingEscrow() external view returns (address);

    function checkPointTotalSupply() external;

    function claimable(uint256 _tokenId) external view returns (uint256);
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

    function createLockFor(uint _value, uint _lock_duration, address _to) external returns (uint);

    function locked(uint id) external view returns(LockedBalance memory);
    function tokenOfOwnerByIndex(address _owner, uint _tokenIndex) external view returns (uint);

    function token() external view returns (address);
    function team() external returns (address);
    function epoch() external view returns (uint);
    function pointHistory(uint loc) external view returns (Point memory);
    function userPointHistory(uint tokenId, uint loc) external view returns (Point memory);
    function userPointEpoch(uint tokenId) external view returns (uint);

    function ownerOf(uint) external view returns (address);
    function isApprovedOrOwner(address, uint) external view returns (bool);
    function transferFrom(address, address, uint) external;

    function voted(uint) external view returns (bool);
    function attachments(uint) external view returns (uint);
    function voting(uint tokenId) external;
    function abstain(uint tokenId) external;
    function attach(uint tokenId) external;
    function detach(uint tokenId) external;

    function checkpoint() external;
    function depositFor(uint tokenId, uint value) external;

    function balanceOfNFT(uint _id) external view returns (uint);
    function balanceOf(address _owner) external view returns (uint);
    function totalSupply() external view returns (uint);
    function supply() external view returns (uint);


    function decimals() external view returns(uint8);
}