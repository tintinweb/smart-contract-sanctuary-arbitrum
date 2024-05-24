// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IStargateReceiver, ISpheraxVault} from "./interfaces/IStargateReceiver.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract StgComposed is IStargateReceiver {
    // address constant stgRouter = 0x53Bf833A5d6c4ddA888F69c22C88C9f356a41614;
    // sperax vault
    ISpheraxVault vault = ISpheraxVault(0x6Bbc476Ee35CBA9e9c3A59fc5b10d7a0BC6f74Ca);

    IERC20 usds = IERC20(0xD74f5255D557944cf7Dd0E45FF521520002D5748);

    event USDSMinted(address indexed to, uint256 amount);

    function sgReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external {
        // require(msg.sender == address(stgRouter), "Stargate: only router");
        if (payload.length <= 40) return; // 20 + 20 + payload

        // decode data for sperax usds minting
        (address toAddr, uint256 deadline) = abi.decode(payload, (address, uint256));
        IERC20(_token).approve(address(vault), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint256 usdsBefore = usds.balanceOf(address(this));
        uint256 usdsAfter;
        try vault.mint(_token, amountLD, 0, deadline) {
            usdsAfter = usds.balanceOf(address(this));
            usds.transfer(address(toAddr), usdsAfter - usdsBefore);
        } catch {}

        emit USDSMinted(toAddr, usdsAfter - usdsBefore);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

interface IStargateReceiver {
    function sgReceive(
        uint16 _srcChainId, // the remote chainId sending the tokens
        bytes memory _srcAddress, // the remote Bridge address
        uint256 _nonce,
        address _token, // the token contract on the local chain
        uint256 amountLD, // the qty of local _token contract tokens
        bytes memory payload
    ) external;
}

interface ISpheraxVault {
    function mint(address _collateral, uint256 _collateralAmt, uint256 _minUSDSAmt, uint256 _deadline) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

/// @dev Interface of the ERC20 standard as defined in the EIP.
/// @dev This includes the optional name, symbol, and decimals metadata.
interface IERC20 {
    /// @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set, where `value`
    /// is the new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Moves `amount` tokens from the caller's account to `to`.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Returns the remaining number of tokens that `spender` is allowed
    /// to spend on behalf of `owner`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    /// @dev Be aware of front-running risks: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `from` to `to` using the allowance mechanism.
    /// `amount` is then deducted from the caller's allowance.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token.
    function symbol() external view returns (string memory);

    /// @notice Returns the decimals places of the token.
    function decimals() external view returns (uint8);
}