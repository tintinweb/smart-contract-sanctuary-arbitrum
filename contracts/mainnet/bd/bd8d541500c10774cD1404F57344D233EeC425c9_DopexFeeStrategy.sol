// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IToken {
    function balanceOf(address _user) external view returns (uint256 _blanace);
}

contract DopexFeeStrategy {
    struct DiscountType {
        address tokenAddress;
        uint256 decimals;
        uint256 maxBalance;
        uint256 discountBps;
    }

    struct FeeType {
        uint256 feeBps;
        uint256 maxDiscountFeeBps;
    }

    uint256 public constant FEE_BPS_PRECISION = 10000000;
    address public gov;

    mapping(uint256 => FeeType) private feeTypeBps;
    mapping(address => DiscountType[]) public vaultDiscounts;

    constructor(address _gov) {
        gov = _gov;
    }

    function getFeeBps(uint256 _feeType) public view returns (FeeType memory) {
        return feeTypeBps[_feeType];
    }

    function getFeeBps(
        uint256 _feeType,
        address _user,
        bool _useDiscount
    ) external view returns (uint256 _feeBps) {
        _feeBps = feeTypeBps[_feeType].feeBps;
        if (_useDiscount && _user != address(0)) {
            _feeBps = _applyDiscount(_feeType, msg.sender, _user);
        }
    }

    function getFeeBps(
        uint256 _feeType,
        address _user,
        address _vault,
        bool _useDiscount
    ) external view returns (uint256 _feeBps) {
        _feeBps = feeTypeBps[_feeType].feeBps;

        if (_useDiscount) {
            _feeBps = _applyDiscount(_feeType, _vault, _user);
        }
    }

    function _applyDiscount(
        uint256 _feeType,
        address _caller,
        address _user
    ) private view returns (uint256 _discountedBps) {
        FeeType memory feeType = feeTypeBps[_feeType];
        DiscountType[] memory _vaultDiscounts = vaultDiscounts[_caller];
        uint256 balance;
        for (uint256 i; i < _vaultDiscounts.length; ) {
            balance = IToken(_vaultDiscounts[i].tokenAddress).balanceOf(_user);

            if (balance != 0) {
                if (_vaultDiscounts[i].maxBalance < balance) {
                    balance = _vaultDiscounts[i].maxBalance;
                }
                if (_vaultDiscounts[i].decimals > 1) {
                    balance =
                        (balance * FEE_BPS_PRECISION) /
                        10 ** (_vaultDiscounts[i].decimals);
                } else {
                    balance = balance * FEE_BPS_PRECISION;
                }
                _discountedBps +=
                    (_vaultDiscounts[i].discountBps * balance) /
                    FEE_BPS_PRECISION;
            }

            unchecked {
                ++i;
            }
        }

        if (_discountedBps > feeType.maxDiscountFeeBps) {
            _discountedBps = feeType.maxDiscountFeeBps;
        }

        _discountedBps =
            (feeType.feeBps * (FEE_BPS_PRECISION - _discountedBps)) /
            FEE_BPS_PRECISION;
    }

    function setFeeTypes(
        uint256 _key,
        FeeType calldata _feeType
    ) external onlyGov returns (bool) {
        feeTypeBps[_key] = _feeType;
        emit FeeTypeBpsSet(_key, _feeType);
        return true;
    }

    function setVaultDiscount(
        address _contract,
        DiscountType[] calldata _discounts
    ) external onlyGov returns (bool) {
        delete vaultDiscounts[_contract];
        for (uint256 i; i < _discounts.length; ) {
            if (_discounts[i].discountBps > FEE_BPS_PRECISION) {
                revert MaxDiscountFeeBpsExceeded();
            }
            vaultDiscounts[_contract].push(_discounts[i]);
            unchecked {
                ++i;
            }
        }
        return true;
    }

    function setGov(address _gov) external onlyGov returns (bool) {
        if (_gov == address(0)) revert ZeroAddressInput();

        gov = _gov;

        emit GovSet(_gov);

        return true;
    }

    modifier onlyGov() {
        if (msg.sender != gov) revert Forbidden();
        _;
    }

    error Forbidden();
    error MaxFeeBpsExceeded();
    error MaxDiscountFeeBpsExceeded();
    error ZeroAddressInput();

    event TokenDiscountBpsSet(address _token, uint256 _feeBps);
    event FeeTypeBpsSet(uint256 _feeType, FeeType _feeTypeBps);
    event GovSet(address _newGov);
    event MinFeeBpsSet(uint256 _minFeeBps);
}