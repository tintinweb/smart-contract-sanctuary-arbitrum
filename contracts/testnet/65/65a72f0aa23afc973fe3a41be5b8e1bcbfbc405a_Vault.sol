// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;
import { IVault } from "../interfaces/IVault.sol";
import { ITinuToken } from "../interfaces/ITinuToken.sol";
import { ICollateralManager } from "../interfaces/ICollateralManager.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IVaultPriceFeed } from "../interfaces/IVaultPriceFeed.sol";
import { IFlashLoan } from "../interfaces/IFlashLoan.sol";

contract Vault is IVault {

    event IncreaseCollateral (
        address indexed owner,
        uint256 indexed unitDebt,
        address collateralToken,
        uint256 amount,
        uint256 indexed liquidationPrice
    );

    event DecreaseCollateral (
        address indexed owner,
        uint256 indexed unitDebt,
        address collateralToken,
        uint256 collateralAmount,
        uint256 indexed liquidationPrice
    );

    event CollateralOwnerTrasnfer (
        address indexed from,
        address indexed to,
        address token,
        uint256 tokenAssets,
        uint256 unitDebt
    );

    event IncreaseDebt (
        address indexed owner,
        uint256 indexed unitDebt,
        address collateralToken,
        uint256 amount,
        uint256 indexed liquidationPrice
    );

    event DecreaseDebt (
        address indexed owner,
        uint256 indexed unitDebt,
        address collateralToken,
        uint256 amount,
        uint256 indexed liquidationPrice
    );

    event Approval(
        address indexed owner, 
        address operator,
        bool allow
    );

    event LiquidateCollateral(
        address indexed owner,
        address collateralToken,
        uint256 tokenAssets,
        uint256 unitDebt,
        address feeTo
    );

    address public gov;

    address public tinu;

    address public priceFeed;

    address public treasury;

    uint256 public liquidationTreasuryFee = 990; // 990 = 1.0%

    // uint256 public liquidationRatio = 1150; // 1150 = 15.0% 
    uint256 public minimumCollateral = 100 * 1e18 ; // default 100 UNIT

    uint256 public flashLoanFee = 999; // 999 = 0.1%
    
    struct Account {
        uint256 tokenAssets;
        uint256 tinuDebt;
    }

    mapping (address => mapping (address => Account) ) public override vaultOwnerAccount;

    mapping (address => Account) public vaultPoolAccount;

    mapping(address => mapping(address => bool)) public allowances;

    mapping (address => uint256 ) public liquidationRatio;

    mapping (address => bool) freeFlashLoanWhitelist;
    
    uint private unlocked = 1;
    
    modifier lock() {
        require(unlocked == 1, "Vault: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }
    modifier onlyGov {
        require(msg.sender == gov, "Vault: onlyGov");
        _;
    }

    constructor(address _tinu) {
        gov = msg.sender;
        tinu = _tinu;
    }

    function setGov(address _gov) public onlyGov{
        gov = _gov;
    }

    function setPriceFeed(address _priceFeed) public onlyGov {
        priceFeed = _priceFeed;
    }

    function setLiquidationRatio(address _token, uint256 _ratio) public onlyGov {
        liquidationRatio[_token] = _ratio;
    }
    function setTreasury(address _treasury) public  onlyGov{
        treasury = _treasury;
    }

    function setMinimumCollateral(uint256 _minimumCollateral) public  onlyGov{
        minimumCollateral = _minimumCollateral;
    }

    function setLiquidationTreasuryFee(uint256 _liquidationTreasuryFee) public  onlyGov{
        liquidationTreasuryFee = _liquidationTreasuryFee;
    }

    function setFreeFlashLoanWhitelist(address _addr, bool _isActive)  public  onlyGov{
        freeFlashLoanWhitelist[_addr] = _isActive;
    }

    // the governance controlling this function should have a timelock
    function upgradeVault(address _newVault, address _token, uint256 _amount) external onlyGov {
        IERC20(_token).transfer(_newVault, _amount);
    }

    function approve(address _operator, bool _allow) external override {
        allowances[msg.sender][_operator] = _allow;
        emit Approval(msg.sender, _operator, _allow);
    }

    function increaseCollateral(
        address _collateralToken, 
        address _receiver
    ) external override returns (bool) {
        uint256 _balance0 = vaultPoolAccount[_collateralToken].tokenAssets;
        uint256 _balance1 = IERC20(_collateralToken).balanceOf(address(this));
        require(_balance1 > 0, "Vault: balance1==0");
        uint256 _balanceDelta = _balance1 - _balance0;
        require(_balanceDelta > 0, "Vault: 0");
        vaultOwnerAccount[_receiver][_collateralToken].tokenAssets = 
            vaultOwnerAccount[_receiver][_collateralToken].tokenAssets + _balanceDelta;
        vaultPoolAccount[_collateralToken].tokenAssets = 
            vaultPoolAccount[_collateralToken].tokenAssets + _balanceDelta;
        emit IncreaseCollateral(
            _receiver, 
            vaultOwnerAccount[_receiver][_collateralToken].tinuDebt, 
            _collateralToken, 
            _balanceDelta, 
            _getLiquidationPrice(_receiver, _collateralToken)
        );
        return true;
    }

    function decreaseCollateral(
        address _collateralToken,
        address _receiver,
        uint256 _collateralAmount
    ) external override returns (bool){
        _decreaseCollateral(msg.sender, _collateralToken, _receiver, _collateralAmount, new bytes(0));
        return true;
    }

    function _decreaseCollateral(
        address _from,
        address _collateralToken,
        address _receiver,
        uint256 _collateralAmount,
        bytes memory _params
    ) internal returns (bool){
        uint256 _tokenAssets = vaultOwnerAccount[_from][_collateralToken].tokenAssets;
        require(_collateralAmount <= _tokenAssets, "Vault: not enough collateral");

        vaultOwnerAccount[_from][_collateralToken].tokenAssets = 
            vaultOwnerAccount[_from][_collateralToken].tokenAssets - _collateralAmount;
        vaultPoolAccount[_collateralToken].tokenAssets = 
            vaultPoolAccount[_collateralToken].tokenAssets - _collateralAmount;

       IERC20(_collateralToken).transfer(_receiver, _collateralAmount);

       if (_params.length > 0) IFlashLoan(_receiver).flashLoanCall(_from, _collateralToken, _collateralAmount, _params);

        bool yes = validateLiquidation(_from, _collateralToken, true); 
        require(!yes, "Vault: Collateral amount out of range");

        emit DecreaseCollateral(
            _from, 
            vaultOwnerAccount[_from][_collateralToken].tinuDebt, 
            _collateralToken, 
            _collateralAmount, 
            _getLiquidationPrice(_from, _collateralToken));
        return true;
    }
    
    function decreaseCollateralFrom(
        address _from,
        address _collateralToken,
        address _receiver,
        uint256 _collateralAmount,
        bytes calldata _data
    ) external override returns (bool){
        require(allowances[_from][msg.sender], "Vault: not allow");
        _decreaseCollateral(_from, _collateralToken, _receiver, _collateralAmount, _data);
        return true;
    }

    function _increaseDebt(
        address _from, 
        address _collateralToken, 
        uint256 _amount, 
        address _receiver,
        bytes memory _params
    ) internal returns (bool)  {
        vaultOwnerAccount[_from][_collateralToken].tinuDebt = 
            vaultOwnerAccount[_from][_collateralToken].tinuDebt + _amount;
        ITinuToken(tinu).mint(_receiver, _amount);
        if (_params.length > 0) IFlashLoan(_receiver).flashLoanCall(_from, _collateralToken, _amount, _params);

        bool yes = validateLiquidation(_from, _collateralToken, true);
        require(!yes, "Vault: unit debt out of range");

        emit IncreaseDebt(
            _from, 
            vaultOwnerAccount[_from][_collateralToken].tinuDebt,
            _collateralToken, 
            _amount, 
            _getLiquidationPrice(_from, _collateralToken)
        );
        return true;
    }

    function flashLoan(
        address _collateralToken, 
        uint256 _amount, 
        address _receiver,
        bytes calldata _data
    ) external lock override returns (bool) {
        if(!freeFlashLoanWhitelist[msg.sender] && flashLoanFee > 0) {
            uint256 _fee =  (_amount * 1000 - _amount * flashLoanFee) / 1000;
            IERC20(tinu).transferFrom(msg.sender, treasury, _fee);
        }
        _increaseDebt(msg.sender, _collateralToken, _amount, _receiver, _data);
        return true;
    }
    
    function flashLoanFrom(
        address _from, 
        address _collateralToken, 
        uint256 _amount, 
        address _receiver,
        bytes calldata _data
    ) external lock override returns (bool) {
        require(allowances[_from][msg.sender], "Vault: not allow");
        if(!freeFlashLoanWhitelist[msg.sender] && flashLoanFee > 0) {
            uint256 _fee =  (_amount * 1000 - _amount * flashLoanFee) / 1000;
            IERC20(tinu).transferFrom(msg.sender, treasury, _fee);
        }
        _increaseDebt(_from, _collateralToken, _amount, _receiver, _data);
        return true;
    }

    function flashLoanAssets(
        address _from,
        address _collateralToken,
        uint256 _amount, 
        address _receiver,
        bytes calldata _data
    ) external lock override returns (bool) {
        if(!freeFlashLoanWhitelist[msg.sender] && flashLoanFee > 0) {
            uint256 _fee =  (_amount * 1000 - _amount * flashLoanFee) / 1000;
            IERC20(_collateralToken).transferFrom(msg.sender, treasury, _fee);
        }

        uint256 _totalAmount = IERC20(_collateralToken).balanceOf(address(this));
        require(_amount <= _totalAmount, "Vault: out of total amount");
        IERC20(_collateralToken).transfer(_receiver, _amount); // 放贷
        if (_data.length > 0) IFlashLoan(_receiver).flashLoanCall(_from, _collateralToken, _amount, _data); //使用资金
        IERC20(_collateralToken).transferFrom(_receiver, address(this), _amount); // 收回, 资金必须让合约收回，不能让用户自己还款。
        uint256 _afterTotalAmount = IERC20(_collateralToken).balanceOf(address(this));
        require(_afterTotalAmount >= _totalAmount, "Vault: out of total amount");
        return true;
    }
    
    function increaseDebt(
        address _collateralToken, 
        uint256 _amount, 
        address _receiver
    ) external lock override returns (bool)  {
        _increaseDebt(msg.sender, _collateralToken, _amount, _receiver, new bytes(0));
        return true;
    }
    function increaseDebtFrom(
        address _from, 
        address _collateralToken, 
        uint256 _amount, 
        address _receiver
    ) external lock override returns (bool)  {
        require(allowances[_from][msg.sender], "Vault: not allow");
        _increaseDebt(_from, _collateralToken, _amount, _receiver, new bytes(0));
        return true;
    }

    function decreaseDebt(
        address _collateralToken,
        address _receiver
    ) external override returns (bool) {
        uint256 _balance = IERC20(tinu).balanceOf(address(this));
        require(_balance > 0, "balance == 0");
        ITinuToken(tinu).burn(_balance);
        vaultOwnerAccount[_receiver][_collateralToken].tinuDebt = 
            vaultOwnerAccount[_receiver][_collateralToken].tinuDebt - _balance;
        emit DecreaseDebt(
            _receiver, 
            vaultOwnerAccount[_receiver][_collateralToken].tinuDebt,
            _collateralToken, 
            _balance, 
            _getLiquidationPrice(_receiver, _collateralToken)
        );

        return true;
    }

    function liquidation(address _collateralToken, address _account, address _feeTo) external override returns (bool) {
        bool yes = validateLiquidation(_account, _collateralToken, false);
        require(yes, "Vault: no validateLiquidation");
        uint256 _balance = IERC20(tinu).balanceOf(address(this));
        Account storage account = vaultOwnerAccount[_account][_collateralToken];
        require(_balance >= account.tinuDebt, "Vault: insufficient unit token");
        ITinuToken(tinu).burn(account.tinuDebt);

        // 1%, liquidationTreasuryFee default 990
        uint256 _treasuryFee =  (account.tokenAssets * 1000 - account.tokenAssets * liquidationTreasuryFee) / 1000;
        uint256 _returnCollateral = account.tokenAssets - _treasuryFee;
        account.tinuDebt = 0;
        account.tokenAssets = 0;

        IERC20(_collateralToken).transfer(treasury, _treasuryFee);
        IERC20(_collateralToken).transfer(_feeTo, _returnCollateral);

        emit LiquidateCollateral(_account, _collateralToken, account.tokenAssets, account.tinuDebt, _feeTo);

        return true;
    }

    function validateLiquidation(
        address _account, 
        address _collateralToken, 
        bool _checkCollateral 
    ) public view returns(bool){
        Account memory account = vaultOwnerAccount[_account][_collateralToken];
        uint256 _price = getPrice(_collateralToken);
        uint256 _tokenTinuAmount = tokenToTinu(_price, account.tokenAssets);

        if(_checkCollateral && account.tinuDebt > 0) {
            require(_tokenTinuAmount >=  minimumCollateral, "Vault: minimumTINU");
        }

        if(_tokenTinuAmount * 1000 >= account.tinuDebt * liquidationRatio[_collateralToken]) { // liquidationRatio = 1150.  115.0  
            return false;
        }
        return true;
    }

    function _getLiquidationPrice(address _account, address _collateralToken ) public view returns(uint256) {
        Account memory account = vaultOwnerAccount[_account][_collateralToken];
        if (account.tokenAssets > 0) {
            uint256 _liquidationPrice = account.tinuDebt * liquidationRatio[_collateralToken] / account.tokenAssets;
            return _liquidationPrice;
        } 
        return 0;
    }

    function tokenToTinu(uint256 _price, uint256 amount) public pure returns(uint256){
        return _price * amount / 1e18;
    }

    function getPrice(address _token) public override view returns (uint256) {
        return IVaultPriceFeed(priceFeed).getPrice(_token);
    }
   
    function transferVaultOwner(address _newAccount, address _collateralToken) external override {
        Account storage account = vaultOwnerAccount[msg.sender][_collateralToken];
        Account storage newAccount = vaultOwnerAccount[_newAccount][_collateralToken];
        require(newAccount.tokenAssets == 0, "Vault: newAccount not new");     
        
        newAccount.tokenAssets = newAccount.tokenAssets + account.tokenAssets;
        newAccount.tinuDebt = newAccount.tinuDebt + account.tinuDebt;

        account.tokenAssets = 0;
        account.tinuDebt = 0;
    
        emit CollateralOwnerTrasnfer(msg.sender, _newAccount, _collateralToken, account.tokenAssets, account.tinuDebt);
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

interface ITinuToken {
    function mint(address _to, uint256 value) external returns(bool);
    function burn(uint256 value) external returns(bool);
    // function unitDebt(address _account, address _collateralToken) external view returns( uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

interface ICollateralManager {
    function liquidationFee(address) external view returns(uint256);
    function maxDecreaseCollateralAmount(address _collateralToken, address _account,  uint256 _totalCollateralAmount) external view returns(uint256);
    function maxMintUnitValue(address _collateralToken, address _account) external view returns(uint256);
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

interface IVaultPriceFeed {

    function getPrice(address _token) external view returns (uint256);
 
    function setTokenConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals
    ) external;

    function tokenToUnit(address _token, uint256 _price, uint256 amount) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

interface IFlashLoan {
     function flashLoanCall(address sender, address _collateralToken, uint256 amount, bytes calldata data) external;
}