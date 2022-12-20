pragma solidity 0.8.17;

import "./interfaces/IRegistry.sol";
import "./interfaces/IMarket.sol";
import "./interfaces/IParameters.sol";

contract PolicyUnlocker {
    uint256 public maxGasPrice = 30 gwei;
    IRegistry immutable registry;
    IParameters immutable param;

    constructor(address _registry, address _parameter) {
        registry = IRegistry(_registry);
        param = IParameters(_parameter);
    }

    function unlockBatch(
        address _targetMarket,
        uint256[] memory _ids
    ) external {
        IMarket _market = IMarket(_targetMarket);

        _market.unlockBatch(_ids);
    }

    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        if (tx.gasprice <= maxGasPrice) {
            (
                address _market,
                uint256[] memory _ids
            ) = _getFirstUnlockablePoolAndIds();

            if (_ids.length != 0) {
                canExec = true;

                execPayload = abi.encodeWithSelector(
                    this.unlockBatch.selector,
                    address(_market),
                    _ids
                );
            } else {
                execPayload = bytes("No Unlockable Policy");
            }
        }
    }

    function manualExecute() external {
        (
            address _market,
            uint256[] memory _ids
        ) = _getFirstUnlockablePoolAndIds();

        if (_ids.length != 0) {
            IMarket(_market).unlockBatch(_ids);
        }
    }

    function _getFirstUnlockablePoolAndIds()
        internal
        view
        returns (address, uint256[] memory)
    {
        address[] memory _markets = _getAllMarkets();
        IMarket _market;
        uint256[] memory _ids;

        for (uint256 i; i < _markets.length; ) {
            _market = IMarket(_markets[i]);
            _ids = _getAllUnlockableIds(_market);

            if (_ids.length != 0) {
                break;
            }

            unchecked {
                ++i;
            }
        }

        return (address(_market), _ids);
    }

    function _getAllMarkets() internal view returns (address[] memory) {
        return registry.getAllPools();
    }

    function _getAllUnlockableIds(
        IMarket _market
    ) internal view returns (uint256[] memory) {
        if (
            _isMarket(_market) &&
            _market.marketStatus() == IMarket.MarketStatus.Trading
        ) {
            uint256 _idCounts = _market.allInsuranceCount();
            uint256 _gracePeriod = param.getUnlockGracePeriod(address(_market));

            uint256[] memory _draftUnlockableIds = new uint256[](_idCounts);
            uint256 _nextSlot;

            for (uint256 i; i < _idCounts; ) {
                IMarket.Insurance memory _insurance = _market.insurances(i);
                uint256 _unlockableTime = uint256(_insurance.endTime) +
                    _gracePeriod;

                if (_insurance.status && _unlockableTime <= block.timestamp) {
                    _draftUnlockableIds[_nextSlot] = i;
                    ++_nextSlot;
                }

                unchecked {
                    ++i;
                }
            }

            uint256[] memory _unlockableIds = new uint256[](_nextSlot);

            for (uint256 i; i < _nextSlot; i++) {
                _unlockableIds[i] = _draftUnlockableIds[i];
            }

            return _unlockableIds;
        }
    }

    function _isMarket(IMarket _market) internal view returns (bool) {
        try _market.marketStatus() returns (IMarket.MarketStatus) {
            return true;
        } catch {}
    }

    function setMaxGasPrice(uint256 _gwei) external {
        maxGasPrice = _gwei * 1 gwei;
    }

    //fnctions for test
    function getFirstUnlockablePoolAndIds()
        external
        view
        returns (address, uint256[] memory)
    {
        return _getFirstUnlockablePoolAndIds();
    }

    function getAllMarkets() external view returns (address[] memory) {
        return _getAllMarkets();
    }

    function getAllUnlockableIds(
        IMarket _market
    ) external view returns (uint256[] memory _unlockableIds) {
        return _getAllUnlockableIds(_market);
    }
}

pragma solidity 0.8.17;

interface IRegistry {
    function getAllPools() external view returns (address[] memory);
}

pragma solidity 0.8.17;

interface IParameters {
    function setVault(address _token, address _vault) external;

    function setRequestDuration(address _address, uint256 _target) external;

    function setUnlockGracePeriod(address _address, uint256 _target) external;

    function setMaxInsureSpan(address _address, uint256 _target) external;

    function setMinInsureSpan(address _address, uint256 _target) external;

    function setUpperSlack(address _address, uint256 _target) external;

    function setLowerSlack(address _address, uint256 _target) external;

    function setWithdrawableDuration(
        address _address,
        uint256 _target
    ) external;

    function setPremiumModel(address _address, address _target) external;

    function setFeeRate(address _address, uint256 _target) external;

    function setMaxList(address _address, uint256 _target) external;

    function setCondition(bytes32 _reference, bytes32 _target) external;

    function getOwner() external view returns (address);

    function getVault(address _token) external view returns (address);

    function getPremium(
        uint256 _amount,
        uint256 _term,
        uint256 _totalLiquidity,
        uint256 _lockedAmount,
        address _target
    ) external view returns (uint256);

    function getFeeRate(address _target) external view returns (uint256);

    function getUpperSlack(address _target) external view returns (uint256);

    function getLowerSlack(address _target) external view returns (uint256);

    function getRequestDuration(
        address _target
    ) external view returns (uint256);

    function getWithdrawableDuration(
        address _target
    ) external view returns (uint256);

    function getUnlockGracePeriod(
        address _target
    ) external view returns (uint256);

    function getMaxInsureSpan(address _target) external view returns (uint256);

    function getMinInsureSpan(address _target) external view returns (uint256);

    function getMaxList(address _target) external view returns (uint256);

    function getCondition(bytes32 _reference) external view returns (bytes32);

    function getPremiumModel(address _market) external view returns (address);
}

pragma solidity 0.8.17;

interface IMarket {
    enum MarketStatus {
        Trading,
        Payingout
    }
    struct Insurance {
        uint256 id; //each insuance has their own id
        uint48 startTime; //timestamp of starttime
        uint48 endTime; //timestamp of endtime
        uint256 amount; //insured amount
        bytes32 target; //target id in bytes32
        address insured; //the address holds the right to get insured
        address agent; //address have control. can be different from insured.
        bool status; //true if insurance is not expired or redeemed
    }

    function marketStatus() external view returns (MarketStatus);

    function allInsuranceCount() external view returns (uint256);

    function insurances(uint256) external view returns (Insurance memory);

    function unlockBatch(uint256[] calldata _ids) external;

    function unlock(uint256 _id) external;
}