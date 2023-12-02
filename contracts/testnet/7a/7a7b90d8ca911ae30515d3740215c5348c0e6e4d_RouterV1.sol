// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IVault } from "../interfaces/IVault.sol";
import { IWETH } from "../interfaces/IWETH.sol";

contract RouterV1 {
    
    address public VAULT;
    address public WETH;
    address public TINU;

    event IncreaseCollateral (
        address indexed receiver,
        address collateralToken,
        uint256 amount
    );

    event DecreaseCollateral (
        address indexed receiver,
        address collateralToken,
        uint256 amount
    );

    event MintUnit (
        address indexed receiver,
        address collateralToken,
        uint256 amount
    );
    event BurnUnit (
        address indexed receiver,
        address collateralToken,
        uint256 amount
    );
    
    constructor (address _vault, address _weth, address _tinu) {
        VAULT = _vault;
        WETH = _weth;
        TINU = _tinu;
    } 
    
    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }
 
    function increaseCollateral(address _collateralToken, uint256 _tokenAmount, address _receiver) external returns(bool) {  
        require(IERC20(_collateralToken).balanceOf(msg.sender) >= _tokenAmount, "Router: not enough balance");
        IERC20(_collateralToken).transferFrom(msg.sender, VAULT, _tokenAmount);
        IVault(VAULT).increaseCollateral(_collateralToken, _receiver);
        emit IncreaseCollateral(_receiver, _collateralToken, _tokenAmount);
        return true;
    }

    function increaseETH(address _receiver) external payable returns(bool) {  
        require(msg.value > 0, "Router: value cannot be 0");
        IWETH(WETH).deposit{value: msg.value}();
        IWETH(WETH).transfer(VAULT, msg.value);
        IVault(VAULT).increaseCollateral(WETH, _receiver);
        emit IncreaseCollateral(_receiver, WETH, msg.value);
        return true;
    }

    function decreaseCollateral(address _collateralToken, uint256 _tokenAmount, address _receiver) external returns(bool)  {
        require(_tokenAmount > 0, "UintRouter: amount cannot be 0");
        IVault(VAULT).decreaseCollateralFrom(msg.sender, _collateralToken, _receiver, _tokenAmount, new bytes(0));
        emit DecreaseCollateral(_receiver, _collateralToken, _tokenAmount);
        return true;
    }

    function decreaseETH(uint256 _ETHAmount, address _receiver) external returns(bool)  {
        require(_ETHAmount > 0, "UintRouter: amount cannot be 0");
        IVault(VAULT).decreaseCollateralFrom(msg.sender, WETH, address(this), _ETHAmount , new bytes(0));
        IWETH(WETH).withdraw(_ETHAmount);
        safeTransferETH(_receiver, _ETHAmount);
        emit DecreaseCollateral(_receiver, WETH, _ETHAmount);
        return true;
    }

    function mintUnit(address _collateralToken, uint256 _UNITAmount, address _receiver) external returns(bool) {
        require(_UNITAmount > 0, "UintRouter: amount cannot be 0");
        IVault(VAULT).increaseDebtFrom(msg.sender, _collateralToken, _UNITAmount, _receiver);
        emit MintUnit(_receiver, _collateralToken, _UNITAmount);
        return true;
    }

    function burnUnit(address _collateralToken, uint256 _UNITAmount, address _receiver)  external returns(bool) {
         require(_UNITAmount > 0, "UintRouter: amount cannot be 0");
        IERC20(TINU).transferFrom(msg.sender, VAULT, _UNITAmount);
        IVault(VAULT).decreaseDebt( _collateralToken, _receiver);
        emit BurnUnit(_receiver, _collateralToken, _UNITAmount);
        return true;
    }

    function increaseCollateralAndMint(address _collateralToken, uint256 _tokenAmount, uint256 _UNITAmount, address _receiver) public returns(bool) {
        require(_tokenAmount > 0 || _UNITAmount > 0, "UintRouter: amount cannot be 0");
        if(_tokenAmount >0 ) {
            require(IERC20(_collateralToken).balanceOf(msg.sender) >= _tokenAmount, "UintRouter: in");
            IERC20(_collateralToken).transferFrom(msg.sender, VAULT, _tokenAmount);
            IVault(VAULT).increaseCollateral(_collateralToken, _receiver);
            emit IncreaseCollateral(_receiver, _collateralToken, _tokenAmount);
        }
        if(_UNITAmount >0) {
            IVault(VAULT).increaseDebtFrom(msg.sender, _collateralToken, _UNITAmount, _receiver);   
            emit MintUnit(_receiver, _collateralToken, _UNITAmount);
        }
        return true;
    }

    function decreaseCollateralAndBurn(address _collateralToken, uint256 _tokenAmount, uint256 _UNITAmount, address _receiver) public returns(bool) {
        require(_tokenAmount > 0 || _UNITAmount > 0, "UintRouter: amount cannot be 0");  
        if(_UNITAmount > 0) {
            IVault(VAULT).decreaseCollateralFrom(msg.sender, _collateralToken, _receiver, _tokenAmount, new bytes(0));
            IERC20(TINU).transferFrom(msg.sender, VAULT, _UNITAmount);
            emit DecreaseCollateral(_receiver, _collateralToken, _tokenAmount);
        }

        if(_tokenAmount > 0) {
            IVault(VAULT).decreaseDebt( _collateralToken, _receiver);
            emit BurnUnit(_receiver, _collateralToken, _UNITAmount);
        }
        return true;
    }

    function increaseETHAndMint(uint256 _UNITAmount, address _receiver) public payable returns(bool) {
        require(msg.value > 0 || _UNITAmount > 0, "UintRouter: amount cannot be 0");
        if(msg.value >0 ) {
            IWETH(WETH).deposit{value: msg.value}();
            IWETH(WETH).transfer(VAULT, msg.value);
            IVault(VAULT).increaseCollateral(WETH, _receiver);
            emit IncreaseCollateral(_receiver, WETH, msg.value);
        }
        if(_UNITAmount >0) {
            IVault(VAULT).increaseDebtFrom(msg.sender, WETH, _UNITAmount, _receiver);   
            emit MintUnit(_receiver, WETH, _UNITAmount);
        }
        return true;
    }

    function decreaseETHAndBurn(uint256 _ETHAmount, uint256 _UNITAmount, address _receiver) public payable returns(bool) {   
        require(_ETHAmount > 0 || _UNITAmount > 0, "UintRouter: amount cannot be 0");
        if(_UNITAmount > 0) {
            IERC20(TINU).transferFrom(msg.sender, VAULT, _UNITAmount);
            IVault(VAULT).decreaseDebt(WETH, _receiver);
            emit BurnUnit(_receiver, WETH, _UNITAmount);
        }
    
        if(_ETHAmount > 0) {
            IVault(VAULT).decreaseCollateralFrom(msg.sender, WETH, address(this), _ETHAmount, new bytes(0));
            uint256 wethBalance = IERC20(WETH).balanceOf(address(this));
            require(wethBalance > 0, "UintRouter: WETH not allow 0");
            IWETH(WETH).withdraw(wethBalance);
            safeTransferETH(_receiver, wethBalance);
            emit DecreaseCollateral(_receiver, WETH, wethBalance);
        }
        return true;
    }

    function increaseETHAndBurn(uint256 _UNITAmount, address _receiver) public payable returns(bool) {
        require(msg.value > 0 || _UNITAmount > 0, "UintRouter: amount cannot be 0");
        if(msg.value >0 ) {
            IWETH(WETH).deposit{value: msg.value}();
            IWETH(WETH).transfer(VAULT, msg.value);
            IVault(VAULT).increaseCollateral(WETH, _receiver);
            emit IncreaseCollateral(_receiver, WETH, msg.value);
        }
        if(_UNITAmount > 0) {
            IERC20(TINU).transferFrom(msg.sender, VAULT, _UNITAmount);
            IVault(VAULT).decreaseDebt(WETH, _receiver);
            emit BurnUnit(_receiver, WETH, _UNITAmount);
        }
        return true;
    }

    function decreaseETHAndMint(uint256 _ETHAmount, uint256 _UNITAmount, address _receiver) public returns(bool) {   
        require(_ETHAmount > 0 || _UNITAmount > 0, "UintRouter: amount cannot be 0");

        if(_ETHAmount > 0) {
            IVault(VAULT).decreaseCollateralFrom(msg.sender, WETH, address(this), _ETHAmount, new bytes(0));
            uint256 wethBalance = IERC20(WETH).balanceOf(address(this));
            require(wethBalance > 0, "UintRouter: WETH not allow 0");
            IWETH(WETH).withdraw(wethBalance);
            safeTransferETH(_receiver, wethBalance);
            emit DecreaseCollateral(_receiver, WETH, wethBalance);
        }
        if(_UNITAmount >0) {
            IVault(VAULT).increaseDebtFrom(msg.sender, WETH, _UNITAmount, _receiver);   
            emit MintUnit(_receiver, WETH, _UNITAmount);
        }
        return true;
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "UintRouter: ETH transfer failed");
    }

    function liquidation(address _collateralToken, address _account, address _feeTo) external returns (bool) {
        (, uint256 _debt) = IVault(VAULT).vaultOwnerAccount(_account, _collateralToken);
        uint256 _balance = IERC20(TINU).balanceOf(msg.sender);
        require(_balance >= _debt, "UintRouter: not enough TINU");
        IERC20(TINU).transferFrom(msg.sender, VAULT, _debt);
        IVault(VAULT).liquidation(_collateralToken, _account, _feeTo);
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

interface IVault {

    // The number of all tokens in the pool
    // function poolAmounts(address _token) external view returns (uint256);
    function approve(address _operator, bool _allow) external;
    function increaseCollateral(address _collateralToken, address _receiver) external returns (bool);
    
    function decreaseCollateral(
        address _collateralToken,
        address _receiver, 
        uint256 _collateralAmount
    ) external returns(bool);
    
    function decreaseCollateralFrom(
        address _from,
        address _collateralToken,
        address _receiver,
        uint256 _collateralAmount,
        bytes calldata _data
    ) external returns (bool);

    function liquidation(address _token, address _account, address _feeTo
    ) external returns (bool);

    // function vaultOwnerAccount(address _receiver, address _collateralToken) external view returns (uint256);
    function flashLoan(address _collateralToken, uint256 _amount, address _receiver, bytes calldata _data) external returns (bool);
    function flashLoanFrom(address _from, address _collateralToken, uint256 _amount, address _receiver, bytes calldata _data) external returns (bool);
    function flashLoanAssets(
        address _from,
        address _collateralToken, 
        uint256 _amount, 
        address _receiver,
        bytes calldata _data
    ) external returns (bool);

    function increaseDebt(address _collateralToken, uint256 _amount, address _receiver) external returns (bool);
    function increaseDebtFrom(address from,address _collateralToken, uint256 _amount, address _receiver) external returns (bool);

    function decreaseDebt(
        address _collateralToken,
        address _receiver
    ) external returns (bool);

     function getPrice(address _token) external view returns (uint256);

    function transferVaultOwner(address _newAccount, address _collateralToken) external;
    // function transferFromVaultOwner(address _from ,address _newAccount, address _collateralToken, uint256 _tokenAssets, uint256 _unitDebt) external;

    function vaultOwnerAccount(address _account, address _collateralToken) external view returns (uint256, uint256);

    function setFreeFlashLoanWhitelist(address _addr, bool _isActive) external;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function approve(address guy, uint wad) external;
    function balanceOf(address from) external view returns(uint256)
    ;
}