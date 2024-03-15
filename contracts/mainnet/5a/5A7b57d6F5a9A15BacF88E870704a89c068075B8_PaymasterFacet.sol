// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import {IPaymasterFacet} from "../interfaces/internal/IPaymasterFacet.sol";

contract PaymasterFacet is IPaymasterFacet {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.Paymaster.diamond.storage");
    struct Paymaster {
        //paymaster balance
        mapping(address => uint256) walletPaymasterBalance;
        address payer;
        mapping(address => uint256) quotaWhiteList;
        mapping(address => bool) minerList;
        bool openValidMiner; // true：verify  miner address  in  minerList
    }

    function diamondStorage() internal pure returns (Paymaster storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    //-paymaster
    function setWalletPaymasterBalance(
        address _wallet,
        uint256 _amount,
        bool _type
    ) external {
        Paymaster storage ds = diamondStorage();
        if (_type) {
            ds.walletPaymasterBalance[_wallet] += _amount;
        } else {
            require(
                ds.walletPaymasterBalance[_wallet] >= _amount,
                "Paymaster:balance not enough"
            );
            ds.walletPaymasterBalance[_wallet] -= _amount;
        }
        emit SetWalletPaymasterBalance(_wallet, _amount, _type);
    }

    function getWalletPaymasterBalance(
        address _wallet
    ) external view returns (uint256) {
        Paymaster storage ds = diamondStorage();
        return ds.walletPaymasterBalance[_wallet];
    }

    function setPayer(address _payer) external {
        Paymaster storage ds = diamondStorage();
        ds.payer = _payer;
    }

    function getPayer() external view returns (address) {
        Paymaster storage ds = diamondStorage();
        return ds.payer;
    }

    function setQuotaWhiteList(
        uint8 _type,
        address _target,
        uint256 _amount
    ) external {
        Paymaster storage ds = diamondStorage();
        if (_type == 2) {} else if (_type == 1) {
            ds.quotaWhiteList[_target] += _amount;
        } else if (_type == 0) {
            require(
                ds.quotaWhiteList[_target] >= _amount,
                "Paymaster:quota not enough"
            );
            ds.quotaWhiteList[_target] -= _amount;
        }
        emit SetQuotaWhiteList(_type, _target, _amount);
    }

    function getQuota(address _target) external view returns (uint256) {
        Paymaster storage ds = diamondStorage();
        return ds.quotaWhiteList[_target];
    }

    //---miner---
    function setOpenValidMiner(bool _openValidMiner) external {
        Paymaster storage ds = diamondStorage();
        ds.openValidMiner = _openValidMiner;
        emit SetOpenValidMiner(_openValidMiner);
    }

    function getOpenValidMiner() external view returns (bool) {
        Paymaster storage ds = diamondStorage();
        return ds.openValidMiner;
    }

    function setMinerList(
        address[] memory _addMiners,
        address[] memory _delMiners
    ) external {
        Paymaster storage ds = diamondStorage();
        for (uint256 i; i < _delMiners.length; i++) {
            ds.minerList[_delMiners[i]] = false;
        }
        for (uint256 i; i < _addMiners.length; i++) {
            ds.minerList[_addMiners[i]] = true;
        }
        emit SetMinerList(_addMiners, _delMiners);
    }

    function getMinerStatus(address _miner) external view returns (bool) {
        Paymaster storage ds = diamondStorage();
        return ds.minerList[_miner];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IPaymasterFacet {
    struct DepositInfo {
        address wallet;
        string protocol;
        uint256 positionType;
        address sendAsset;
        address receiveAsset;
        uint256 adapterType;
        uint256 amountIn;
        uint256 amountLimit;
        uint256 approveAmount;
        bytes adapterData;
    }
    event SetOpenValidMiner(bool _openValidMiner);
    event SetMinerList(address[] _addMiners, address[] _delMiners);
    event SetQuotaWhiteList(uint8 _type, address _target, uint256 _amount);
    event SetWalletPaymasterBalance(
        address _wallet,
        uint256 _amount,
        bool _type
    );

    function setWalletPaymasterBalance(
        address _wallet,
        uint256 _amount,
        bool _type
    ) external;

    function getWalletPaymasterBalance(
        address _wallet
    ) external view returns (uint256);

    function setPayer(address _payer) external;

    function getPayer() external view returns (address);

    function setQuotaWhiteList(
        uint8 _type,
        address _target,
        uint256 _amount
    ) external;

    function getQuota(address _target) external view returns (uint256);

    function setOpenValidMiner(bool _openValidMiner) external;

    function getOpenValidMiner() external view returns (bool);

    function setMinerList(
        address[] memory _addMiners,
        address[] memory _delMiners
    ) external;

    function getMinerStatus(address _miner) external view returns (bool);
}