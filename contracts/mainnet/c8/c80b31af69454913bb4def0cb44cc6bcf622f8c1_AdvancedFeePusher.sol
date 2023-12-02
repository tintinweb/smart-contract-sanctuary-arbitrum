/**
 *Submitted for verification at Arbiscan.io on 2023-12-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IGauge {
    function claimFees() external;
}

interface IPool {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function fee() external view returns (uint24);

    function protocolFees()
        external
        view
        returns (uint128 token0, uint128 token1);
}

interface IFeeCollector {
    function collectProtocolFees(address _pool) external;
}

interface IVoter {
    function length() external view returns (uint256);

    function pools(uint256) external view returns (address);

    function gauges(address _pool) external view returns (address);
}

contract AdvancedFeePusher {
    IVoter private constant VOTER =
        IVoter(0xAAA2564DEb34763E3d05162ed3f5C2658691f499);
    IFeeCollector private constant COLLECTOR =
        IFeeCollector(0xAA2ef8a3b34B414F8F7B47183971f18e4F367dC4);
    address private constant OWNER = 0xCAfc58De1E6A071790eFbB6B83b35397023E1544;
    uint256 public iterations = 75;
    uint256 public lastIndex = 0;
    mapping(uint256 => bool) frozen;
    mapping(uint256 => bool) isCL;
    mapping(address => bool) blacklisted;

    ///@notice iteratively claim, then restart at index end
    function claimIterative() external {
        uint256 endIndex = lastIndex + iterations;
        endIndex > _length() ? endIndex = _length() : endIndex = endIndex;
        for (uint256 i = lastIndex; i < endIndex; ++i) {
            if (!isCL[i]) {
                if (!frozen[i]) {
                    IGauge(VOTER.gauges(VOTER.pools(i))).claimFees();
                }
            } else {
                ///@dev this will sometimes fail due to "#LOK" reversion, so try-catch used to proceed
                try COLLECTOR.collectProtocolFees(VOTER.pools(i)) {} catch {}
            }
        }
        ///@dev if the endIndex is the limit, restart the lastIndex to 0
        endIndex == _length() ? lastIndex = 0 : lastIndex = endIndex;
    }

    ///@notice claim batched fees, regardless of v1 or CL status
    function batchClaim(address[] calldata _pools) external {
        for (uint256 i = 0; i < _pools.length; ++i) {
            ///@dev try-catch to determine if a pool is CL or not
            try IPool(_pools[i]).fee() {
                COLLECTOR.collectProtocolFees(_pools[i]);
            } catch {
                IGauge(VOTER.gauges(VOTER.pools(i))).claimFees();
            }
        }
    }

    ///@notice change the iteration limit
    function changeIterations(uint256 _newIterations) external {
        require(msg.sender == OWNER, "!O");
        iterations = _newIterations;
    }

    ///@notice add a token to the blacklist
    function blackList(address _token, bool _status) external {
        require(msg.sender == OWNER, "!O");
        blacklisted[_token] = _status;
    }

    ///@notice periodically call in order to designate poisoned indices and exempt them
    function mapStatus() external {
        for (uint256 i = 0; i < _length(); ++i) {
            if (
                blacklisted[IPool(VOTER.pools(i)).token0()] ||
                blacklisted[IPool(VOTER.pools(i)).token1()]
            ) {
                frozen[i] = true;
                isCL[i] = false;
            } else {
                frozen[i] = false;
                try IPool(VOTER.pools(i)).fee() {
                    isCL[i] = true;
                } catch {
                    isCL[i] = false;
                }
            }
        }
    }

    ///@notice shows the pending fees for a CL pool
    function pendingFees(address _pool)
        public
        view
        returns (
            address _poolID,
            address[] memory _tokens,
            uint128[] memory _amounts
        )
    {
        address[] memory localTokens = new address[](2);
        uint128[] memory localAmounts = new uint128[](2);

        localTokens[0] = IPool(_pool).token0();
        localTokens[1] = IPool(_pool).token1();

        (uint128 amount0, uint128 amount1) = IPool(_pool).protocolFees();
        localAmounts[0] = amount0;
        localAmounts[1] = amount1;

        return (_pool, localTokens, localAmounts);
    }

    ///@notice length of all pools in the voter
    function _length() public view returns (uint256) {
        return VOTER.length();
    }
}