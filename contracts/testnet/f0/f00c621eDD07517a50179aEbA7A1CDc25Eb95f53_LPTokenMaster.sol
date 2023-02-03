// SPDX-License-Identifier: UNLICENSED

// Copyright (c) FloraLoans - All rights reserved
// https://twitter.com/Flora_Loans

// This contract is a wrapper around the LendingPair contract
// Each new LendingPair implementation delegates its calls to this contract
// It enables ERC20 functionality around the postion tokens

pragma solidity ^0.8.6;

import "./interfaces/ILPTokenMaster.sol";
import "./interfaces/ILendingPair.sol";
import "./interfaces/ILendingController.sol";
import "./external/SafeOwnable.sol";

/// @title LendingPairTokenMaster: An ERC20-like Master contract
/// @author 0xdev & flora.loans
/// @notice Serves as a fungible token
/// @dev Implements the ERC20 standard
contract LPTokenMaster is ILPTokenMaster, SafeOwnable {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    mapping(address => mapping(address => uint256)) public override allowance;

    address public override underlying;
    address public lendingController;
    string public constant name = "Flora-Lendpair";
    string public constant symbol = "FLORA-LP";
    uint8 public constant override decimals = 18;
    bool private initialized;

    modifier onlyOperator() {
        require(
            msg.sender == ILendingController(lendingController).owner(),
            "LPToken: caller is not an operator"
        );
        _;
    }

    function initialize(address _underlying, address _lendingController)
        external
        override
    {
        require(initialized != true, "LPToken: already intialized");
        owner = msg.sender;
        underlying = _underlying;
        lendingController = _lendingController;
        initialized = true;
    }

    /// @dev Transfer token to a specified address
    /// @param _recipient The address to transfer to
    /// @param _amount The amount to be transferred
    /// @return a boolean value indicating whether the operation succeeded.
    /// @notice Emits a {Transfer} event.
    function transfer(address _recipient, uint256 _amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    /// @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
    /// @param _spender The address which will spend the funds
    /// @param _amount The amount of tokens to be spent
    /// @return bool
    /// @dev Beware that changing an allowance with this method brings the risk that someone may use both the old
    /// and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    /// race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    /// https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address _spender, uint256 _amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    /// @notice Transfer tokens from one address to another.
    /// @param _sender The address which you want to send tokens from
    /// @param _recipient The address which you want to transfer to
    /// @param _amount The amount of tokens to be transferred
    /// @return bool
    /// @dev Note that while this function emits an Approval event, this is not required as per the specification and other compliant implementations may not emit the event.
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external override returns (bool) {
        _approve(_sender, msg.sender, allowance[_sender][msg.sender] - _amount);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    /// @notice returns associated LendingPair Contract
    function lendingPair() external view override returns (address) {
        return owner;
    }

    /// @notice Gets the balance of the specified address
    /// @param _account The address to query the balance of
    /// @return A uint256 representing the amount owned by the passed address
    function balanceOf(address _account)
        external
        view
        override
        returns (uint256)
    {
        return ILendingPair(owner).supplySharesOf(underlying, _account);
    }

    /// @notice Total number of tokens in existence
    function totalSupply() external view override returns (uint256) {
        return ILendingPair(owner).totalSupplyShares(underlying);
    }

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(
            _recipient != address(0),
            "ERC20: transfer to the zero address"
        );

        ILendingPair(owner).transferLp(
            underlying,
            _sender,
            _recipient,
            _amount
        );

        emit Transfer(_sender, _recipient, _amount);
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        allowance[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.6;

import "./IOwnable.sol";
import "./IERC20.sol";

interface ILPTokenMaster is IOwnable, IERC20 {
    function initialize(address _underlying, address _lendingController)
        external;

    function underlying() external view returns (address);

    function lendingPair() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.6;

interface ILendingPair {
    function tokenA() external view returns (address);

    function tokenB() external view returns (address);

    function lpToken(address _token) external view returns (address);

    function operate(uint256[] calldata _actions, bytes[] calldata _data)
        external
        payable;

    function transferLp(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function supplySharesOf(address _token, address _account)
        external
        view
        returns (uint256);

    function totalSupplyShares(address _token) external view returns (uint256);

    function totalSupplyAmount(address _token) external view returns (uint256);

    function totalDebtShares(address _token) external view returns (uint256);

    function totalDebtAmount(address _token) external view returns (uint256);

    function debtOf(address _token, address _account)
        external
        view
        returns (uint256);

    function supplyOf(address _token, address _account)
        external
        view
        returns (uint256);

    function pendingSystemFees(address _token) external view returns (uint256);

    function supplyBalanceConverted(
        address _account,
        address _suppliedToken,
        address _returnToken
    ) external view returns (uint256);

    function initialize(
        address _lpTokenMaster,
        address _lendingController,
        address _uniV3Helper,
        address _feeRecipient,
        address _tokenA,
        address _tokenB
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.6;

import "./IOwnable.sol";
import "./IUnifiedOracleAggregator.sol";

interface ILendingController is IOwnable {
    function oracleAggregator()
        external
        view
        returns (IUnifiedOracleAggregator);

    function liqFeeSystem(address _token) external view returns (uint256);

    function liqFeeCaller(address _token) external view returns (uint256);

    function uniMinOutputPct() external view returns (uint256);

    function colFactor(address _token) external view returns (uint256);

    function defaultColFactor() external view returns (uint256);

    function depositLimit(address _lendingPair, address _token)
        external
        view
        returns (uint256);

    function borrowLimit(address _lendingPair, address _token)
        external
        view
        returns (uint256);

    function depositsEnabled() external view returns (bool);

    function borrowingEnabled() external view returns (bool);

    function tokenPrice(address _token) external view returns (uint256);

    function minBorrow(address _token) external view returns (uint256);

    function tokenPrices(address _tokenA, address _tokenB)
        external
        view
        returns (uint256, uint256);

    function tokenSupported(address _token) external view returns (bool);

    function isBaseAsset(address _token) external view returns (bool);

    function minObservationCardinalityNext() external view returns (uint16);

    function preparePool(address _tokenA, address _tokenB) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.6;

import "../interfaces/IOwnable.sol";

contract SafeOwnable is IOwnable {
    uint public constant RENOUNCE_TIMEOUT = 1 hours;

    address public override owner;
    address public pendingOwner;
    uint public renouncedAt;

    event OwnershipTransferInitiated(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipTransferConfirmed(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferConfirmed(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function transferOwnership(address _newOwner) external override onlyOwner {
        require(
            _newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferInitiated(owner, _newOwner);
        pendingOwner = _newOwner;
    }

    function acceptOwnership() external override {
        require(
            msg.sender == pendingOwner,
            "Ownable: caller is not pending owner"
        );
        emit OwnershipTransferConfirmed(msg.sender, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    function initiateRenounceOwnership() external onlyOwner {
        require(renouncedAt == 0, "Ownable: already initiated");
        renouncedAt = block.timestamp;
    }

    function acceptRenounceOwnership() external onlyOwner {
        require(renouncedAt > 0, "Ownable: not initiated");
        require(
            block.timestamp - renouncedAt > RENOUNCE_TIMEOUT,
            "Ownable: too early"
        );
        owner = address(0);
        pendingOwner = address(0);
        renouncedAt = 0;
    }

    function cancelRenounceOwnership() external onlyOwner {
        require(renouncedAt > 0, "Ownable: not initiated");
        renouncedAt = 0;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.6;

interface IOwnable {
    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;

    function acceptOwnership() external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint);

    function decimals() external view returns (uint8);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./IPriceOracle.sol";
import "../external/SafeOwnable.sol";

interface IExternalOracle {
    function price(address _token) external view returns (uint256);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

/// @title Oracle aggergator for uni and link oracles
/// @author flora.loans
/// @notice Owner can set Chainlink oracles for specific tokens
/// @notice returns the token price from chainlink oracle (if available) otherwise the uni oracle will be used
/// @dev
/// @custom:this contract is configured for Arbitrum mainnet
interface IUnifiedOracleAggregator {
    function setOracle(address, IExternalOracle) external;

    function preparePool(
        address,
        address,
        uint16
    ) external;

    function tokenSupported(address) external view returns (bool);

    function tokenPrice(address) external view returns (uint256);

    function tokenPrices(address, address)
        external
        view
        returns (uint256, uint256);

    /// @dev Not used in any code to save gas. But useful for external usage.
    function convertTokenValues(
        address,
        address,
        uint256
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.6;

interface IPriceOracle {
    function tokenPrice(address _token) external view returns (uint256);

    function tokenSupported(address _token) external view returns (bool);

    function convertTokenValues(
        address _fromToken,
        address _toToken,
        uint256 _amount
    ) external view returns (uint256);
}