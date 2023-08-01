// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStakingBank is IERC20 {
    /// @param id address of validator wallet
    /// @param location URL of the validator API
    struct Validator {
        address id;
        string location;
    }

    event LogValidatorRegistered(address indexed id);
    event LogValidatorUpdated(address indexed id);
    event LogValidatorRemoved(address indexed id);
    event LogMinAmountForStake(uint256 minAmountForStake);

    /// @dev setter for `minAmountForStake`
    function setMinAmountForStake(uint256 _minAmountForStake) external;

    /// @dev allows to stake `token` by validators
    /// Validator needs to approve StakingBank beforehand
    /// @param _value amount of tokens to stake
    function stake(uint256 _value) external;

    /// @dev notification about approval from `_from` address on UMB token
    /// Staking bank will stake max approved amount from `_from` address
    /// @param _from address which approved token spend for IStakingBank
    function receiveApproval(address _from) external returns (bool success);

    /// @dev withdraws stake tokens
    /// it throws, when balance will be less than required minimum for stake
    /// to withdraw all use `exit`
    function withdraw(uint256 _value) external returns (bool success);

    /// @dev unstake and withdraw all tokens
    function exit() external returns (bool success);

    /// @dev creates (register) new validator
    /// @param _id validator address
    /// @param _location location URL of the validator API
    function create(address _id, string calldata _location) external;

    /// @dev removes validator
    /// @param _id validator wallet
    function remove(address _id) external;

    /// @dev updates validator location
    /// @param _id validator wallet
    /// @param _location new validator URL
    function update(address _id, string calldata _location) external;

    /// @return total number of registered validators (with and without balance)
    function getNumberOfValidators() external view returns (uint256);

    /// @dev gets validator address for provided index
    /// @param _ix index in array of list of all validators wallets
    function addresses(uint256 _ix) external view returns (address);

    /// @param _id address of validator
    /// @return id address of validator
    /// @return location URL of validator
    function validators(address _id) external view returns (address id, string memory location);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IStakingBank.sol";

abstract contract StakingBankStaticNotSupported is IStakingBank {
    error NotSupported();

    function create(address, string calldata) external pure {
        revert NotSupported();
    }

    function update(address, string calldata) external pure {
        revert NotSupported();
    }

    function remove(address) external pure {
        revert NotSupported();
    }

    function transfer(address, uint256) external pure returns (bool) {
        revert NotSupported();
    }

    function transferFrom(address, address, uint256) external pure returns (bool) {
        revert NotSupported();
    }

    function receiveApproval(address) external pure returns (bool) {
        revert NotSupported();
    }

    function allowance(address, address) external pure returns (uint256) {
        revert NotSupported();
    }

    function approve(address, uint256) external pure returns (bool) {
        revert NotSupported();
    }

    function stake(uint256) external pure {
        revert NotSupported();
    }

    function withdraw(uint256) external pure returns (bool) {
        revert NotSupported();
    }

    function exit() external pure returns (bool) {
        revert NotSupported();
    }

    function setMinAmountForStake(uint256) external pure {
        revert NotSupported();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../interfaces/StakingBankStaticNotSupported.sol";

/// @dev Because we are using PoA in UMB oracle, staked balance does not matter. What's matter is, if signer is
/// validator or not. In this case  we can optimise `StakingBank` and make it static for better gas performance.
abstract contract StakingBankStatic is StakingBankStaticNotSupported {
    uint256 public constant ONE = 1e18;

    uint256 public immutable NUMBER_OF_VALIDATORS; // solhint-disable-line var-name-mixedcase
    uint256 public immutable TOTAL_SUPPLY; // solhint-disable-line var-name-mixedcase

    constructor(uint256 _validatorsCount) {
        NUMBER_OF_VALIDATORS = _validatorsCount;
        TOTAL_SUPPLY = _validatorsCount * ONE;

        _assertValidSetup(_validatorsCount);
    }

    function balances(address _validator) external view returns (uint256) {
        return _isValidator(_validator) ? ONE : 0;
    }

    function verifyValidators(address[] calldata _validators) external view returns (bool) {
        for (uint256 i; i < _validators.length;) {
            if (!_isValidator(_validators[i])) return false;
            unchecked { i++; }
        }

        return true;
    }

    function getNumberOfValidators() external view returns (uint256) {
        return NUMBER_OF_VALIDATORS;
    }

    function getAddresses() external view returns (address[] memory) {
        return _addresses();
    }

    function getBalances() external view returns (uint256[] memory allBalances) {
        allBalances = new uint256[](NUMBER_OF_VALIDATORS);

        for (uint256 i; i < NUMBER_OF_VALIDATORS;) {
            allBalances[i] = ONE;

            unchecked {
                // we will not have enough data to overflow
                i++;
            }
        }
    }

    function addresses(uint256 _ix) external view returns (address) {
        return _addresses()[_ix];
    }

    function validators(address _id) external view virtual returns (address id, string memory location);

    /// @dev to follow ERC20 interface
    function balanceOf(address _account) external view returns (uint256) {
        return _isValidator(_account) ? ONE : 0;
    }

    /// @dev to follow ERC20 interface
    function totalSupply() external view returns (uint256) {
        return TOTAL_SUPPLY;
    }

    /// @dev to follow Registrable interface
    function getName() external pure returns (bytes32) {
        return "StakingBank";
    }

    /// @dev to follow Registrable interface
    function register() external pure {
        // there are no requirements atm
    }

    /// @dev to follow Registrable interface
    function unregister() external pure {
        // there are no requirements atm
    }

    function _addresses() internal view virtual returns (address[] memory);

    function _isValidator(address _validator) internal view virtual returns (bool);

    function _assertValidSetup(uint256 _validatorsCount) internal view virtual{
        address[] memory list = _addresses();
        require(list.length == _validatorsCount);

        for (uint256 i; i < _validatorsCount;) {
            require(_isValidator(list[i]));

            unchecked { i ++; }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./StakingBankStatic.sol";

contract StakingBankStaticProd is StakingBankStatic {
    address public constant VALIDATOR_0 = 0x977Ba523420110e230643B772Fe9cF955e11dA7B;
    address public constant VALIDATOR_1 = 0xe2422b23e52bc13ebA04d7FbB9F332Deb43360fB;

    // external order is based on validators submits on AVAX for Apr 2023
    address public constant VALIDATOR_2 = 0x57F404aD75e371c1A539589C1eFCA12e0C6980AD;
    address public constant VALIDATOR_3 = 0xD56C6A4f64E0bD70260472d1DB6Cf5825858CB0d;
    address public constant VALIDATOR_4 = 0x220230Eda8f50067Dd9e4729345dabCCe0C61542;
    address public constant VALIDATOR_5 = 0x93FdcAB283b0BcAc48157590af482E1CFd6af6aC;
    address public constant VALIDATOR_6 = 0xCd733E06B06083d52fC5867E8E3432aA5c103A38;
    address public constant VALIDATOR_7 = 0x42e210b110c6aa49CdfA7ceF1444Aa4719653111;
    address public constant VALIDATOR_8 = 0x501731c6a69803a53Ec6c3e12f293c247cE1092B;
    address public constant VALIDATOR_9 = 0x8bF9661F1b247522C75DD0FE84355aD2EfF27144;
    address public constant VALIDATOR_10 = 0x281754Ab58391A478B7aA4E7f39991CfB41118c4;
    address public constant VALIDATOR_11 = 0xB9C63a350A04d8BD245d18928a26EE036352dDd8;
    address public constant VALIDATOR_12 = 0x57A51D5BDcE188c2295fCA3b4687475a54E65A02;
    address public constant VALIDATOR_13 = 0x777FbA3666fa7747476a34577FcCC404b263E09F;
    address public constant VALIDATOR_14 = 0x2F85824B2B38F179E451988670935d315b5b9692;

    constructor(uint256 _validatorsCount) StakingBankStatic(_validatorsCount) {}

    // solhint-disable-next-line code-complexity
    function validators(address _id) external pure override returns (address id, string memory location) {
        if (_id == VALIDATOR_0) return (_id, "https://validator.umb.network");
        if (_id == VALIDATOR_1) return (_id, "https://validator2.umb.network");
        if (_id == VALIDATOR_2) return (_id, "https://umbrella.artemahr.tech");
        if (_id == VALIDATOR_3) return (_id, "https://umb.vtabsolutions.com:3030");
        if (_id == VALIDATOR_4) return (_id, "https://umb.stakers.world");
        if (_id == VALIDATOR_5) return (_id, "https://umbrella.crazywhale.es");
        if (_id == VALIDATOR_6) return (_id, "https://umbrella-node.gateomega.com");
        if (_id == VALIDATOR_7) return (_id, "https://umb.anorak.technology");
        if (_id == VALIDATOR_8) return (_id, "https://umbrella.infstones.io");
        if (_id == VALIDATOR_9) return (_id, "https://umb.hashquark.io");
        if (_id == VALIDATOR_10) return (_id, "http://umbrella.staking4all.org:3000");
        if (_id == VALIDATOR_11) return (_id, "https://umbrella-api.validatrium.club");
        if (_id == VALIDATOR_12) return (_id, "http://5.161.78.230:3000");
        if (_id == VALIDATOR_13) return (_id, "https://umbnode.blockchainliverpool.com");
        if (_id == VALIDATOR_14) return (_id, "https://umb-api.staking.rocks");

        return (address(0), "");
    }

    function _addresses() internal view override returns (address[] memory) {
        address[] memory list = new address[](NUMBER_OF_VALIDATORS);

        list[0] = VALIDATOR_0;
        list[1] = VALIDATOR_1;
        list[2] = VALIDATOR_2;
        list[3] = VALIDATOR_3;
        list[4] = VALIDATOR_4;
        list[5] = VALIDATOR_5;
        list[6] = VALIDATOR_6;
        list[7] = VALIDATOR_7;
        list[8] = VALIDATOR_8;
        list[9] = VALIDATOR_9;
        list[10] = VALIDATOR_10;
        list[11] = VALIDATOR_11;
        list[12] = VALIDATOR_12;
        list[13] = VALIDATOR_13;
        list[14] = VALIDATOR_14;

        return list;
    }

    function _isValidator(address _validator) internal pure override returns (bool) {
        return (
            _validator == VALIDATOR_0
            || _validator == VALIDATOR_1
            || _validator == VALIDATOR_2
            || _validator == VALIDATOR_3
            || _validator == VALIDATOR_4
            || _validator == VALIDATOR_5
            || _validator == VALIDATOR_6
            || _validator == VALIDATOR_7
            || _validator == VALIDATOR_8
            || _validator == VALIDATOR_9
            || _validator == VALIDATOR_10
            || _validator == VALIDATOR_11
            || _validator == VALIDATOR_12
            || _validator == VALIDATOR_13
            || _validator == VALIDATOR_14
        );
    }
}