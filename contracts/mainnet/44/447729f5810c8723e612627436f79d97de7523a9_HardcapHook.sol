// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

import "./BaseHook.sol";

contract HardcapHook is BaseHook {
    string public constant hookName = "Hardcap";
    string public constant parameterEncoder = "(uint256)";
    constructor(address factory) BaseHook(factory) {}

    mapping(address => uint256) capMap;

    function registerHook(address token, bytes calldata data) external virtual override onlyFactory {
        require(capMap[token] == 0, "already registered");
        uint256 cap = abi.decode(data, (uint256));
        capMap[token] = cap;
    }

    function unregisterHook(address token) external virtual override onlyFactory {
        revert("can not unregister");
        delete capMap[token];
    }

    function beforeMintHook(address, address, uint256 amount) external view override {
        require(IERC20(msg.sender).totalSupply() + amount <= capMap[msg.sender], "capped");
    }

}

// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

import "../interfaces/IHook.sol";

import "openzeppelin/token/ERC20/IERC20.sol";

abstract contract BaseHook is IHook {
    address public immutable factory;
    modifier onlyFactory() {
        require(msg.sender == factory, "only factory");
        _;
    }

    constructor(address _factory) {
        factory = _factory;
    }

    function registerHook(address token, bytes calldata data) external virtual override onlyFactory {}

    function unregisterHook(address token) external virtual override onlyFactory {}

    function beforeTransferHook(address from, address to, uint256 amount) external virtual override {}

    function afterTransferHook(address from, address to, uint256 amount) external virtual override {}

    function beforeMintHook(address from, address to, uint256 amount) external virtual override {}

    function afterMintHook(address from, address to, uint256 amount) external virtual override {}

    function beforeBurnHook(address from, address to, uint256 amount) external virtual override {}

    function afterBurnHook(address from, address to, uint256 amount) external virtual override {}
}

// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

interface IHook {

    function hookName() external pure returns (string memory);
    function parameterEncoder() external pure returns (string memory);
    function registerHook(address token, bytes calldata data) external;

    function unregisterHook(address token) external;

    function beforeTransferHook(address from, address to, uint256 amount) external;

    function afterTransferHook(address from, address to, uint256 amount) external;

    function beforeMintHook(address from, address to, uint256 amount) external;

    function afterMintHook(address from, address to, uint256 amount) external;

    function beforeBurnHook(address from, address to, uint256 amount) external;

    function afterBurnHook(address from, address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}