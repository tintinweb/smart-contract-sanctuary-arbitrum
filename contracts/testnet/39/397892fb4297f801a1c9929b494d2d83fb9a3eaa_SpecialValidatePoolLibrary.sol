//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IERC20.sol";

import "./ISpecialPool.sol";

library SpecialValidatePoolLibrary {
    function _preValidatePoolCreation(
        ISpecialPool.PoolModel memory _pool,
        bool _isAdminSale,
        uint256 _allowDateTime
    ) public view {
        require(_pool.hardCap > 0, "hardCap > 0");
        require(_pool.softCap > 0, "softCap > 0");
        require(_pool.softCap < _pool.hardCap, "softCap < hardCap");
        require(
            _pool.softCap >= (_pool.hardCap * 3) / 10,
            "softCap > hardCap*30%"
        );

        require(
            _isAdminSale || address(_pool.projectTokenAddress) != address(0),
            "token is a zero address!"
        );
        require(_pool.specialSaleRate > 0, "specialSaleRate > 0!");
        require(
            _pool.startDateTime >= block.timestamp,
            "startDate fail!"
        );

        require(
            _pool.startDateTime + 1 days <= _pool.endDateTime,
            "start<end!"
        );
        require(_allowDateTime >= _pool.endDateTime, "allow>=end!");
        require(_pool.minAllocationPerUser > 0, "min>0");
        require(
            _pool.minAllocationPerUser <= _pool.maxAllocationPerUser,
            "min<max"
        );
    }

    function _preValidateUserVesting(
        ISpecialPool.UserVesting memory _vesting,
        uint256 _cliff
    ) public pure {
        require(
            !_vesting.isVesting || _vesting.firstPercent > 0,
            "user firstPercent > 0"
        );
        require(
            !_vesting.isVesting || _vesting.eachPeriod >= 1,
            "user period >= 1"
        );
        require(
            !_vesting.isVesting ||
                _vesting.firstPercent + _vesting.eachPercent <= 100,
            "user firstPercent + eachPercent <= 100"
        );
        require(_cliff >= 0 && _cliff <= 365, "0<=cliff<=365");
    }

    function _poolIsOngoing(ISpecialPool.PoolModel memory poolInformation)
        public
        view
    {
        require(
            poolInformation.status == ISpecialPool.PoolStatus.Inprogress,
            "not available!"
        );
        // solhint-disable-next-line not-rely-on-time
        require(
            poolInformation.startDateTime <= block.timestamp,
            "not started!"
        );
        // solhint-disable-next-line not-rely-on-time
        require(poolInformation.endDateTime >= block.timestamp, "ended!");
    }

    function _poolIsUpcoming(ISpecialPool.PoolModel memory poolInformation)
        public
        view
    {
        require(
            poolInformation.status == ISpecialPool.PoolStatus.Inprogress,
            "not available!"
        );
        // solhint-disable-next-line not-rely-on-time
        require(poolInformation.endDateTime > block.timestamp, "ended!");
    }

    function _poolIsFillable(
        ISpecialPool.PoolModel memory poolInformation,
        uint256 _weiRaised
    ) public view {
        require(
            poolInformation.status == ISpecialPool.PoolStatus.Inprogress ||
                poolInformation.status == ISpecialPool.PoolStatus.Collected,
            "not available!"
        );
        // solhint-disable-next-line not-rely-on-time
        require(
            poolInformation.endDateTime >= block.timestamp ||
                poolInformation.softCap <= _weiRaised,
            "started!"
        );
    }

    function _poolIsNotCancelled(ISpecialPool.PoolModel memory _pool)
        public
        pure
    {
        require(
            _pool.status == ISpecialPool.PoolStatus.Inprogress,
            "already cancelled!"
        );
    }

    function _poolIsCancelled(
        ISpecialPool.PoolModel memory _pool,
        uint256 _weiRaised
    ) public view {
        require(
            _pool.status == ISpecialPool.PoolStatus.Cancelled ||
                (_pool.status == ISpecialPool.PoolStatus.Inprogress &&
                    _pool.endDateTime <= block.timestamp &&
                    _pool.softCap > _weiRaised),
            "not cancelled!"
        );
    }

    function _poolIsReadyCollect(
        ISpecialPool.PoolModel memory _pool,
        uint256 _weiRaised,
        address poolAddress,
        address fundRaiseToken,
        bool _isAdminSale
    ) public view {
        if (!_isAdminSale) {
            require(
                (_pool.endDateTime <= block.timestamp &&
                    _pool.status == ISpecialPool.PoolStatus.Inprogress &&
                    _pool.softCap <= _weiRaised) ||
                    (_pool.status == ISpecialPool.PoolStatus.Inprogress &&
                        _pool.hardCap == _weiRaised &&
                        _pool.startDateTime + 24 hours <= block.timestamp),
                "not finalized!"
            );
        } else {
            require(
                (_pool.endDateTime <= block.timestamp &&
                    _pool.status == ISpecialPool.PoolStatus.Inprogress &&
                    _pool.softCap <= _weiRaised) ||
                    (_pool.status == ISpecialPool.PoolStatus.Inprogress &&
                        _pool.hardCap == _weiRaised),
                "not finalized!"
            );
        }

        if (fundRaiseToken == address(0))
            require(payable(poolAddress).balance > 0, "collected!");
        else {
            IERC20 _token = IERC20(fundRaiseToken);
            require(_token.balanceOf(poolAddress) > 0, "collected!");
        }
    }

    function _poolIsReadyAllow(
        ISpecialPool.PoolModel memory _pool,
        uint256 allowDateTime
    ) public view {
        require(
            _pool.status == ISpecialPool.PoolStatus.Collected &&
                allowDateTime <= block.timestamp,
            "not finalized!"
        );
    }

    function _poolIsAllowed(ISpecialPool.PoolModel memory _pool) public pure {
        require(
            _pool.status == ISpecialPool.PoolStatus.Allowed,
            "not allowed!"
        );
    }

    function _hardCapNotPassed(
        uint256 _hardCap,
        uint256 _weiRaised,
        address fundRaiseToken,
        uint256 amount
    ) public view {
        uint256 _beforeBalance = _weiRaised;
        uint256 sum;
        if (fundRaiseToken == address(0)) {
            sum = _weiRaised + msg.value;
        } else {
            sum = _weiRaised + amount;
        }
        require(sum <= _hardCap, "hardCap!");
        require(sum > _beforeBalance, "hardCap overflow!");
    }

    function _minAllocationNotPassed(
        uint256 _minAllocationPerUser,
        uint256 _weiRaised,
        uint256 hardCap,
        uint256 collaboration,
        address fundRaiseToken,
        uint256 amount
    ) public view {
        uint256 aa;
        if (fundRaiseToken == address(0)) {
            aa = collaboration + msg.value;
        } else {
            aa = collaboration + amount;
        }

        require(
            hardCap - _weiRaised < _minAllocationPerUser ||
                _minAllocationPerUser <= aa,
            "Less!"
        );
    }

    function _maxAllocationNotPassed(
        uint256 _maxAllocationPerUser,
        uint256 collaboration,
        address fundRaiseToken,
        uint256 amount
    ) public view {
        uint256 aa;
        if (fundRaiseToken == address(0)) {
            aa = collaboration + msg.value;
        } else {
            aa = collaboration + amount;
        }
        require(aa <= _maxAllocationPerUser, "More!");
    }

    function _onlyFactory(address sender, address factory) public pure {
        require(factory == sender, "Not factory!");
    }
}