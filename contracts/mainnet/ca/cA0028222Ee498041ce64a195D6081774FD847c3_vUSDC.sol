// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./interfaces/IVUSDC.sol";
import "../access/Governable.sol";

contract vUSDC is IVUSDC, Governable {
    uint8 public constant decimals = 30;

    string public name;
    string public symbol;
    uint256 public totalSupply;
    mapping(address => uint256) public balances;
    event Burn(address indexed account, uint256 value);
    event Mint(address indexed beneficiary, uint256 value);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        _mint(msg.sender, _initialSupply);
    }

    function burn(
        address _account,
        uint256 _amount
    ) external override onlyGov {
        _burn(_account, _amount);
    }

    function mint(
        address _account,
        uint256 _amount
    ) external override onlyGov {
        _mint(_account, _amount);
    }

    function setInfo(
        string memory _name,
        string memory _symbol
    ) external onlyGov {
        name = _name;
        symbol = _symbol;
    }

    function balanceOf(
        address _account
    ) external view override returns (uint256) {
        return balances[_account];
    }

    function _burn(address _account, uint256 _amount) internal {
        require(_account != address(0), "VUSD: burn from the zero address");

        require(
            balances[_account] >= _amount,
            "VUSD: burn amount exceeds balance"
        );
        balances[_account] -= _amount;
        totalSupply -= _amount;
        emit Burn(_account, _amount);
    }

    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0), "VUSD: mint to the zero address");
        totalSupply += _amount;
        balances[_account] += _amount;
        emit Mint(_account, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IVUSDC {
    function burn(address _account, uint256 _amount) external;

    function mint(address _account, uint256 _amount) external;

    function balanceOf(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract Governable {
    address public gov;

    event UpdateGov(address indexed oldGov, address indexed newGov);

    constructor() {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        require(_gov != address(0), "Governable: zero address is invalid");
        emit UpdateGov(gov, _gov);
        gov = _gov;
    }
}