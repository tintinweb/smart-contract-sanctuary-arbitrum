pragma solidity ^0.8.0;

import "./IParameters.sol";

contract Parameters is IParameters {
    /// @notice Fee rate applied to notional value of trade.
    /// @notice Prevents soft frontrunning.
    /// @dev 18-decimal fixed-point
    uint immutable fee;

    /// @notice Interest rate model
    IModel immutable model;

    /// @notice Price of underlying in target asset
    IPrice immutable price;

    /// @notice Tokens representing the swap's protection buyers
    /// @notice Pegged to denominating asset + accrewed interest
    /// @dev Must use 18 decimals
    IToken immutable hedge;

    /// @notice Tokens representing the swap's protection sellers
    /// @notice Pegged to [R/(R-1)]x leveraged underlying
    /// @dev Must use 18 decimals
    IToken immutable leverage;

    /// @notice Token collateralizing hedge / underlying leverage
    /// @dev Must use 18 decimals
    IToken immutable underlying;

    constructor(
        uint _fee,
        IModel _model,
        IPrice _price,
        IToken _hedge,
        IToken _leverage,
        IToken _underlying)
    {
        fee        = _fee;
        model      = _model;
        price      = _price;
        hedge      = _hedge;
        leverage   = _leverage;
        underlying = _underlying;
    }

    function get() public view returns (uint, IModel, IPrice, IToken, IToken, IToken) {
        return (fee, model, price, hedge, leverage, underlying);
    }
}

pragma solidity ^0.8.0;

interface IToken {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient,uint256 amount) external returns (bool);

    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;

interface IPrice {
    function get() external view returns (uint);
}

pragma solidity ^0.8.0;

import "./IPrice.sol";
import "./IModel.sol";
import "./IToken.sol";

interface IParameters {
    function get() external view returns (uint, IModel, IPrice, IToken, IToken, IToken);
}

pragma solidity ^0.8.0;

interface IModel {
    function getInterestRate(uint potValue, uint hedgeTV) external view returns (int);
}