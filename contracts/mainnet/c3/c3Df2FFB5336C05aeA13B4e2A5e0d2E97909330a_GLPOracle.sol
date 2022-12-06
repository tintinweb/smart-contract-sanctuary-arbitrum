pragma solidity ^0.8.10;
import "../EIP20Interface.sol";
import "./Interfaces/GLPManagerInterface.sol";
import "./Interfaces/plvGLPInterface.sol";

contract GLPOracle {

    address public admin;

    address public GLP;

    address public GLPManager;

    address public plvGLP;

    uint256 constant private DECIMAL_DIFFERENCE = 1e6;

    uint256 constant private BASE = 1e18;

    event newGLPAddress(address newGLPAddress);

    event newGLPManagerAddress(address newGLPManagerAddress);

    event newAdmin(address newAdmin);

    event newPlvGLPAddress(address newPlvGLPAddress);

    constructor(
        address admin_,
        address GLPAddress_,
        address GLPManagerAddress_,
        address plvGLPAddress_
    ) public {
        admin = admin_;
        GLP = GLPAddress_;
        GLPManager = GLPManagerAddress_;
        plvGLP = plvGLPAddress_;
    }

    function getGLPPrice() public view returns (uint256) {

        //retrieve the minimized AUM from GLP Manager Contract
        uint256 glpAUM = GLPManagerInterface(GLPManager).getAum(false);

        //retrieve the total supply of GLP
        uint256 glpSupply = EIP20Interface(GLP).totalSupply();

        //GLP Price = AUM / Total Supply
        uint256 price = glpAUM / glpSupply * DECIMAL_DIFFERENCE;

        return price;
    }

    function getPlutusExchangeRate() public view returns (uint256) {

        //retrieve total assets from plvGLP contract
        uint256 totalAssets = plvGLPInterface(plvGLP).totalAssets();

        //retrieve total supply from plvGLP contract
        uint256 totalSupply = EIP20Interface(plvGLP).totalSupply();

        //plvGLP/GLP Exchange Rate = Total Assets / Total Supply
        uint256 exchangeRate = (totalAssets * BASE) / totalSupply;

        return exchangeRate;
    }

    function getPlvGLPPrice() public view returns (uint256) {
        uint256 exchangeRate = getPlutusExchangeRate();

        uint256 glpPrice = getGLPPrice();

        uint256 price = exchangeRate * glpPrice / BASE;

        return price;
    }

    function updateAdmin(address _newAdmin) public returns (address) {
        require(msg.sender == admin, "Only the current admin is authorized to change the admin");
        admin = _newAdmin;
        emit newAdmin(_newAdmin);
        return _newAdmin;
    }

    function updateGlpAddress(address _newGlpAddress) public returns (address) {
        require(msg.sender == admin, "Only the admin can change the GLP contract address");
        GLP = _newGlpAddress;
        emit newGLPAddress(_newGlpAddress);
        return _newGlpAddress;
    }

    function updateGlpManagerAddress(address _newGlpManagerAddress) public returns (address) {
        require(msg.sender == admin, "Only the admin can change the GLP Manager contract address");
        GLPManager = _newGlpManagerAddress;
        emit newGLPManagerAddress(_newGlpManagerAddress);
        return _newGlpManagerAddress;
    }

    function updatePlvGlpAddress(address _newPlvGlpAddress) public returns (address) {
        require(msg.sender == admin, "Only the admin can change the plvGLP contract address");
        plvGLP = _newPlvGlpAddress;
        emit newPlvGLPAddress(_newPlvGlpAddress);
        return _newPlvGlpAddress;
    }

}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface EIP20Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return success Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return success Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return success Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

pragma solidity ^0.8.10;

interface GLPManagerInterface {
    function getAum(bool maximise) external view returns (uint256);
}

pragma solidity ^0.8.10;

interface plvGLPInterface {
    function totalAssets() external view returns (uint256);
}