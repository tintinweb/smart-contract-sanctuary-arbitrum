// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract Governable {
    address public gov;

    constructor() public {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IAdmin {
    function setAdmin(address _admin) external;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/ERC721/IERC721.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "../peripherals/interfaces/ITimelock.sol";

contract TokenManager is ReentrancyGuard {
    using SafeMath for uint256;

    bool public isInitialized;

    uint256 public actionsNonce;
    uint256 public minAuthorizations;

    address public admin;

    address[] public signers;
    mapping (address => bool) public isSigner;
    mapping (bytes32 => bool) public pendingActions;
    mapping (address => mapping (bytes32 => bool)) public signedActions;

    event SignalApprove(address token, address spender, uint256 amount, bytes32 action, uint256 nonce);
    event SignalApproveNFT(address token, address spender, uint256 tokenId, bytes32 action, uint256 nonce);
    event SignalApproveNFTs(address token, address spender, uint256[] tokenIds, bytes32 action, uint256 nonce);
    event SignalSetAdmin(address target, address admin, bytes32 action, uint256 nonce);
    event SignalSetGov(address timelock, address target, address gov, bytes32 action, uint256 nonce);
    event SignalPendingAction(bytes32 action, uint256 nonce);
    event SignAction(bytes32 action, uint256 nonce);
    event ClearAction(bytes32 action, uint256 nonce);

    constructor(uint256 _minAuthorizations) public {
        admin = msg.sender;
        minAuthorizations = _minAuthorizations;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "TokenManager: forbidden");
        _;
    }

    modifier onlySigner() {
        require(isSigner[msg.sender], "TokenManager: forbidden");
        _;
    }

    function initialize(address[] memory _signers) public virtual onlyAdmin {
        require(!isInitialized, "TokenManager: already initialized");
        isInitialized = true;

        signers = _signers;
        for (uint256 i = 0; i < _signers.length; i++) {
            address signer = _signers[i];
            isSigner[signer] = true;
        }
    }

    function signersLength() public view returns (uint256) {
        return signers.length;
    }

    function signalApprove(address _token, address _spender, uint256 _amount) external nonReentrant onlyAdmin {
        actionsNonce++;
        uint256 nonce = actionsNonce;
        bytes32 action = keccak256(abi.encodePacked("approve", _token, _spender, _amount, nonce));
        _setPendingAction(action, nonce);
        emit SignalApprove(_token, _spender, _amount, action, nonce);
    }

    function signApprove(address _token, address _spender, uint256 _amount, uint256 _nonce) external nonReentrant onlySigner {
        bytes32 action = keccak256(abi.encodePacked("approve", _token, _spender, _amount, _nonce));
        _validateAction(action);
        require(!signedActions[msg.sender][action], "TokenManager: already signed");
        signedActions[msg.sender][action] = true;
        emit SignAction(action, _nonce);
    }

    function approve(address _token, address _spender, uint256 _amount, uint256 _nonce) external nonReentrant onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("approve", _token, _spender, _amount, _nonce));
        _validateAction(action);
        _validateAuthorization(action);

        IERC20(_token).approve(_spender, _amount);
        _clearAction(action, _nonce);
    }

    function signalApproveNFT(address _token, address _spender, uint256 _tokenId) external nonReentrant onlyAdmin {
        actionsNonce++;
        uint256 nonce = actionsNonce;
        bytes32 action = keccak256(abi.encodePacked("approveNFT", _token, _spender, _tokenId, nonce));
        _setPendingAction(action, nonce);
        emit SignalApproveNFT(_token, _spender, _tokenId, action, nonce);
    }

    function signApproveNFT(address _token, address _spender, uint256 _tokenId, uint256 _nonce) external nonReentrant onlySigner {
        bytes32 action = keccak256(abi.encodePacked("approveNFT", _token, _spender, _tokenId, _nonce));
        _validateAction(action);
        require(!signedActions[msg.sender][action], "TokenManager: already signed");
        signedActions[msg.sender][action] = true;
        emit SignAction(action, _nonce);
    }

    function approveNFT(address _token, address _spender, uint256 _tokenId, uint256 _nonce) external nonReentrant onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("approveNFT", _token, _spender, _tokenId, _nonce));
        _validateAction(action);
        _validateAuthorization(action);

        IERC721(_token).approve(_spender, _tokenId);
        _clearAction(action, _nonce);
    }

    function signalApproveNFTs(address _token, address _spender, uint256[] memory _tokenIds) external nonReentrant onlyAdmin {
        actionsNonce++;
        uint256 nonce = actionsNonce;
        bytes32 action = keccak256(abi.encodePacked("approveNFTs", _token, _spender, _tokenIds, nonce));
        _setPendingAction(action, nonce);
        emit SignalApproveNFTs(_token, _spender, _tokenIds, action, nonce);
    }

    function signApproveNFTs(address _token, address _spender, uint256[] memory _tokenIds, uint256 _nonce) external nonReentrant onlySigner {
        bytes32 action = keccak256(abi.encodePacked("approveNFTs", _token, _spender, _tokenIds, _nonce));
        _validateAction(action);
        require(!signedActions[msg.sender][action], "TokenManager: already signed");
        signedActions[msg.sender][action] = true;
        emit SignAction(action, _nonce);
    }

    function approveNFTs(address _token, address _spender, uint256[] memory _tokenIds, uint256 _nonce) external nonReentrant onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("approveNFTs", _token, _spender, _tokenIds, _nonce));
        _validateAction(action);
        _validateAuthorization(action);

        for (uint256 i = 0 ; i < _tokenIds.length; i++) {
            IERC721(_token).approve(_spender, _tokenIds[i]);
        }
        _clearAction(action, _nonce);
    }

    function receiveNFTs(address _token, address _sender, uint256[] memory _tokenIds) external nonReentrant onlyAdmin {
        for (uint256 i = 0 ; i < _tokenIds.length; i++) {
            IERC721(_token).transferFrom(_sender, address(this), _tokenIds[i]);
        }
    }

    function signalSetAdmin(address _target, address _admin) external nonReentrant onlySigner {
        actionsNonce++;
        uint256 nonce = actionsNonce;
        bytes32 action = keccak256(abi.encodePacked("setAdmin", _target, _admin, nonce));
        _setPendingAction(action, nonce);
        signedActions[msg.sender][action] = true;
        emit SignalSetAdmin(_target, _admin, action, nonce);
    }

    function signSetAdmin(address _target, address _admin, uint256 _nonce) external nonReentrant onlySigner {
        bytes32 action = keccak256(abi.encodePacked("setAdmin", _target, _admin, _nonce));
        _validateAction(action);
        require(!signedActions[msg.sender][action], "TokenManager: already signed");
        signedActions[msg.sender][action] = true;
        emit SignAction(action, _nonce);
    }

    function setAdmin(address _target, address _admin, uint256 _nonce) external nonReentrant onlySigner {
        bytes32 action = keccak256(abi.encodePacked("setAdmin", _target, _admin, _nonce));
        _validateAction(action);
        _validateAuthorization(action);

        ITimelock(_target).setAdmin(_admin);
        _clearAction(action, _nonce);
    }

    function signalSetGov(address _timelock, address _target, address _gov) external nonReentrant onlyAdmin {
        actionsNonce++;
        uint256 nonce = actionsNonce;
        bytes32 action = keccak256(abi.encodePacked("signalSetGov", _timelock, _target, _gov, nonce));
        _setPendingAction(action, nonce);
        signedActions[msg.sender][action] = true;
        emit SignalSetGov(_timelock, _target, _gov, action, nonce);
    }

    function signSetGov(address _timelock, address _target, address _gov, uint256 _nonce) external nonReentrant onlySigner {
        bytes32 action = keccak256(abi.encodePacked("signalSetGov", _timelock, _target, _gov, _nonce));
        _validateAction(action);
        require(!signedActions[msg.sender][action], "TokenManager: already signed");
        signedActions[msg.sender][action] = true;
        emit SignAction(action, _nonce);
    }

    function setGov(address _timelock, address _target, address _gov, uint256 _nonce) external nonReentrant onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("signalSetGov", _timelock, _target, _gov, _nonce));
        _validateAction(action);
        _validateAuthorization(action);

        ITimelock(_timelock).signalSetGov(_target, _gov);
        _clearAction(action, _nonce);
    }

    function _setPendingAction(bytes32 _action, uint256 _nonce) private {
        pendingActions[_action] = true;
        emit SignalPendingAction(_action, _nonce);
    }

    function _validateAction(bytes32 _action) private view {
        require(pendingActions[_action], "TokenManager: action not signalled");
    }

    function _validateAuthorization(bytes32 _action) private view {
        uint256 count = 0;
        for (uint256 i = 0; i < signers.length; i++) {
            address signer = signers[i];
            if (signedActions[signer][_action]) {
                count++;
            }
        }

        if (count == 0) {
            revert("TokenManager: action not authorized");
        }
        require(count >= minAuthorizations, "TokenManager: insufficient authorization");
    }

    function _clearAction(bytes32 _action, uint256 _nonce) private {
        require(pendingActions[_action], "TokenManager: invalid _action");
        delete pendingActions[_action];
        emit ClearAction(_action, _nonce);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./interfaces/IAmmFactory.sol";

contract AmmFactory is IAmmFactory {
    address public btc;
    address public bnb;
    address public busd;

    address public bnbBusdPair;
    address public btcBnbPair;

    constructor(address[] memory _addresses) public {
        btc = _addresses[0];
        bnb = _addresses[1];
        busd = _addresses[2];

        bnbBusdPair = _addresses[3];
        btcBnbPair = _addresses[4];
    }

    function getPair(address tokenA, address tokenB) external override view returns (address) {
        if (tokenA == busd && tokenB == bnb) {
            return bnbBusdPair;
        }
        if (tokenA == bnb && tokenB == btc) {
            return btcBnbPair;
        }
        revert("Invalid tokens");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./interfaces/IAmmPair.sol";

contract AmmPair is IAmmPair {
    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    function setReserves(uint256 balance0, uint256 balance1) external {
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = uint32(block.timestamp);
    }

    function getReserves() public override view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../tokens/Token.sol";
import "../libraries/token/IERC20.sol";
import "./interfaces/IAmmRouter.sol";

contract AmmRouter is IAmmRouter {
    address public pair;

    constructor(address _pair) public {
        pair = _pair;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 /*amountAMin*/,
        uint256 /*amountBMin*/,
        address to,
        uint256 deadline
    ) external override returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(deadline >= block.timestamp, 'PancakeRouter: EXPIRED');

        Token(pair).mint(to, 1000);

        IERC20(tokenA).transferFrom(msg.sender, pair, amountADesired);
        IERC20(tokenB).transferFrom(msg.sender, pair, amountBDesired);

        amountA = amountADesired;
        amountB = amountBDesired;
        liquidity = 1000;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IAmmFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IAmmPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IAmmRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../tokens/MintableBaseToken.sol";

contract BLP is MintableBaseToken {
    constructor() public MintableBaseToken("BLP", "BLP", 0) {
    }

    function id() external pure returns (string memory _name) {
        return "BLP";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../tokens/MintableBaseToken.sol";

contract BXP is MintableBaseToken {
    constructor() public MintableBaseToken("BXP", "BXP", 0) {
    }

    function id() external pure returns (string memory _name) {
        return "BXP";
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "../tokens/interfaces/IMintable.sol";
import "../access/TokenManager.sol";

contract BxpFloor is ReentrancyGuard, TokenManager {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant BURN_BASIS_POINTS = 9000;

    address public bxp;
    address public reserveToken;
    uint256 public backedSupply;
    uint256 public baseMintPrice;
    uint256 public mintMultiplier;
    uint256 public mintedSupply;
    uint256 public multiplierPrecision;

    mapping (address => bool) public isHandler;

    modifier onlyHandler() {
        require(isHandler[msg.sender], "BxpFloor: forbidden");
        _;
    }

    constructor(
        address _bxp,
        address _reserveToken,
        uint256 _backedSupply,
        uint256 _baseMintPrice,
        uint256 _mintMultiplier,
        uint256 _multiplierPrecision,
        uint256 _minAuthorizations
    ) public TokenManager(_minAuthorizations) {
        bxp = _bxp;

        reserveToken = _reserveToken;
        backedSupply = _backedSupply;

        baseMintPrice = _baseMintPrice;
        mintMultiplier = _mintMultiplier;
        multiplierPrecision = _multiplierPrecision;
    }

    function initialize(address[] memory _signers) public override onlyAdmin {
        TokenManager.initialize(_signers);
    }

    function setHandler(address _handler, bool _isHandler) public onlyAdmin {
        isHandler[_handler] = _isHandler;
    }

    function setBackedSupply(uint256 _backedSupply) public onlyAdmin {
        require(_backedSupply > backedSupply, "BxpFloor: invalid _backedSupply");
        backedSupply = _backedSupply;
    }

    function setMintMultiplier(uint256 _mintMultiplier) public onlyAdmin {
        require(_mintMultiplier > mintMultiplier, "BxpFloor: invalid _mintMultiplier");
        mintMultiplier = _mintMultiplier;
    }

    // mint refers to increasing the circulating supply
    // the BXP tokens to be transferred out must be pre-transferred into this contract
    function mint(uint256 _amount, uint256 _maxCost, address _receiver) public onlyHandler nonReentrant returns (uint256) {
        require(_amount > 0, "BxpFloor: invalid _amount");

        uint256 currentMintPrice = getMintPrice();
        uint256 nextMintPrice = currentMintPrice.add(_amount.mul(mintMultiplier).div(multiplierPrecision));
        uint256 averageMintPrice = currentMintPrice.add(nextMintPrice).div(2);

        uint256 cost = _amount.mul(averageMintPrice).div(PRICE_PRECISION);
        require(cost <= _maxCost, "BxpFloor: _maxCost exceeded");

        mintedSupply = mintedSupply.add(_amount);
        backedSupply = backedSupply.add(_amount);

        IERC20(reserveToken).safeTransferFrom(msg.sender, address(this), cost);
        IERC20(bxp).transfer(_receiver, _amount);

        return cost;
    }

    function burn(uint256 _amount, uint256 _minOut, address _receiver) public onlyHandler nonReentrant returns (uint256) {
        require(_amount > 0, "BxpFloor: invalid _amount");

        uint256 amountOut = getBurnAmountOut(_amount);
        require(amountOut >= _minOut, "BxpFloor: insufficient amountOut");

        backedSupply = backedSupply.sub(_amount);

        IMintable(bxp).burn(msg.sender, _amount);
        IERC20(reserveToken).safeTransfer(_receiver, amountOut);

        return amountOut;
    }

    function getMintPrice() public view returns (uint256) {
        return baseMintPrice.add(mintedSupply.mul(mintMultiplier).div(multiplierPrecision));
    }

    function getBurnAmountOut(uint256 _amount) public view returns (uint256) {
        uint256 balance = IERC20(reserveToken).balanceOf(address(this));
        return _amount.mul(balance).div(backedSupply).mul(BURN_BASIS_POINTS).div(BASIS_POINTS_DIVISOR);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/math/SafeMath.sol";

import "./interfaces/IBxpIou.sol";

contract BxpIou is IERC20, IBxpIou {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    uint256 public override totalSupply;

    string public name;
    string public symbol;
    uint8 public decimals;

    address public minter;

    constructor (address _minter, string memory _name, string memory _symbol) public {
        name = _name;
        symbol = _symbol;
        minter = _minter;
        decimals = 18;
    }

    function mint(address account, uint256 amount) public override returns (bool) {
        require(msg.sender == minter, "BxpIou: forbidden");
        _mint(account, amount);
        return true;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // empty implementation, BxpIou tokens are non-transferrable
    function transfer(address /* recipient */, uint256 /* amount */) public override returns (bool) {
        revert("BxpIou: non-transferrable");
    }

    // empty implementation, BxpIou tokens are non-transferrable
    function allowance(address /* owner */, address /* spender */) public view virtual override returns (uint256) {
        return 0;
    }

    // empty implementation, BxpIou tokens are non-transferrable
    function approve(address /* spender */, uint256 /* amount */) public virtual override returns (bool) {
        revert("BxpIou: non-transferrable");
    }

    // empty implementation, BxpIou tokens are non-transferrable
    function transferFrom(address /* sender */, address /* recipient */, uint256 /* amount */) public virtual override returns (bool) {
        revert("BxpIou: non-transferrable");
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BxpIou: mint to the zero address");

        totalSupply = totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IBxpIou.sol";
import "./interfaces/IAmmRouter.sol";
import "./interfaces/IBxpMigrator.sol";

contract BxpMigrator is ReentrancyGuard, IBxpMigrator {
    using SafeMath for uint256;

    bool public isInitialized;
    bool public isMigrationActive = true;
    bool public hasMaxMigrationLimit = false;

    uint256 public minAuthorizations;

    address public ammRouter;
    uint256 public bxpPrice;

    uint256 public actionsNonce;
    address public admin;

    address[] public signers;
    mapping (address => bool) public isSigner;
    mapping (bytes32 => bool) public pendingActions;
    mapping (address => mapping (bytes32 => bool)) public signedActions;

    mapping (address => bool) public whitelistedTokens;
    mapping (address => address) public override iouTokens;
    mapping (address => uint256) public prices;
    mapping (address => uint256) public caps;

    mapping (address => bool) public lpTokens;
    mapping (address => address) public lpTokenAs;
    mapping (address => address) public lpTokenBs;

    mapping (address => uint256) public tokenAmounts;

    mapping (address => mapping (address => uint256)) public migratedAmounts;
    mapping (address => mapping (address => uint256)) public maxMigrationAmounts;

    event SignalApprove(address token, address spender, uint256 amount, bytes32 action, uint256 nonce);

    event SignalPendingAction(bytes32 action, uint256 nonce);
    event SignAction(bytes32 action, uint256 nonce);
    event ClearAction(bytes32 action, uint256 nonce);

    constructor(uint256 _minAuthorizations) public {
        admin = msg.sender;
        minAuthorizations = _minAuthorizations;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "BxpMigrator: forbidden");
        _;
    }

    modifier onlySigner() {
        require(isSigner[msg.sender], "BxpMigrator: forbidden");
        _;
    }

    function initialize(
        address _ammRouter,
        uint256 _bxpPrice,
        address[] memory _signers,
        address[] memory _whitelistedTokens,
        address[] memory _iouTokens,
        uint256[] memory _prices,
        uint256[] memory _caps,
        address[] memory _lpTokens,
        address[] memory _lpTokenAs,
        address[] memory _lpTokenBs
    ) public onlyAdmin {
        require(!isInitialized, "BxpMigrator: already initialized");
        require(_whitelistedTokens.length == _iouTokens.length, "BxpMigrator: invalid _iouTokens.length");
        require(_whitelistedTokens.length == _prices.length, "BxpMigrator: invalid _prices.length");
        require(_whitelistedTokens.length == _caps.length, "BxpMigrator: invalid _caps.length");
        require(_lpTokens.length == _lpTokenAs.length, "BxpMigrator: invalid _lpTokenAs.length");
        require(_lpTokens.length == _lpTokenBs.length, "BxpMigrator: invalid _lpTokenBs.length");

        isInitialized = true;

        ammRouter = _ammRouter;
        bxpPrice = _bxpPrice;

        signers = _signers;
        for (uint256 i = 0; i < _signers.length; i++) {
            address signer = _signers[i];
            isSigner[signer] = true;
        }

        for (uint256 i = 0; i < _whitelistedTokens.length; i++) {
            address token = _whitelistedTokens[i];
            whitelistedTokens[token] = true;
            iouTokens[token] = _iouTokens[i];
            prices[token] = _prices[i];
            caps[token] = _caps[i];
        }

        for (uint256 i = 0; i < _lpTokens.length; i++) {
            address token = _lpTokens[i];
            lpTokens[token] = true;
            lpTokenAs[token] = _lpTokenAs[i];
            lpTokenBs[token] = _lpTokenBs[i];
        }
    }

    function endMigration() public onlyAdmin {
        isMigrationActive = false;
    }

    function setHasMaxMigrationLimit(bool _hasMaxMigrationLimit) public onlyAdmin {
        hasMaxMigrationLimit = _hasMaxMigrationLimit;
    }

    function setMaxMigrationAmount(address _account, address _token, uint256 _maxMigrationAmount) public onlyAdmin {
        maxMigrationAmounts[_account][_token] = _maxMigrationAmount;
    }

    function migrate(
        address _token,
        uint256 _tokenAmount
    ) public nonReentrant {
        require(isMigrationActive, "BxpMigrator: migration is no longer active");
        require(whitelistedTokens[_token], "BxpMigrator: token not whitelisted");
        require(_tokenAmount > 0, "BxpMigrator: invalid tokenAmount");

        if (hasMaxMigrationLimit) {
            migratedAmounts[msg.sender][_token] = migratedAmounts[msg.sender][_token].add(_tokenAmount);
            require(migratedAmounts[msg.sender][_token] <= maxMigrationAmounts[msg.sender][_token], "BxpMigrator: maxMigrationAmount exceeded");
        }

        uint256 tokenPrice = getTokenPrice(_token);
        uint256 mintAmount = _tokenAmount.mul(tokenPrice).div(bxpPrice);
        require(mintAmount > 0, "BxpMigrator: invalid mintAmount");

        tokenAmounts[_token] = tokenAmounts[_token].add(_tokenAmount);
        require(tokenAmounts[_token] < caps[_token], "BxpMigrator: token cap exceeded");

        IERC20(_token).transferFrom(msg.sender, address(this), _tokenAmount);

        if (lpTokens[_token]) {
            address tokenA = lpTokenAs[_token];
            address tokenB = lpTokenBs[_token];
            require(tokenA != address(0), "BxpMigrator: invalid tokenA");
            require(tokenB != address(0), "BxpMigrator: invalid tokenB");

            IERC20(_token).approve(ammRouter, _tokenAmount);
            IAmmRouter(ammRouter).removeLiquidity(tokenA, tokenB, _tokenAmount, 0, 0, address(this), block.timestamp);
        }

        address iouToken = getIouToken(_token);
        IBxpIou(iouToken).mint(msg.sender, mintAmount);
    }

    function signalApprove(address _token, address _spender, uint256 _amount) external nonReentrant onlyAdmin {
        actionsNonce++;
        uint256 nonce = actionsNonce;
        bytes32 action = keccak256(abi.encodePacked("approve", _token, _spender, _amount, nonce));
        _setPendingAction(action, nonce);
        emit SignalApprove(_token, _spender, _amount, action, nonce);
    }

    function signApprove(address _token, address _spender, uint256 _amount, uint256 _nonce) external nonReentrant onlySigner {
        bytes32 action = keccak256(abi.encodePacked("approve", _token, _spender, _amount, _nonce));
        _validateAction(action);
        require(!signedActions[msg.sender][action], "BxpMigrator: already signed");
        signedActions[msg.sender][action] = true;
        emit SignAction(action, _nonce);
    }

    function approve(address _token, address _spender, uint256 _amount, uint256 _nonce) external nonReentrant onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("approve", _token, _spender, _amount, _nonce));
        _validateAction(action);
        _validateAuthorization(action);

        IERC20(_token).approve(_spender, _amount);
        _clearAction(action, _nonce);
    }

    function getTokenAmounts(address[] memory _tokens) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            amounts[i] = tokenAmounts[token];
        }

        return amounts;
    }

    function getTokenPrice(address _token) public view returns (uint256) {
        uint256 price = prices[_token];
        require(price != 0, "BxpMigrator: invalid token price");
        return price;
    }

    function getIouToken(address _token) public view returns (address) {
        address iouToken = iouTokens[_token];
        require(iouToken != address(0), "BxpMigrator: invalid iou token");
        return iouToken;
    }

    function _setPendingAction(bytes32 _action, uint256 _nonce) private {
        pendingActions[_action] = true;
        emit SignalPendingAction(_action, _nonce);
    }

    function _validateAction(bytes32 _action) private view {
        require(pendingActions[_action], "BxpMigrator: action not signalled");
    }

    function _validateAuthorization(bytes32 _action) private view {
        uint256 count = 0;
        for (uint256 i = 0; i < signers.length; i++) {
            address signer = signers[i];
            if (signedActions[signer][_action]) {
                count++;
            }
        }

        if (count == 0) {
            revert("BxpMigrator: action not authorized");
        }
        require(count >= minAuthorizations, "BxpMigrator: insufficient authorization");
    }

    function _clearAction(bytes32 _action, uint256 _nonce) private {
        require(pendingActions[_action], "BxpMigrator: invalid _action");
        delete pendingActions[_action];
        emit ClearAction(_action, _nonce);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../tokens/MintableBaseToken.sol";

contract htdBXP is MintableBaseToken {
    constructor() public MintableBaseToken("htdBXP", "htdBXP", 0) {
    }

    function id() external pure returns (string memory _name) {
        return "htdBXP";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IAmmRouter {
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IBxpIou {
    function mint(address account, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IBxpMigrator {
    function iouTokens(address _token) external view returns (address);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IAmmRouter.sol";
import "./interfaces/IBxpMigrator.sol";
import "../core/interfaces/IVault.sol";

contract MigrationHandler is ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public constant BXD_PRECISION = 10 ** 18;

    bool public isInitialized;

    address public admin;
    address public ammRouterV1;
    address public ammRouterV2;

    address public vault;

    address public gmt;
    address public xgmt;
    address public bxd;
    address public bnb;
    address public busd;

    mapping (address => mapping (address => uint256)) public refundedAmounts;

    modifier onlyAdmin() {
        require(msg.sender == admin, "MigrationHandler: forbidden");
        _;
    }

    constructor() public {
        admin = msg.sender;
    }

    function initialize(
        address _ammRouterV1,
        address _ammRouterV2,
        address _vault,
        address _gmt,
        address _xgmt,
        address _bxd,
        address _bnb,
        address _busd
    ) public onlyAdmin {
        require(!isInitialized, "MigrationHandler: already initialized");
        isInitialized = true;

        ammRouterV1 = _ammRouterV1;
        ammRouterV2 = _ammRouterV2;

        vault = _vault;

        gmt = _gmt;
        xgmt = _xgmt;
        bxd = _bxd;
        bnb = _bnb;
        busd = _busd;
    }

    function redeemBxd(
        address _migrator,
        address _redemptionToken,
        uint256 _bxdAmount
    ) external onlyAdmin nonReentrant {
        IERC20(bxd).transferFrom(_migrator, vault, _bxdAmount);
        uint256 amount = IVault(vault).sellBXD(_redemptionToken, address(this));

        address[] memory path = new address[](2);
        path[0] = bnb;
        path[1] = busd;

        if (_redemptionToken != bnb) {
            path = new address[](3);
            path[0] = _redemptionToken;
            path[1] = bnb;
            path[2] = busd;
        }

        IERC20(_redemptionToken).approve(ammRouterV2, amount);
        IAmmRouter(ammRouterV2).swapExactTokensForTokens(
            amount,
            0,
            path,
            _migrator,
            block.timestamp
        );
    }

    function swap(
        address _migrator,
        uint256 _gmtAmountForBxd,
        uint256 _xgmtAmountForBxd,
        uint256 _gmtAmountForBusd
    ) external onlyAdmin nonReentrant {
        address[] memory path = new address[](2);

        path[0] = gmt;
        path[1] = bxd;
        IERC20(gmt).transferFrom(_migrator, address(this), _gmtAmountForBxd);
        IERC20(gmt).approve(ammRouterV2, _gmtAmountForBxd);
        IAmmRouter(ammRouterV2).swapExactTokensForTokens(
            _gmtAmountForBxd,
            0,
            path,
            _migrator,
            block.timestamp
        );

        path[0] = xgmt;
        path[1] = bxd;
        IERC20(xgmt).transferFrom(_migrator, address(this), _xgmtAmountForBxd);
        IERC20(xgmt).approve(ammRouterV2, _xgmtAmountForBxd);
        IAmmRouter(ammRouterV2).swapExactTokensForTokens(
            _xgmtAmountForBxd,
            0,
            path,
            _migrator,
            block.timestamp
        );

        path[0] = gmt;
        path[1] = busd;
        IERC20(gmt).transferFrom(_migrator, address(this), _gmtAmountForBusd);
        IERC20(gmt).approve(ammRouterV1, _gmtAmountForBusd);
        IAmmRouter(ammRouterV1).swapExactTokensForTokens(
            _gmtAmountForBusd,
            0,
            path,
            _migrator,
            block.timestamp
        );
    }

    function refund(
        address _migrator,
        address _account,
        address _token,
        uint256 _bxdAmount
    ) external onlyAdmin nonReentrant {
        address iouToken = IBxpMigrator(_migrator).iouTokens(_token);
        uint256 iouBalance = IERC20(iouToken).balanceOf(_account);
        uint256 iouTokenAmount = _bxdAmount.div(2); // each BXP is priced at $2

        uint256 refunded = refundedAmounts[_account][iouToken];
        refundedAmounts[_account][iouToken] = refunded.add(iouTokenAmount);

        require(refundedAmounts[_account][iouToken] <= iouBalance, "MigrationHandler: refundable amount exceeded");

        IERC20(bxd).transferFrom(_migrator, _account, _bxdAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../tokens/interfaces/IWETH.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/Address.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IRouter.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IShortsTracker.sol";
import "./interfaces/IOrderBook.sol";
import "./interfaces/IBasePositionManager.sol";

import "../access/Governable.sol";
import "../peripherals/interfaces/ITimelock.sol";
import "../referrals/interfaces/IReferralStorage.sol";

import "./PositionUtils.sol";

contract BasePositionManager is IBasePositionManager, ReentrancyGuard, Governable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    address public admin;

    address public vault;
    address public shortsTracker;
    address public router;
    address public weth;

    uint256 public ethTransferGasLimit = 500 * 1000;

    // to prevent using the deposit and withdrawal of collateral as a zero fee swap,
    // there is a small depositFee charged if a collateral deposit results in the decrease
    // of leverage for an existing position
    // increasePositionBufferBps allows for a small amount of decrease of leverage
    uint256 public depositFee;
    uint256 public increasePositionBufferBps = 100;

    address public referralStorage;

    mapping (address => uint256) public feeReserves;

    mapping (address => uint256) public override maxGlobalLongSizes;
    mapping (address => uint256) public override maxGlobalShortSizes;

    event SetDepositFee(uint256 depositFee);
    event SetEthTransferGasLimit(uint256 ethTransferGasLimit);
    event SetIncreasePositionBufferBps(uint256 increasePositionBufferBps);
    event SetReferralStorage(address referralStorage);
    event SetAdmin(address admin);
    event WithdrawFees(address token, address receiver, uint256 amount);

    event SetMaxGlobalSizes(
        address[] tokens,
        uint256[] longSizes,
        uint256[] shortSizes
    );

    event IncreasePositionReferral(
        address account,
        uint256 sizeDelta,
        uint256 marginFeeBasisPoints,
        bytes32 referralCode,
        address referrer
    );

    event DecreasePositionReferral(
        address account,
        uint256 sizeDelta,
        uint256 marginFeeBasisPoints,
        bytes32 referralCode,
        address referrer
    );

    modifier onlyAdmin() {
        require(msg.sender == admin, "forbidden");
        _;
    }

    constructor(
        address _vault,
        address _router,
        address _shortsTracker,
        address _weth,
        uint256 _depositFee
    ) public {
        vault = _vault;
        router = _router;
        weth = _weth;
        depositFee = _depositFee;
        shortsTracker = _shortsTracker;

        admin = msg.sender;
    }

    receive() external payable {
        require(msg.sender == weth, "invalid sender");
    }

    function setAdmin(address _admin) external onlyGov {
        admin = _admin;
        emit SetAdmin(_admin);
    }

    function setEthTransferGasLimit(uint256 _ethTransferGasLimit) external onlyAdmin {
        ethTransferGasLimit = _ethTransferGasLimit;
        emit SetEthTransferGasLimit(_ethTransferGasLimit);
    }

    function setDepositFee(uint256 _depositFee) external onlyAdmin {
        depositFee = _depositFee;
        emit SetDepositFee(_depositFee);
    }

    function setIncreasePositionBufferBps(uint256 _increasePositionBufferBps) external onlyAdmin {
        increasePositionBufferBps = _increasePositionBufferBps;
        emit SetIncreasePositionBufferBps(_increasePositionBufferBps);
    }

    function setReferralStorage(address _referralStorage) external onlyAdmin {
        referralStorage = _referralStorage;
        emit SetReferralStorage(_referralStorage);
    }

    function setMaxGlobalSizes(
        address[] memory _tokens,
        uint256[] memory _longSizes,
        uint256[] memory _shortSizes
    ) external onlyAdmin {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            maxGlobalLongSizes[token] = _longSizes[i];
            maxGlobalShortSizes[token] = _shortSizes[i];
        }

        emit SetMaxGlobalSizes(_tokens, _longSizes, _shortSizes);
    }

    function withdrawFees(address _token, address _receiver) external onlyAdmin {
        uint256 amount = feeReserves[_token];
        if (amount == 0) { return; }

        feeReserves[_token] = 0;
        IERC20(_token).safeTransfer(_receiver, amount);

        emit WithdrawFees(_token, _receiver, amount);
    }

    function approve(address _token, address _spender, uint256 _amount) external onlyGov {
        IERC20(_token).approve(_spender, _amount);
    }

    function sendValue(address payable _receiver, uint256 _amount) external onlyGov {
        _receiver.sendValue(_amount);
    }

    function _validateMaxGlobalSize(address _indexToken, bool _isLong, uint256 _sizeDelta) internal view {
        if (_sizeDelta == 0) {
            return;
        }

        if (_isLong) {
            uint256 maxGlobalLongSize = maxGlobalLongSizes[_indexToken];
            if (maxGlobalLongSize > 0 && IVault(vault).guaranteedUsd(_indexToken).add(_sizeDelta) > maxGlobalLongSize) {
                revert("max longs exceeded");
            }
        } else {
            uint256 maxGlobalShortSize = maxGlobalShortSizes[_indexToken];
            if (maxGlobalShortSize > 0 && IVault(vault).globalShortSizes(_indexToken).add(_sizeDelta) > maxGlobalShortSize) {
                revert("max shorts exceeded");
            }
        }
    }

    function _increasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong, uint256 _price) internal {
        _validateMaxGlobalSize(_indexToken, _isLong, _sizeDelta);

        PositionUtils.increasePosition(
            vault,
            router,
            shortsTracker,
            _account,
            _collateralToken,
            _indexToken,
            _sizeDelta,
            _isLong,
            _price
        );

        _emitIncreasePositionReferral(_account, _sizeDelta);
    }

    function _decreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver, uint256 _price) internal returns (uint256) {
        address _vault = vault;

        uint256 markPrice = _isLong ? IVault(_vault).getMinPrice(_indexToken) : IVault(_vault).getMaxPrice(_indexToken);
        if (_isLong) {
            require(markPrice >= _price, "markPrice < price");
        } else {
            require(markPrice <= _price, "markPrice > price");
        }

        address timelock = IVault(_vault).gov();

        // should be called strictly before position is updated in Vault
        IShortsTracker(shortsTracker).updateGlobalShortData(_account, _collateralToken, _indexToken, _isLong, _sizeDelta, markPrice, false);

        ITimelock(timelock).enableLeverage(_vault);
        uint256 amountOut = IRouter(router).pluginDecreasePosition(_account, _collateralToken, _indexToken, _collateralDelta, _sizeDelta, _isLong, _receiver);
        ITimelock(timelock).disableLeverage(_vault);

        _emitDecreasePositionReferral(
            _account,
            _sizeDelta
        );

        return amountOut;
    }

    function _swap(address[] memory _path, uint256 _minOut, address _receiver) internal returns (uint256) {
        if (_path.length == 2) {
            return _vaultSwap(_path[0], _path[1], _minOut, _receiver);
        }
        revert("invalid _path.length");
    }

    function _vaultSwap(address _tokenIn, address _tokenOut, uint256 _minOut, address _receiver) internal returns (uint256) {
        uint256 amountOut = IVault(vault).swap(_tokenIn, _tokenOut, _receiver);
        require(amountOut >= _minOut, "insufficient amountOut");
        return amountOut;
    }

    function _transferInETH() internal {
        if (msg.value != 0) {
            IWETH(weth).deposit{value: msg.value}();
        }
    }

    function _transferOutETHWithGasLimitFallbackToWeth(uint256 _amountOut, address payable _receiver) internal {
        IWETH _weth = IWETH(weth);
        _weth.withdraw(_amountOut);

        (bool success, /* bytes memory data */) = _receiver.call{ value: _amountOut, gas: ethTransferGasLimit }("");

        if (success) { return; }

        // if the transfer failed, re-wrap the token and send it to the receiver
        _weth.deposit{ value: _amountOut }();
        _weth.transfer(address(_receiver), _amountOut);
    }

    function _collectFees(
        address _account,
        address[] memory _path,
        uint256 _amountIn,
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta
    ) internal returns (uint256) {
        bool shouldDeductFee = PositionUtils.shouldDeductFee(
            vault,
            _account,
            _path,
            _amountIn,
            _indexToken,
            _isLong,
            _sizeDelta,
            increasePositionBufferBps
        );

        if (shouldDeductFee) {
            uint256 afterFeeAmount = _amountIn.mul(BASIS_POINTS_DIVISOR.sub(depositFee)).div(BASIS_POINTS_DIVISOR);
            uint256 feeAmount = _amountIn.sub(afterFeeAmount);
            address feeToken = _path[_path.length - 1];
            feeReserves[feeToken] = feeReserves[feeToken].add(feeAmount);
            return afterFeeAmount;
        }

        return _amountIn;
    }

    function _emitIncreasePositionReferral(address _account, uint256 _sizeDelta) internal {
        address _referralStorage = referralStorage;
        if (_referralStorage == address(0)) { return; }


        (bytes32 referralCode, address referrer) = IReferralStorage(_referralStorage).getTraderReferralInfo(_account);
        if (referralCode == bytes32(0)) { return; }

        address timelock = IVault(vault).gov();

        emit IncreasePositionReferral(
            _account,
            _sizeDelta,
            ITimelock(timelock).marginFeeBasisPoints(),
            referralCode,
            referrer
        );
    }

    function _emitDecreasePositionReferral(address _account, uint256 _sizeDelta) internal {
        address _referralStorage = referralStorage;
        if (_referralStorage == address(0)) { return; }

        (bytes32 referralCode, address referrer) = IReferralStorage(_referralStorage).getTraderReferralInfo(_account);
        if (referralCode == bytes32(0)) { return; }

        address timelock = IVault(vault).gov();

        emit DecreasePositionReferral(
            _account,
            _sizeDelta,
            ITimelock(timelock).marginFeeBasisPoints(),
            referralCode,
            referrer
        );
    }
}

// SPDX-License-Identifier: MIT

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IVault.sol";
import "./interfaces/IBlpManager.sol";
import "./interfaces/IShortsTracker.sol";
import "../tokens/interfaces/IBXD.sol";
import "../tokens/interfaces/IMintable.sol";
import "../access/Governable.sol";

pragma solidity 0.6.12;

contract BlpManager is ReentrancyGuard, Governable, IBlpManager {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant BXD_DECIMALS = 18;
    uint256 public constant BLP_PRECISION = 10 ** 18;
    uint256 public constant MAX_COOLDOWN_DURATION = 48 hours;
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    IVault public override vault;
    IShortsTracker public shortsTracker;
    address public override bxd;
    address public override blp;

    uint256 public override cooldownDuration;
    mapping (address => uint256) public override lastAddedAt;

    uint256 public aumAddition;
    uint256 public aumDeduction;

    bool public inPrivateMode;
    uint256 public shortsTrackerAveragePriceWeight;
    mapping (address => bool) public isHandler;

    event AddLiquidity(
        address account,
        address token,
        uint256 amount,
        uint256 aumInBxd,
        uint256 blpSupply,
        uint256 bxdAmount,
        uint256 mintAmount
    );

    event RemoveLiquidity(
        address account,
        address token,
        uint256 blpAmount,
        uint256 aumInBxd,
        uint256 blpSupply,
        uint256 bxdAmount,
        uint256 amountOut
    );

    constructor(address _vault, address _bxd, address _blp, address _shortsTracker, uint256 _cooldownDuration) public {
        gov = msg.sender;
        vault = IVault(_vault);
        bxd = _bxd;
        blp = _blp;
        shortsTracker = IShortsTracker(_shortsTracker);
        cooldownDuration = _cooldownDuration;
    }

    function setInPrivateMode(bool _inPrivateMode) external onlyGov {
        inPrivateMode = _inPrivateMode;
    }

    function setShortsTracker(IShortsTracker _shortsTracker) external onlyGov {
        shortsTracker = _shortsTracker;
    }

    function setShortsTrackerAveragePriceWeight(uint256 _shortsTrackerAveragePriceWeight) external override onlyGov {
        require(shortsTrackerAveragePriceWeight <= BASIS_POINTS_DIVISOR, "BlpManager: invalid weight");
        shortsTrackerAveragePriceWeight = _shortsTrackerAveragePriceWeight;
    }

    function setHandler(address _handler, bool _isActive) external onlyGov {
        isHandler[_handler] = _isActive;
    }

    function setCooldownDuration(uint256 _cooldownDuration) external override onlyGov {
        require(_cooldownDuration <= MAX_COOLDOWN_DURATION, "BlpManager: invalid _cooldownDuration");
        cooldownDuration = _cooldownDuration;
    }

    function setAumAdjustment(uint256 _aumAddition, uint256 _aumDeduction) external onlyGov {
        aumAddition = _aumAddition;
        aumDeduction = _aumDeduction;
    }

    function addLiquidity(address _token, uint256 _amount, uint256 _minBxd, uint256 _minBlp) external override nonReentrant returns (uint256) {
        if (inPrivateMode) { revert("BlpManager: action not enabled"); }
        return _addLiquidity(msg.sender, msg.sender, _token, _amount, _minBxd, _minBlp);
    }

    function addLiquidityForAccount(address _fundingAccount, address _account, address _token, uint256 _amount, uint256 _minBxd, uint256 _minBlp) external override nonReentrant returns (uint256) {
        _validateHandler();
        return _addLiquidity(_fundingAccount, _account, _token, _amount, _minBxd, _minBlp);
    }

    function removeLiquidity(address _tokenOut, uint256 _blpAmount, uint256 _minOut, address _receiver) external override nonReentrant returns (uint256) {
        if (inPrivateMode) { revert("BlpManager: action not enabled"); }
        return _removeLiquidity(msg.sender, _tokenOut, _blpAmount, _minOut, _receiver);
    }

    function removeLiquidityForAccount(address _account, address _tokenOut, uint256 _blpAmount, uint256 _minOut, address _receiver) external override nonReentrant returns (uint256) {
        _validateHandler();
        return _removeLiquidity(_account, _tokenOut, _blpAmount, _minOut, _receiver);
    }

    function getPrice(bool _maximise) external view returns (uint256) {
        uint256 aum = getAum(_maximise);
        uint256 supply = IERC20(blp).totalSupply();
        return aum.mul(BLP_PRECISION).div(supply);
    }

    function getAums() public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = getAum(true);
        amounts[1] = getAum(false);
        return amounts;
    }

    function getAumInBxd(bool maximise) public override view returns (uint256) {
        uint256 aum = getAum(maximise);
        return aum.mul(10 ** BXD_DECIMALS).div(PRICE_PRECISION);
    }

    function getAum(bool maximise) public view returns (uint256) {
        uint256 length = vault.allWhitelistedTokensLength();
        uint256 aum = aumAddition;
        uint256 shortProfits = 0;
        IVault _vault = vault;

        for (uint256 i = 0; i < length; i++) {
            address token = vault.allWhitelistedTokens(i);
            bool isWhitelisted = vault.whitelistedTokens(token);

            if (!isWhitelisted) {
                continue;
            }

            uint256 price = maximise ? _vault.getMaxPrice(token) : _vault.getMinPrice(token);
            uint256 poolAmount = _vault.poolAmounts(token);
            uint256 decimals = _vault.tokenDecimals(token);

            if (_vault.stableTokens(token)) {
                aum = aum.add(poolAmount.mul(price).div(10 ** decimals));
            } else {
                // add global short profit / loss
                uint256 size = _vault.globalShortSizes(token);

                if (size > 0) {
                    (uint256 delta, bool hasProfit) = getGlobalShortDelta(token, price, size);
                    if (!hasProfit) {
                        // add losses from shorts
                        aum = aum.add(delta);
                    } else {
                        shortProfits = shortProfits.add(delta);
                    }
                }

                aum = aum.add(_vault.guaranteedUsd(token));

                uint256 reservedAmount = _vault.reservedAmounts(token);
                aum = aum.add(poolAmount.sub(reservedAmount).mul(price).div(10 ** decimals));
            }
        }

        aum = shortProfits > aum ? 0 : aum.sub(shortProfits);
        return aumDeduction > aum ? 0 : aum.sub(aumDeduction);
    }

    function getGlobalShortDelta(address _token, uint256 _price, uint256 _size) public view returns (uint256, bool) {
        uint256 averagePrice = getGlobalShortAveragePrice(_token);
        uint256 priceDelta = averagePrice > _price ? averagePrice.sub(_price) : _price.sub(averagePrice);
        uint256 delta = _size.mul(priceDelta).div(averagePrice);
        return (delta, averagePrice > _price);
    }

    function getGlobalShortAveragePrice(address _token) public view returns (uint256) {
        IShortsTracker _shortsTracker = shortsTracker;
        if (address(_shortsTracker) == address(0) || !_shortsTracker.isGlobalShortDataReady()) {
            return vault.globalShortAveragePrices(_token);
        }

        uint256 _shortsTrackerAveragePriceWeight = shortsTrackerAveragePriceWeight;
        if (_shortsTrackerAveragePriceWeight == 0) {
            return vault.globalShortAveragePrices(_token);
        } else if (_shortsTrackerAveragePriceWeight == BASIS_POINTS_DIVISOR) {
            return _shortsTracker.globalShortAveragePrices(_token);
        }

        uint256 vaultAveragePrice = vault.globalShortAveragePrices(_token);
        uint256 shortsTrackerAveragePrice = _shortsTracker.globalShortAveragePrices(_token);

        return vaultAveragePrice.mul(BASIS_POINTS_DIVISOR.sub(_shortsTrackerAveragePriceWeight))
            .add(shortsTrackerAveragePrice.mul(_shortsTrackerAveragePriceWeight))
            .div(BASIS_POINTS_DIVISOR);
    }

    function _addLiquidity(address _fundingAccount, address _account, address _token, uint256 _amount, uint256 _minBxd, uint256 _minBlp) private returns (uint256) {
        require(_amount > 0, "BlpManager: invalid _amount");

        // calculate aum before buyBXD
        uint256 aumInBxd = getAumInBxd(true);
        uint256 blpSupply = IERC20(blp).totalSupply();

        IERC20(_token).safeTransferFrom(_fundingAccount, address(vault), _amount);
        uint256 bxdAmount = vault.buyBXD(_token, address(this));
        require(bxdAmount >= _minBxd, "BlpManager: insufficient BXD output");

        uint256 mintAmount = aumInBxd == 0 ? bxdAmount : bxdAmount.mul(blpSupply).div(aumInBxd);
        require(mintAmount >= _minBlp, "BlpManager: insufficient BLP output");

        IMintable(blp).mint(_account, mintAmount);

        lastAddedAt[_account] = block.timestamp;

        emit AddLiquidity(_account, _token, _amount, aumInBxd, blpSupply, bxdAmount, mintAmount);

        return mintAmount;
    }

    function _removeLiquidity(address _account, address _tokenOut, uint256 _blpAmount, uint256 _minOut, address _receiver) private returns (uint256) {
        require(_blpAmount > 0, "BlpManager: invalid _blpAmount");
        require(lastAddedAt[_account].add(cooldownDuration) <= block.timestamp, "BlpManager: cooldown duration not yet passed");

        // calculate aum before sellBXD
        uint256 aumInBxd = getAumInBxd(false);
        uint256 blpSupply = IERC20(blp).totalSupply();

        uint256 bxdAmount = _blpAmount.mul(aumInBxd).div(blpSupply);
        uint256 bxdBalance = IERC20(bxd).balanceOf(address(this));
        if (bxdAmount > bxdBalance) {
            IBXD(bxd).mint(address(this), bxdAmount.sub(bxdBalance));
        }

        IMintable(blp).burn(_account, _blpAmount);

        IERC20(bxd).transfer(address(vault), bxdAmount);
        uint256 amountOut = vault.sellBXD(_tokenOut, _receiver);
        require(amountOut >= _minOut, "BlpManager: insufficient output");

        emit RemoveLiquidity(_account, _tokenOut, _blpAmount, aumInBxd, blpSupply, bxdAmount, amountOut);

        return amountOut;
    }

    function _validateHandler() private view {
        require(isHandler[msg.sender], "BlpManager: forbidden");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../tokens/interfaces/IWETH.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/Address.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IRouter.sol";
import "./interfaces/IVault.sol";

contract GroupBuyingPool is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    struct Pool {
        uint256 poolId;
        address account;
        address[] path;
        uint256 amountIn;
        uint256 amountOut;
        uint256 duration;
        uint256 expired;
        uint256 discount;
        uint256 poolPrice;
        uint256 threshold;
        uint256 groupAmount;
        uint256 protocolFee;
        uint256 ownerClaimed;
        uint256 totalIn;
        uint256 totalOut;
    }

    struct BuyPool {
        uint256 poolId;
        uint256 times;
        address account;
        uint256 amountIn;
        uint256 amountOut;
    }

    struct Group {
        uint256 poolId;
        uint256 groupId;
        address account;
        bool isEligible;
        uint256 totalIn;
        uint256 totalOut;
    }

    struct BuyGroup {
        uint256 poolId;
        uint256 groupId;
        uint256 times;
        address account;
        uint256 amountIn;
        uint256 amountOut;
    }

    uint256 public listPoolsIndex; // Index 1,2,3,... of all pools
    mapping(uint256 => Pool) public listPools; // Index 1,2,3,...  -> Pool

    mapping(address => mapping(uint256 => uint256)) public listBuyPools; // Trader -> Index 1,2,3,... -> poolId
    mapping(address => uint256) public listBuyPoolsIndex; // Index 1,2,3,... of Trader
    mapping(address => mapping(uint256 => BuyPool)) public buyPools; // Trader -> poolId -> BuyPool

    uint256 public listGroupsIndex; // Index 1,2,3,... of all Groups
    mapping(uint256 => Group) public listGroups; // Index 1,2,3,... of group  -> Group
    mapping(uint256 => uint256) public groupsIndex; // poolId -> Index 1,2,3,... of group
    mapping(uint256 => mapping(uint256 => uint256)) public groups; // poolId -> Index 1,2,3,... of group -> groupId

    mapping(address => uint256) public listBuyGroupsIndex; // Trader -> Index 1,2,3,... of group
    mapping(address => mapping(uint256 => uint256)) public listBuyGroups; // Trader -> Index 1,2,3,... -> groupId
    mapping(address => mapping(uint256 => BuyGroup)) public buyGroups; // Trader -> groupId -> BuyGroup
    mapping(uint256 => uint256) public countBuyGroup;

    address public gov;
    address public weth;
    address public router;
    address public vault;
    uint256 public minExecutionFee;
    uint256 public minPurchaseTokenAmountUsd;
    bool public isInitialized = false;

    event CreatePoolEvent(
        uint256 poolId,
        address indexed account,
        address[] path,
        uint256 amountIn,
        uint256 amountOut,
        uint256 duration,
        uint256 expired,
        uint256 discount,
        uint256 poolPrice,
        uint256 threshold,
        uint256 groupAmount,
        uint256 protocolFee,
        uint256 ownerClaimed
    );

    event CreateGroupEvent(
        uint256 poolId,
        uint256 groupId,
        address indexed account,
        address[] path,
        bool isEligible,
        uint256 totalIn,
        uint256 totalOut
    );

    event BuyPoolEvent(
        uint256 poolId,
        uint256 buyPoolIndex,
        address indexed account,
        address[] path,
        uint256 amountIn,
        uint256 amountOut
    );

    event BuyGroupEvent(
        uint256 poolId,
        uint256 groupId,
        uint256 buyGroupId,
        address indexed account,
        address[] path,
        uint256 amountIn,
        uint256 amountOut
    );

    event OwnerClaimPool(
        address account,
        uint256 poolId,
        uint256 refundableAmount,
        uint256 claimableAmount
    );

    event TraderClaimPool(
        address account,
        uint256 poolId,
        uint256 refundableAmount,
        uint256 claimableAmount
    );

    event TraderClaimGroup(
        address account,
        uint256 poolId,
        uint256 groupId,
        bool isEligible,
        uint256 claimableAmount
    );

    event Initialize(
        address router,
        address vault,
        address weth,
        uint256 minExecutionFee,
        uint256 minPurchaseTokenAmountUsd
    );
    event UpdateMinExecutionFee(uint256 minExecutionFee);
    event UpdateMinPurchaseTokenAmountUsd(uint256 minPurchaseTokenAmountUsd);
    event UpdateRouter(address router);
    event UpdateVault(address vault);
    event UpdateGov(address gov);

    modifier onlyGov() {
        require(msg.sender == gov, "forbidden");
        _;
    }

    constructor() public {
        gov = msg.sender;
    }

    function initialize(
        address _router,
        address _vault,
        address _weth,
        uint256 _minExecutionFee,
        uint256 _minPurchaseTokenAmountUsd
    ) external onlyGov {
        require(!isInitialized, "initialized");
        isInitialized = true;

        router = _router;
        vault = _vault;
        weth = _weth;
        minExecutionFee = _minExecutionFee;
        minPurchaseTokenAmountUsd = _minPurchaseTokenAmountUsd;

        emit Initialize(
            _router,
            _vault,
            _weth,
            _minExecutionFee,
            _minPurchaseTokenAmountUsd
        );
    }

    receive() external payable {
        require(msg.sender == weth, "sender");
    }

    function setMinExecutionFee(uint256 _minExecutionFee) external onlyGov {
        minExecutionFee = _minExecutionFee;
        emit UpdateMinExecutionFee(_minExecutionFee);
    }

    function setMinPurchaseTokenAmountUsd(uint256 _minPurchaseTokenAmountUsd) external onlyGov {
        minPurchaseTokenAmountUsd = _minPurchaseTokenAmountUsd;
        emit UpdateMinPurchaseTokenAmountUsd(_minPurchaseTokenAmountUsd);
    }

    function setRouter(address _router) external onlyGov {
        router = _router;
        emit UpdateRouter(_router);
    }

    function setVault(address _vault) external onlyGov {
        vault = _vault;
        emit UpdateVault(_vault);
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
        emit UpdateGov(_gov);
    }

    function getPools(
        uint256 _offset,
        uint256 _limit
    ) public view returns (Pool[] memory) {
        uint256 from = _offset > 0 && _offset <= listPoolsIndex
            ? listPoolsIndex - _offset + 1
            : 0;
        uint256 limit = _limit < from ? _limit : from;
        Pool[] memory items = new Pool[](limit);
        for (uint256 i = 0; i < limit; i++) {
            Pool memory item = listPools[from - i];
            items[i] = item;
        }
        return items;
    }

    function getPoolActive(
        uint256 _offset,
        uint256 _limit
    ) public view returns (Pool[] memory) {
        uint256 limit = _limit < listPoolsIndex ? _limit : listPoolsIndex;
        uint256 count = 0;
        Pool[] memory items = new Pool[](limit);
        for (uint256 i = listPoolsIndex; i > 0; i--) {
            Pool memory item = listPools[i];
            if (item.expired > block.timestamp) {
                count = count.add(1);
                if (count >= _offset + limit) {
                    break;
                }
                if (count >= _offset) {
                    items[count - _offset] = item;
                }
            }
        }
        return items;
    }

    function getPoolOwner(
        address _account,
        uint256 _offset,
        uint256 _limit
    ) public view returns (Pool[] memory) {
        uint256 limit = _limit < listPoolsIndex ? _limit : listPoolsIndex;
        uint256 count = 0;
        Pool[] memory items = new Pool[](limit);
        for (uint256 i = listPoolsIndex; i > 0; i--) {
            Pool memory item = listPools[i];
            if (item.account == _account) {
                count = count.add(1);
                if (count >= _offset + limit) {
                    break;
                }
                if (count >= _offset) {
                    items[count - _offset] = item;
                }
            }
        }
        return items;
    }

    function getPoolByAddress(
        address _account,
        uint256 _offset,
        uint256 _limit
    ) public view returns (BuyPool[] memory, Pool[] memory) {
        uint256 from = _offset > 0 && _offset <= listBuyPoolsIndex[msg.sender]
            ? listBuyPoolsIndex[msg.sender] - _offset + 1
            : 0;
        uint256 limit = _limit < from ? _limit : from;
        BuyPool[] memory items = new BuyPool[](limit);
        Pool[] memory groupItems = new Pool[](limit);
        for (uint256 i = 0; i < limit; i++) {
            uint256 poolId = listBuyPools[_account][from - i];
            BuyPool memory item = buyPools[_account][poolId];
            items[i] = item;
            Pool memory groupItem = listPools[poolId];
            groupItems[i] = groupItem;
        }
        return (items, groupItems);
    }

    function getBuyGroupByAddress(
        address _account,
        uint256 _offset,
        uint256 _limit
    ) public view returns (BuyGroup[] memory, Pool[] memory) {
        uint256 from = _offset > 0 && _offset <= listBuyPoolsIndex[msg.sender]
            ? listBuyPoolsIndex[msg.sender] - _offset + 1
            : 0;
        uint256 limit = _limit < from ? _limit : from;
        BuyGroup[] memory items = new BuyGroup[](limit);
        Pool[] memory groupItems = new Pool[](limit);
        for (uint256 i = 0; i < limit; i++) {
            uint256 groupId = listBuyGroups[_account][from - i];
            BuyGroup memory item = buyGroups[_account][groupId];
            items[i] = item;
            Pool memory poolItem = listPools[item.poolId];
            groupItems[i] = poolItem;
        }
        return (items, groupItems);
    }

    function getGroups(
        uint256 _poolId,
        uint256 _offset,
        uint256 _limit
    ) public view returns (Group[] memory) {
        uint256 from = _offset > 0 && _offset <= groupsIndex[_poolId] ? groupsIndex[_poolId] - _offset + 1 : 0;
        uint256 limit = _limit < from ? _limit : from;
        Group[] memory items = new Group[](limit);
        for (uint256 i = 0; i < limit; i++) {
            uint256 groupId = groups[_poolId][from - i];
            Group memory item = listGroups[groupId];
            items[i] = item;
        }
        return items;
    }

    function getMarketAmountOut(
        uint256 _amountIn,
        address[] memory _path,
        uint256 discount
    ) public view returns (uint256, uint256, uint256, uint256) {
        address _tokenIn = _path.length == 2 ? _path[0] : _path[1];
        address _tokenOut = _path.length == 2 ? _path[1] : _path[2];
        uint256 priceIn = IVault(vault).getMinPrice(_tokenIn);
        uint256 priceOut = IVault(vault).getMinPrice(_tokenOut);

        uint256 amountOut = _amountIn.mul(priceIn).div(priceOut);
        amountOut = IVault(vault).adjustForDecimals(
            amountOut,
            _tokenIn,
            _tokenOut
        );
        amountOut = amountOut.mul(BASIS_POINTS_DIVISOR.sub(discount)).div(
            BASIS_POINTS_DIVISOR
        );

        uint256 poolPrice = (10**IVault(vault).tokenDecimals(_tokenOut)).mul(priceIn).div(priceOut);
        poolPrice = poolPrice.mul(BASIS_POINTS_DIVISOR.sub(discount)).div(BASIS_POINTS_DIVISOR);
        
        return (priceIn, priceOut, amountOut, poolPrice);
    }

    function getPoolAmountOut(
        uint256 _amountIn,
        uint256 _poolId,
        address[] memory _path,
        bool _isReversalPoolPath
    ) public view returns (uint256 amountOut) {
        Pool memory item = listPools[_poolId];

        address _tokenIn = _path.length == 2 ? _path[0] : _path[1];
        address _tokenOut = _path.length == 2 ? _path[1] : _path[2];

        uint256 amountIn = IVault(vault).adjustForDecimals(
            _amountIn,
            _tokenIn,
            _tokenOut
        );
        amountOut = _isReversalPoolPath ? 
            amountIn.mul(10**IVault(vault).tokenDecimals(_tokenOut)).div(item.poolPrice) : 
            _amountIn.mul(item.poolPrice).div(10**IVault(vault).tokenDecimals(_tokenIn));
    }

    function createPool(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _duration,
        uint256 _discount,
        uint256 _threshold,
        uint256 _groupAmount,
        bool _shouldWrap
    ) external payable nonReentrant {
        require(_path.length == 2 || _path.length == 3, "path.length");
        require(_path[0] != _path[_path.length - 1], "path");
        require(_amountIn > 0, "amountIn");

        // always need this call because of mandatory executionFee user has to transfer in ETH
        _transferInETH();
        _wrapAndTransfer(_amountIn, _path[0], _shouldWrap);

        uint256 amountInExcludingFee = _amountIn.mul(BASIS_POINTS_DIVISOR).div(
            BASIS_POINTS_DIVISOR.add(minExecutionFee)
        );
        uint256 protocolFee = _amountIn.sub(amountInExcludingFee);

        uint256 expired = _duration + block.timestamp;

        uint256 amountOut;
        uint256 poolPrice;
        (, , amountOut, poolPrice) = getMarketAmountOut(amountInExcludingFee, _path, _discount);

        listPoolsIndex = listPoolsIndex.add(1);

        Pool memory pool = Pool(
            listPoolsIndex,
            msg.sender,
            _path,
            amountInExcludingFee,
            amountOut,
            _duration,
            expired,
            _discount,
            poolPrice,
            _threshold,
            _groupAmount,
            protocolFee,
            0,
            0,
            0
        );
        listPools[listPoolsIndex] = pool;

        if(_groupAmount > 0 ){
            uint256 numberOfGroup = _amountIn.div(_groupAmount);
            if(_groupAmount != 0){
                for(uint256 i = numberOfGroup; i > 0; i--){
                    _createGroup(listPoolsIndex);
                }
            }
        }

        emit CreatePoolEvent(
            listPoolsIndex,
            msg.sender,
            pool.path,
            pool.amountIn,
            pool.amountOut,
            pool.duration,
            pool.expired,
            pool.discount,
            pool.poolPrice,
            pool.threshold,
            pool.groupAmount,
            pool.protocolFee,
            0
        );
    }

    function validatePair(
        address[] memory _path,
        address[] memory _buyPath
    ) public pure {
        require(_path.length == 2 || _path.length == 3, "path.length");
        require(_path[0] != _path[_path.length - 1], "path");
        require(
            _buyPath.length == 2 || _buyPath.length == 3,
            "_buyPath.length"
        );
        require(_buyPath[0] != _buyPath[_buyPath.length - 1], "_buyPath");
        address _tokenIn = _path.length == 2 ? _path[0] : _path[1];
        address _tokenOut = _path.length == 2 ? _path[1] : _path[2];
        address _buyTokenIn = _buyPath.length == 2 ? _buyPath[0] : _buyPath[1];
        address _buyTokenOut = _buyPath.length == 2 ? _buyPath[1] : _buyPath[2];
        require(_tokenIn == _buyTokenOut, "_buyTokenOut");
        require(_tokenOut == _buyTokenIn, "_buyTokenIn");
    }

    function purchasePool(
        uint256 _poolId,
        address[] memory _path,
        uint256 _amountIn,
        bool _shouldWrap
    ) external payable nonReentrant {
        Pool memory item = listPools[_poolId];
        validatePair(item.path, _path);
        require(item.expired > block.timestamp, "expired");
        require (item.groupAmount == 0, "group");

        uint256 amountOut = getPoolAmountOut(_amountIn,_poolId ,  _path, true);
        require(item.totalOut.add(amountOut) <= item.amountIn, "soldout");
        require(item.groupAmount == 0 || amountOut >= item.groupAmount, "_amountIn");

        _transferInETH();
        _wrapAndTransfer(_amountIn, _path[0], _shouldWrap);

        listPools[_poolId].totalOut = listPools[_poolId].totalOut.add(amountOut);
        listPools[_poolId].totalIn = listPools[_poolId].totalIn.add(_amountIn);

        BuyPool memory buyPool;
        if (buyPools[msg.sender][_poolId].poolId > 0) {
            buyPool = buyPools[msg.sender][_poolId];
            buyPool.amountIn = buyPool.amountIn.add(_amountIn);
            buyPool.amountOut = buyPool.amountOut.add(amountOut);
            buyPool.times = buyPool.times.add(1);
        } else {
            buyPool = BuyPool(
                _poolId,
                1,
                msg.sender,
                _amountIn,
                amountOut
            );
            listBuyPoolsIndex[msg.sender] = listBuyPoolsIndex[msg.sender].add(1);
            listBuyPools[msg.sender][listBuyPoolsIndex[msg.sender]] = _poolId;
        }
        buyPools[msg.sender][_poolId] = buyPool;

        emit BuyPoolEvent(
            _poolId,
            buyPool.times,
            msg.sender,
            _path,
            _amountIn,
            amountOut
        );
    }

    function placeGroup(
        uint256 _poolId,
        uint256 _groupId,
        address[] memory _path,
        uint256 _amountIn,
        bool _shouldWrap
    ) external payable nonReentrant {
        Pool memory item = listPools[_poolId];
        Group memory group = listGroups[_groupId];
        validatePair(item.path, _path);
        require(item.expired > block.timestamp, "expired");
        
        uint256 amountOut = getPoolAmountOut(_amountIn,_poolId ,  _path, true);
        require(item.totalOut.add(amountOut) <= item.amountIn, "soldout");
        require(item.groupAmount > 0 && group.totalOut.add(amountOut) <= item.groupAmount, "done");

        _transferInETH();
        _wrapAndTransfer(_amountIn, _path[0], _shouldWrap);

        group.totalOut = group.totalOut.add(amountOut);
        group.totalIn = group.totalIn.add(_amountIn);
        if (item.groupAmount > 0 && group.totalOut == item.groupAmount) {
            group.isEligible = true;
            item.totalOut = item.totalOut.add(group.totalOut);
            item.totalIn = item.totalIn.add(group.totalIn);
            listPools[_poolId] = item;
        }
        listGroups[_groupId] = group;

        BuyGroup memory buyGroup;
        if (buyGroups[msg.sender][_groupId].groupId > 0) {
            buyGroup = buyGroups[msg.sender][_groupId];
            buyGroup.amountIn = buyGroup.amountIn.add(_amountIn);
            buyGroup.amountOut = buyGroup.amountOut.add(amountOut);
            buyGroup.times = buyGroup.times.add(1);
        } else {
            buyGroup = BuyGroup(
                _poolId,
                _groupId,
                1,
                msg.sender,
                _amountIn,
                amountOut
            );
            listBuyGroupsIndex[msg.sender] = listBuyGroupsIndex[msg.sender].add(1);
            listBuyGroups[msg.sender][listBuyGroupsIndex[msg.sender]] = _groupId;
            countBuyGroup[_groupId] = countBuyGroup[_groupId].add(1);
        }
        buyGroups[msg.sender][_groupId] = buyGroup;

        emit BuyGroupEvent(
            _poolId,
            _groupId,
            buyGroup.times,
            msg.sender,
            _path,
            _amountIn,
            amountOut
        );
    }

    function ownerClaimPool(uint256 _poolId) external nonReentrant {
        Pool memory item = listPools[_poolId];
        require(item.account == msg.sender, "owner");

        address _tokenIn = item.path.length == 2 ? item.path[0] : item.path[1];
        address _tokenOut = item.path.length == 2 ? item.path[1] : item.path[2];

        uint256 refundableAmount;
        uint256 claimableAmount;
        (, refundableAmount, claimableAmount) = getownerClaimPool(_poolId);
        listPools[_poolId].ownerClaimed = item.ownerClaimed.add(claimableAmount);
        if(refundableAmount != 0){
            listPools[_poolId].totalOut = item.amountIn;
            IERC20(_tokenIn).safeTransfer(msg.sender, refundableAmount);
            IERC20(_tokenOut).safeTransfer(msg.sender, claimableAmount);
        }else {
            IERC20(_tokenOut).safeTransfer(msg.sender, claimableAmount);
        }

        emit OwnerClaimPool(msg.sender, _poolId, refundableAmount, claimableAmount);
    }

    function getownerClaimPool(
        uint256 _poolId
    ) public view returns (address, uint256, uint256) {
        Pool memory item = listPools[_poolId];

        uint256 refundableAmount;
        uint256 claimableAmount;
        if(item.expired < block.timestamp){
            refundableAmount = item.amountIn.sub(item.totalOut);
        }
        if(item.totalOut >= item.amountIn.mul(item.threshold).div(BASIS_POINTS_DIVISOR)){
            claimableAmount = item.totalIn.sub(item.ownerClaimed);
        }

        return (item.account, refundableAmount, claimableAmount);
    }

    function claimPool(uint256 _poolId) external nonReentrant {
        Pool memory item = listPools[_poolId];
        BuyPool memory buyPool = buyPools[msg.sender][_poolId];
        
        address _tokenIn = item.path.length == 2 ? item.path[0] : item.path[1];
        address _tokenOut = item.path.length == 2 ? item.path[1] : item.path[2];

        uint256 refundableAmount;
        uint256 claimableAmount;
        if(item.groupAmount > 0){
            for (uint256 i = groupsIndex[_poolId]; i > 0; i--) {
                Group memory group = listGroups[i];
                BuyGroup memory buyGroup = buyGroups[msg.sender][group.groupId];
                if (group.isEligible) {
                    claimableAmount = claimableAmount.add(buyGroup.amountOut);
                    buyGroups[msg.sender][group.groupId].amountOut = 0;
                } else {
                    if(item.expired < block.timestamp){
                        refundableAmount = refundableAmount.add(buyGroup.amountIn);
                        buyGroups[msg.sender][group.groupId].amountIn = 0; 
                    }
                }
            }
        } else {
            if (item.totalOut >= item.amountIn.mul(item.threshold).div(BASIS_POINTS_DIVISOR)) {
                claimableAmount = claimableAmount.add(buyPool.amountOut);
                buyPools[msg.sender][_poolId].amountOut = 0;
            } else {
                if(item.expired < block.timestamp){
                    refundableAmount = refundableAmount.add(buyPool.amountIn);
                    buyPools[msg.sender][_poolId].amountIn = 0;
                }
            }
        }

        IERC20(_tokenIn).safeTransfer(msg.sender, claimableAmount);
        IERC20(_tokenOut).safeTransfer(msg.sender, refundableAmount);

        emit TraderClaimPool(msg.sender, _poolId, refundableAmount, claimableAmount);
    }

    function getTraderClaimPool(
        uint256 _poolId,
        address _account
    ) public view returns (address, uint256, uint256) {
        Pool memory item = listPools[_poolId];
        BuyPool memory buyPool = buyPools[_account][_poolId];

        uint256 refundableAmount;
        uint256 claimableAmount;
        for (uint256 i = groupsIndex[_poolId]; i > 0; i--) {
            Group memory group = listGroups[i];
            BuyGroup memory buyGroup = buyGroups[_account][group.groupId];
            if (group.isEligible) {
                claimableAmount = claimableAmount.add(buyGroup.amountOut);
            } else {
                if(item.expired < block.timestamp){
                    refundableAmount = refundableAmount.add(buyGroup.amountIn);
                }
            }
        }

        if (item.totalOut >= item.amountIn.mul(item.threshold).div(BASIS_POINTS_DIVISOR)) {
            claimableAmount = claimableAmount.add(buyPool.amountOut);
        } else {
            if(item.expired < block.timestamp){
                refundableAmount = refundableAmount.add(buyPool.amountIn);
            }
        }

        return (_account, refundableAmount, claimableAmount);
        
    }

    function claimGroup(
        uint256 _poolId,
        uint256 _groupId
    ) external nonReentrant {
        Pool memory item = listPools[_poolId];
        Group memory group = listGroups[_groupId];
        BuyGroup memory buyGroup = buyGroups[msg.sender][_groupId];

        require(buyGroup.groupId > 0, "buy");
        require(buyGroup.account == msg.sender, "buyer");
        require(buyGroups[msg.sender][_groupId].amountOut > 0, "amountOut");
        
        address _tokenIn = item.path.length == 2 ? item.path[0] : item.path[1];
        address _tokenOut = item.path.length == 2 ? item.path[1] : item.path[2];

        uint256 claimableAmount;
        if(group.isEligible){
            claimableAmount = buyGroups[msg.sender][_groupId].amountOut;
            buyGroups[msg.sender][_groupId].amountOut = 0;
            IERC20(_tokenOut).safeTransfer(msg.sender, claimableAmount);
        }else{
            claimableAmount = buyGroups[msg.sender][_groupId].amountIn;
            buyGroups[msg.sender][_groupId].amountIn = 0;
            IERC20(_tokenIn).safeTransfer(msg.sender, claimableAmount);
        }

        emit TraderClaimGroup(msg.sender, _poolId, _groupId, group.isEligible, claimableAmount);
    }

    function _createGroup(
        uint256 _poolId
    ) internal {
        Pool memory item = listPools[_poolId];

        listGroupsIndex = listGroupsIndex.add(1);
        Group memory group = Group(
            _poolId,
            listGroupsIndex,
            msg.sender,
            true,
            0,
            0
        );
        listGroups[listGroupsIndex] = group;
        groupsIndex[_poolId] = groupsIndex[_poolId].add(1);
        groups[_poolId][groupsIndex[_poolId]] = listGroupsIndex;

        emit CreateGroupEvent(
            _poolId,
            listGroupsIndex,
            msg.sender,
            item.path,
            true,
            0,
            0
        );
    }

    function _wrapAndTransfer(
        uint256 _amountIn,
        address _path0,
        bool _shouldWrap
    ) private {
        if (_shouldWrap) {
            require(_path0 == weth, "weth");
            require(msg.value == _amountIn, "value");
        } else {
            IRouter(router).pluginTransfer(
                _path0,
                msg.sender,
                address(this),
                _amountIn
            );
        }
    }

    function _transferInETH() private {
        if (msg.value != 0) {
            IWETH(weth).deposit{value: msg.value}();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../tokens/interfaces/IWETH.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/Address.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IRouter.sol";
import "./interfaces/IVault.sol";

contract GroupSellingPool is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    struct Pool {
        uint256 poolId;
        address account;
        address[] path;
        uint256 amountIn;
        uint256 amountOut;
        uint256 duration;
        uint256 expired;
        uint256 discount;
        uint256 poolPrice;
        uint256 threshold;
        uint256 groupAmount;
        uint256 protocolFee;
        uint256 ownerClaimed;
        uint256 totalIn;
        uint256 totalOut;
    }

    struct BuyPool {
        uint256 poolId;
        uint256 times;
        address account;
        uint256 amountIn;
        uint256 amountOut;
    }

    struct Group {
        uint256 poolId;
        uint256 groupId;
        address account;
        bool isEligible;
        uint256 totalIn;
        uint256 totalOut;
    }

    struct BuyGroup {
        uint256 poolId;
        uint256 groupId;
        uint256 times;
        address account;
        uint256 amountIn;
        uint256 amountOut;
    }

    uint256 public listPoolsIndex; // Index 1,2,3,... of all pools
    mapping(uint256 => Pool) public listPools; // Index 1,2,3,...  -> Pool

    mapping(address => mapping(uint256 => uint256)) public listBuyPools; // Trader -> Index 1,2,3,... -> poolId
    mapping(address => uint256) public listBuyPoolsIndex; // Index 1,2,3,... of Trader
    mapping(address => mapping(uint256 => BuyPool)) public buyPools; // Trader -> poolId -> BuyPool

    uint256 public listGroupsIndex; // Index 1,2,3,... of all Groups
    mapping(uint256 => Group) public listGroups; // Index 1,2,3,... of group  -> Group
    mapping(uint256 => uint256) public groupsIndex; // poolId -> Index 1,2,3,... of group
    mapping(uint256 => mapping(uint256 => uint256)) public groups; // poolId -> Index 1,2,3,... of group -> groupId

    mapping(address => uint256) public listBuyGroupsIndex; // Trader -> Index 1,2,3,... of group
    mapping(address => mapping(uint256 => uint256)) public listBuyGroups; // Trader -> Index 1,2,3,... -> groupId
    mapping(address => mapping(uint256 => BuyGroup)) public buyGroups; // Trader -> groupId -> BuyGroup
    mapping(uint256 => uint256) public countBuyGroup;

    address public gov;
    address public weth;
    address public router;
    address public vault;
    uint256 public minExecutionFee;
    uint256 public minPurchaseTokenAmountUsd;
    bool public isInitialized = false;

    event CreatePoolEvent(
        uint256 poolId,
        address indexed account,
        address[] path,
        uint256 amountIn,
        uint256 amountOut,
        uint256 duration,
        uint256 expired,
        uint256 discount,
        uint256 poolPrice,
        uint256 threshold,
        uint256 groupAmount,
        uint256 protocolFee,
        uint256 ownerClaimed
    );

    event CreateGroupEvent(
        uint256 poolId,
        uint256 groupId,
        address indexed account,
        address[] path,
        bool isEligible,
        uint256 totalIn,
        uint256 totalOut
    );

    event BuyPoolEvent(
        uint256 poolId,
        uint256 buyPoolIndex,
        address indexed account,
        address[] path,
        uint256 amountIn,
        uint256 amountOut
    );

    event BuyGroupEvent(
        uint256 poolId,
        uint256 groupId,
        uint256 buyGroupId,
        address indexed account,
        address[] path,
        uint256 amountIn,
        uint256 amountOut
    );

    event OwnerClaimPool(
        address account,
        uint256 poolId,
        uint256 refundableAmount,
        uint256 claimableAmount
    );

    event TraderClaimPool(
        address account,
        uint256 poolId,
        uint256 refundableAmount,
        uint256 claimableAmount
    );

    event TraderClaimGroup(
        address account,
        uint256 poolId,
        uint256 groupId,
        bool isEligible,
        uint256 claimableAmount
    );

    event Initialize(
        address router,
        address vault,
        address weth,
        uint256 minExecutionFee,
        uint256 minPurchaseTokenAmountUsd
    );
    event UpdateMinExecutionFee(uint256 minExecutionFee);
    event UpdateMinPurchaseTokenAmountUsd(uint256 minPurchaseTokenAmountUsd);
    event UpdateRouter(address router);
    event UpdateVault(address vault);
    event UpdateGov(address gov);

    modifier onlyGov() {
        require(msg.sender == gov, "forbidden");
        _;
    }

    constructor() public {
        gov = msg.sender;
    }

    function initialize(
        address _router,
        address _vault,
        address _weth,
        uint256 _minExecutionFee,
        uint256 _minPurchaseTokenAmountUsd
    ) external onlyGov {
        require(!isInitialized, "initialized");
        isInitialized = true;

        router = _router;
        vault = _vault;
        weth = _weth;
        minExecutionFee = _minExecutionFee;
        minPurchaseTokenAmountUsd = _minPurchaseTokenAmountUsd;

        emit Initialize(
            _router,
            _vault,
            _weth,
            _minExecutionFee,
            _minPurchaseTokenAmountUsd
        );
    }

    receive() external payable {
        require(msg.sender == weth, "sender");
    }

    function setMinExecutionFee(uint256 _minExecutionFee) external onlyGov {
        minExecutionFee = _minExecutionFee;
        emit UpdateMinExecutionFee(_minExecutionFee);
    }

    function setMinPurchaseTokenAmountUsd(uint256 _minPurchaseTokenAmountUsd) external onlyGov {
        minPurchaseTokenAmountUsd = _minPurchaseTokenAmountUsd;
        emit UpdateMinPurchaseTokenAmountUsd(_minPurchaseTokenAmountUsd);
    }

    function setRouter(address _router) external onlyGov {
        router = _router;
        emit UpdateRouter(_router);
    }

    function setVault(address _vault) external onlyGov {
        vault = _vault;
        emit UpdateVault(_vault);
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
        emit UpdateGov(_gov);
    }

    function getPools(
        uint256 _offset,
        uint256 _limit
    ) public view returns (Pool[] memory) {
        uint256 from = _offset > 0 && _offset <= listPoolsIndex
            ? listPoolsIndex - _offset + 1
            : 0;
        uint256 limit = _limit < from ? _limit : from;
        Pool[] memory items = new Pool[](limit);
        for (uint256 i = 0; i < limit; i++) {
            Pool memory item = listPools[from - i];
            items[i] = item;
        }
        return items;
    }

    function getPoolActive(
        uint256 _offset,
        uint256 _limit
    ) public view returns (Pool[] memory) {
        uint256 limit = _limit < listPoolsIndex ? _limit : listPoolsIndex;
        uint256 count = 0;
        Pool[] memory items = new Pool[](limit);
        for (uint256 i = listPoolsIndex; i > 0; i--) {
            Pool memory item = listPools[i];
            if (item.expired > block.timestamp) {
                count = count.add(1);
                if (count >= _offset + limit) {
                    break;
                }
                if (count >= _offset) {
                    items[count - _offset] = item;
                }
            }
        }
        return items;
    }

    function getPoolOwner(
        address _account,
        uint256 _offset,
        uint256 _limit
    ) public view returns (Pool[] memory) {
        uint256 limit = _limit < listPoolsIndex ? _limit : listPoolsIndex;
        uint256 count = 0;
        Pool[] memory items = new Pool[](limit);
        for (uint256 i = listPoolsIndex; i > 0; i--) {
            Pool memory item = listPools[i];
            if (item.account == _account) {
                count = count.add(1);
                if (count >= _offset + limit) {
                    break;
                }
                if (count >= _offset) {
                    items[count - _offset] = item;
                }
            }
        }
        return items;
    }

    function getPoolByAddress(
        address _account,
        uint256 _offset,
        uint256 _limit
    ) public view returns (BuyPool[] memory, Pool[] memory) {
        uint256 from = _offset > 0 && _offset <= listBuyPoolsIndex[msg.sender]
            ? listBuyPoolsIndex[msg.sender] - _offset + 1
            : 0;
        uint256 limit = _limit < from ? _limit : from;
        BuyPool[] memory items = new BuyPool[](limit);
        Pool[] memory groupItems = new Pool[](limit);
        for (uint256 i = 0; i < limit; i++) {
            uint256 poolId = listBuyPools[_account][from - i];
            BuyPool memory item = buyPools[_account][poolId];
            items[i] = item;
            Pool memory groupItem = listPools[poolId];
            groupItems[i] = groupItem;
        }
        return (items, groupItems);
    }

    function getBuyPoolByAddress(
        address _account,
        uint256 _offset,
        uint256 _limit
    ) public view returns (BuyGroup[] memory, Pool[] memory) {
        uint256 from = _offset > 0 && _offset <= listBuyPoolsIndex[msg.sender]
            ? listBuyPoolsIndex[msg.sender] - _offset + 1
            : 0;
        uint256 limit = _limit < from ? _limit : from;
        BuyGroup[] memory items = new BuyGroup[](limit);
        Pool[] memory groupItems = new Pool[](limit);
        for (uint256 i = 0; i < limit; i++) {
            uint256 groupId = listBuyGroups[_account][from - i];
            BuyGroup memory item = buyGroups[_account][groupId];
            items[i] = item;
            Pool memory groupItem = listPools[item.poolId];
            groupItems[i] = groupItem;
        }
        return (items, groupItems);
    }

    function getGroups(
        uint256 _poolId,
        uint256 _offset,
        uint256 _limit
    ) public view returns (Group[] memory) {
        uint256 from = _offset > 0 && _offset <= groupsIndex[_poolId]
            ? groupsIndex[_poolId] - _offset + 1
            : 0;
        uint256 limit = _limit < from ? _limit : from;
        Group[] memory items = new Group[](limit);
        for (uint256 i = 0; i < limit; i++) {
            uint256 groupId = groups[_poolId][from - i];
            Group memory item = listGroups[groupId];
            items[i] = item;
        }
        return items;
    }

    function getMarketSellingAmountOut(
        uint256 _amountIn,
        address[] memory _path,
        uint256 discount
    ) public view returns (uint256, uint256, uint256, uint256) {
        address _tokenIn = _path.length == 2 ? _path[0] : _path[1];
        address _tokenOut = _path.length == 2 ? _path[1] : _path[2];
        uint256 priceIn = IVault(vault).getMinPrice(_tokenIn);
        uint256 priceOut = IVault(vault).getMinPrice(_tokenOut);

        uint256 amountOut = _amountIn.mul(priceOut).div(priceIn);
        amountOut = IVault(vault).adjustForDecimals(
            amountOut,
            _tokenIn,
            _tokenOut
        );
        amountOut = amountOut.mul(BASIS_POINTS_DIVISOR).div(
            BASIS_POINTS_DIVISOR.add(discount)
        );

        uint256 poolPrice = (10**IVault(vault).tokenDecimals(_tokenOut)).mul(priceIn).div(priceOut);
        poolPrice = poolPrice.mul(BASIS_POINTS_DIVISOR.add(discount)).div(BASIS_POINTS_DIVISOR);
        
        return (priceIn, priceOut, amountOut, poolPrice);
    }

    function getSellingPoolAmountOut(
        uint256 _amountIn,
        uint256 _poolId,
        address[] memory _path,
        bool _isReversalPoolPath
    ) public view returns (uint256 amountOut) {
        Pool memory item = listPools[_poolId];

        address _tokenIn = _path.length == 2 ? _path[1] : _path[2];
        address _tokenOut = _path.length == 2 ? _path[0] : _path[1];

        uint256 amountIn = IVault(vault).adjustForDecimals(
            _amountIn,
            _tokenIn,
            _tokenOut
        );
        amountOut = _isReversalPoolPath ? _amountIn.mul(item.poolPrice).div(10**IVault(vault).tokenDecimals(_tokenIn)) : 
                    amountIn.mul(10**IVault(vault).tokenDecimals(_tokenOut)).div(item.poolPrice);
    }

    function validatePair(
        address[] memory _path,
        address[] memory _buyPath
    ) public pure {
        require(_path.length == 2 || _path.length == 3, "path.length");
        require(_path[0] != _path[_path.length - 1], "path");
        require(
            _buyPath.length == 2 || _buyPath.length == 3,
            "_buyPath.length"
        );
        require(_buyPath[0] != _buyPath[_buyPath.length - 1], "_buyPath");
        address _tokenIn = _path.length == 2 ? _path[0] : _path[1];
        address _tokenOut = _path.length == 2 ? _path[1] : _path[2];
        address _buyTokenIn = _buyPath.length == 2 ? _buyPath[0] : _buyPath[1];
        address _buyTokenOut = _buyPath.length == 2 ? _buyPath[1] : _buyPath[2];
        require(_tokenIn == _buyTokenOut, "_buyTokenOut");
        require(_tokenOut == _buyTokenIn, "_buyTokenIn");
    }

    function createPool(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _duration,
        uint256 _discount,
        uint256 _threshold,
        uint256 _groupAmount,
        bool _shouldWrap
    ) external payable nonReentrant {
        require(_path.length == 2 || _path.length == 3, "path.length");
        require(_path[0] != _path[_path.length - 1], "path");
        require(_amountIn > 0, "amountIn");

        // always need this call because of mandatory executionFee user has to transfer in ETH
        _transferInETH();
        _wrapAndTransfer(_amountIn, _path[0], _shouldWrap);

        uint256 amountInExcludingFee = _amountIn.mul(BASIS_POINTS_DIVISOR).div(
            BASIS_POINTS_DIVISOR.add(minExecutionFee)
        );
        uint256 protocolFee = _amountIn.sub(amountInExcludingFee);

        uint256 expired = _duration + block.timestamp;

        uint256 amountOut;
        uint256 poolPrice;
        (, , amountOut, poolPrice) = getMarketSellingAmountOut(amountInExcludingFee, _path, _discount);

        listPoolsIndex = listPoolsIndex.add(1);
        Pool memory pool = Pool(
            listPoolsIndex,
            msg.sender,
            _path,
            amountInExcludingFee,
            amountOut,
            _duration,
            expired,
            _discount,
            poolPrice,
            _threshold,
            _groupAmount,
            protocolFee,
            0,
            0,
            0
        );
        listPools[listPoolsIndex] = pool;

        uint256 numberOfGroup = amountOut.div(_groupAmount);
        if(_groupAmount != 0){
            for(uint256 i = numberOfGroup; i > 0; i--){
                _createGroup(listPoolsIndex);
            }
        }

        emit CreatePoolEvent(
            listPoolsIndex,
            msg.sender,
            pool.path,
            pool.amountIn,
            pool.amountOut,
            pool.duration,
            pool.expired,
            pool.discount,
            pool.poolPrice,
            pool.threshold,
            pool.groupAmount,
            pool.protocolFee,
            0
        );
    }

    function purchasePool(
        uint256 _poolId,
        address[] memory _path,
        uint256 _amountIn,
        bool _shouldWrap
    ) external payable nonReentrant {
        Pool memory item = listPools[_poolId];
        validatePair(item.path, _path);
        require(item.expired > block.timestamp, "expired");
        require (item.groupAmount == 0, "group");

        uint256 amountOut = getSellingPoolAmountOut(_amountIn, item.poolId, _path, true);
        require(item.totalOut.add(amountOut) <= item.amountIn, "soldout");

        _transferInETH();
        _wrapAndTransfer(_amountIn, _path.length == 2 ? _path[1] : _path[2], _shouldWrap);

        listPools[_poolId].totalOut = listPools[_poolId].totalOut.add(amountOut);
        listPools[_poolId].totalIn = listPools[_poolId].totalIn.add(_amountIn);

        BuyPool memory buyPool;
        if (buyPools[msg.sender][_poolId].poolId > 0) {
            buyPool = buyPools[msg.sender][_poolId];
            buyPool.amountIn = buyPool.amountIn.add(_amountIn);
            buyPool.amountOut = buyPool.amountOut.add(amountOut);
            buyPool.times = buyPool.times.add(1);
        } else {
            buyPool = BuyPool(
                _poolId,
                1,
                msg.sender,
                _amountIn,
                amountOut
            );
            listBuyPoolsIndex[msg.sender] = listBuyPoolsIndex[msg.sender].add(1);
            listBuyPools[msg.sender][listBuyPoolsIndex[msg.sender]] = _poolId;
        }
        buyPools[msg.sender][_poolId] = buyPool;

        emit BuyPoolEvent(
            _poolId,
            buyPool.times,
            msg.sender,
            _path,
            _amountIn,
            amountOut
        );
    }

    function placeGroup(
        uint256 _poolId,
        uint256 _groupId,
        address[] memory _path,
        uint256 _amountIn,
        bool _shouldWrap
    ) external payable nonReentrant {
        Pool memory item = listPools[_poolId];
        validatePair(item.path, _path);
        Group memory group = listGroups[_groupId];
        require(item.expired > block.timestamp, "expired");

        uint256 amountOut = getSellingPoolAmountOut(_amountIn, item.poolId, _path, true);
        require(item.totalOut.add(amountOut) <= item.amountIn, "soldout");
        require(item.groupAmount > 0 && group.totalIn.add(_amountIn) <= item.groupAmount, "done");

        _transferInETH();
        _wrapAndTransfer(_amountIn, _path.length == 2 ? _path[1] : _path[2], _shouldWrap);

        group.totalOut = group.totalOut.add(amountOut);
        group.totalIn = group.totalIn.add(_amountIn);
        if (item.groupAmount > 0 && group.totalIn == item.groupAmount) {
            group.isEligible = true;
            item.totalOut = item.totalOut.add(group.totalOut);
            item.totalIn = item.totalIn.add(group.totalIn);
            listPools[_poolId] = item;
        }
        listGroups[_groupId] = group;

        BuyGroup memory buyGroup;
        if (buyGroups[msg.sender][_groupId].groupId > 0) {
            buyGroup = buyGroups[msg.sender][_groupId];
            buyGroup.amountIn = buyGroup.amountIn.add(_amountIn);
            buyGroup.amountOut = buyGroup.amountOut.add(amountOut);
            buyGroup.times = buyGroup.times.add(1);
        } else {
            buyGroup = BuyGroup(
                _poolId,
                _groupId,
                1,
                msg.sender,
                _amountIn,
                amountOut
            );
            listBuyGroupsIndex[msg.sender] = listBuyGroupsIndex[msg.sender].add(1);
            listBuyGroups[msg.sender][listBuyGroupsIndex[msg.sender]] = _groupId;
            countBuyGroup[_groupId] = countBuyGroup[_groupId].add(1);
        }
        buyGroups[msg.sender][_groupId] = buyGroup;

        emit BuyGroupEvent(
            _poolId,
            _groupId,
            buyGroup.times,
            msg.sender,
            _path,
            _amountIn,
            amountOut
        );
    }

    function ownerClaimPool(uint256 _poolId) external nonReentrant {
        Pool memory item = listPools[_poolId];
        require(item.account == msg.sender, "owner");

        address _tokenIn = item.path.length == 2 ? item.path[1] : item.path[2];
        address _tokenOut = item.path.length == 2 ? item.path[0] : item.path[1];

        uint256 refundableAmount;
        uint256 claimableAmount;
        (, refundableAmount, claimableAmount) = getOwnerClaimPool(_poolId);
        listPools[_poolId].ownerClaimed = item.ownerClaimed.add(claimableAmount);
        if(refundableAmount != 0){
            listPools[_poolId].totalOut = item.amountIn;
            IERC20(_tokenIn).safeTransfer(msg.sender, refundableAmount);
            IERC20(_tokenOut).safeTransfer(msg.sender, claimableAmount);
        }else {
            IERC20(_tokenOut).safeTransfer(msg.sender, claimableAmount);
        }

        emit OwnerClaimPool(msg.sender, _poolId, refundableAmount, claimableAmount);
    }

    function getOwnerClaimPool(
        uint256 _poolId
    ) public view returns (address, uint256, uint256) {
        Pool memory item = listPools[_poolId];

        uint256 claimableAmount;
        uint256 refundableAmount;
        if(item.expired < block.timestamp){
            refundableAmount = item.amountIn.sub(item.totalOut);
        }
        if(item.totalOut >= item.amountIn.mul(item.threshold).div(BASIS_POINTS_DIVISOR)){
            claimableAmount = item.totalIn.sub(item.ownerClaimed);
        }

        return (item.account, refundableAmount, claimableAmount);
    }

    function claimPool(uint256 _poolId) external nonReentrant {
        Pool memory item = listPools[_poolId];
        BuyPool memory buyPool = buyPools[msg.sender][_poolId];

        address _tokenIn = item.path.length == 2 ? item.path[1] : item.path[2];
        address _tokenOut = item.path.length == 2 ? item.path[0] : item.path[1];

        uint256 refundableAmount;
        uint256 claimableAmount;
        if(item.groupAmount > 0){
            for (uint256 i = groupsIndex[_poolId]; i > 0; i--) {
                Group memory group = listGroups[i];
                BuyGroup memory buyGroup = buyGroups[msg.sender][group.groupId];
                if (group.isEligible) {
                    claimableAmount = claimableAmount.add(buyGroup.amountOut);
                    buyGroups[msg.sender][group.groupId].amountOut = 0;
                } else {
                    if(item.expired < block.timestamp){
                        refundableAmount = refundableAmount.add(buyGroup.amountIn);
                        buyGroups[msg.sender][group.groupId].amountIn = 0; 
                    }
                }
            }
        } else {
            if (item.totalOut >= item.amountIn.mul(item.threshold).div(BASIS_POINTS_DIVISOR)) {
                claimableAmount = claimableAmount.add(buyPool.amountOut);
                buyPools[msg.sender][_poolId].amountOut = 0;
            } else {
                if(item.expired < block.timestamp){
                    refundableAmount = refundableAmount.add(buyPool.amountIn);
                    buyPools[msg.sender][_poolId].amountIn = 0;
                }
            }
        }

        IERC20(_tokenIn).safeTransfer(msg.sender, claimableAmount);
        IERC20(_tokenOut).safeTransfer(msg.sender, refundableAmount);

        emit TraderClaimPool(msg.sender, _poolId, refundableAmount, claimableAmount);
    }

    function getTraderClaimPool(
        uint256 _poolId,
        address _account
    ) public view returns (address, uint256, uint256) {
        Pool memory item = listPools[_poolId];
        BuyPool memory buyPool = buyPools[_account][_poolId];

        uint256 refundableAmount;
        uint256 claimableAmount;
        if(item.groupAmount > 0){
            for (uint256 i = groupsIndex[_poolId]; i > 0; i--) {
                Group memory group = listGroups[i];
                BuyGroup memory buyGroup = buyGroups[_account][group.groupId];
                if (group.isEligible) {
                    claimableAmount = claimableAmount.add(buyGroup.amountOut);
                } else {
                    if(item.expired < block.timestamp){
                        refundableAmount = refundableAmount.add(buyGroup.amountIn);
                    }
                }
            }
        } else {
            if (item.totalOut >= item.amountIn.mul(item.threshold).div(BASIS_POINTS_DIVISOR)) {
                claimableAmount = claimableAmount.add(buyPool.amountOut);
            } else {
                if(item.expired < block.timestamp){
                    refundableAmount = refundableAmount.add(buyPool.amountIn);
                }
            }
        }
        
        return (_account, refundableAmount, claimableAmount);
    }

    function claimGroup(
        uint256 _poolId,
        uint256 _groupId
    ) external nonReentrant {
        Pool memory item = listPools[_poolId];
        Group memory group = listGroups[_groupId];
        BuyGroup memory buyGroup = buyGroups[msg.sender][_groupId];

        require(buyGroup.groupId > 0, "buy");
        require(buyGroup.account == msg.sender, "buyer");
        require(buyGroups[msg.sender][_groupId].amountOut > 0, "amountOut");
        
        address _tokenIn = item.path.length == 2 ? item.path[0] : item.path[1];
        address _tokenOut = item.path.length == 2 ? item.path[1] : item.path[2];

        uint256 claimableAmount;
        if(group.isEligible){
            claimableAmount = buyGroups[msg.sender][_groupId].amountOut;
            buyGroups[msg.sender][_groupId].amountOut = 0;
            IERC20(_tokenIn).safeTransfer(msg.sender, claimableAmount);
        }else{
            claimableAmount = buyGroups[msg.sender][_groupId].amountIn;
            buyGroups[msg.sender][_groupId].amountIn = 0;
            IERC20(_tokenOut).safeTransfer(msg.sender, claimableAmount);
        }

        emit TraderClaimGroup(msg.sender, _poolId, _groupId, group.isEligible, claimableAmount);
    }

    function _createGroup(uint256 _poolId) internal {
        Pool memory item = listPools[_poolId];

        listGroupsIndex = listGroupsIndex.add(1);
        Group memory group = Group(
            _poolId,
            listGroupsIndex,
            msg.sender,
            true,
            0,
            0
        );
        listGroups[listGroupsIndex] = group;
        groupsIndex[_poolId] = groupsIndex[_poolId].add(1);
        groups[_poolId][groupsIndex[_poolId]] = listGroupsIndex;

        emit CreateGroupEvent(
            _poolId,
            listGroupsIndex,
            msg.sender,
            item.path,
            true,
            0,
            0
        );
    }

    function _wrapAndTransfer(
        uint256 _amountIn,
        address _path0,
        bool _shouldWrap
    ) private {
        if (_shouldWrap) {
            require(_path0 == weth, "weth");
            require(msg.value == _amountIn, "value");
        } else {
            IRouter(router).pluginTransfer(
                _path0,
                msg.sender,
                address(this),
                _amountIn
            );
        }
    }

    function _transferInETH() private {
        if (msg.value != 0) {
            IWETH(weth).deposit{value: msg.value}();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IBasePositionManager {
    function maxGlobalLongSizes(address _token) external view returns (uint256);
    function maxGlobalShortSizes(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IVault.sol";

interface IBlpManager {
    function blp() external view returns (address);
    function bxd() external view returns (address);
    function vault() external view returns (IVault);
    function cooldownDuration() external returns (uint256);
    function getAumInBxd(bool maximise) external view returns (uint256);
    function lastAddedAt(address _account) external returns (uint256);
    function addLiquidity(address _token, uint256 _amount, uint256 _minBxd, uint256 _minBlp) external returns (uint256);
    function addLiquidityForAccount(address _fundingAccount, address _account, address _token, uint256 _amount, uint256 _minBxd, uint256 _minBlp) external returns (uint256);
    function removeLiquidity(address _tokenOut, uint256 _blpAmount, uint256 _minOut, address _receiver) external returns (uint256);
    function removeLiquidityForAccount(address _account, address _tokenOut, uint256 _blpAmount, uint256 _minOut, address _receiver) external returns (uint256);
    function setShortsTrackerAveragePriceWeight(uint256 _shortsTrackerAveragePriceWeight) external;
    function setCooldownDuration(uint256 _cooldownDuration) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface ILPTOLock {
    function lock(
        address owner,
        address token,
        bool isLpToken,
        uint256 amount,
        uint256 unlockDate,
        string memory description
    ) external payable returns (uint256 lockId);

    function vestingLock(
        address owner,
        address token,
        bool isLpToken,
        uint256 amount,
        uint256 tgeDate,
        uint256 tgeBps,
        uint256 cycle,
        uint256 cycleBps,
        string memory description
    ) external payable returns (uint256 lockId);

    function multipleVestingLock(
        address[] calldata owners,
        uint256[] calldata amounts,
        address token,
        bool isLpToken,
        uint256 tgeDate,
        uint256 tgeBps,
        uint256 cycle,
        uint256 cycleBps,
        string memory description
    ) external payable returns (uint256[] memory);

    function unlock(uint256 lockId) external;

    function editLock(
        uint256 lockId,
        uint256 newAmount,
        uint256 newUnlockDate
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IOrderBook {
	function getSwapOrder(address _account, uint256 _orderIndex) external view returns (
        address path0, 
        address path1,
        address path2,
        uint256 amountIn,
        uint256 minOut,
        uint256 triggerRatio,
        bool triggerAboveThreshold,
        bool shouldUnwrap,
        uint256 executionFee
    );

    function getIncreaseOrder(address _account, uint256 _orderIndex) external view returns (
        address purchaseToken, 
        uint256 purchaseTokenAmount,
        address collateralToken,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );

    function getDecreaseOrder(address _account, uint256 _orderIndex) external view returns (
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );

    function executeSwapOrder(address, uint256, address payable) external;
    function executeDecreaseOrder(address, uint256, address payable) external;
    function executeIncreaseOrder(address, uint256, address payable) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IPositionRouter {
    function increasePositionRequestKeysStart() external view returns (uint256);
    function decreasePositionRequestKeysStart() external view returns (uint256);
    function increasePositionRequestKeys(uint256 index) external view returns (bytes32);
    function decreasePositionRequestKeys(uint256 index) external view returns (bytes32);
    function executeIncreasePositions(uint256 _count, address payable _executionFeeReceiver) external;
    function executeDecreasePositions(uint256 _count, address payable _executionFeeReceiver) external;
    function getRequestQueueLengths() external view returns (uint256, uint256, uint256, uint256);
    function getIncreasePositionRequestPath(bytes32 _key) external view returns (address[] memory);
    function getDecreasePositionRequestPath(bytes32 _key) external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IPositionRouterCallbackReceiver {
    function bxpPositionCallback(bytes32 positionKey, bool isExecuted, bool isIncrease) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IRouter {
    function addPlugin(address _plugin) external;
    function pluginTransfer(address _token, address _account, address _receiver, uint256 _amount) external;
    function pluginIncreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external;
    function pluginDecreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256);
    function swap(address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IShortsTracker {
    function isGlobalShortDataReady() external view returns (bool);
    function globalShortAveragePrices(address _token) external view returns (uint256);
    function getNextGlobalShortData(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _nextPrice,
        uint256 _sizeDelta,
        bool _isIncrease
    ) external view returns (uint256, uint256);
    function updateGlobalShortData(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta,
        uint256 _markPrice,
        bool _isIncrease
    ) external;
    function setIsGlobalShortDataReady(bool value) external;
    function setInitData(address[] calldata _tokens, uint256[] calldata _averagePrices) external;
}

// SPDX-License-Identifier: MIT
import "../../libraries/token/IERC20.sol";

pragma solidity ^0.6.0;

interface ISPERC20 is IERC20 {
   function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IVaultUtils.sol";

interface IVault {
    function isInitialized() external view returns (bool);
    function isSwapEnabled() external view returns (bool);
    function isLeverageEnabled() external view returns (bool);

    function setVaultUtils(IVaultUtils _vaultUtils) external;
    function setError(uint256 _errorCode, string calldata _error) external;

    function router() external view returns (address);
    function bxd() external view returns (address);
    function gov() external view returns (address);

    function whitelistedTokenCount() external view returns (uint256);
    function maxLeverage() external view returns (uint256);

    function minProfitTime() external view returns (uint256);
    function hasDynamicFees() external view returns (bool);
    function fundingInterval() external view returns (uint256);
    function totalTokenWeights() external view returns (uint256);
    function getTargetBxdAmount(address _token) external view returns (uint256);

    function inManagerMode() external view returns (bool);
    function inPrivateLiquidationMode() external view returns (bool);

    function maxGasPrice() external view returns (uint256);

    function approvedRouters(address _account, address _router) external view returns (bool);
    function isLiquidator(address _account) external view returns (bool);
    function isManager(address _account) external view returns (bool);

    function minProfitBasisPoints(address _token) external view returns (uint256);
    function tokenBalances(address _token) external view returns (uint256);
    function lastFundingTimes(address _token) external view returns (uint256);

    function setMaxLeverage(uint256 _maxLeverage) external;
    function setInManagerMode(bool _inManagerMode) external;
    function setManager(address _manager, bool _isManager) external;
    function setIsSwapEnabled(bool _isSwapEnabled) external;
    function setIsLeverageEnabled(bool _isLeverageEnabled) external;
    function setMaxGasPrice(uint256 _maxGasPrice) external;
    function setBxdAmount(address _token, uint256 _amount) external;
    function setBufferAmount(address _token, uint256 _amount) external;
    function setMaxGlobalShortSize(address _token, uint256 _amount) external;
    function setInPrivateLiquidationMode(bool _inPrivateLiquidationMode) external;
    function setLiquidator(address _liquidator, bool _isActive) external;

    function setFundingRate(uint256 _fundingInterval, uint256 _fundingRateFactor, uint256 _stableFundingRateFactor) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _minProfitBps,
        uint256 _maxBxdAmount,
        bool _isStable,
        bool _isShortable
    ) external;

    function setPriceFeed(address _priceFeed) external;
    function withdrawFees(address _token, address _receiver) external returns (uint256);

    function directPoolDeposit(address _token) external;
    function buyBXD(address _token, address _receiver) external returns (uint256);
    function sellBXD(address _token, address _receiver) external returns (uint256);
    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);
    function increasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external;
    function decreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256);
    function validateLiquidation(address _account, address _collateralToken, address _indexToken, bool _isLong, bool _raise) external view returns (uint256, uint256);
    function liquidatePosition(address _account, address _collateralToken, address _indexToken, bool _isLong, address _feeReceiver) external;
    function tokenToUsdMin(address _token, uint256 _tokenAmount) external view returns (uint256);

    function priceFeed() external view returns (address);
    function fundingRateFactor() external view returns (uint256);
    function stableFundingRateFactor() external view returns (uint256);
    function cumulativeFundingRates(address _token) external view returns (uint256);
    function getNextFundingRate(address _token) external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _bxdDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);
    function taxBasisPoints() external view returns (uint256);
    function stableTaxBasisPoints() external view returns (uint256);
    function mintBurnFeeBasisPoints() external view returns (uint256);
    function swapFeeBasisPoints() external view returns (uint256);
    function stableSwapFeeBasisPoints() external view returns (uint256);
    function marginFeeBasisPoints() external view returns (uint256);

    function allWhitelistedTokensLength() external view returns (uint256);
    function allWhitelistedTokens(uint256) external view returns (address);
    function whitelistedTokens(address _token) external view returns (bool);
    function stableTokens(address _token) external view returns (bool);
    function shortableTokens(address _token) external view returns (bool);
    function feeReserves(address _token) external view returns (uint256);
    function globalShortSizes(address _token) external view returns (uint256);
    function globalShortAveragePrices(address _token) external view returns (uint256);
    function maxGlobalShortSizes(address _token) external view returns (uint256);
    function tokenDecimals(address _token) external view returns (uint256);
    function tokenWeights(address _token) external view returns (uint256);
    function guaranteedUsd(address _token) external view returns (uint256);
    function poolAmounts(address _token) external view returns (uint256);
    function bufferAmounts(address _token) external view returns (uint256);
    function reservedAmounts(address _token) external view returns (uint256);
    function bxdAmounts(address _token) external view returns (uint256);
    function maxBxdAmounts(address _token) external view returns (uint256);
    function getRedemptionAmount(address _token, uint256 _bxdAmount) external view returns (uint256);
    function getMaxPrice(address _token) external view returns (uint256);
    function getMinPrice(address _token) external view returns (uint256);

    function getDelta(address _indexToken, uint256 _size, uint256 _averagePrice, bool _isLong, uint256 _lastIncreasedTime) external view returns (bool, uint256);
    function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);

    function adjustForDecimals(uint256 _amount, address _tokenDiv, address _tokenMul) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IVaultPriceFeed {
    function adjustmentBasisPoints(address _token) external view returns (uint256);
    function isAdjustmentAdditive(address _token) external view returns (bool);
    function setAdjustment(address _token, bool _isAdditive, uint256 _adjustmentBps) external;
    function setUseV2Pricing(bool _useV2Pricing) external;
    function setIsAmmEnabled(bool _isEnabled) external;
    function setIsSecondaryPriceEnabled(bool _isEnabled) external;
    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints) external;
    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints) external;
    function setFavorPrimaryPrice(bool _favorPrimaryPrice) external;
    function setPriceSampleSpace(uint256 _priceSampleSpace) external;
    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation) external;
    function getPrice(address _token, bool _maximise, bool _includeAmmPrice, bool _useSwapPricing) external view returns (uint256);
    function getAmmPrice(address _token) external view returns (uint256);
    function getLatestPrimaryPrice(address _token) external view returns (uint256);
    function getPrimaryPrice(address _token, bool _maximise) external view returns (uint256);
    function setTokenConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IVaultUtils {
    function updateCumulativeFundingRate(address _collateralToken, address _indexToken) external returns (bool);
    function validateIncreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external view;
    function validateDecreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external view;
    function validateLiquidation(address _account, address _collateralToken, address _indexToken, bool _isLong, bool _raise) external view returns (uint256, uint256);
    function getEntryFundingRate(address _collateralToken, address _indexToken, bool _isLong) external view returns (uint256);
    function getPositionFee(address _account, address _collateralToken, address _indexToken, bool _isLong, uint256 _sizeDelta) external view returns (uint256);
    function getFundingFee(address _account, address _collateralToken, address _indexToken, bool _isLong, uint256 _size, uint256 _entryFundingRate) external view returns (uint256);
    function getBuyBxdFeeBasisPoints(address _token, uint256 _bxdAmount) external view returns (uint256);
    function getSellBxdFeeBasisPoints(address _token, uint256 _bxdAmount) external view returns (uint256);
    function getSwapFeeBasisPoints(address _tokenIn, address _tokenOut, uint256 _bxdAmount) external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _bxdDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../tokens/interfaces/IWETH.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/Address.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IRouter.sol";
import "./interfaces/IVault.sol";

contract LeaderBuyingPool is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    struct Pool {
        uint256 poolId;
        address account;
        address[] path;
        uint256 amountIn;
        uint256 amountOut;
        uint256 duration;
        uint256 expired;
        uint256 discount;
        uint256 poolPrice;
        uint256 leaderThreshold;
        uint256 commission;
        uint256 protocolFee;
        uint256 ownerClaimed;
        uint256 totalIn;
        uint256 totalOut;
    }

    struct Group {
        uint256 poolId;
        uint256 groupId;
        address account;
        bool isEligible;
        uint256 totalCommission;
        uint256 leaderClaimed;
        uint256 totalIn;
        uint256 totalOut;
    }

    struct BuyGroup {
        uint256 poolId;
        uint256 groupId;
        uint256 times;
        address account;
        uint256 amountIn;
        uint256 amountOut;
    }

    uint256 public listPoolsIndex; // Index 1,2,3,... of all pools
    mapping(uint256 => Pool) public listPools; // Index 1,2,3,...  -> Pool

    uint256 public listGroupsIndex; // Index 1,2,3,... of all Groups
    mapping(uint256 => Group) public listGroups; // Index 1,2,3,... of group  -> Group
    mapping(uint256 => uint256) public groupsIndex; // poolId -> Index 1,2,3,... of group
    mapping(uint256 => mapping(uint256 => uint256)) public groups; // poolId -> Index 1,2,3,... of group -> groupId
    mapping(uint256 => mapping(address => uint256)) public leaderInPool; // poolId -> Leader -> groupIndex 

    mapping(address => uint256) public listBuyGroupsIndex; // Trader -> Index 1,2,3,... of group
    mapping(address => mapping(uint256 => uint256)) public listBuyGroups; // Trader -> Index 1,2,3,... -> groupId
    mapping(address => mapping(uint256 => BuyGroup)) public buyGroups; // Trader -> groupId -> BuyGroup
    mapping(uint256 => uint256) public countBuyGroup;

    address public gov;
    address public weth;
    address public router;
    address public vault;
    uint256 public minExecutionFee;
    uint256 public minPurchaseTokenAmountUsd;
    bool public isInitialized = false;

    event CreatePoolEvent(
        uint256 poolId,
        address indexed account,
        address[] path,
        uint256 amountIn,
        uint256 amountOut,
        uint256 duration,
        uint256 expired,
        uint256 discount,
        uint256 poolPrice,
        uint256 commission,
        uint256 leaderThreshold,
        uint256 protocolFee,
        uint256 ownerClaimed
    );

    event CreateGroupEvent(
        uint256 poolId,
        uint256 groupId,
        address indexed account,
        address[] path,
        bool isEligible,
        uint256 totalCommission,
        uint256 leaderClaimed,
        uint256 totalIn,
        uint256 totalOut
    );

    event BuyGroupEvent(
        uint256 poolId,
        uint256 groupId,
        uint256 buyGroupId,
        address indexed account,
        address[] path,
        uint256 amountIn,
        uint256 amountOut
    );

    event LeaderClaimCommission(
        address account,
        uint256 poolId,
        uint256 totalCommission
    );

    event OwnerClaimPool(
        address account,
        uint256 poolId,
        uint256 refundableAmount,
        uint256 claimableAmount
    );

    event TraderClaimPool(
        address account,
        uint256 poolId,
        uint256 refundableAmount,
        uint256 claimableAmount
    );

    event TraderClaimGroup(
        address account,
        uint256 poolId,
        uint256 groupId,
        bool isEligible,
        uint256 claimableAmount
    );

    event Initialize(
        address router,
        address vault,
        address weth,
        uint256 minExecutionFee,
        uint256 minPurchaseTokenAmountUsd
    );
    event UpdateMinExecutionFee(uint256 minExecutionFee);
    event UpdateMinPurchaseTokenAmountUsd(uint256 minPurchaseTokenAmountUsd);
    event UpdateRouter(address router);
    event UpdateVault(address vault);
    event UpdateGov(address gov);

    modifier onlyGov() {
        require(msg.sender == gov, "forbidden");
        _;
    }

    constructor() public {
        gov = msg.sender;
    }

    function initialize(
        address _router,
        address _vault,
        address _weth,
        uint256 _minExecutionFee,
        uint256 _minPurchaseTokenAmountUsd
    ) external onlyGov {
        require(!isInitialized, "initialized");
        isInitialized = true;

        router = _router;
        vault = _vault;
        weth = _weth;
        minExecutionFee = _minExecutionFee;
        minPurchaseTokenAmountUsd = _minPurchaseTokenAmountUsd;

        emit Initialize(
            _router,
            _vault,
            _weth,
            _minExecutionFee,
            _minPurchaseTokenAmountUsd
        );
    }

    receive() external payable {
        require(msg.sender == weth, "sender");
    }

    function setMinExecutionFee(uint256 _minExecutionFee) external onlyGov {
        minExecutionFee = _minExecutionFee;
        emit UpdateMinExecutionFee(_minExecutionFee);
    }

    function setMinPurchaseTokenAmountUsd(
        uint256 _minPurchaseTokenAmountUsd
    ) external onlyGov {
        minPurchaseTokenAmountUsd = _minPurchaseTokenAmountUsd;
        emit UpdateMinPurchaseTokenAmountUsd(_minPurchaseTokenAmountUsd);
    }

    function setRouter(address _router) external onlyGov {
        router = _router;
        emit UpdateRouter(_router);
    }

    function setVault(address _vault) external onlyGov {
        vault = _vault;
        emit UpdateVault(_vault);
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
        emit UpdateGov(_gov);
    }

    function validatePair(
        address[] memory _path,
        address[] memory _buyPath
    ) public pure {
        require(_path.length == 2 || _path.length == 3, "path.length");
        require(_path[0] != _path[_path.length - 1], "path");
        require(
            _buyPath.length == 2 || _buyPath.length == 3,
            "_buyPath.length"
        );
        require(_buyPath[0] != _buyPath[_buyPath.length - 1], "_buyPath");
        address _tokenIn = _path.length == 2 ? _path[0] : _path[1];
        address _tokenOut = _path.length == 2 ? _path[1] : _path[2];
        address _buyTokenIn = _buyPath.length == 2 ? _buyPath[0] : _buyPath[1];
        address _buyTokenOut = _buyPath.length == 2 ? _buyPath[1] : _buyPath[2];
        require(_tokenIn == _buyTokenOut, "_buyTokenOut");
        require(_tokenOut == _buyTokenIn, "_buyTokenIn");
    }

    function getPools(
        uint256 _offset,
        uint256 _limit
    ) public view returns (Pool[] memory) {
        uint256 from = _offset > 0 && _offset <= listPoolsIndex
            ? listPoolsIndex - _offset + 1
            : 0;
        uint256 limit = _limit < from ? _limit : from;
        Pool[] memory items = new Pool[](limit);
        for (uint256 i = 0; i < limit; i++) {
            Pool memory item = listPools[from - i];
            items[i] = item;
        }
        return items;
    }

    function getPoolActive(
        uint256 _offset,
        uint256 _limit
    ) public view returns (Pool[] memory) {
        uint256 limit = _limit < listPoolsIndex ? _limit : listPoolsIndex;
        uint256 count = 0;
        Pool[] memory items = new Pool[](limit);
        for (uint256 i = listPoolsIndex; i > 0; i--) {
            Pool memory item = listPools[i];
            if (item.expired > block.timestamp) {
                count = count.add(1);
                if (count >= _offset + limit) {
                    break;
                }
                if (count >= _offset) {
                    items[count - _offset] = item;
                }
            }
        }
        return items;
    }

    function getPoolOwner(
        address _account,
        uint256 _offset,
        uint256 _limit
    ) public view returns (Pool[] memory) {
        uint256 limit = _limit < listPoolsIndex ? _limit : listPoolsIndex;
        uint256 count = 0;
        Pool[] memory items = new Pool[](limit);
        for (uint256 i = listPoolsIndex; i > 0; i--) {
            Pool memory item = listPools[i];
            if (item.account == _account) {
                count = count.add(1);
                if (count >= _offset + limit) {
                    break;
                }
                if (count >= _offset) {
                    items[count - _offset] = item;
                }
            }
        }
        return items;
    }

    function getGroups(
        uint256 _poolId,
        uint256 _offset,
        uint256 _limit
    ) public view returns (Group[] memory) {
        uint256 from = _offset > 0 && _offset <= groupsIndex[_poolId]
            ? groupsIndex[_poolId] - _offset + 1
            : 0;
        uint256 limit = _limit < from ? _limit : from;
        Group[] memory items = new Group[](limit);
        for (uint256 i = 0; i < limit; i++) {
            uint256 groupId = groups[_offset][from - i];
            Group memory item = listGroups[groupId];
            items[i] = item;
        }
        return items;
    }

    function getMarketAmountOut(
        uint256 _amountIn,
        address[] memory _path,
        uint256 discount
    ) public view returns (uint256, uint256, uint256, uint256) {
        address _tokenIn = _path.length == 2 ? _path[0] : _path[1];
        address _tokenOut = _path.length == 2 ? _path[1] : _path[2];
        uint256 priceIn = IVault(vault).getMinPrice(_tokenIn);
        uint256 priceOut = IVault(vault).getMinPrice(_tokenOut);

        uint256 amountOut = _amountIn.mul(priceIn).div(priceOut);
        amountOut = IVault(vault).adjustForDecimals(
            amountOut,
            _tokenIn,
            _tokenOut
        );
        amountOut = amountOut.mul(BASIS_POINTS_DIVISOR.sub(discount)).div(
            BASIS_POINTS_DIVISOR
        );

        uint256 poolPrice = (10**IVault(vault).tokenDecimals(_tokenOut)).mul(priceIn).div(priceOut);
        poolPrice = poolPrice.mul(BASIS_POINTS_DIVISOR.sub(discount)).div(BASIS_POINTS_DIVISOR);
        
        return (priceIn, priceOut, amountOut, poolPrice);
    }

    function getPoolAmountOut(
        uint256 _amountIn,
        uint256 _poolId,
        address[] memory _path,
        bool _isReversalPoolPath
    ) public view returns (uint256 amountOut) {
        Pool memory item = listPools[_poolId];

        address _tokenIn = _path.length == 2 ? _path[0] : _path[1];
        address _tokenOut = _path.length == 2 ? _path[1] : _path[2];

        uint256 amountIn = IVault(vault).adjustForDecimals(
            _amountIn,
            _tokenIn,
            _tokenOut
        );
        amountOut = _isReversalPoolPath ? 
            amountIn.mul(10**IVault(vault).tokenDecimals(_tokenOut)).div(item.poolPrice) : 
            _amountIn.mul(item.poolPrice).div(10**IVault(vault).tokenDecimals(_tokenIn));
    }

    function createPool(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _duration,
        uint256 _discount,
        uint256 _leaderThreshold,
        uint256 _commission,
        bool _shouldWrap
    ) external payable nonReentrant {
        require(_path.length == 2 || _path.length == 3, "length");
        require(_path[0] != _path[_path.length - 1], "path");
        require(_amountIn > 0, "amountIn");

        // always need this call because of mandatory executionFee user has to transfer in ETH
        _transferInETH();
        _wrapAndTransfer(_amountIn, _path[0], _shouldWrap);

        uint256 amountInExcludingFee = _amountIn.mul(BASIS_POINTS_DIVISOR).div(
            BASIS_POINTS_DIVISOR.add(minExecutionFee)
        );
        uint256 protocolFee = _amountIn.sub(amountInExcludingFee);

        uint256 expired = _duration + block.timestamp;

        uint256 amountOut;
        uint256 poolPrice;
        (, , amountOut, poolPrice) = getMarketAmountOut(amountInExcludingFee, _path, _discount);
        
        listPoolsIndex = listPoolsIndex.add(1);
        Pool memory pool = Pool(
            listPoolsIndex,
            msg.sender,
            _path,
            amountInExcludingFee,
            amountOut,
            _duration,
            expired,
            _discount,
            poolPrice,
            _leaderThreshold,
            _commission,
            protocolFee,
            0,
            0,
            0
        );

        listPools[listPoolsIndex] = pool;

        emit CreatePoolEvent(
            listPoolsIndex,
            msg.sender,
            pool.path,
            pool.amountIn,
            pool.amountOut,
            pool.duration,
            pool.expired,
            pool.discount,
            pool.poolPrice,
            pool.leaderThreshold,
            pool.commission,
            pool.protocolFee,
            0
        );
    }

    function createGroup(
        uint256 _poolId,
        address[] memory _path
    ) external payable nonReentrant {
        Pool memory item = listPools[_poolId];
        validatePair(item.path, _path);
        require(item.expired > block.timestamp, "expired");
        require(item.totalOut < item.amountIn, "soldout");
        require(leaderInPool[_poolId][msg.sender] == 0, "created");

        listGroupsIndex = listGroupsIndex.add(1);
        Group memory group = Group(
            _poolId,
            listGroupsIndex,
            msg.sender,
            false,
            0,
            0,
            0,
            0
        );
        listGroups[listGroupsIndex] = group;
        groupsIndex[_poolId] = groupsIndex[_poolId].add(1);
        groups[_poolId][groupsIndex[_poolId]] = listGroupsIndex;
        leaderInPool[_poolId][msg.sender] = listGroupsIndex;

        BuyGroup memory buyGroup = BuyGroup(
            _poolId,
            listGroupsIndex,
            1,
            msg.sender,
            0,
            0
        );
        listBuyGroupsIndex[msg.sender] = listBuyGroupsIndex[msg.sender].add(1);
        listBuyGroups[msg.sender][listBuyGroupsIndex[msg.sender]] = listGroupsIndex;
        buyGroups[msg.sender][listGroupsIndex] = buyGroup;
        countBuyGroup[listGroupsIndex] = 1;

        emit CreateGroupEvent(
            _poolId,
            listGroupsIndex,
            msg.sender,
            _path,
            false,
            0,
            0,
            0,
            0
        );
    }

    function placeGroup(
        uint256 _poolId,
        uint256 _groupId,
        address[] memory _path,
        uint256 _amountIn,
        bool _shouldWrap
    ) external payable nonReentrant {
        Pool memory item = listPools[_poolId];
        validatePair(item.path, _path);
        require(item.expired > block.timestamp, "expired");
        Group memory group = listGroups[_groupId];

        uint256 amountOut = getPoolAmountOut(_amountIn, item.poolId, _path, true);
        require(item.totalOut.add(amountOut) <= item.amountIn, "soldout");
        
        _transferInETH();
        _wrapAndTransfer(_amountIn, _path[0], _shouldWrap);

        group.totalOut = group.totalOut.add(amountOut);
        group.totalIn = group.totalIn.add(_amountIn);
        group.totalCommission = group.totalCommission.add(_amountIn.mul(item.commission).div(BASIS_POINTS_DIVISOR));
        if (group.totalOut >= item.amountIn.mul(item.leaderThreshold).div(BASIS_POINTS_DIVISOR)) {
            group.isEligible = true;
            item.totalOut = item.totalOut.add(group.totalOut);
            item.totalIn = item.totalIn.add(group.totalIn);
            listPools[_poolId] = item;
        }
        listGroups[_groupId] = group;

        BuyGroup memory buyGroup;
        if (buyGroups[msg.sender][_groupId].groupId > 0) {
            buyGroup = buyGroups[msg.sender][_groupId];
            buyGroup.amountIn = buyGroup.amountIn.add(_amountIn);
            buyGroup.amountOut = buyGroup.amountOut.add(amountOut);
            buyGroup.times = buyGroup.times.add(1);
        } else {
            buyGroup = BuyGroup(
                _poolId,
                _groupId,
                1,
                msg.sender,
                _amountIn,
                amountOut
            );
            listBuyGroupsIndex[msg.sender] = listBuyGroupsIndex[msg.sender].add(1);
            listBuyGroups[msg.sender][listBuyGroupsIndex[msg.sender]] = _groupId;
            countBuyGroup[_groupId] = countBuyGroup[_groupId].add(1);
        }
        buyGroups[msg.sender][_groupId] = buyGroup;

        emit BuyGroupEvent(
            _poolId,
            _groupId,
            buyGroup.times,
            msg.sender,
            _path,
            _amountIn,
            amountOut
        );
    }

    function leaderClaimPoolCommission(
        uint256 _poolId
    ) external nonReentrant {
        Pool memory item = listPools[_poolId];
        Group memory group = listGroups[leaderInPool[_poolId][msg.sender]];
        address tokenOut = item.path.length == 2 ? item.path[1] : item.path[2];

        uint256 claimableCommission = getLeaderClaimableCommission(_poolId, msg.sender);
        listGroups[leaderInPool[_poolId][msg.sender]].leaderClaimed = group.totalCommission;

        IERC20(tokenOut).safeTransfer(msg.sender, claimableCommission);

        emit LeaderClaimCommission(
            msg.sender,
            _poolId,
            claimableCommission
        );
    }

    function getLeaderClaimableCommission(uint256 _poolId, address _leader) public view returns (uint256 claimableCommission) {
        Group memory group = listGroups[leaderInPool[_poolId][_leader]];
        if (group.account == _leader && group.isEligible) {
            claimableCommission = claimableCommission.add(group.totalCommission).sub(group.leaderClaimed);
        }
    }

    function ownerClaimPool(uint256 _poolId) external nonReentrant {
        Pool memory item = listPools[_poolId];
        require(item.account == msg.sender, "owner");

        address _tokenIn = item.path.length == 2 ? item.path[0] : item.path[1];
        address _tokenOut = item.path.length == 2 ? item.path[1] : item.path[2];

        uint256 refundableAmount;
        uint256 claimableAmount;
        (, , refundableAmount, claimableAmount) = getOwnerClaimPool(_poolId);
        listPools[_poolId].ownerClaimed = item.ownerClaimed.add(claimableAmount);
        if (refundableAmount != 0) {
            listPools[_poolId].totalOut = item.amountIn;
            IERC20(_tokenIn).safeTransfer(msg.sender, refundableAmount);
            IERC20(_tokenOut).safeTransfer(msg.sender,claimableAmount);
        } else {
            IERC20(_tokenOut).safeTransfer(msg.sender, claimableAmount);
        }

        emit OwnerClaimPool(msg.sender, _poolId, refundableAmount, claimableAmount);
    }

    function getOwnerClaimPool(uint256 _poolId) public view returns (address, uint256, uint256, uint256) {
        Pool memory item = listPools[_poolId];

        uint256 totalLeaderCommission;
        uint256 refundableAmount;
        uint256 claimableAmount;
        if (item.expired < block.timestamp) {
            for (uint256 i = groupsIndex[_poolId]; i > 0; i--) {
                Group memory group = listGroups[i];
                if (group.isEligible) {
                    totalLeaderCommission = totalLeaderCommission.add(group.totalCommission);
                }
            }
            claimableAmount = item.totalIn.sub(totalLeaderCommission).sub(item.ownerClaimed);
            refundableAmount = item.amountIn.sub(item.totalOut);
            return (item.account, totalLeaderCommission, refundableAmount, claimableAmount);
        }

        totalLeaderCommission = item.amountOut.mul(item.commission).div(BASIS_POINTS_DIVISOR);
        if(item.totalIn >= totalLeaderCommission){
            claimableAmount = item.totalIn.sub(totalLeaderCommission).sub(item.ownerClaimed);
        }

        return (item.account, totalLeaderCommission, 0, claimableAmount);
    }

    function claimPool(uint256 _poolId) external nonReentrant {
        Pool memory item = listPools[_poolId];
        address _tokenIn = item.path.length == 2 ? item.path[0] : item.path[1];
        address _tokenOut = item.path.length == 2 ? item.path[1] : item.path[2];
        
        uint256 refundableAmount;
        uint256 claimableAmount;
        for (uint256 i = groupsIndex[_poolId]; i > 0; i--) {
            Group memory group = listGroups[i];
            BuyGroup memory buyGroup = buyGroups[msg.sender][group.groupId];
            if (group.isEligible) {
                claimableAmount = claimableAmount.add(buyGroup.amountOut);
                buyGroups[msg.sender][group.groupId].amountOut = 0;
            } else {
                if(item.amountIn == item.totalOut || item.expired < block.timestamp){
                    refundableAmount = refundableAmount.add(buyGroup.amountIn);
                    buyGroups[msg.sender][group.groupId].amountIn = 0;                
                }
            }
        }

        if(refundableAmount != 0){
            IERC20(_tokenIn).safeTransfer(msg.sender, claimableAmount);
            IERC20(_tokenOut).safeTransfer(msg.sender, refundableAmount);
        } else{
            IERC20(_tokenIn).safeTransfer(msg.sender, claimableAmount);
        }

        emit TraderClaimPool(msg.sender, _poolId, refundableAmount, claimableAmount);
    }

    function getTraderClaimPool(
        uint256 _poolId,
        address _account
    ) public view returns (address, uint256, uint256) {
        Pool memory item = listPools[_poolId];

        uint256 refundableAmount;
        uint256 claimableAmount;
        for (uint256 i = groupsIndex[_poolId]; i > 0; i--) {
            Group memory group = listGroups[i];
            BuyGroup memory buyGroup = buyGroups[_account][group.groupId];
            if (group.isEligible) {
                claimableAmount = claimableAmount.add(buyGroup.amountOut);
            } else {
                if(item.amountIn == item.totalOut || item.expired < block.timestamp){
                    refundableAmount = refundableAmount.add(buyGroup.amountIn);                
                }
            }
        }

        return (_account, refundableAmount, claimableAmount);

    }

    function claimGroup(
        uint256 _poolId,
        uint256 _groupId
    ) external nonReentrant {
        Pool memory item = listPools[_poolId];
        Group memory group = listGroups[_groupId];
        BuyGroup memory buyGroup = buyGroups[msg.sender][_groupId];

        require(buyGroup.groupId > 0, "buy");
        require(buyGroup.account == msg.sender, "buyer");
        require(buyGroups[msg.sender][_groupId].amountOut > 0, "amountOut");
        
        address _tokenIn = item.path.length == 2 ? item.path[0] : item.path[1];
        address _tokenOut = item.path.length == 2 ? item.path[1] : item.path[2];

        uint256 claimableAmount;
        if(group.isEligible){
            claimableAmount = buyGroups[msg.sender][_groupId].amountOut;
            buyGroups[msg.sender][_groupId].amountOut = 0;
            IERC20(_tokenOut).safeTransfer(msg.sender, claimableAmount);
        }else{
            if(item.expired < block.timestamp){
                claimableAmount = buyGroups[msg.sender][_groupId].amountIn;
                buyGroups[msg.sender][_groupId].amountIn = 0;
                IERC20(_tokenIn).safeTransfer(msg.sender, claimableAmount);
            }
        }

        emit TraderClaimGroup(msg.sender, _poolId, _groupId, group.isEligible, claimableAmount);
    }

    function _wrapAndTransfer(
        uint256 _amountIn,
        address _path0,
        bool _shouldWrap
    ) private {
        if (_shouldWrap) {
            require(_path0 == weth, "weth");
            require(msg.value == _amountIn, "value");
        } else {
            IRouter(router).pluginTransfer(
                _path0,
                msg.sender,
                address(this),
                _amountIn
            );
        }
    }

    function _transferInETH() private {
        if (msg.value != 0) {
            IWETH(weth).deposit{value: msg.value}();
        }
    }
    function _withdrawOutETH(uint _amount) private {
        if (msg.value != 0) {
            IWETH(weth).withdraw(_amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../tokens/interfaces/IWETH.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/Address.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IRouter.sol";
import "./interfaces/IVault.sol";

contract LeaderSellingPool is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    struct Pool {
        uint256 poolId;
        address account;
        address[] path;
        uint256 amountIn;
        uint256 amountOut;
        uint256 duration;
        uint256 expired;
        uint256 discount;
        uint256 poolPrice;
        uint256 leaderThreshold;
        uint256 commission;
        uint256 protocolFee;
        uint256 ownerClaimed;
        uint256 totalIn;
        uint256 totalOut;
    }

    struct Group {
        uint256 poolId;
        uint256 groupId;
        address account;
        bool isEligible;
        uint256 totalCommission;
        uint256 leaderClaimed;
        uint256 totalIn;
        uint256 totalOut;
    }

    struct BuyGroup {
        uint256 poolId;
        uint256 groupId;
        uint256 times;
        address account;
        uint256 amountIn;
        uint256 amountOut;
    }

    uint256 public listPoolsIndex; // Index 1,2,3,... of all pools
    mapping(uint256 => Pool) public listPools; // Index 1,2,3,...  -> Pool

    uint256 public listGroupsIndex; // Index 1,2,3,... of all Groups
    mapping(uint256 => Group) public listGroups; // Index 1,2,3,... of group  -> Group
    mapping(uint256 => uint256) public groupsIndex; // poolId -> Index 1,2,3,... of group
    mapping(uint256 => mapping(uint256 => uint256)) public groups; // poolId -> Index 1,2,3,... of group -> groupId
    mapping(uint256 => mapping(address => uint256)) public leaderInPool; // poolId -> Leader -> groupIndex 

    mapping(address => uint256) public listBuyGroupsIndex; // Trader -> Index 1,2,3,... of group
    mapping(address => mapping(uint256 => uint256)) public listBuyGroups; // Trader -> Index 1,2,3,... -> groupId
    mapping(address => mapping(uint256 => BuyGroup)) public buyGroups; // Trader -> groupId -> BuyGroup
    mapping(uint256 => uint256) public countBuyGroup;

    address public gov;
    address public weth;
    address public router;
    address public vault;
    uint256 public minExecutionFee;
    uint256 public minPurchaseTokenAmountUsd;
    bool public isInitialized = false;

    event CreatePoolEvent(
        uint256 poolId,
        address indexed account,
        address[] path,
        uint256 amountIn,
        uint256 amountOut,
        uint256 duration,
        uint256 expired,
        uint256 discount,
        uint256 poolPrice,
        uint256 commission,
        uint256 leaderThreshold,
        uint256 protocolFee,
        uint256 ownerClaimed
    );

    event CreateGroupEvent(
        uint256 poolId,
        uint256 groupId,
        address indexed account,
        address[] path,
        bool isEligible,
        uint256 totalCommission,
        uint256 leaderClaimed,
        uint256 totalIn,
        uint256 totalOut
    );

    event BuyGroupEvent(
        uint256 poolId,
        uint256 groupId,
        uint256 buyGroupTimes,
        address indexed account,
        address[] path,
        uint256 amountIn,
        uint256 amountOut
    );

    event LeaderClaimCommission(
        address account,
        uint256 poolId,
        uint256 totalCommission
    );

    event OwnerClaimPool(
        address account,
        uint256 poolId,
        uint256 refundableAmount,
        uint256 claimableAmount
    );

    event TraderClaimPool(
        address account,
        uint256 poolId,
        uint256 refundableAmount,
        uint256 claimableAmount
    );

    event TraderClaimGroup(
        address account,
        uint256 poolId,
        uint256 groupId,
        bool isEligible,
        uint256 claimableAmount
    );

    event Initialize(
        address router,
        address vault,
        address weth,
        uint256 minExecutionFee,
        uint256 minPurchaseTokenAmountUsd
    );
    event UpdateMinExecutionFee(uint256 minExecutionFee);
    event UpdateMinPurchaseTokenAmountUsd(uint256 minPurchaseTokenAmountUsd);
    event UpdateRouter(address router);
    event UpdateVault(address vault);
    event UpdateGov(address gov);

    modifier onlyGov() {
        require(msg.sender == gov, "forbidden");
        _;
    }

    constructor() public {
        gov = msg.sender;
    }

    function initialize(
        address _router,
        address _vault,
        address _weth,
        uint256 _minExecutionFee,
        uint256 _minPurchaseTokenAmountUsd
    ) external onlyGov {
        require(!isInitialized, "initialized");
        isInitialized = true;

        router = _router;
        vault = _vault;
        weth = _weth;
        minExecutionFee = _minExecutionFee;
        minPurchaseTokenAmountUsd = _minPurchaseTokenAmountUsd;

        emit Initialize(
            _router,
            _vault,
            _weth,
            _minExecutionFee,
            _minPurchaseTokenAmountUsd
        );
    }

    receive() external payable {
        require(msg.sender == weth, "sender");
    }

    function setMinExecutionFee(uint256 _minExecutionFee) external onlyGov {
        minExecutionFee = _minExecutionFee;
        emit UpdateMinExecutionFee(_minExecutionFee);
    }

    function setMinPurchaseTokenAmountUsd(
        uint256 _minPurchaseTokenAmountUsd
    ) external onlyGov {
        minPurchaseTokenAmountUsd = _minPurchaseTokenAmountUsd;
        emit UpdateMinPurchaseTokenAmountUsd(_minPurchaseTokenAmountUsd);
    }

    function setRouter(address _router) external onlyGov {
        router = _router;
        emit UpdateRouter(_router);
    }

    function setVault(address _vault) external onlyGov {
        vault = _vault;
        emit UpdateVault(_vault);
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
        emit UpdateGov(_gov);
    }

    function validatePair(
        address[] memory _path,
        address[] memory _buyPath
    ) public pure {
        require(_path.length == 2 || _path.length == 3, "path.length");
        require(_path[0] != _path[_path.length - 1], "path");
        require(
            _buyPath.length == 2 || _buyPath.length == 3,
            "_buyPath.length"
        );
        require(_buyPath[0] != _buyPath[_buyPath.length - 1], "_buyPath");
        address _tokenIn = _path.length == 2 ? _path[0] : _path[1];
        address _tokenOut = _path.length == 2 ? _path[1] : _path[2];
        address _buyTokenIn = _buyPath.length == 2 ? _buyPath[0] : _buyPath[1];
        address _buyTokenOut = _buyPath.length == 2 ? _buyPath[1] : _buyPath[2];
        require(_tokenIn == _buyTokenOut, "_buyTokenOut");
        require(_tokenOut == _buyTokenIn, "_buyTokenIn");
    }

    function getPools(
        uint256 _offset,
        uint256 _limit
    ) public view returns (Pool[] memory) {
        uint256 from = _offset > 0 && _offset <= listPoolsIndex
            ? listPoolsIndex - _offset + 1
            : 0;
        uint256 limit = _limit < from ? _limit : from;
        Pool[] memory items = new Pool[](limit);
        for (uint256 i = 0; i < limit; i++) {
            Pool memory item = listPools[from - i];
            items[i] = item;
        }
        return items;
    }

    function getPoolActive(
        uint256 _offset,
        uint256 _limit
    ) public view returns (Pool[] memory) {
        uint256 limit = _limit < listPoolsIndex ? _limit : listPoolsIndex;
        uint256 count = 0;
        Pool[] memory items = new Pool[](limit);
        for (uint256 i = listPoolsIndex; i > 0; i--) {
            Pool memory item = listPools[i];
            if (item.expired > block.timestamp) {
                count = count.add(1);
                if (count >= _offset + limit) {
                    break;
                }
                if (count >= _offset) {
                    items[count - _offset] = item;
                }
            }
        }
        return items;
    }

    function getPoolOwner(
        address _account,
        uint256 _offset,
        uint256 _limit
    ) public view returns (Pool[] memory) {
        uint256 limit = _limit < listPoolsIndex ? _limit : listPoolsIndex;
        uint256 count = 0;
        Pool[] memory items = new Pool[](limit);
        for (uint256 i = listPoolsIndex; i > 0; i--) {
            Pool memory item = listPools[i];
            if (item.account == _account) {
                count = count.add(1);
                if (count >= _offset + limit) {
                    break;
                }
                if (count >= _offset) {
                    items[count - _offset] = item;
                }
            }
        }
        return items;
    }

    function getGroups(
        uint256 _poolId,
        uint256 _offset,
        uint256 _limit
    ) public view returns (Group[] memory) {
        uint256 from = _offset > 0 && _offset <= groupsIndex[_poolId]
            ? groupsIndex[_poolId] - _offset + 1
            : 0;
        uint256 limit = _limit < from ? _limit : from;
        Group[] memory items = new Group[](limit);
        for (uint256 i = 0; i < limit; i++) {
            uint256 groupId = groups[_offset][from - i];
            Group memory item = listGroups[groupId];
            items[i] = item;
        }
        return items;
    }

    function getMarketSellingAmountOut(
        uint256 _amountIn,
        address[] memory _path,
        uint256 discount
    ) public view returns (uint256, uint256, uint256, uint256) {
        address _tokenIn = _path.length == 2 ? _path[0] : _path[1];
        address _tokenOut = _path.length == 2 ? _path[1] : _path[2];
        uint256 priceIn = IVault(vault).getMinPrice(_tokenIn);
        uint256 priceOut = IVault(vault).getMinPrice(_tokenOut);

        uint256 amountOut = _amountIn.mul(priceOut).div(priceIn);
        amountOut = IVault(vault).adjustForDecimals(
            amountOut,
            _tokenIn,
            _tokenOut
        );
        amountOut = amountOut.mul(BASIS_POINTS_DIVISOR).div(
            BASIS_POINTS_DIVISOR.add(discount)
        );

        uint256 poolPrice = (10**IVault(vault).tokenDecimals(_tokenOut)).mul(priceIn).div(priceOut);
        poolPrice = poolPrice.mul(BASIS_POINTS_DIVISOR.add(discount)).div(BASIS_POINTS_DIVISOR);
        
        return (priceIn, priceOut, poolPrice, amountOut);
    }

    function getSellingPoolAmountOut(
        uint256 _amountIn,
        uint256 _poolId,
        address[] memory _path,
        bool _isReversalPoolPath
    ) public view returns (uint256 amountOut) {
        Pool memory item = listPools[_poolId];

        address _tokenIn = _path.length == 2 ? _path[1] : _path[2];
        address _tokenOut = _path.length == 2 ? _path[0] : _path[1];

        uint256 amountIn = IVault(vault).adjustForDecimals(
            _amountIn,
            _tokenIn,
            _tokenOut
        );
        amountOut = _isReversalPoolPath ? _amountIn.mul(item.poolPrice).div(10**IVault(vault).tokenDecimals(_tokenIn)) : 
                    amountIn.mul(10**IVault(vault).tokenDecimals(_tokenOut)).div(item.poolPrice);
    }

    function createPool(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _duration,
        uint256 _discount,
        uint256 _leaderThreshold,
        uint256 _commission,
        bool _shouldWrap
    ) external payable nonReentrant {
        require(_path.length == 2 || _path.length == 3, "length");
        require(_path[0] != _path[_path.length - 1], "path");
        require(_amountIn > 0, "amountIn");

        // always need this call because of mandatory executionFee user has to transfer in ETH
        _transferInETH();
        _wrapAndTransfer(_amountIn, _path.length == 2 ? _path[1] : _path[2], _shouldWrap);

        uint256 amountInExcludingFee = _amountIn.mul(BASIS_POINTS_DIVISOR).div(
            BASIS_POINTS_DIVISOR.add(minExecutionFee)
        );
        uint256 protocolFee = _amountIn.sub(amountInExcludingFee);

        uint256 expired = _duration + block.timestamp;

        uint256 amountOut;
        uint256 poolPrice;
        (, ,poolPrice , amountOut) = getMarketSellingAmountOut(amountInExcludingFee, _path, _discount);


        listPoolsIndex = listPoolsIndex.add(1);

        Pool memory pool = Pool(
            listPoolsIndex,
            msg.sender,
            _path,
            amountInExcludingFee,
            amountOut,
            _duration,
            expired,
            _discount,
            poolPrice,
            _leaderThreshold,
            _commission,
            protocolFee,
            0,
            0,
            0
        );

        listPools[listPoolsIndex] = pool;

        emit CreatePoolEvent(
            listPoolsIndex,
            msg.sender,
            pool.path,
            pool.amountIn,
            pool.amountOut,
            pool.duration,
            pool.expired,
            pool.discount,
            pool.poolPrice,
            pool.leaderThreshold,
            pool.commission,
            pool.protocolFee,
            0
        );
    }

    function createGroup(
        uint256 _poolId,
        address[] memory _path
    ) external payable nonReentrant {
        Pool memory item = listPools[_poolId];
        validatePair(item.path, _path);
        require(item.expired > block.timestamp, "expired");
        require(item.totalOut < item.amountIn, "soldout");
        require(leaderInPool[_poolId][msg.sender] == 0, "created");

        listGroupsIndex = listGroupsIndex.add(1);
        Group memory group = Group(
            _poolId,
            listGroupsIndex,
            msg.sender,
            false,
            0,
            0,
            0,
            0
        );
        listGroups[listGroupsIndex] = group;
        groupsIndex[_poolId] = groupsIndex[_poolId].add(1);
        groups[_poolId][groupsIndex[_poolId]] = listGroupsIndex;
        leaderInPool[_poolId][msg.sender] = listGroupsIndex;

        BuyGroup memory buyGroup = BuyGroup(
            _poolId,
            listGroupsIndex,
            1,
            msg.sender,
            0,
            0
        );
        listBuyGroupsIndex[msg.sender] = listBuyGroupsIndex[msg.sender].add(1);
        listBuyGroups[msg.sender][
            listBuyGroupsIndex[msg.sender]
        ] = listGroupsIndex;
        buyGroups[msg.sender][listGroupsIndex] = buyGroup;
        countBuyGroup[listGroupsIndex] = 1;

        emit CreateGroupEvent(
            _poolId,
            listGroupsIndex,
            msg.sender,
            _path,
            false,
            0,
            0,
            0,
            0
        );
    }

    function placeGroup(
        uint256 _poolId,
        uint256 _groupId,
        address[] memory _path,
        uint256 _amountIn,
        bool _shouldWrap
    ) external payable nonReentrant {
        Pool memory item = listPools[_poolId];
        validatePair(item.path, _path);
        require(item.expired > block.timestamp, "expired");
        Group memory group = listGroups[_groupId];

        uint256 amountOut = getSellingPoolAmountOut(_amountIn, item.poolId, _path, true);
        require(item.totalOut.add(amountOut) <= item.amountIn, "soldout");

        _transferInETH();
        _wrapAndTransfer(_amountIn, _path.length == 2 ? _path[1] : _path[2], _shouldWrap);

        group.totalOut = group.totalOut.add(amountOut);
        group.totalIn = group.totalIn.add(_amountIn);
        group.totalCommission = group.totalCommission.add(
            _amountIn.mul(item.commission).div(BASIS_POINTS_DIVISOR)
        );
        if (group.totalIn >= item.amountOut.mul(item.leaderThreshold).div(BASIS_POINTS_DIVISOR)) {
            group.isEligible = true;
            item.totalOut = item.totalOut.add(group.totalOut);
            item.totalIn = item.totalIn.add(group.totalIn);
            listPools[_groupId] = item;
        }
        listGroups[_groupId] = group;

        BuyGroup memory buyGroup;
        if (buyGroups[msg.sender][_groupId].groupId > 0) {
            buyGroup = buyGroups[msg.sender][_groupId];
            buyGroup.amountIn = buyGroup.amountIn.add(_amountIn);
            buyGroup.amountOut = buyGroup.amountOut.add(amountOut);
            buyGroup.times = buyGroup.times.add(1);
        } else {
            buyGroup = BuyGroup(
                _poolId,
                _groupId,
                1,
                msg.sender,
                _amountIn,
                amountOut
            );
            listBuyGroupsIndex[msg.sender] = listBuyGroupsIndex[msg.sender].add(
                1
            );
            listBuyGroups[msg.sender][
                listBuyGroupsIndex[msg.sender]
            ] = _groupId;
            countBuyGroup[_groupId] = countBuyGroup[_groupId].add(1);
        }
        buyGroups[msg.sender][_groupId] = buyGroup;

        emit BuyGroupEvent(
            _poolId,
            _groupId,
            buyGroup.times,
            msg.sender,
            _path,
            _amountIn,
            amountOut
        );
    }

    function leaderClaimPoolCommission(
        uint256 _poolId
    ) external nonReentrant {
        Pool memory item = listPools[_poolId];
        Group memory group = listGroups[leaderInPool[_poolId][msg.sender]];

        address _tokenIn = item.path.length == 2 ? item.path[0] : item.path[1];

        uint256 claimableCommission = getLeaderClaimableCommission(_poolId, msg.sender);
        listGroups[leaderInPool[_poolId][msg.sender]].leaderClaimed = group.totalCommission;
        IERC20(_tokenIn).safeTransfer(msg.sender, claimableCommission);
    }

    function getLeaderClaimableCommission(uint256 _poolId, address _leader) public view returns (uint256 claimableCommission) {
        Group memory group = listGroups[leaderInPool[_poolId][_leader]];
        if (group.account == _leader && group.isEligible) {
            claimableCommission = claimableCommission.add(group.totalCommission).sub(group.leaderClaimed);
        }
    }

    function ownerClaimPool(uint256 _poolId) external nonReentrant {
        Pool memory item = listPools[_poolId];

        require(item.account == msg.sender, "owner");

        address _tokenIn = item.path.length == 2 ? item.path[1] : item.path[2];
        address _tokenOut = item.path.length == 2 ? item.path[0] : item.path[1];

        uint256 refundableAmount;
        uint256 claimableAmount;
        (, , refundableAmount, claimableAmount) = getOwnerClaimPool(_poolId);
        listPools[_poolId].ownerClaimed = item.ownerClaimed.add(claimableAmount);

        if (refundableAmount != 0) {
            listPools[_poolId].totalOut = item.amountIn;
            IERC20(_tokenIn).safeTransfer(msg.sender, refundableAmount);
            IERC20(_tokenOut).safeTransfer(msg.sender, claimableAmount);
        } else {
            IERC20(_tokenOut).safeTransfer(msg.sender, claimableAmount);
        }

        emit OwnerClaimPool(msg.sender, _poolId, refundableAmount, claimableAmount);
    }

    function getOwnerClaimPool(
        uint256 _poolId
    ) public view returns (address, uint256, uint256, uint256) {
        Pool memory item = listPools[_poolId];

        uint256 totalLeaderCommission;
        uint256 refundableAmount;
        uint256 claimableAmount;
        if (item.expired < block.timestamp) {
            for (uint256 i = groupsIndex[_poolId]; i > 0; i--) {
                Group memory group = listGroups[i];
                if (group.isEligible) {
                    totalLeaderCommission = totalLeaderCommission.add(group.totalCommission);
                }
            }
            claimableAmount = item.totalIn.sub(totalLeaderCommission).sub(item.ownerClaimed);
            refundableAmount = item.amountIn.sub(item.totalOut);
            return (item.account, totalLeaderCommission, refundableAmount, claimableAmount);
        }

        totalLeaderCommission = item.amountOut.mul(item.commission).div(BASIS_POINTS_DIVISOR);
        if(item.totalIn >= totalLeaderCommission){
            claimableAmount = item.totalIn.sub(totalLeaderCommission).sub(item.ownerClaimed);
        }

        return (item.account, totalLeaderCommission, refundableAmount, claimableAmount);
    }

    function claimPool(uint256 _poolId) external nonReentrant {
        Pool memory item = listPools[_poolId];
        address _tokenIn = item.path.length == 2 ? item.path[1] : item.path[2];
        address _tokenOut = item.path.length == 2 ? item.path[0] : item.path[1];

        uint256 refundableAmount;
        uint256 claimableAmount;
        for (uint256 i = groupsIndex[_poolId]; i > 0; i--) {
            Group memory group = listGroups[i];
            BuyGroup memory buyGroup = buyGroups[msg.sender][group.groupId];
            if (group.isEligible) {
                claimableAmount = claimableAmount.add(buyGroup.amountOut);
                buyGroups[msg.sender][group.groupId].amountOut = 0;
            } else {
                if(item.amountIn == item.totalOut || item.expired < block.timestamp){
                    refundableAmount = refundableAmount.add(buyGroup.amountIn);
                    buyGroups[msg.sender][group.groupId].amountIn = 0;                
                }
            }
        }

        if(refundableAmount != 0){
            IERC20(_tokenIn).safeTransfer(msg.sender, claimableAmount);
            IERC20(_tokenOut).safeTransfer(msg.sender, refundableAmount);
        } else{
            IERC20(_tokenIn).safeTransfer(msg.sender, claimableAmount);
        }

        emit TraderClaimPool(msg.sender, _poolId, refundableAmount, claimableAmount);
    }

    function getTraderClaimPool(
        uint256 _poolId,
        address _account
    ) public view returns (address, uint256, uint256) {
        Pool memory item = listPools[_poolId];

        uint256 refundableAmount;
        uint256 claimableAmount;
        for (uint256 i = groupsIndex[_poolId]; i > 0; i--) {
            Group memory group = listGroups[i];
            BuyGroup memory buyGroup = buyGroups[_account][group.groupId];
            if (group.isEligible) {
                claimableAmount = claimableAmount.add(buyGroup.amountOut);
            } else {
                refundableAmount = refundableAmount.add(buyGroup.amountIn);
            }
        }
        if(item.amountIn == item.totalOut || item.expired < block.timestamp){
            return (_account, refundableAmount, claimableAmount);
        } else{
            return (_account, 0, claimableAmount);
        }
    }

    function claimGroup(
        uint256 _poolId,
        uint256 _groupId
    ) external nonReentrant {
        Pool memory item = listPools[_poolId];
        Group memory group = listGroups[_groupId];
        BuyGroup memory buyGroup = buyGroups[msg.sender][_groupId];

        require(buyGroup.groupId > 0, "buy");
        require(buyGroup.account == msg.sender, "buyer");
        require(buyGroups[msg.sender][_groupId].amountOut > 0, "amountOut");
        
        address _tokenIn = item.path.length == 2 ? item.path[0] : item.path[1];
        address _tokenOut = item.path.length == 2 ? item.path[1] : item.path[2];

        uint256 claimableAmount;
        if(group.isEligible){
            claimableAmount = buyGroups[msg.sender][_groupId].amountOut;
            buyGroups[msg.sender][_groupId].amountOut = 0;
            IERC20(_tokenIn).safeTransfer(msg.sender, claimableAmount);
        }else{
            claimableAmount = buyGroups[msg.sender][_groupId].amountIn;
            buyGroups[msg.sender][_groupId].amountIn = 0;
            IERC20(_tokenOut).safeTransfer(msg.sender, claimableAmount);
        }

        emit TraderClaimGroup(msg.sender, _poolId, _groupId, group.isEligible, claimableAmount);
    }

    function _wrapAndTransfer(
        uint256 _amountIn,
        address _path0,
        bool _shouldWrap
    ) private {
        if (_shouldWrap) {
            require(_path0 == weth, "weth");
            require(msg.value == _amountIn, "value");
        } else {
            IRouter(router).pluginTransfer(
                _path0,
                msg.sender,
                address(this),
                _amountIn
            );
        }
    }

    function _transferInETH() private {
        if (msg.value != 0) {
            IWETH(weth).deposit{value: msg.value}();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../libraries/access/Ownable.sol";
import "../libraries/math/FullMath.sol";
import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/Address.sol";
import "../libraries/utils/EnumerableSet.sol";

import "./interfaces/ILPTOLock.sol";


contract LPTOLock is Ownable {
    using SafeMath for uint256;
    using Address for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;

    uint256 public fee;
    address payable public feeWallet;

    struct Lock {
        uint256 id;
        address token;
        address owner;
        uint256 amount;
        uint256 lockDate; // insert time
        uint256 tgeDate; // TGE date for vesting locks, unlock date for normal locks
        uint256 tgeBps; // In bips. Is 0 for normal locks percent
        uint256 cycle; // Is 0 for normal locks
        uint256 cycleBps; // In bips. Is 0 for normal locks percent
        uint256 unlockedAmount; // claimed Amount
        string description; // description
    }

    // Information of cumulative token, factory dex
    struct CumulativeLockInfo {
        address token;
        address factory;
        uint256 amount;
    }

    // ID padding from LPTO v1, as there is a lack of a pausing mechanism
    // as of now the lastest id from v1 is about 22K, so this is probably a safe padding value.
    uint256 private constant ID_PADDING = 1000000;

    Lock[] private _locks;
    mapping(address => EnumerableSet.UintSet) private _userNormalLockIds; // user => lockId

    EnumerableSet.AddressSet private _normalLockedTokens; // set of normal tokens address
    mapping(address => CumulativeLockInfo) public cumulativeLockInfo; // address token => info
    mapping(address => EnumerableSet.UintSet) private _tokenToLockIds; // address token -> lock ids

    event LockAdded(
        uint256 indexed id,
        address token,
        address owner,
        uint256 amount,
        uint256 unlockDate
    );
    event LockUpdated(
        uint256 indexed id,
        address token,
        address owner,
        uint256 newAmount,
        uint256 newUnlockDate
    );
    event LockRemoved(
        uint256 indexed id,
        address token,
        address owner,
        uint256 amount,
        uint256 unlockedAt
    );
    event LockVested(
        uint256 indexed id,
        address token,
        address owner,
        uint256 amount,
        uint256 remaining,
        uint256 timestamp
    );
    event LockDescriptionChanged(uint256 lockId);
    event LockOwnerChanged(uint256 lockId, address owner, address newOwner);

    modifier validLock(uint256 lockId) {
        _getActualIndex(lockId);
        _;
    }

    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    function setFeeWallet(address payable _feewallet) public onlyOwner {
        feeWallet = _feewallet;
    }

    function lock(
        address owner,
        address token,
        uint256 amount,
        uint256 unlockDate,
        string memory description
    )  external payable returns (uint256 id) {
        require(unlockDate > block.timestamp, "Unlock date should be in the future");
        require(amount > 0, "Amount should be greater than 0");
        if (!isContract(msg.sender)){
            require(msg.value >= fee, "Not enough fee");
            payable(feeWallet).transfer(fee);
        }
        id = _createLock(
            owner,
            token,
            amount,
            unlockDate,
            0,
            0,
            0,
            description
        );
        _safeTransferFromEnsureExactAmount(
            token,
            msg.sender,
            address(this),
            amount
        );
        emit LockAdded(id, token, owner, amount, unlockDate);
        return id;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function vestingLock(
        address owner,
        address token,
        uint256 amount,
        uint256 tgeDate,
        uint256 tgeBps,
        uint256 cycle,
        uint256 cycleBps,
        string memory description
    ) external payable returns (uint256 id) {
        require(tgeDate > block.timestamp, "TGE date should be in the future");
        require(cycle > 0, "Invalid cycle");
        require(tgeBps > 0 && tgeBps < 10_000, "Invalid bips for TGE");
        require(cycleBps > 0 && cycleBps < 10_000, "Invalid bips for cycle");
        require(
            tgeBps + cycleBps <= 10_000,
            "Sum of TGE bps and cycle should be less than 10000"
        );
        require(amount > 0, "Amount should be greater than 0");
        if (!isContract(msg.sender)){
            require(msg.value >= fee, "Not enough fee");
            payable(feeWallet).transfer(fee);
        }
        id = _createLock(
            owner,
            token,
            amount,
            tgeDate,
            tgeBps,
            cycle,
            cycleBps,
            description
        );
        _safeTransferFromEnsureExactAmount(
            token,
            msg.sender,
            address(this),
            amount
        );
        emit LockAdded(id, token, owner, amount, tgeDate);
        return id;
    }

    function multipleVestingLock(
        address[] calldata owners,
        uint256[] calldata amounts,
        address token,
        uint256 tgeDate,
        uint256 tgeBps,
        uint256 cycle,
        uint256 cycleBps,
        string memory description
    ) external payable returns (uint256[] memory) {
        require(owners.length == amounts.length, "Length mismatched");
        require(tgeDate > block.timestamp, "TGE date should be in the future");
        require(cycle > 0, "Invalid cycle");
        require(tgeBps > 0 && tgeBps < 10_000, "Invalid bips for TGE");
        require(cycleBps > 0 && cycleBps < 10_000, "Invalid bips for cycle");
        require(tgeBps.add(cycleBps) <= 10_000, "Sum of TGE bps and cycle should be less than 10000");
        if (!isContract(msg.sender)){
            require(msg.value >= fee, "Not enough fee");
            payable(feeWallet).transfer(fee);
        }

        return _multipleVestingLock(
                owners,
                amounts,
                token,
                [tgeDate, tgeBps, cycle, cycleBps],
                description
            );
    }

    function _multipleVestingLock(
        address[] calldata owners,
        uint256[] calldata amounts,
        address token,
        uint256[4] memory vestingSettings, // avoid stack too deep
        string memory description
    ) internal returns (uint256[] memory) {
        uint256 sumAmount = _sumAmount(amounts);
        uint256 count = owners.length;
        uint256[] memory ids = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            ids[i] = _createLock(
                owners[i],
                token,
                amounts[i],
                vestingSettings[0], // TGE date
                vestingSettings[1], // TGE bps
                vestingSettings[2], // cycle
                vestingSettings[3], // cycle bps
                description
            );
            emit LockAdded(
                ids[i],
                token,
                owners[i],
                amounts[i],
                vestingSettings[0] // TGE date
            );
        }
        _safeTransferFromEnsureExactAmount(
            token,
            msg.sender,
            address(this),
            sumAmount
        );
        return ids;
    }

    function _sumAmount(uint256[] calldata amounts)
        internal
        pure
        returns (uint256)
    {
        uint256 sum = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] == 0) {
                revert("Amount cant be zero");
            }
            sum = sum.add(amounts[i]);
        }
        return sum;
    }

    function _createLock(
        address owner,
        address token,
        uint256 amount,
        uint256 tgeDate,
        uint256 tgeBps,
        uint256 cycle,
        uint256 cycleBps,
        string memory description
    ) internal returns (uint256 id) {
        id = _lockNormalToken(
                owner,
                token,
                amount,
                tgeDate,
                tgeBps,
                cycle,
                cycleBps,
                description
            );
    }

    function _lockNormalToken(
        address owner,
        address token,
        uint256 amount,
        uint256 tgeDate,
        uint256 tgeBps,
        uint256 cycle,
        uint256 cycleBps,
        string memory description
    ) private returns (uint256 id) {
        id = _registerLock(
            owner,
            token,
            amount,
            tgeDate,
            tgeBps,
            cycle,
            cycleBps,
            description
        );
        _userNormalLockIds[owner].add(id);
        _normalLockedTokens.add(token);

        CumulativeLockInfo storage tokenInfo = cumulativeLockInfo[token];
        if (tokenInfo.token == address(0)) {
            tokenInfo.token = token;
            tokenInfo.factory = address(0);
        }
        tokenInfo.amount = tokenInfo.amount.add(amount);

        _tokenToLockIds[token].add(id);
    }

    function _registerLock(
        address owner,
        address token,
        uint256 amount,
        uint256 tgeDate,
        uint256 tgeBps,
        uint256 cycle,
        uint256 cycleBps,
        string memory description
    ) private returns (uint256 id) {
        id = _locks.length.add(ID_PADDING);
        Lock memory newLock = Lock({
            id: id,
            token: token,
            owner: owner,
            amount: amount,
            lockDate: block.timestamp,
            tgeDate: tgeDate,
            tgeBps: tgeBps,
            cycle: cycle,
            cycleBps: cycleBps,
            unlockedAmount: 0,
            description: description
        });
        _locks.push(newLock);
    }

    function unlock(uint256 lockId) external validLock(lockId) {
        Lock storage userLock = _locks[_getActualIndex(lockId)];
        require(
            userLock.owner == msg.sender,
            "You are not the owner of this lock"
        );

        if (userLock.tgeBps > 0) {
            _vestingUnlock(userLock);
        } else {
            _normalUnlock(userLock);
        }
    }

    function _normalUnlock(Lock storage userLock) internal {
        require(
            block.timestamp >= userLock.tgeDate,
            "It is not time to unlock"
        );
        require(userLock.unlockedAmount == 0, "Nothing to unlock");

        CumulativeLockInfo storage tokenInfo = cumulativeLockInfo[userLock.token];

        _userNormalLockIds[msg.sender].remove(userLock.id);
        

        uint256 unlockAmount = userLock.amount;

        if (tokenInfo.amount <= unlockAmount) {
            tokenInfo.amount = 0;
        } else {
            tokenInfo.amount = tokenInfo.amount.sub(unlockAmount);
        }

        if (tokenInfo.amount == 0) {
            _normalLockedTokens.remove(userLock.token);
        }
        userLock.unlockedAmount = unlockAmount;

        _tokenToLockIds[userLock.token].remove(userLock.id);

        IERC20(userLock.token).safeTransfer(msg.sender, unlockAmount);

        emit LockRemoved(
            userLock.id,
            userLock.token,
            msg.sender,
            unlockAmount,
            block.timestamp
        );
    }

    function _vestingUnlock(Lock storage userLock) internal {
        uint256 withdrawable = _withdrawableTokens(userLock);
        uint256 newTotalUnlockAmount = userLock.unlockedAmount.add(withdrawable);
        require(withdrawable > 0 && newTotalUnlockAmount <= userLock.amount, "Nothing to unlock");

        CumulativeLockInfo storage tokenInfo = cumulativeLockInfo[userLock.token];

        if (newTotalUnlockAmount == userLock.amount) {

            _userNormalLockIds[msg.sender].remove(userLock.id);
            
            _tokenToLockIds[userLock.token].remove(userLock.id);
            emit LockRemoved(
                userLock.id,
                userLock.token,
                msg.sender,
                newTotalUnlockAmount,
                block.timestamp
            );
        }

        if (tokenInfo.amount <= withdrawable) {
            tokenInfo.amount = 0;
        } else {
            tokenInfo.amount = tokenInfo.amount.sub(withdrawable);
        }

        if (tokenInfo.amount == 0) {
            _normalLockedTokens.remove(userLock.token);
        }
        userLock.unlockedAmount = newTotalUnlockAmount;

        IERC20(userLock.token).safeTransfer(userLock.owner, withdrawable);

        emit LockVested(
            userLock.id,
            userLock.token,
            msg.sender,
            withdrawable,
            userLock.amount.sub(userLock.unlockedAmount),
            block.timestamp
        );
    }

    function withdrawableTokens(uint256 lockId)
        external
        view
        returns (uint256)
    {
        Lock memory userLock = getLockById(lockId);
        return _withdrawableTokens(userLock);
    }

    function _withdrawableTokens(Lock memory userLock)internal view returns (uint256){
        if (userLock.amount == 0) return 0;
        if (userLock.unlockedAmount >= userLock.amount) return 0;
        if (block.timestamp < userLock.tgeDate) return 0;
        if (userLock.cycle == 0) return 0;

        uint256 tgeReleaseAmount = FullMath.mulDiv(userLock.amount, userLock.tgeBps, 10_000);
        uint256 cycleReleaseAmount = FullMath.mulDiv(userLock.amount, userLock.cycleBps, 10_000);
        uint256 currentTotal = 0;
        if (block.timestamp >= userLock.tgeDate) {
            currentTotal = (((block.timestamp.sub(userLock.tgeDate)).mul(cycleReleaseAmount).div(userLock.cycle))).add(tgeReleaseAmount); // Truncation is expected here
        }
        uint256 withdrawable = 0;
        if (currentTotal > userLock.amount) {
            withdrawable = userLock.amount.sub(userLock.unlockedAmount);
        } else {
            withdrawable = currentTotal.sub(userLock.unlockedAmount);
        }
        return withdrawable;
    }

    function editLock(
        uint256 lockId,
        uint256 newAmount,
        uint256 newUnlockDate
    ) external validLock(lockId) {
        Lock storage userLock = _locks[_getActualIndex(lockId)];
        require(userLock.owner == msg.sender,"You are not the owner of this lock");
        require(userLock.unlockedAmount == 0, "Lock was unlocked");

        if (newUnlockDate > 0) {
            require(newUnlockDate >= userLock.tgeDate && newUnlockDate > block.timestamp,"New unlock time should not be before old unlock time or current time");
            userLock.tgeDate = newUnlockDate;
        }

        if (newAmount > 0) {
            require(newAmount >= userLock.amount, "New amount should not be less than current amount");

            uint256 diff = newAmount.sub(userLock.amount);

            if (diff > 0) {
                userLock.amount = newAmount;
                CumulativeLockInfo storage tokenInfo = cumulativeLockInfo[userLock.token];
                tokenInfo.amount = tokenInfo.amount.add(diff);
                _safeTransferFromEnsureExactAmount(
                    userLock.token,
                    msg.sender,
                    address(this),
                    diff
                );
            }
        }

        emit LockUpdated(
            userLock.id,
            userLock.token,
            userLock.owner,
            userLock.amount,
            userLock.tgeDate
        );
    }

    function editLockDescription(uint256 lockId, string memory description) external  validLock(lockId) {
        Lock storage userLock = _locks[_getActualIndex(lockId)];
        require(userLock.owner == msg.sender, "You are not the owner of this lock");
        userLock.description = description;
        emit LockDescriptionChanged(lockId);
    }

    function transferLockOwnership(uint256 lockId, address newOwner) public validLock(lockId){
        Lock storage userLock = _locks[_getActualIndex(lockId)];
        address currentOwner = userLock.owner;
        require(currentOwner == msg.sender, "You are not the owner of this lock");

        userLock.owner = newOwner;

        _userNormalLockIds[currentOwner].remove(lockId);
        _userNormalLockIds[newOwner].add(lockId);

        emit LockOwnerChanged(lockId, currentOwner, newOwner);
    }

    function renounceLockOwnership(uint256 lockId) external {
        transferLockOwnership(lockId, address(0));
    }

    function _safeTransferFromEnsureExactAmount(
        address token,
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        uint256 oldRecipientBalance = IERC20(token).balanceOf(recipient);
        IERC20(token).safeTransferFrom(sender, recipient, amount);
        uint256 newRecipientBalance = IERC20(token).balanceOf(recipient);
        require(newRecipientBalance.sub(oldRecipientBalance) == amount, "Not enough token was transfered");
    }

    function getTotalLockCount() external view returns (uint256) {
        // Returns total lock count, regardless of whether it has been unlocked or not
        return _locks.length;
    }

    function getLockAt(uint256 index) external view returns (Lock memory) {
        return _locks[index];
    }

    function getLockById(uint256 lockId) public view returns (Lock memory) {
        return _locks[_getActualIndex(lockId)];
    }

    function allNormalTokenLockedCount() public view returns (uint256) {
        return _normalLockedTokens.length();
    }

    function getCumulativeNormalTokenLockInfoAt(uint256 index)
        external
        view
        returns (CumulativeLockInfo memory)
    {
        return cumulativeLockInfo[_normalLockedTokens.at(index)];
    }

    function getCumulativeNormalTokenLockInfo(uint256 start, uint256 end)
        external
        view
        returns (CumulativeLockInfo[] memory)
    {
        if (end >= _normalLockedTokens.length()) {
            end = _normalLockedTokens.length() - 1;
        }
        uint256 length = end - start + 1;
        CumulativeLockInfo[] memory lockInfo = new CumulativeLockInfo[](length);
        uint256 currentIndex = 0;
        for (uint256 i = start; i <= end; i++) {
            lockInfo[currentIndex] = cumulativeLockInfo[
                _normalLockedTokens.at(i)
            ];
            currentIndex++;
        }
        return lockInfo;
    }

    function totalTokenLockedCount() external view returns (uint256) {
        return allNormalTokenLockedCount();
    }

    function normalLockCountForUser(address user)
        public
        view
        returns (uint256)
    {
        return _userNormalLockIds[user].length();
    }

    function normalLocksForUser(address user)
        external
        view
        returns (Lock[] memory)
    {
        uint256 length = _userNormalLockIds[user].length();
        Lock[] memory userLocks = new Lock[](length);

        for (uint256 i = 0; i < length; i++) {
            userLocks[i] = getLockById(_userNormalLockIds[user].at(i));
        }
        return userLocks;
    }

    function normalLockForUserAtIndex(address user, uint256 index)
        external
        view
        returns (Lock memory)
    {
        require(normalLockCountForUser(user) > index, "Invalid index");
        return getLockById(_userNormalLockIds[user].at(index));
    }

    function totalLockCountForUser(address user)
        external
        view
        returns (uint256)
    {
        return normalLockCountForUser(user);
    }

    function totalLockCountForToken(address token)
        external
        view
        returns (uint256)
    {
        return _tokenToLockIds[token].length();
    }

    function getLocksForToken(
        address token,
        uint256 start,
        uint256 end
    ) public view returns (Lock[] memory) {
        if (end >= _tokenToLockIds[token].length()) {
            end = _tokenToLockIds[token].length().sub(1);
        }
        uint256 length = end.sub(start).add(1);
        Lock[] memory locks = new Lock[](length);
        uint256 currentIndex = 0;
        for (uint256 i = start; i <= end; i++) {
            locks[currentIndex] = getLockById(_tokenToLockIds[token].at(i));
            currentIndex = currentIndex.add(1);
        }
        return locks;
    }

    function _getActualIndex(uint256 lockId) internal view returns (uint256) {
        if (lockId < ID_PADDING) {
            revert("Invalid lock id");
        }
        uint256 actualIndex = lockId.sub(ID_PADDING);
        require(actualIndex < _locks.length, "Invalid lock id");
        return actualIndex;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../tokens/interfaces/IWETH.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/Address.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IRouter.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IOrderBook.sol";

contract OrderBook is ReentrancyGuard, IOrderBook {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    uint256 public constant PRICE_PRECISION = 1e30;
    uint256 public constant BXD_PRECISION = 1e18;

    struct IncreaseOrder {
        address account;
        address purchaseToken;
        uint256 purchaseTokenAmount;
        address collateralToken;
        address indexToken;
        uint256 sizeDelta;
        bool isLong;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
        uint256 executionFee;
    }
    struct DecreaseOrder {
        address account;
        address collateralToken;
        uint256 collateralDelta;
        address indexToken;
        uint256 sizeDelta;
        bool isLong;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
        uint256 executionFee;
    }
    struct SwapOrder {
        address account;
        address[] path;
        uint256 amountIn;
        uint256 minOut;
        uint256 triggerRatio;
        bool triggerAboveThreshold;
        bool shouldUnwrap;
        uint256 executionFee;
    }

    mapping (address => mapping(uint256 => IncreaseOrder)) public increaseOrders;
    mapping (address => uint256) public increaseOrdersIndex;
    mapping (address => mapping(uint256 => DecreaseOrder)) public decreaseOrders;
    mapping (address => uint256) public decreaseOrdersIndex;
    mapping (address => mapping(uint256 => SwapOrder)) public swapOrders;
    mapping (address => uint256) public swapOrdersIndex;

    address public gov;
    address public weth;
    address public bxd;
    address public router;
    address public vault;
    uint256 public minExecutionFee;
    uint256 public minPurchaseTokenAmountUsd;
    bool public isInitialized = false;

    event CreateIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address purchaseToken,
        uint256 purchaseTokenAmount,
        address collateralToken,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event CancelIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address purchaseToken,
        uint256 purchaseTokenAmount,
        address collateralToken,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event ExecuteIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address purchaseToken,
        uint256 purchaseTokenAmount,
        address collateralToken,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        uint256 executionPrice
    );
    event UpdateIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        address indexToken,
        bool isLong,
        uint256 sizeDelta,
        uint256 triggerPrice,
        bool triggerAboveThreshold
    );
    event CreateDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event CancelDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event ExecuteDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        uint256 executionPrice
    );
    event UpdateDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold
    );
    event CreateSwapOrder(
        address indexed account,
        uint256 orderIndex,
        address[] path,
        uint256 amountIn,
        uint256 minOut,
        uint256 triggerRatio,
        bool triggerAboveThreshold,
        bool shouldUnwrap,
        uint256 executionFee
    );
    event CancelSwapOrder(
        address indexed account,
        uint256 orderIndex,
        address[] path,
        uint256 amountIn,
        uint256 minOut,
        uint256 triggerRatio,
        bool triggerAboveThreshold,
        bool shouldUnwrap,
        uint256 executionFee
    );
    event UpdateSwapOrder(
        address indexed account,
        uint256 ordexIndex,
        address[] path,
        uint256 amountIn,
        uint256 minOut,
        uint256 triggerRatio,
        bool triggerAboveThreshold,
        bool shouldUnwrap,
        uint256 executionFee
    );
    event ExecuteSwapOrder(
        address indexed account,
        uint256 orderIndex,
        address[] path,
        uint256 amountIn,
        uint256 minOut,
        uint256 amountOut,
        uint256 triggerRatio,
        bool triggerAboveThreshold,
        bool shouldUnwrap,
        uint256 executionFee
    );

    event Initialize(
        address router,
        address vault,
        address weth,
        address bxd,
        uint256 minExecutionFee,
        uint256 minPurchaseTokenAmountUsd
    );
    event UpdateMinExecutionFee(uint256 minExecutionFee);
    event UpdateMinPurchaseTokenAmountUsd(uint256 minPurchaseTokenAmountUsd);
    event UpdateGov(address gov);

    modifier onlyGov() {
        require(msg.sender == gov, "OrderBook: forbidden");
        _;
    }

    constructor() public {
        gov = msg.sender;
    }

    function initialize(
        address _router,
        address _vault,
        address _weth,
        address _bxd,
        uint256 _minExecutionFee,
        uint256 _minPurchaseTokenAmountUsd
    ) external onlyGov {
        require(!isInitialized, "OrderBook: already initialized");
        isInitialized = true;

        router = _router;
        vault = _vault;
        weth = _weth;
        bxd = _bxd;
        minExecutionFee = _minExecutionFee;
        minPurchaseTokenAmountUsd = _minPurchaseTokenAmountUsd;

        emit Initialize(_router, _vault, _weth, _bxd, _minExecutionFee, _minPurchaseTokenAmountUsd);
    }

    receive() external payable {
        require(msg.sender == weth, "OrderBook: invalid sender");
    }

    function setMinExecutionFee(uint256 _minExecutionFee) external onlyGov {
        minExecutionFee = _minExecutionFee;

        emit UpdateMinExecutionFee(_minExecutionFee);
    }

    function setMinPurchaseTokenAmountUsd(uint256 _minPurchaseTokenAmountUsd) external onlyGov {
        minPurchaseTokenAmountUsd = _minPurchaseTokenAmountUsd;

        emit UpdateMinPurchaseTokenAmountUsd(_minPurchaseTokenAmountUsd);
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;

        emit UpdateGov(_gov);
    }

    function getSwapOrder(address _account, uint256 _orderIndex) override public view returns (
        address path0,
        address path1,
        address path2,
        uint256 amountIn,
        uint256 minOut,
        uint256 triggerRatio,
        bool triggerAboveThreshold,
        bool shouldUnwrap,
        uint256 executionFee
    ) {
        SwapOrder memory order = swapOrders[_account][_orderIndex];
        return (
            order.path.length > 0 ? order.path[0] : address(0),
            order.path.length > 1 ? order.path[1] : address(0),
            order.path.length > 2 ? order.path[2] : address(0),
            order.amountIn,
            order.minOut,
            order.triggerRatio,
            order.triggerAboveThreshold,
            order.shouldUnwrap,
            order.executionFee
        );
    }

    function createSwapOrder(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _triggerRatio, // tokenB / tokenA
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap,
        bool _shouldUnwrap
    ) external payable nonReentrant {
        require(_path.length == 2 || _path.length == 3, "OrderBook: invalid _path.length");
        require(_path[0] != _path[_path.length - 1], "OrderBook: invalid _path");
        require(_amountIn > 0, "OrderBook: invalid _amountIn");
        require(_executionFee >= minExecutionFee, "OrderBook: insufficient execution fee");

        // always need this call because of mandatory executionFee user has to transfer in ETH
        _transferInETH();

        if (_shouldWrap) {
            require(_path[0] == weth, "OrderBook: only weth could be wrapped");
            require(msg.value == _executionFee.add(_amountIn), "OrderBook: incorrect value transferred");
        } else {
            require(msg.value == _executionFee, "OrderBook: incorrect execution fee transferred");
            IRouter(router).pluginTransfer(_path[0], msg.sender, address(this), _amountIn);
        }

        _createSwapOrder(msg.sender, _path, _amountIn, _minOut, _triggerRatio, _triggerAboveThreshold, _shouldUnwrap, _executionFee);
    }

    function _createSwapOrder(
        address _account,
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _triggerRatio,
        bool _triggerAboveThreshold,
        bool _shouldUnwrap,
        uint256 _executionFee
    ) private {
        uint256 _orderIndex = swapOrdersIndex[_account];
        SwapOrder memory order = SwapOrder(
            _account,
            _path,
            _amountIn,
            _minOut,
            _triggerRatio,
            _triggerAboveThreshold,
            _shouldUnwrap,
            _executionFee
        );
        swapOrdersIndex[_account] = _orderIndex.add(1);
        swapOrders[_account][_orderIndex] = order;

        emit CreateSwapOrder(
            _account,
            _orderIndex,
            _path,
            _amountIn,
            _minOut,
            _triggerRatio,
            _triggerAboveThreshold,
            _shouldUnwrap,
            _executionFee
        );
    }

    function cancelMultiple(
        uint256[] memory _swapOrderIndexes,
        uint256[] memory _increaseOrderIndexes,
        uint256[] memory _decreaseOrderIndexes
    ) external {
        for (uint256 i = 0; i < _swapOrderIndexes.length; i++) {
            cancelSwapOrder(_swapOrderIndexes[i]);
        }
        for (uint256 i = 0; i < _increaseOrderIndexes.length; i++) {
            cancelIncreaseOrder(_increaseOrderIndexes[i]);
        }
        for (uint256 i = 0; i < _decreaseOrderIndexes.length; i++) {
            cancelDecreaseOrder(_decreaseOrderIndexes[i]);
        }
    }

    function cancelSwapOrder(uint256 _orderIndex) public nonReentrant {
        SwapOrder memory order = swapOrders[msg.sender][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");

        delete swapOrders[msg.sender][_orderIndex];

        if (order.path[0] == weth) {
            _transferOutETH(order.executionFee.add(order.amountIn), msg.sender);
        } else {
            IERC20(order.path[0]).safeTransfer(msg.sender, order.amountIn);
            _transferOutETH(order.executionFee, msg.sender);
        }

        emit CancelSwapOrder(
            msg.sender,
            _orderIndex,
            order.path,
            order.amountIn,
            order.minOut,
            order.triggerRatio,
            order.triggerAboveThreshold,
            order.shouldUnwrap,
            order.executionFee
        );
    }

    function getBxdMinPrice(address _otherToken) public view returns (uint256) {
        // BXD_PRECISION is the same as 1 BXD
        uint256 redemptionAmount = IVault(vault).getRedemptionAmount(_otherToken, BXD_PRECISION);
        uint256 otherTokenPrice = IVault(vault).getMinPrice(_otherToken);

        uint256 otherTokenDecimals = IVault(vault).tokenDecimals(_otherToken);
        return redemptionAmount.mul(otherTokenPrice).div(10 ** otherTokenDecimals);
    }

    function validateSwapOrderPriceWithTriggerAboveThreshold(
        address[] memory _path,
        uint256 _triggerRatio
    ) public view returns (bool) {
        require(_path.length == 2 || _path.length == 3, "OrderBook: invalid _path.length");

        // limit orders don't need this validation because minOut is enough
        // so this validation handles scenarios for stop orders only
        // when a user wants to swap when a price of tokenB increases relative to tokenA
        address tokenA = _path[0];
        address tokenB = _path[_path.length - 1];
        uint256 tokenAPrice;
        uint256 tokenBPrice;

        // 1. BXD doesn't have a price feed so we need to calculate it based on redepmtion amount of a specific token
        // That's why BXD price in USD can vary depending on the redepmtion token
        // 2. In complex scenarios with path=[BXD, BNB, BTC] we need to know how much BNB we'll get for provided BXD
        // to know how much BTC will be received
        // That's why in such scenario BNB should be used to determine price of BXD
        if (tokenA == bxd) {
            // with both _path.length == 2 or 3 we need bxd price against _path[1]
            tokenAPrice = getBxdMinPrice(_path[1]);
        } else {
            tokenAPrice = IVault(vault).getMinPrice(tokenA);
        }

        if (tokenB == bxd) {
            tokenBPrice = PRICE_PRECISION;
        } else {
            tokenBPrice = IVault(vault).getMaxPrice(tokenB);
        }

        uint256 currentRatio = tokenBPrice.mul(PRICE_PRECISION).div(tokenAPrice);

        bool isValid = currentRatio > _triggerRatio;
        return isValid;
    }

    function updateSwapOrder(uint256 _orderIndex, uint256 _minOut, uint256 _triggerRatio, bool _triggerAboveThreshold) external nonReentrant {
        SwapOrder storage order = swapOrders[msg.sender][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");

        order.minOut = _minOut;
        order.triggerRatio = _triggerRatio;
        order.triggerAboveThreshold = _triggerAboveThreshold;

        emit UpdateSwapOrder(
            msg.sender,
            _orderIndex,
            order.path,
            order.amountIn,
            _minOut,
            _triggerRatio,
            _triggerAboveThreshold,
            order.shouldUnwrap,
            order.executionFee
        );
    }

    function executeSwapOrder(address _account, uint256 _orderIndex, address payable _feeReceiver) override external nonReentrant {
        SwapOrder memory order = swapOrders[_account][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");

        if (order.triggerAboveThreshold) {
            // gas optimisation
            // order.minAmount should prevent wrong price execution in case of simple limit order
            require(
                validateSwapOrderPriceWithTriggerAboveThreshold(order.path, order.triggerRatio),
                "OrderBook: invalid price for execution"
            );
        }

        delete swapOrders[_account][_orderIndex];

        IERC20(order.path[0]).safeTransfer(vault, order.amountIn);

        uint256 _amountOut;
        if (order.path[order.path.length - 1] == weth && order.shouldUnwrap) {
            _amountOut = _swap(order.path, order.minOut, address(this));
            _transferOutETH(_amountOut, payable(order.account));
        } else {
            _amountOut = _swap(order.path, order.minOut, order.account);
        }

        // pay executor
        _transferOutETH(order.executionFee, _feeReceiver);

        emit ExecuteSwapOrder(
            _account,
            _orderIndex,
            order.path,
            order.amountIn,
            order.minOut,
            _amountOut,
            order.triggerRatio,
            order.triggerAboveThreshold,
            order.shouldUnwrap,
            order.executionFee
        );
    }

    function validatePositionOrderPrice(
        bool _triggerAboveThreshold,
        uint256 _triggerPrice,
        address _indexToken,
        bool _maximizePrice,
        bool _raise
    ) public view returns (uint256, bool) {
        uint256 currentPrice = _maximizePrice
            ? IVault(vault).getMaxPrice(_indexToken) : IVault(vault).getMinPrice(_indexToken);
        bool isPriceValid = _triggerAboveThreshold ? currentPrice > _triggerPrice : currentPrice < _triggerPrice;
        if (_raise) {
            require(isPriceValid, "OrderBook: invalid price for execution");
        }
        return (currentPrice, isPriceValid);
    }

    function getDecreaseOrder(address _account, uint256 _orderIndex) override public view returns (
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    ) {
        DecreaseOrder memory order = decreaseOrders[_account][_orderIndex];
        return (
            order.collateralToken,
            order.collateralDelta,
            order.indexToken,
            order.sizeDelta,
            order.isLong,
            order.triggerPrice,
            order.triggerAboveThreshold,
            order.executionFee
        );
    }

    function getIncreaseOrder(address _account, uint256 _orderIndex) override public view returns (
        address purchaseToken,
        uint256 purchaseTokenAmount,
        address collateralToken,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    ) {
        IncreaseOrder memory order = increaseOrders[_account][_orderIndex];
        return (
            order.purchaseToken,
            order.purchaseTokenAmount,
            order.collateralToken,
            order.indexToken,
            order.sizeDelta,
            order.isLong,
            order.triggerPrice,
            order.triggerAboveThreshold,
            order.executionFee
        );
    }

    function createIncreaseOrder(
        address[] memory _path,
        uint256 _amountIn,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        address _collateralToken,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap
    ) external payable nonReentrant {
        // always need this call because of mandatory executionFee user has to transfer in ETH
        _transferInETH();

        require(_executionFee >= minExecutionFee, "OrderBook: insufficient execution fee");
        if (_shouldWrap) {
            require(_path[0] == weth, "OrderBook: only weth could be wrapped");
            require(msg.value == _executionFee.add(_amountIn), "OrderBook: incorrect value transferred");
        } else {
            require(msg.value == _executionFee, "OrderBook: incorrect execution fee transferred");
            IRouter(router).pluginTransfer(_path[0], msg.sender, address(this), _amountIn);
        }

        address _purchaseToken = _path[_path.length - 1];
        uint256 _purchaseTokenAmount;
        if (_path.length > 1) {
            require(_path[0] != _purchaseToken, "OrderBook: invalid _path");
            IERC20(_path[0]).safeTransfer(vault, _amountIn);
            _purchaseTokenAmount = _swap(_path, _minOut, address(this));
        } else {
            _purchaseTokenAmount = _amountIn;
        }

        {
            uint256 _purchaseTokenAmountUsd = IVault(vault).tokenToUsdMin(_purchaseToken, _purchaseTokenAmount);
            require(_purchaseTokenAmountUsd >= minPurchaseTokenAmountUsd, "OrderBook: insufficient collateral");
        }

        _createIncreaseOrder(
            msg.sender,
            _purchaseToken,
            _purchaseTokenAmount,
            _collateralToken,
            _indexToken,
            _sizeDelta,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold,
            _executionFee
        );
    }

    function _createIncreaseOrder(
        address _account,
        address _purchaseToken,
        uint256 _purchaseTokenAmount,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee
    ) private {
        uint256 _orderIndex = increaseOrdersIndex[msg.sender];
        IncreaseOrder memory order = IncreaseOrder(
            _account,
            _purchaseToken,
            _purchaseTokenAmount,
            _collateralToken,
            _indexToken,
            _sizeDelta,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold,
            _executionFee
        );
        increaseOrdersIndex[_account] = _orderIndex.add(1);
        increaseOrders[_account][_orderIndex] = order;

        emit CreateIncreaseOrder(
            _account,
            _orderIndex,
            _purchaseToken,
            _purchaseTokenAmount,
            _collateralToken,
            _indexToken,
            _sizeDelta,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold,
            _executionFee
        );
    }

    function updateIncreaseOrder(uint256 _orderIndex, uint256 _sizeDelta, uint256 _triggerPrice, bool _triggerAboveThreshold) external nonReentrant {
        IncreaseOrder storage order = increaseOrders[msg.sender][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");

        order.triggerPrice = _triggerPrice;
        order.triggerAboveThreshold = _triggerAboveThreshold;
        order.sizeDelta = _sizeDelta;

        emit UpdateIncreaseOrder(
            msg.sender,
            _orderIndex,
            order.collateralToken,
            order.indexToken,
            order.isLong,
            _sizeDelta,
            _triggerPrice,
            _triggerAboveThreshold
        );
    }

    function cancelIncreaseOrder(uint256 _orderIndex) public nonReentrant {
        IncreaseOrder memory order = increaseOrders[msg.sender][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");

        delete increaseOrders[msg.sender][_orderIndex];

        if (order.purchaseToken == weth) {
            _transferOutETH(order.executionFee.add(order.purchaseTokenAmount), msg.sender);
        } else {
            IERC20(order.purchaseToken).safeTransfer(msg.sender, order.purchaseTokenAmount);
            _transferOutETH(order.executionFee, msg.sender);
        }

        emit CancelIncreaseOrder(
            order.account,
            _orderIndex,
            order.purchaseToken,
            order.purchaseTokenAmount,
            order.collateralToken,
            order.indexToken,
            order.sizeDelta,
            order.isLong,
            order.triggerPrice,
            order.triggerAboveThreshold,
            order.executionFee
        );
    }

    function executeIncreaseOrder(address _address, uint256 _orderIndex, address payable _feeReceiver) override external nonReentrant {
        IncreaseOrder memory order = increaseOrders[_address][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");

        // increase long should use max price
        // increase short should use min price
        (uint256 currentPrice, ) = validatePositionOrderPrice(
            order.triggerAboveThreshold,
            order.triggerPrice,
            order.indexToken,
            order.isLong,
            true
        );

        delete increaseOrders[_address][_orderIndex];

        IERC20(order.purchaseToken).safeTransfer(vault, order.purchaseTokenAmount);

        if (order.purchaseToken != order.collateralToken) {
            address[] memory path = new address[](2);
            path[0] = order.purchaseToken;
            path[1] = order.collateralToken;

            uint256 amountOut = _swap(path, 0, address(this));
            IERC20(order.collateralToken).safeTransfer(vault, amountOut);
        }

        IRouter(router).pluginIncreasePosition(order.account, order.collateralToken, order.indexToken, order.sizeDelta, order.isLong);

        // pay executor
        _transferOutETH(order.executionFee, _feeReceiver);

        emit ExecuteIncreaseOrder(
            order.account,
            _orderIndex,
            order.purchaseToken,
            order.purchaseTokenAmount,
            order.collateralToken,
            order.indexToken,
            order.sizeDelta,
            order.isLong,
            order.triggerPrice,
            order.triggerAboveThreshold,
            order.executionFee,
            currentPrice
        );
    }

    function createDecreaseOrder(
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external payable nonReentrant {
        _transferInETH();

        require(msg.value > minExecutionFee, "OrderBook: insufficient execution fee");

        _createDecreaseOrder(
            msg.sender,
            _collateralToken,
            _collateralDelta,
            _indexToken,
            _sizeDelta,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold
        );
    }

    function _createDecreaseOrder(
        address _account,
        address _collateralToken,
        uint256 _collateralDelta,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) private {
        uint256 _orderIndex = decreaseOrdersIndex[_account];
        DecreaseOrder memory order = DecreaseOrder(
            _account,
            _collateralToken,
            _collateralDelta,
            _indexToken,
            _sizeDelta,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold,
            msg.value
        );
        decreaseOrdersIndex[_account] = _orderIndex.add(1);
        decreaseOrders[_account][_orderIndex] = order;

        emit CreateDecreaseOrder(
            _account,
            _orderIndex,
            _collateralToken,
            _collateralDelta,
            _indexToken,
            _sizeDelta,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold,
            msg.value
        );
    }

    function executeDecreaseOrder(address _address, uint256 _orderIndex, address payable _feeReceiver) override external nonReentrant {
        DecreaseOrder memory order = decreaseOrders[_address][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");

        // decrease long should use min price
        // decrease short should use max price
        (uint256 currentPrice, ) = validatePositionOrderPrice(
            order.triggerAboveThreshold,
            order.triggerPrice,
            order.indexToken,
            !order.isLong,
            true
        );

        delete decreaseOrders[_address][_orderIndex];

        uint256 amountOut = IRouter(router).pluginDecreasePosition(
            order.account,
            order.collateralToken,
            order.indexToken,
            order.collateralDelta,
            order.sizeDelta,
            order.isLong,
            address(this)
        );

        // transfer released collateral to user
        if (order.collateralToken == weth) {
            _transferOutETH(amountOut, payable(order.account));
        } else {
            IERC20(order.collateralToken).safeTransfer(order.account, amountOut);
        }

        // pay executor
        _transferOutETH(order.executionFee, _feeReceiver);

        emit ExecuteDecreaseOrder(
            order.account,
            _orderIndex,
            order.collateralToken,
            order.collateralDelta,
            order.indexToken,
            order.sizeDelta,
            order.isLong,
            order.triggerPrice,
            order.triggerAboveThreshold,
            order.executionFee,
            currentPrice
        );
    }

    function cancelDecreaseOrder(uint256 _orderIndex) public nonReentrant {
        DecreaseOrder memory order = decreaseOrders[msg.sender][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");

        delete decreaseOrders[msg.sender][_orderIndex];
        _transferOutETH(order.executionFee, msg.sender);

        emit CancelDecreaseOrder(
            order.account,
            _orderIndex,
            order.collateralToken,
            order.collateralDelta,
            order.indexToken,
            order.sizeDelta,
            order.isLong,
            order.triggerPrice,
            order.triggerAboveThreshold,
            order.executionFee
        );
    }

    function updateDecreaseOrder(
        uint256 _orderIndex,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external nonReentrant {
        DecreaseOrder storage order = decreaseOrders[msg.sender][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");

        order.triggerPrice = _triggerPrice;
        order.triggerAboveThreshold = _triggerAboveThreshold;
        order.sizeDelta = _sizeDelta;
        order.collateralDelta = _collateralDelta;

        emit UpdateDecreaseOrder(
            msg.sender,
            _orderIndex,
            order.collateralToken,
            _collateralDelta,
            order.indexToken,
            _sizeDelta,
            order.isLong,
            _triggerPrice,
            _triggerAboveThreshold
        );
    }

    function _transferInETH() private {
        if (msg.value != 0) {
            IWETH(weth).deposit{value: msg.value}();
        }
    }

    function _transferOutETH(uint256 _amountOut, address payable _receiver) private {
        IWETH(weth).withdraw(_amountOut);
        _receiver.sendValue(_amountOut);
    }

    function _swap(address[] memory _path, uint256 _minOut, address _receiver) private returns (uint256) {
        if (_path.length == 2) {
            return _vaultSwap(_path[0], _path[1], _minOut, _receiver);
        }
        if (_path.length == 3) {
            uint256 midOut = _vaultSwap(_path[0], _path[1], 0, address(this));
            IERC20(_path[1]).safeTransfer(vault, midOut);
            return _vaultSwap(_path[1], _path[2], _minOut, _receiver);
        }

        revert("OrderBook: invalid _path.length");
    }

    function _vaultSwap(address _tokenIn, address _tokenOut, uint256 _minOut, address _receiver) private returns (uint256) {
        uint256 amountOut;

        if (_tokenOut == bxd) { // buyBXD
            amountOut = IVault(vault).buyBXD(_tokenIn, _receiver);
        } else if (_tokenIn == bxd) { // sellBXD
            amountOut = IVault(vault).sellBXD(_tokenOut, _receiver);
        } else { // swap
            amountOut = IVault(vault).swap(_tokenIn, _tokenOut, _receiver);
        }

        require(amountOut >= _minOut, "OrderBook: insufficient amountOut");
        return amountOut;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./interfaces/IRouter.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IOrderBook.sol";

import "../peripherals/interfaces/ITimelock.sol";
import "./BasePositionManager.sol";

contract PositionManager is BasePositionManager {

    address public orderBook;
    bool public inLegacyMode;

    bool public shouldValidateIncreaseOrder = true;

    mapping (address => bool) public isOrderKeeper;
    mapping (address => bool) public isPartner;
    mapping (address => bool) public isLiquidator;

    event SetOrderKeeper(address indexed account, bool isActive);
    event SetLiquidator(address indexed account, bool isActive);
    event SetPartner(address account, bool isActive);
    event SetInLegacyMode(bool inLegacyMode);
    event SetShouldValidateIncreaseOrder(bool shouldValidateIncreaseOrder);

    modifier onlyOrderKeeper() {
        require(isOrderKeeper[msg.sender], "PositionManager: forbidden");
        _;
    }

    modifier onlyLiquidator() {
        require(isLiquidator[msg.sender], "PositionManager: forbidden");
        _;
    }

    modifier onlyPartnersOrLegacyMode() {
        require(isPartner[msg.sender] || inLegacyMode, "PositionManager: forbidden");
        _;
    }

    constructor(
        address _vault,
        address _router,
        address _shortsTracker,
        address _weth,
        uint256 _depositFee,
        address _orderBook
    ) public BasePositionManager(_vault, _router, _shortsTracker, _weth, _depositFee) {
        orderBook = _orderBook;
    }

    function setOrderKeeper(address _account, bool _isActive) external onlyAdmin {
        isOrderKeeper[_account] = _isActive;
        emit SetOrderKeeper(_account, _isActive);
    }

    function setLiquidator(address _account, bool _isActive) external onlyAdmin {
        isLiquidator[_account] = _isActive;
        emit SetLiquidator(_account, _isActive);
    }

    function setPartner(address _account, bool _isActive) external onlyAdmin {
        isPartner[_account] = _isActive;
        emit SetPartner(_account, _isActive);
    }

    function setInLegacyMode(bool _inLegacyMode) external onlyAdmin {
        inLegacyMode = _inLegacyMode;
        emit SetInLegacyMode(_inLegacyMode);
    }

    function setShouldValidateIncreaseOrder(bool _shouldValidateIncreaseOrder) external onlyAdmin {
        shouldValidateIncreaseOrder = _shouldValidateIncreaseOrder;
        emit SetShouldValidateIncreaseOrder(_shouldValidateIncreaseOrder);
    }

    function increasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price
    ) external nonReentrant onlyPartnersOrLegacyMode {
        require(_path.length == 1 || _path.length == 2, "PositionManager: invalid _path.length");

        if (_amountIn > 0) {
            if (_path.length == 1) {
                IRouter(router).pluginTransfer(_path[0], msg.sender, address(this), _amountIn);
            } else {
                IRouter(router).pluginTransfer(_path[0], msg.sender, vault, _amountIn);
                _amountIn = _swap(_path, _minOut, address(this));
            }

            uint256 afterFeeAmount = _collectFees(msg.sender, _path, _amountIn, _indexToken, _isLong, _sizeDelta);
            IERC20(_path[_path.length - 1]).safeTransfer(vault, afterFeeAmount);
        }

        _increasePosition(msg.sender, _path[_path.length - 1], _indexToken, _sizeDelta, _isLong, _price);
    }

    function increasePositionETH(
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price
    ) external payable nonReentrant onlyPartnersOrLegacyMode {
        require(_path.length == 1 || _path.length == 2, "PositionManager: invalid _path.length");
        require(_path[0] == weth, "PositionManager: invalid _path");

        if (msg.value > 0) {
            _transferInETH();
            uint256 _amountIn = msg.value;

            if (_path.length > 1) {
                IERC20(weth).safeTransfer(vault, msg.value);
                _amountIn = _swap(_path, _minOut, address(this));
            }

            uint256 afterFeeAmount = _collectFees(msg.sender, _path, _amountIn, _indexToken, _isLong, _sizeDelta);
            IERC20(_path[_path.length - 1]).safeTransfer(vault, afterFeeAmount);
        }

        _increasePosition(msg.sender, _path[_path.length - 1], _indexToken, _sizeDelta, _isLong, _price);
    }

    function decreasePosition(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price
    ) external nonReentrant onlyPartnersOrLegacyMode {
        _decreasePosition(msg.sender, _collateralToken, _indexToken, _collateralDelta, _sizeDelta, _isLong, _receiver, _price);
    }

    function decreasePositionETH(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address payable _receiver,
        uint256 _price
    ) external nonReentrant onlyPartnersOrLegacyMode {
        require(_collateralToken == weth, "PositionManager: invalid _collateralToken");

        uint256 amountOut = _decreasePosition(msg.sender, _collateralToken, _indexToken, _collateralDelta, _sizeDelta, _isLong, address(this), _price);
        _transferOutETHWithGasLimitFallbackToWeth(amountOut, _receiver);
    }

    function decreasePositionAndSwap(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price,
        uint256 _minOut
    ) external nonReentrant onlyPartnersOrLegacyMode {
        require(_path.length == 2, "PositionManager: invalid _path.length");

        uint256 amount = _decreasePosition(msg.sender, _path[0], _indexToken, _collateralDelta, _sizeDelta, _isLong, address(this), _price);
        IERC20(_path[0]).safeTransfer(vault, amount);
        _swap(_path, _minOut, _receiver);
    }

    function decreasePositionAndSwapETH(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address payable _receiver,
        uint256 _price,
        uint256 _minOut
    ) external nonReentrant onlyPartnersOrLegacyMode {
        require(_path.length == 2, "PositionManager: invalid _path.length");
        require(_path[_path.length - 1] == weth, "PositionManager: invalid _path");

        uint256 amount = _decreasePosition(msg.sender, _path[0], _indexToken, _collateralDelta, _sizeDelta, _isLong, address(this), _price);
        IERC20(_path[0]).safeTransfer(vault, amount);
        uint256 amountOut = _swap(_path, _minOut, address(this));
        _transferOutETHWithGasLimitFallbackToWeth(amountOut, _receiver);
    }

    function liquidatePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        address _feeReceiver
    ) external nonReentrant onlyLiquidator {
        address _vault = vault;
        address timelock = IVault(_vault).gov();
        (uint256 size, , , , , , , ) = IVault(vault).getPosition(_account, _collateralToken, _indexToken, _isLong);

        uint256 markPrice = _isLong ? IVault(_vault).getMinPrice(_indexToken) : IVault(_vault).getMaxPrice(_indexToken);
        // should be called strictly before position is updated in Vault
        IShortsTracker(shortsTracker).updateGlobalShortData(_account, _collateralToken, _indexToken, _isLong, size, markPrice, false);

        ITimelock(timelock).enableLeverage(_vault);
        IVault(_vault).liquidatePosition(_account, _collateralToken, _indexToken, _isLong, _feeReceiver);
        ITimelock(timelock).disableLeverage(_vault);
    }

    function executeSwapOrder(address _account, uint256 _orderIndex, address payable _feeReceiver) external onlyOrderKeeper {
        IOrderBook(orderBook).executeSwapOrder(_account, _orderIndex, _feeReceiver);
    }

    function executeIncreaseOrder(address _account, uint256 _orderIndex, address payable _feeReceiver) external onlyOrderKeeper {
        _validateIncreaseOrder(_account, _orderIndex);

        address _vault = vault;
        address timelock = IVault(_vault).gov();

        (
            /*address purchaseToken*/,
            /*uint256 purchaseTokenAmount*/,
            address collateralToken,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            /*uint256 triggerPrice*/,
            /*bool triggerAboveThreshold*/,
            /*uint256 executionFee*/
        ) = IOrderBook(orderBook).getIncreaseOrder(_account, _orderIndex);

        uint256 markPrice = isLong ? IVault(_vault).getMaxPrice(indexToken) : IVault(_vault).getMinPrice(indexToken);
        // should be called strictly before position is updated in Vault
        IShortsTracker(shortsTracker).updateGlobalShortData(_account, collateralToken, indexToken, isLong, sizeDelta, markPrice, true);

        ITimelock(timelock).enableLeverage(_vault);
        IOrderBook(orderBook).executeIncreaseOrder(_account, _orderIndex, _feeReceiver);
        ITimelock(timelock).disableLeverage(_vault);

        _emitIncreasePositionReferral(_account, sizeDelta);
    }

    function executeDecreaseOrder(address _account, uint256 _orderIndex, address payable _feeReceiver) external onlyOrderKeeper {
        address _vault = vault;
        address timelock = IVault(_vault).gov();

        (
            address collateralToken,
            /*uint256 collateralDelta*/,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            /*uint256 triggerPrice*/,
            /*bool triggerAboveThreshold*/,
            /*uint256 executionFee*/
        ) = IOrderBook(orderBook).getDecreaseOrder(_account, _orderIndex);

        uint256 markPrice = isLong ? IVault(_vault).getMinPrice(indexToken) : IVault(_vault).getMaxPrice(indexToken);
        // should be called strictly before position is updated in Vault
        IShortsTracker(shortsTracker).updateGlobalShortData(_account, collateralToken, indexToken, isLong, sizeDelta, markPrice, false);

        ITimelock(timelock).enableLeverage(_vault);
        IOrderBook(orderBook).executeDecreaseOrder(_account, _orderIndex, _feeReceiver);
        ITimelock(timelock).disableLeverage(_vault);

        _emitDecreasePositionReferral(_account, sizeDelta);
    }

    function _validateIncreaseOrder(address _account, uint256 _orderIndex) internal view {
        (
            address _purchaseToken,
            uint256 _purchaseTokenAmount,
            address _collateralToken,
            address _indexToken,
            uint256 _sizeDelta,
            bool _isLong,
            , // triggerPrice
            , // triggerAboveThreshold
            // executionFee
        ) = IOrderBook(orderBook).getIncreaseOrder(_account, _orderIndex);

        _validateMaxGlobalSize(_indexToken, _isLong, _sizeDelta);

        if (!shouldValidateIncreaseOrder) { return; }

        // shorts are okay
        if (!_isLong) { return; }

        // if the position size is not increasing, this is a collateral deposit
        require(_sizeDelta > 0, "PositionManager: long deposit");

        IVault _vault = IVault(vault);
        (uint256 size, uint256 collateral, , , , , , ) = _vault.getPosition(_account, _collateralToken, _indexToken, _isLong);

        // if there is no existing position, do not charge a fee
        if (size == 0) { return; }

        uint256 nextSize = size.add(_sizeDelta);
        uint256 collateralDelta = _vault.tokenToUsdMin(_purchaseToken, _purchaseTokenAmount);
        uint256 nextCollateral = collateral.add(collateralDelta);

        uint256 prevLeverage = size.mul(BASIS_POINTS_DIVISOR).div(collateral);
        // allow for a maximum of a increasePositionBufferBps decrease since there might be some swap fees taken from the collateral
        uint256 nextLeverageWithBuffer = nextSize.mul(BASIS_POINTS_DIVISOR + increasePositionBufferBps).div(nextCollateral);

        require(nextLeverageWithBuffer >= prevLeverage, "PositionManager: long leverage decrease");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./interfaces/IRouter.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IPositionRouter.sol";
import "./interfaces/IPositionRouterCallbackReceiver.sol";

import "../libraries/utils/Address.sol";
import "../peripherals/interfaces/ITimelock.sol";
import "./BasePositionManager.sol";

contract PositionRouter is BasePositionManager, IPositionRouter {
    using Address for address;

    struct IncreasePositionRequest {
        address account;
        address[] path;
        address indexToken;
        uint256 amountIn;
        uint256 minOut;
        uint256 sizeDelta;
        bool isLong;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool hasCollateralInETH;
        address callbackTarget;
    }

    struct DecreasePositionRequest {
        address account;
        address[] path;
        address indexToken;
        uint256 collateralDelta;
        uint256 sizeDelta;
        bool isLong;
        address receiver;
        uint256 acceptablePrice;
        uint256 minOut;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool withdrawETH;
        address callbackTarget;
    }

    uint256 public minExecutionFee;

    uint256 public minBlockDelayKeeper;
    uint256 public minTimeDelayPublic;
    uint256 public maxTimeDelay;

    bool public isLeverageEnabled = true;

    bytes32[] public override increasePositionRequestKeys;
    bytes32[] public override decreasePositionRequestKeys;

    uint256 public override increasePositionRequestKeysStart;
    uint256 public override decreasePositionRequestKeysStart;

    uint256 public callbackGasLimit;
    mapping (address => uint256) public customCallbackGasLimits;

    mapping (address => bool) public isPositionKeeper;

    mapping (address => uint256) public increasePositionsIndex;
    mapping (bytes32 => IncreasePositionRequest) public increasePositionRequests;

    mapping (address => uint256) public decreasePositionsIndex;
    mapping (bytes32 => DecreasePositionRequest) public decreasePositionRequests;

    event CreateIncreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 amountIn,
        uint256 minOut,
        uint256 sizeDelta,
        bool isLong,
        uint256 acceptablePrice,
        uint256 executionFee,
        uint256 index,
        uint256 queueIndex,
        uint256 blockNumber,
        uint256 blockTime,
        uint256 gasPrice
    );

    event ExecuteIncreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 amountIn,
        uint256 minOut,
        uint256 sizeDelta,
        bool isLong,
        uint256 acceptablePrice,
        uint256 executionFee,
        uint256 blockGap,
        uint256 timeGap
    );

    event CancelIncreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 amountIn,
        uint256 minOut,
        uint256 sizeDelta,
        bool isLong,
        uint256 acceptablePrice,
        uint256 executionFee,
        uint256 blockGap,
        uint256 timeGap
    );

    event CreateDecreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        address receiver,
        uint256 acceptablePrice,
        uint256 minOut,
        uint256 executionFee,
        uint256 index,
        uint256 queueIndex,
        uint256 blockNumber,
        uint256 blockTime
    );

    event ExecuteDecreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        address receiver,
        uint256 acceptablePrice,
        uint256 minOut,
        uint256 executionFee,
        uint256 blockGap,
        uint256 timeGap
    );

    event CancelDecreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        address receiver,
        uint256 acceptablePrice,
        uint256 minOut,
        uint256 executionFee,
        uint256 blockGap,
        uint256 timeGap
    );

    event SetPositionKeeper(address indexed account, bool isActive);
    event SetMinExecutionFee(uint256 minExecutionFee);
    event SetIsLeverageEnabled(bool isLeverageEnabled);
    event SetDelayValues(uint256 minBlockDelayKeeper, uint256 minTimeDelayPublic, uint256 maxTimeDelay);
    event SetRequestKeysStartValues(uint256 increasePositionRequestKeysStart, uint256 decreasePositionRequestKeysStart);
    event SetCallbackGasLimit(uint256 callbackGasLimit);
    event SetCustomCallbackGasLimit(address callbackTarget, uint256 callbackGasLimit);
    event Callback(address callbackTarget, bool success, uint256 callbackGasLimit);

    modifier onlyPositionKeeper() {
        require(isPositionKeeper[msg.sender], "403");
        _;
    }

    constructor(
        address _vault,
        address _router,
        address _weth,
        address _shortsTracker,
        uint256 _depositFee,
        uint256 _minExecutionFee
    ) public BasePositionManager(_vault, _router, _shortsTracker, _weth, _depositFee) {
        minExecutionFee = _minExecutionFee;
    }

    function setPositionKeeper(address _account, bool _isActive) external onlyAdmin {
        isPositionKeeper[_account] = _isActive;
        emit SetPositionKeeper(_account, _isActive);
    }

    function setCallbackGasLimit(uint256 _callbackGasLimit) external onlyAdmin {
        callbackGasLimit = _callbackGasLimit;
        emit SetCallbackGasLimit(_callbackGasLimit);
    }

    function setCustomCallbackGasLimit(address _callbackTarget, uint256 _callbackGasLimit) external onlyAdmin {
        customCallbackGasLimits[_callbackTarget] = _callbackGasLimit;
        emit SetCustomCallbackGasLimit(_callbackTarget, _callbackGasLimit);
    }

    function setMinExecutionFee(uint256 _minExecutionFee) external onlyAdmin {
        minExecutionFee = _minExecutionFee;
        emit SetMinExecutionFee(_minExecutionFee);
    }

    function setIsLeverageEnabled(bool _isLeverageEnabled) external onlyAdmin {
        isLeverageEnabled = _isLeverageEnabled;
        emit SetIsLeverageEnabled(_isLeverageEnabled);
    }

    function setDelayValues(uint256 _minBlockDelayKeeper, uint256 _minTimeDelayPublic, uint256 _maxTimeDelay) external onlyAdmin {
        minBlockDelayKeeper = _minBlockDelayKeeper;
        minTimeDelayPublic = _minTimeDelayPublic;
        maxTimeDelay = _maxTimeDelay;
        emit SetDelayValues(_minBlockDelayKeeper, _minTimeDelayPublic, _maxTimeDelay);
    }

    function setRequestKeysStartValues(uint256 _increasePositionRequestKeysStart, uint256 _decreasePositionRequestKeysStart) external onlyAdmin {
        increasePositionRequestKeysStart = _increasePositionRequestKeysStart;
        decreasePositionRequestKeysStart = _decreasePositionRequestKeysStart;

        emit SetRequestKeysStartValues(_increasePositionRequestKeysStart, _decreasePositionRequestKeysStart);
    }

    function executeIncreasePositions(uint256 _endIndex, address payable _executionFeeReceiver) external override onlyPositionKeeper {
        uint256 index = increasePositionRequestKeysStart;
        uint256 length = increasePositionRequestKeys.length;

        if (index >= length) { return; }

        if (_endIndex > length) {
            _endIndex = length;
        }

        while (index < _endIndex) {
            bytes32 key = increasePositionRequestKeys[index];

            // if the request was executed then delete the key from the array
            // if the request was not executed then break from the loop, this can happen if the
            // minimum number of blocks has not yet passed
            // an error could be thrown if the request is too old or if the slippage is
            // higher than what the user specified, or if there is insufficient liquidity for the position
            // in case an error was thrown, cancel the request
            try this.executeIncreasePosition(key, _executionFeeReceiver) returns (bool _wasExecuted) {
                if (!_wasExecuted) { break; }
            } catch {
                // wrap this call in a try catch to prevent invalid cancels from blocking the loop
                try this.cancelIncreasePosition(key, _executionFeeReceiver) returns (bool _wasCancelled) {
                    if (!_wasCancelled) { break; }
                } catch {}
            }

            delete increasePositionRequestKeys[index];
            index++;
        }

        increasePositionRequestKeysStart = index;
    }

    function executeDecreasePositions(uint256 _endIndex, address payable _executionFeeReceiver) external override onlyPositionKeeper {
        uint256 index = decreasePositionRequestKeysStart;
        uint256 length = decreasePositionRequestKeys.length;

        if (index >= length) { return; }

        if (_endIndex > length) {
            _endIndex = length;
        }

        while (index < _endIndex) {
            bytes32 key = decreasePositionRequestKeys[index];

            // if the request was executed then delete the key from the array
            // if the request was not executed then break from the loop, this can happen if the
            // minimum number of blocks has not yet passed
            // an error could be thrown if the request is too old
            // in case an error was thrown, cancel the request
            try this.executeDecreasePosition(key, _executionFeeReceiver) returns (bool _wasExecuted) {
                if (!_wasExecuted) { break; }
            } catch {
                // wrap this call in a try catch to prevent invalid cancels from blocking the loop
                try this.cancelDecreasePosition(key, _executionFeeReceiver) returns (bool _wasCancelled) {
                    if (!_wasCancelled) { break; }
                } catch {}
            }

            delete decreasePositionRequestKeys[index];
            index++;
        }

        decreasePositionRequestKeysStart = index;
    }

    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable nonReentrant returns (bytes32) {
        require(_executionFee >= minExecutionFee, "fee");
        require(msg.value == _executionFee, "val");
        require(_path.length == 1 || _path.length == 2, "len");

        _transferInETH();
        _setTraderReferralCode(_referralCode);

        if (_amountIn > 0) {
            IRouter(router).pluginTransfer(_path[0], msg.sender, address(this), _amountIn);
        }

        return _createIncreasePosition(
            msg.sender,
            _path,
            _indexToken,
            _amountIn,
            _minOut,
            _sizeDelta,
            _isLong,
            _acceptablePrice,
            _executionFee,
            false,
            _callbackTarget
        );
    }

    function createIncreasePositionETH(
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable nonReentrant returns (bytes32) {
        require(_executionFee >= minExecutionFee, "fee");
        require(msg.value >= _executionFee, "val");
        require(_path.length == 1 || _path.length == 2, "len");
        require(_path[0] == weth, "path");
        _transferInETH();
        _setTraderReferralCode(_referralCode);

        uint256 amountIn = msg.value.sub(_executionFee);

        return _createIncreasePosition(
            msg.sender,
            _path,
            _indexToken,
            amountIn,
            _minOut,
            _sizeDelta,
            _isLong,
            _acceptablePrice,
            _executionFee,
            true,
            _callbackTarget
        );
    }

    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external payable nonReentrant returns (bytes32) {
        require(_executionFee >= minExecutionFee, "fee");
        require(msg.value == _executionFee, "val");
        require(_path.length == 1 || _path.length == 2, "len");

        if (_withdrawETH) {
            require(_path[_path.length - 1] == weth, "path");
        }

        _transferInETH();

        return _createDecreasePosition(
            msg.sender,
            _path,
            _indexToken,
            _collateralDelta,
            _sizeDelta,
            _isLong,
            _receiver,
            _acceptablePrice,
            _minOut,
            _executionFee,
            _withdrawETH,
            _callbackTarget
        );
    }

    function getRequestQueueLengths() external view override returns (uint256, uint256, uint256, uint256) {
        return (
            increasePositionRequestKeysStart,
            increasePositionRequestKeys.length,
            decreasePositionRequestKeysStart,
            decreasePositionRequestKeys.length
        );
    }

    function executeIncreasePosition(bytes32 _key, address payable _executionFeeReceiver) public nonReentrant returns (bool) {
        IncreasePositionRequest memory request = increasePositionRequests[_key];
        // if the request was already executed or cancelled, return true so that the executeIncreasePositions loop will continue executing the next request
        if (request.account == address(0)) { return true; }

        bool shouldExecute = _validateExecution(request.blockNumber, request.blockTime, request.account);
        if (!shouldExecute) { return false; }

        delete increasePositionRequests[_key];

        if (request.amountIn > 0) {
            uint256 amountIn = request.amountIn;

            if (request.path.length > 1) {
                IERC20(request.path[0]).safeTransfer(vault, request.amountIn);
                amountIn = _swap(request.path, request.minOut, address(this));
            }

            uint256 afterFeeAmount = _collectFees(request.account, request.path, amountIn, request.indexToken, request.isLong, request.sizeDelta);
            IERC20(request.path[request.path.length - 1]).safeTransfer(vault, afterFeeAmount);
        }

        _increasePosition(request.account, request.path[request.path.length - 1], request.indexToken, request.sizeDelta, request.isLong, request.acceptablePrice);

        _transferOutETHWithGasLimitFallbackToWeth(request.executionFee, _executionFeeReceiver);

        emit ExecuteIncreasePosition(
            request.account,
            request.path,
            request.indexToken,
            request.amountIn,
            request.minOut,
            request.sizeDelta,
            request.isLong,
            request.acceptablePrice,
            request.executionFee,
            block.number.sub(request.blockNumber),
            block.timestamp.sub(request.blockTime)
        );

        _callRequestCallback(request.callbackTarget, _key, true, true);

        return true;
    }

    function cancelIncreasePosition(bytes32 _key, address payable _executionFeeReceiver) public nonReentrant returns (bool) {
        IncreasePositionRequest memory request = increasePositionRequests[_key];
        // if the request was already executed or cancelled, return true so that the executeIncreasePositions loop will continue executing the next request
        if (request.account == address(0)) { return true; }

        bool shouldCancel = _validateCancellation(request.blockNumber, request.blockTime, request.account);
        if (!shouldCancel) { return false; }

        delete increasePositionRequests[_key];

        if (request.hasCollateralInETH) {
            _transferOutETHWithGasLimitFallbackToWeth(request.amountIn, payable(request.account));
        } else {
            IERC20(request.path[0]).safeTransfer(request.account, request.amountIn);
        }

       _transferOutETHWithGasLimitFallbackToWeth(request.executionFee, _executionFeeReceiver);

        emit CancelIncreasePosition(
            request.account,
            request.path,
            request.indexToken,
            request.amountIn,
            request.minOut,
            request.sizeDelta,
            request.isLong,
            request.acceptablePrice,
            request.executionFee,
            block.number.sub(request.blockNumber),
            block.timestamp.sub(request.blockTime)
        );

        _callRequestCallback(request.callbackTarget, _key, false, true);

        return true;
    }

    function executeDecreasePosition(bytes32 _key, address payable _executionFeeReceiver) public nonReentrant returns (bool) {
        DecreasePositionRequest memory request = decreasePositionRequests[_key];
        // if the request was already executed or cancelled, return true so that the executeDecreasePositions loop will continue executing the next request
        if (request.account == address(0)) { return true; }

        bool shouldExecute = _validateExecution(request.blockNumber, request.blockTime, request.account);
        if (!shouldExecute) { return false; }

        delete decreasePositionRequests[_key];

        uint256 amountOut = _decreasePosition(request.account, request.path[0], request.indexToken, request.collateralDelta, request.sizeDelta, request.isLong, address(this), request.acceptablePrice);

        if (amountOut > 0) {
            if (request.path.length > 1) {
                IERC20(request.path[0]).safeTransfer(vault, amountOut);
                amountOut = _swap(request.path, request.minOut, address(this));
            }

            if (request.withdrawETH) {
               _transferOutETHWithGasLimitFallbackToWeth(amountOut, payable(request.receiver));
            } else {
               IERC20(request.path[request.path.length - 1]).safeTransfer(request.receiver, amountOut);
            }
        }

       _transferOutETHWithGasLimitFallbackToWeth(request.executionFee, _executionFeeReceiver);

        emit ExecuteDecreasePosition(
            request.account,
            request.path,
            request.indexToken,
            request.collateralDelta,
            request.sizeDelta,
            request.isLong,
            request.receiver,
            request.acceptablePrice,
            request.minOut,
            request.executionFee,
            block.number.sub(request.blockNumber),
            block.timestamp.sub(request.blockTime)
        );

        _callRequestCallback(request.callbackTarget, _key, true, false);

        return true;
    }

    function cancelDecreasePosition(bytes32 _key, address payable _executionFeeReceiver) public nonReentrant returns (bool) {
        DecreasePositionRequest memory request = decreasePositionRequests[_key];
        // if the request was already executed or cancelled, return true so that the executeDecreasePositions loop will continue executing the next request
        if (request.account == address(0)) { return true; }

        bool shouldCancel = _validateCancellation(request.blockNumber, request.blockTime, request.account);
        if (!shouldCancel) { return false; }

        delete decreasePositionRequests[_key];

       _transferOutETHWithGasLimitFallbackToWeth(request.executionFee, _executionFeeReceiver);

        emit CancelDecreasePosition(
            request.account,
            request.path,
            request.indexToken,
            request.collateralDelta,
            request.sizeDelta,
            request.isLong,
            request.receiver,
            request.acceptablePrice,
            request.minOut,
            request.executionFee,
            block.number.sub(request.blockNumber),
            block.timestamp.sub(request.blockTime)
        );

        _callRequestCallback(request.callbackTarget, _key, false, false);

        return true;
    }

    function getRequestKey(address _account, uint256 _index) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _index));
    }

    function getIncreasePositionRequestPath(bytes32 _key) public view override returns (address[] memory) {
        IncreasePositionRequest memory request = increasePositionRequests[_key];
        return request.path;
    }

    function getDecreasePositionRequestPath(bytes32 _key) public view override returns (address[] memory) {
        DecreasePositionRequest memory request = decreasePositionRequests[_key];
        return request.path;
    }

    function _setTraderReferralCode(bytes32 _referralCode) internal {
        if (_referralCode != bytes32(0) && referralStorage != address(0)) {
            IReferralStorage(referralStorage).setTraderReferralCode(msg.sender, _referralCode);
        }
    }

    function _validateExecution(uint256 _positionBlockNumber, uint256 _positionBlockTime, address _account) internal view returns (bool) {
        if (_positionBlockTime.add(maxTimeDelay) <= block.timestamp) {
            revert("expired");
        }

        return _validateExecutionOrCancellation(_positionBlockNumber, _positionBlockTime, _account);
    }

    function _validateCancellation(uint256 _positionBlockNumber, uint256 _positionBlockTime, address _account) internal view returns (bool) {
        return _validateExecutionOrCancellation(_positionBlockNumber, _positionBlockTime, _account);
    }

    function _validateExecutionOrCancellation(uint256 _positionBlockNumber, uint256 _positionBlockTime, address _account) internal view returns (bool) {
        bool isKeeperCall = msg.sender == address(this) || isPositionKeeper[msg.sender];

        if (!isLeverageEnabled && !isKeeperCall) {
            revert("403");
        }

        if (isKeeperCall) {
            return _positionBlockNumber.add(minBlockDelayKeeper) <= block.number;
        }

        require(msg.sender == _account, "403");

        require(_positionBlockTime.add(minTimeDelayPublic) <= block.timestamp, "delay");

        return true;
    }

    function _createIncreasePosition(
        address _account,
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bool _hasCollateralInETH,
        address _callbackTarget
    ) internal returns (bytes32) {
        IncreasePositionRequest memory request = IncreasePositionRequest(
            _account,
            _path,
            _indexToken,
            _amountIn,
            _minOut,
            _sizeDelta,
            _isLong,
            _acceptablePrice,
            _executionFee,
            block.number,
            block.timestamp,
            _hasCollateralInETH,
            _callbackTarget
        );

        (uint256 index, bytes32 requestKey) = _storeIncreasePositionRequest(request);
        emit CreateIncreasePosition(
            _account,
            _path,
            _indexToken,
            _amountIn,
            _minOut,
            _sizeDelta,
            _isLong,
            _acceptablePrice,
            _executionFee,
            index,
            increasePositionRequestKeys.length - 1,
            block.number,
            block.timestamp,
            tx.gasprice
        );

        return requestKey;
    }

    function _storeIncreasePositionRequest(IncreasePositionRequest memory _request) internal returns (uint256, bytes32) {
        address account = _request.account;
        uint256 index = increasePositionsIndex[account].add(1);
        increasePositionsIndex[account] = index;
        bytes32 key = getRequestKey(account, index);

        increasePositionRequests[key] = _request;
        increasePositionRequestKeys.push(key);

        return (index, key);
    }

    function _storeDecreasePositionRequest(DecreasePositionRequest memory _request) internal returns (uint256, bytes32) {
        address account = _request.account;
        uint256 index = decreasePositionsIndex[account].add(1);
        decreasePositionsIndex[account] = index;
        bytes32 key = getRequestKey(account, index);

        decreasePositionRequests[key] = _request;
        decreasePositionRequestKeys.push(key);

        return (index, key);
    }

    function _createDecreasePosition(
        address _account,
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) internal returns (bytes32) {
        DecreasePositionRequest memory request = DecreasePositionRequest(
            _account,
            _path,
            _indexToken,
            _collateralDelta,
            _sizeDelta,
            _isLong,
            _receiver,
            _acceptablePrice,
            _minOut,
            _executionFee,
            block.number,
            block.timestamp,
            _withdrawETH,
            _callbackTarget
        );

        (uint256 index, bytes32 requestKey) = _storeDecreasePositionRequest(request);
        emit CreateDecreasePosition(
            request.account,
            request.path,
            request.indexToken,
            request.collateralDelta,
            request.sizeDelta,
            request.isLong,
            request.receiver,
            request.acceptablePrice,
            request.minOut,
            request.executionFee,
            index,
            decreasePositionRequestKeys.length - 1,
            block.number,
            block.timestamp
        );
        return requestKey;
    }

    function _callRequestCallback(
        address _callbackTarget,
        bytes32 _key,
        bool _wasExecuted,
        bool _isIncrease
    ) internal {
        if (_callbackTarget == address(0)) {
            return;
        }

        if (!_callbackTarget.isContract()) {
            return;
        }

        uint256 _gasLimit = callbackGasLimit;

        uint256 _customCallbackGasLimit = customCallbackGasLimits[_callbackTarget];

        if (_customCallbackGasLimit > _gasLimit) {
            _gasLimit = _customCallbackGasLimit;
        }

        if (_gasLimit == 0) {
            return;
        }

        bool success;
        try IPositionRouterCallbackReceiver(_callbackTarget).bxpPositionCallback{ gas: _gasLimit }(_key, _wasExecuted, _isIncrease) {
            success = true;
        } catch {}

        emit Callback(_callbackTarget, success, _gasLimit);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../libraries/math/SafeMath.sol";
import "../peripherals/interfaces/ITimelock.sol";

import "./interfaces/IVault.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IShortsTracker.sol";

library PositionUtils {
    using SafeMath for uint256;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    event LeverageDecreased(uint256 collateralDelta, uint256 prevLeverage, uint256 nextLeverage);

    function shouldDeductFee(
        address _vault,
        address _account,
        address[] memory _path,
        uint256 _amountIn,
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta,
        uint256 _increasePositionBufferBps
    ) external returns (bool) {
        // if the position is a short, do not charge a fee
        if (!_isLong) { return false; }

        // if the position size is not increasing, this is a collateral deposit
        if (_sizeDelta == 0) { return true; }

        address collateralToken = _path[_path.length - 1];

        IVault vault = IVault(_vault);
        (uint256 size, uint256 collateral, , , , , , ) = vault.getPosition(_account, collateralToken, _indexToken, _isLong);

        // if there is no existing position, do not charge a fee
        if (size == 0) { return false; }

        uint256 nextSize = size.add(_sizeDelta);
        uint256 collateralDelta = vault.tokenToUsdMin(collateralToken, _amountIn);
        uint256 nextCollateral = collateral.add(collateralDelta);

        uint256 prevLeverage = size.mul(BASIS_POINTS_DIVISOR).div(collateral);
        // allow for a maximum of a increasePositionBufferBps decrease since there might be some swap fees taken from the collateral
        uint256 nextLeverage = nextSize.mul(BASIS_POINTS_DIVISOR + _increasePositionBufferBps).div(nextCollateral);

        emit LeverageDecreased(collateralDelta, prevLeverage, nextLeverage);

        // deduct a fee if the leverage is decreased
        return nextLeverage < prevLeverage;
    }

    function increasePosition(
        address _vault,
        address _router,
        address _shortsTracker,
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price
    ) external {
        uint256 markPrice = _isLong ? IVault(_vault).getMaxPrice(_indexToken) : IVault(_vault).getMinPrice(_indexToken);
        if (_isLong) {
            require(markPrice <= _price, "markPrice > price");
        } else {
            require(markPrice >= _price, "markPrice < price");
        }

        address timelock = IVault(_vault).gov();

        // should be called strictly before position is updated in Vault
        IShortsTracker(_shortsTracker).updateGlobalShortData(_account, _collateralToken, _indexToken, _isLong, _sizeDelta, markPrice, true);

        ITimelock(timelock).enableLeverage(_vault);
        IRouter(_router).pluginIncreasePosition(_account, _collateralToken, _indexToken, _sizeDelta, _isLong);
        ITimelock(timelock).disableLeverage(_vault);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/Address.sol";

import "../tokens/interfaces/IWETH.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IRouter.sol";

contract Router is IRouter {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    address public gov;

    // wrapped BNB / ETH
    address public weth;
    address public bxd;
    address public vault;

    mapping (address => bool) public plugins;
    mapping (address => mapping (address => bool)) public approvedPlugins;

    event Swap(address account, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);

    modifier onlyGov() {
        require(msg.sender == gov, "Router: forbidden");
        _;
    }

    constructor(address _vault, address _bxd, address _weth) public {
        vault = _vault;
        bxd = _bxd;
        weth = _weth;

        gov = msg.sender;
    }

    receive() external payable {
        require(msg.sender == weth, "Router: invalid sender");
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function addPlugin(address _plugin) external override onlyGov {
        plugins[_plugin] = true;
    }

    function removePlugin(address _plugin) external onlyGov {
        plugins[_plugin] = false;
    }

    function approvePlugin(address _plugin) external {
        approvedPlugins[msg.sender][_plugin] = true;
    }

    function denyPlugin(address _plugin) external {
        approvedPlugins[msg.sender][_plugin] = false;
    }

    function pluginTransfer(address _token, address _account, address _receiver, uint256 _amount) external override {
        _validatePlugin(_account);
        IERC20(_token).safeTransferFrom(_account, _receiver, _amount);
    }

    function pluginIncreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external override {
        _validatePlugin(_account);
        IVault(vault).increasePosition(_account, _collateralToken, _indexToken, _sizeDelta, _isLong);
    }

    function pluginDecreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external override returns (uint256) {
        _validatePlugin(_account);
        return IVault(vault).decreasePosition(_account, _collateralToken, _indexToken, _collateralDelta, _sizeDelta, _isLong, _receiver);
    }

    function directPoolDeposit(address _token, uint256 _amount) external {
        IERC20(_token).safeTransferFrom(_sender(), vault, _amount);
        IVault(vault).directPoolDeposit(_token);
    }

    function swap(address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) public override {
        IERC20(_path[0]).safeTransferFrom(_sender(), vault, _amountIn);
        uint256 amountOut = _swap(_path, _minOut, _receiver);
        emit Swap(msg.sender, _path[0], _path[_path.length - 1], _amountIn, amountOut);
    }

    function swapETHToTokens(address[] memory _path, uint256 _minOut, address _receiver) external payable {
        require(_path[0] == weth, "Router: invalid _path");
        _transferETHToVault();
        uint256 amountOut = _swap(_path, _minOut, _receiver);
        emit Swap(msg.sender, _path[0], _path[_path.length - 1], msg.value, amountOut);
    }

    function swapTokensToETH(address[] memory _path, uint256 _amountIn, uint256 _minOut, address payable _receiver) external {
        require(_path[_path.length - 1] == weth, "Router: invalid _path");
        IERC20(_path[0]).safeTransferFrom(_sender(), vault, _amountIn);
        uint256 amountOut = _swap(_path, _minOut, address(this));
        _transferOutETH(amountOut, _receiver);
        emit Swap(msg.sender, _path[0], _path[_path.length - 1], _amountIn, amountOut);
    }

    function increasePosition(address[] memory _path, address _indexToken, uint256 _amountIn, uint256 _minOut, uint256 _sizeDelta, bool _isLong, uint256 _price) external {
        if (_amountIn > 0) {
            IERC20(_path[0]).safeTransferFrom(_sender(), vault, _amountIn);
        }
        if (_path.length > 1 && _amountIn > 0) {
            uint256 amountOut = _swap(_path, _minOut, address(this));
            IERC20(_path[_path.length - 1]).safeTransfer(vault, amountOut);
        }
        _increasePosition(_path[_path.length - 1], _indexToken, _sizeDelta, _isLong, _price);
    }

    function increasePositionETH(address[] memory _path, address _indexToken, uint256 _minOut, uint256 _sizeDelta, bool _isLong, uint256 _price) external payable {
        require(_path[0] == weth, "Router: invalid _path");
        if (msg.value > 0) {
            _transferETHToVault();
        }
        if (_path.length > 1 && msg.value > 0) {
            uint256 amountOut = _swap(_path, _minOut, address(this));
            IERC20(_path[_path.length - 1]).safeTransfer(vault, amountOut);
        }
        _increasePosition(_path[_path.length - 1], _indexToken, _sizeDelta, _isLong, _price);
    }

    function decreasePosition(address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver, uint256 _price) external {
        _decreasePosition(_collateralToken, _indexToken, _collateralDelta, _sizeDelta, _isLong, _receiver, _price);
    }

    function decreasePositionETH(address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address payable _receiver, uint256 _price) external {
        uint256 amountOut = _decreasePosition(_collateralToken, _indexToken, _collateralDelta, _sizeDelta, _isLong, address(this), _price);
        _transferOutETH(amountOut, _receiver);
    }

    function decreasePositionAndSwap(address[] memory _path, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver, uint256 _price, uint256 _minOut) external {
        uint256 amount = _decreasePosition(_path[0], _indexToken, _collateralDelta, _sizeDelta, _isLong, address(this), _price);
        IERC20(_path[0]).safeTransfer(vault, amount);
        _swap(_path, _minOut, _receiver);
    }

    function decreasePositionAndSwapETH(address[] memory _path, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address payable _receiver, uint256 _price, uint256 _minOut) external {
        require(_path[_path.length - 1] == weth, "Router: invalid _path");
        uint256 amount = _decreasePosition(_path[0], _indexToken, _collateralDelta, _sizeDelta, _isLong, address(this), _price);
        IERC20(_path[0]).safeTransfer(vault, amount);
        uint256 amountOut = _swap(_path, _minOut, address(this));
        _transferOutETH(amountOut, _receiver);
    }

    function _increasePosition(address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong, uint256 _price) private {
        if (_isLong) {
            require(IVault(vault).getMaxPrice(_indexToken) <= _price, "Router: mark price higher than limit");
        } else {
            require(IVault(vault).getMinPrice(_indexToken) >= _price, "Router: mark price lower than limit");
        }

        IVault(vault).increasePosition(_sender(), _collateralToken, _indexToken, _sizeDelta, _isLong);
    }

    function _decreasePosition(address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver, uint256 _price) private returns (uint256) {
        if (_isLong) {
            require(IVault(vault).getMinPrice(_indexToken) >= _price, "Router: mark price lower than limit");
        } else {
            require(IVault(vault).getMaxPrice(_indexToken) <= _price, "Router: mark price higher than limit");
        }

        return IVault(vault).decreasePosition(_sender(), _collateralToken, _indexToken, _collateralDelta, _sizeDelta, _isLong, _receiver);
    }

    function _transferETHToVault() private {
        IWETH(weth).deposit{value: msg.value}();
        IERC20(weth).safeTransfer(vault, msg.value);
    }

    function _transferOutETH(uint256 _amountOut, address payable _receiver) private {
        IWETH(weth).withdraw(_amountOut);
        _receiver.sendValue(_amountOut);
    }

    function _swap(address[] memory _path, uint256 _minOut, address _receiver) private returns (uint256) {
        if (_path.length == 2) {
            return _vaultSwap(_path[0], _path[1], _minOut, _receiver);
        }
        if (_path.length == 3) {
            uint256 midOut = _vaultSwap(_path[0], _path[1], 0, address(this));
            IERC20(_path[1]).safeTransfer(vault, midOut);
            return _vaultSwap(_path[1], _path[2], _minOut, _receiver);
        }

        revert("Router: invalid _path.length");
    }

    function _vaultSwap(address _tokenIn, address _tokenOut, uint256 _minOut, address _receiver) private returns (uint256) {
        uint256 amountOut;

        if (_tokenOut == bxd) { // buyBXD
            amountOut = IVault(vault).buyBXD(_tokenIn, _receiver);
        } else if (_tokenIn == bxd) { // sellBXD
            amountOut = IVault(vault).sellBXD(_tokenOut, _receiver);
        } else { // swap
            amountOut = IVault(vault).swap(_tokenIn, _tokenOut, _receiver);
        }

        require(amountOut >= _minOut, "Router: insufficient amountOut");
        return amountOut;
    }

    function _sender() private view returns (address) {
        return msg.sender;
    }

    function _validatePlugin(address _account) private view {
        require(plugins[msg.sender], "Router: invalid plugin");
        require(approvedPlugins[_account][msg.sender], "Router: plugin not approved");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";

import "../access/Governable.sol";
import "./interfaces/IShortsTracker.sol";
import "./interfaces/IVault.sol";

contract ShortsTracker is Governable, IShortsTracker {
    using SafeMath for uint256;

    event GlobalShortDataUpdated(address indexed token, uint256 globalShortSize, uint256 globalShortAveragePrice);

    uint256 public constant MAX_INT256 = uint256(type(int256).max);

    IVault public vault;

    mapping (address => bool) public isHandler;
    mapping (bytes32 => bytes32) public data;

    mapping (address => uint256) override public globalShortAveragePrices;
    bool override public isGlobalShortDataReady;

    modifier onlyHandler() {
        require(isHandler[msg.sender], "ShortsTracker: forbidden");
        _;
    }

    constructor(address _vault) public {
        vault = IVault(_vault);
    }

    function setHandler(address _handler, bool _isActive) external onlyGov {
        require(_handler != address(0), "ShortsTracker: invalid _handler");
        isHandler[_handler] = _isActive;
    }

    function _setGlobalShortAveragePrice(address _token, uint256 _averagePrice) internal {
        globalShortAveragePrices[_token] = _averagePrice;
    }

    function setIsGlobalShortDataReady(bool value) override external onlyGov {
        isGlobalShortDataReady = value;
    }

    function updateGlobalShortData(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta,
        uint256 _markPrice,
        bool _isIncrease
    ) override external onlyHandler {
        if (_isLong || _sizeDelta == 0) {
            return;
        }

        if (!isGlobalShortDataReady) {
            return;
        }

        (uint256 globalShortSize, uint256 globalShortAveragePrice) = getNextGlobalShortData(
            _account,
            _collateralToken,
            _indexToken,
            _markPrice,
            _sizeDelta,
            _isIncrease
        );
        _setGlobalShortAveragePrice(_indexToken, globalShortAveragePrice);

        emit GlobalShortDataUpdated(_indexToken, globalShortSize, globalShortAveragePrice);
    }

    function getGlobalShortDelta(address _token) public view returns (bool, uint256) {
        uint256 size = vault.globalShortSizes(_token);
        uint256 averagePrice = globalShortAveragePrices[_token];
        if (size == 0) { return (false, 0); }

        uint256 nextPrice = IVault(vault).getMaxPrice(_token);
        uint256 priceDelta = averagePrice > nextPrice ? averagePrice.sub(nextPrice) : nextPrice.sub(averagePrice);
        uint256 delta = size.mul(priceDelta).div(averagePrice);
        bool hasProfit = averagePrice > nextPrice;

        return (hasProfit, delta);
    }


    function setInitData(address[] calldata _tokens, uint256[] calldata _averagePrices) override external onlyGov {
        require(!isGlobalShortDataReady, "ShortsTracker: already migrated");

        for (uint256 i = 0; i < _tokens.length; i++) {
            globalShortAveragePrices[_tokens[i]] = _averagePrices[i];
        }
        isGlobalShortDataReady = true;
    }

    function getNextGlobalShortData(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _nextPrice,
        uint256 _sizeDelta,
        bool _isIncrease
    ) override public view returns (uint256, uint256) {
        int256 realisedPnl = getRealisedPnl(_account,_collateralToken, _indexToken, _sizeDelta, _isIncrease);
        uint256 averagePrice = globalShortAveragePrices[_indexToken];
        uint256 priceDelta = averagePrice > _nextPrice ? averagePrice.sub(_nextPrice) : _nextPrice.sub(averagePrice);

        uint256 nextSize;
        uint256 delta;
        // avoid stack to deep
        {
            uint256 size = vault.globalShortSizes(_indexToken);
            nextSize = _isIncrease ? size.add(_sizeDelta) : size.sub(_sizeDelta);

            if (nextSize == 0) {
                return (0, 0);
            }

            if (averagePrice == 0) {
                return (nextSize, _nextPrice);
            }

            delta = size.mul(priceDelta).div(averagePrice);
        }

        uint256 nextAveragePrice = _getNextGlobalAveragePrice(
            averagePrice,
            _nextPrice,
            nextSize,
            delta,
            realisedPnl
        );

        return (nextSize, nextAveragePrice);
    }

    function getRealisedPnl(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isIncrease
    ) public view returns (int256) {
        if (_isIncrease) {
            return 0;
        }

        IVault _vault = vault;
        (uint256 size, /*uint256 collateral*/, uint256 averagePrice, , , , , uint256 lastIncreasedTime) = _vault.getPosition(_account, _collateralToken, _indexToken, false);

        (bool hasProfit, uint256 delta) = _vault.getDelta(_indexToken, size, averagePrice, false, lastIncreasedTime);
        // get the proportional change in pnl
        uint256 adjustedDelta = _sizeDelta.mul(delta).div(size);
        require(adjustedDelta < MAX_INT256, "ShortsTracker: overflow");
        return hasProfit ? int256(adjustedDelta) : -int256(adjustedDelta);
    }

    function _getNextGlobalAveragePrice(
        uint256 _averagePrice,
        uint256 _nextPrice,
        uint256 _nextSize,
        uint256 _delta,
        int256 _realisedPnl
    ) public pure returns (uint256) {
        (bool hasProfit, uint256 nextDelta) = _getNextDelta(_delta, _averagePrice, _nextPrice, _realisedPnl);

        uint256 nextAveragePrice = _nextPrice
            .mul(_nextSize)
            .div(hasProfit ? _nextSize.sub(nextDelta) : _nextSize.add(nextDelta));

        return nextAveragePrice;
    }

    function _getNextDelta(
        uint256 _delta,
        uint256 _averagePrice,
        uint256 _nextPrice,
        int256 _realisedPnl
    ) internal pure returns (bool, uint256) {
        // global delta 10000, realised pnl 1000 => new pnl 9000
        // global delta 10000, realised pnl -1000 => new pnl 11000
        // global delta -10000, realised pnl 1000 => new pnl -11000
        // global delta -10000, realised pnl -1000 => new pnl -9000
        // global delta 10000, realised pnl 11000 => new pnl -1000 (flips sign)
        // global delta -10000, realised pnl -11000 => new pnl 1000 (flips sign)

        bool hasProfit = _averagePrice > _nextPrice;
        if (hasProfit) {
            // global shorts pnl is positive
            if (_realisedPnl > 0) {
                if (uint256(_realisedPnl) > _delta) {
                    _delta = uint256(_realisedPnl).sub(_delta);
                    hasProfit = false;
                } else {
                    _delta = _delta.sub(uint256(_realisedPnl));
                }
            } else {
                _delta = _delta.add(uint256(-_realisedPnl));
            }

            return (hasProfit, _delta);
        }

        if (_realisedPnl > 0) {
            _delta = _delta.add(uint256(_realisedPnl));
        } else {
            if (uint256(-_realisedPnl) > _delta) {
                _delta = uint256(-_realisedPnl).sub(_delta);
                hasProfit = true;
            } else {
                _delta = _delta.sub(uint256(-_realisedPnl));
            }
        }
        return (hasProfit, _delta);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

library FairlaunchStructs {
    struct FairlaunchInfo {
        uint256 totalIcoToken;
        address icoToken;
        address feeToken;
        uint256 softCap;
        bool isMaxinvest;
        uint256 maxInvest;
        uint256 startTime;
        uint256 endTime;
        bool affiliate;
    }

    struct FairlaunchReturnInfo {
        uint256 softCap;
        uint256 totalIcoToken;
        uint256 startTime;
        uint256 endTime;
        uint256 state;
        uint256 raisedAmount;
        uint256 balance;
        address feeToken;
    }

    struct OwnerZoneInfo {
        bool isOwner;
        uint256 whitelistPool;
        bool canFinalize;
        bool canCancel;
    }

    struct FeeSystem {
        uint256 initFee;
        uint256 raisedFeePercent; // ETH With Raised Amount
        uint256 raisedTokenFeePercent;
        uint256 penaltyFee;
    }

    struct SettingAccount {
        address deployer;
        address signer;
        address superAccount; // ETH With Raised Amount
        address payable fundAddress;
        address lptoLock;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

library LaunchpadStructs {
    struct LaunchpadInfo {
        address icoToken;
        address feeToken;
        uint256 softCap;
        uint256 hardCap;
        uint256 presaleRate;
        uint256 minInvest;
        uint256 maxInvest;
        uint256 startTime;
        uint256 endTime;
        uint256 whitelistPool; // 0 public, 1 whitelist, 2 public anti bot
        uint256 poolType; // 0 burn, 1 refund
        bool affiliate;
    }

    struct ClaimInfo {
        uint256 cliffVesting;
        uint256 lockAfterCliffVesting;
        uint256 firstReleasePercent;
        uint256 vestingPeriodEachCycle;
        uint256 tokenReleaseEachCycle; // percent
    }


    struct DexInfo {
        bool manualListing;
        address routerAddress;
        address factoryAddress;
        uint256 listingPrice;
        uint256 listingPercent; // 1=> 10000
        uint256 lpLockTime;
    }


    struct LaunchpadReturnInfo {
        uint256 softCap;
        uint256 hardCap;
        uint256 startTime;
        uint256 endTime;
        uint256 state;
        uint256 raisedAmount;
        uint256 balance;
        address feeToken;
        uint256 listingTime;
        uint256 whitelistPool;
        address holdingToken;
        uint256 holdingTokenAmount;
    }

    struct OwnerZoneInfo {
        bool isOwner;
        uint256 whitelistPool;
        bool canFinalize;
        bool canCancel;
    }

    struct FeeSystem {
        uint256 initFee;
        uint256 raisedFeePercent; // % With Raised Amount
        uint256 raisedTokenFeePercent;
        uint256 penaltyFee;
    }

    struct SettingAccount {
        address deployer;
        address superAccount; // ETH With Raised Amount
        address payable fundAddress;
        address lptoLock;
    }

    struct TeamVestingInfo {
        uint256 teamTotalVestingTokens;
        uint256 teamCliffVesting; //First token release after listing (minutes)
        uint256 teamFirstReleasePercent;
        uint256 teamVestingPeriodEachCycle;
        uint256 teamTokenReleaseEachCycle;
    }

    struct CalculateTokenInput {
        address feeToken;
        uint256 presaleRate;
        uint256 hardCap;
        uint256 raisedTokenFeePercent;
        uint256 raisedFeePercent;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../interfaces/IPositionRouterCallbackReceiver.sol";

contract PositionRouterCallbackReceiverTest is IPositionRouterCallbackReceiver {
    event CallbackCalled(
        bytes32 positionKey,
        bool isExecuted,
        bool isIncrease
    );

    function bxpPositionCallback(bytes32 positionKey, bool isExecuted, bool isIncrease) override external {
        emit CallbackCalled(positionKey, isExecuted, isIncrease);
    }
}

// SPDX-License-Identifier: MIT

import "../ShortsTracker.sol";

pragma solidity 0.6.12;

contract ShortsTrackerTest is ShortsTracker {
    constructor(address _vault) public ShortsTracker(_vault) {}

    function getNextGlobalShortDataWithRealisedPnl(
       address _indexToken,
       uint256 _nextPrice,
       uint256 _sizeDelta,
       int256 _realisedPnl,
       bool _isIncrease
    ) public view returns (uint256, uint256) {
        uint256 averagePrice = globalShortAveragePrices[_indexToken];
        uint256 priceDelta = averagePrice > _nextPrice ? averagePrice.sub(_nextPrice) : _nextPrice.sub(averagePrice);

        uint256 nextSize;
        uint256 delta;
        // avoid stack to deep
        {
            uint256 size = vault.globalShortSizes(_indexToken);
            nextSize = _isIncrease ? size.add(_sizeDelta) : size.sub(_sizeDelta);

            if (nextSize == 0) {
                return (0, 0);
            }

            if (averagePrice == 0) {
                return (nextSize, _nextPrice);
            }

            delta = size.mul(priceDelta).div(averagePrice);
        }

        uint256 nextAveragePrice = _getNextGlobalAveragePrice(
            averagePrice,
            _nextPrice,
            nextSize,
            delta,
            _realisedPnl
        );

        return (nextSize, nextAveragePrice);
    }

    function setGlobalShortAveragePrice(address _token, uint256 _averagePrice) public {
        globalShortAveragePrices[_token] = _averagePrice;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../Vault.sol";

contract VaultTest is Vault {
    function increaseGlobalShortSize(address token, uint256 amount) external {
        _increaseGlobalShortSize(token, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


import "../libraries/access/Ownable.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/EnumerableSet.sol";
import "../libraries/math/SafeMath.sol";

import "./structs/Fairlaunch.sol";
import "./interfaces/ILPTOLock.sol";
import "./interfaces/ISPERC20.sol";


contract Fairlaunch is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ISPERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private whiteListUsers;
    EnumerableSet.AddressSet private superAccounts;


    modifier onlyWhiteListUser() {
        require(whiteListUsers.contains(msg.sender), "Only Admin");
        _;
    }

    modifier onlySuperAccount() {
        require(superAccounts.contains(msg.sender), "Only Super");
        _;
    }

    modifier onlyRunningPool() {
        require(state == 1, "Not available pool");
        _;
    }

    function addWhiteListUsers(address[] memory _user) public onlyWhiteListUser {
        for (uint i = 0; i < _user.length; i++) {
            whiteListUsers.add(_user[i]);
        }
    }

    function removeWhiteListUsers(address[] memory _user) public onlyWhiteListUser {
        for (uint i = 0; i < _user.length; i++) {
            whiteListUsers.remove(_user[i]);
         }
    }

    ISPERC20 public icoToken;
    address public feeToken; //USDT, ETH
    uint256 public softCap;

    uint256 public maxInvest;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public currentPrice = 0;

    bool public affiliate; 
    uint256 public percentAffiliate;
    uint256 public affiliateReward;

    uint256 public state; // 1 running||available, 2 finalize, 3 cancel
    uint256 public raisedAmount; 
    address public signer;
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public penaltyFee = 1000;

    // Lock
    ILPTOLock public lptoLock;

    //fee
    uint256 public raisedFeePercent; // % Raised Amount
    uint256 public raisedTokenFeePercent;

    address payable public fundAddress;

    address public deadAddress = address(0x0000dead);
    uint256 public totalRaise = 0;

    struct JoinInfo {
        uint256 totalInvestment;
        uint256 totalTokens;
    }

    mapping(address => JoinInfo) public joinInfos;
    EnumerableSet.AddressSet private _joinedUsers; // set of joined users

    event Invest(address investor, uint value, uint tokens);
    event Buy(uint256 indexed _saleId, uint256 indexed _quantity, uint256 indexed _price, address _buyer, address _seller);
    event UpdateSaleQuantity(uint256 indexed _saleId, address indexed _seller, uint256 indexed _quantity, uint256 _status);
    event UpdateSalePrice(uint256 indexed _saleId, address indexed _seller, uint256 indexed _price);
    event CancelListed(uint256 indexed _saleId, address indexed _receiver);
    event List(uint indexed _saleId, uint256 indexed _price, uint256 indexed _quantity, address _owner, uint256 _tokenId, uint256 status);
    event TokenClaimed(address _address, uint256 tokensClaimed);


    function setFundAddress(address payable _fundAddress) public onlySuperAccount {
        fundAddress = _fundAddress;
    }

    function setSigner(address _signer) public onlySuperAccount {
        signer = _signer;
    }

    function setPenaltyFee(uint256 _penaltyFee) public onlySuperAccount {
        penaltyFee = _penaltyFee;
    }

    bool public isMaxinvest;

    constructor(
        FairlaunchStructs.FairlaunchInfo memory info, 
        FairlaunchStructs.FeeSystem memory feeInfo, 
        FairlaunchStructs.SettingAccount memory settingAccount,
        uint256 _percentAffiliate
    )public {
        require(info.icoToken != address(0), 'token');
        require(info.softCap > 0, 'cap');
        require(info.startTime < info.endTime, 'time');
        isMaxinvest = info.isMaxinvest;
        if (info.isMaxinvest) {
            require(info.maxInvest > 0, 'invest');
        }

        totalRaise = info.totalIcoToken;
        icoToken = ISPERC20(info.icoToken);
        feeToken = info.feeToken;
        softCap = info.softCap;
        
   
        maxInvest = info.maxInvest;
        startTime = info.startTime;
        endTime = info.endTime;

        percentAffiliate = _percentAffiliate;
        affiliate = info.affiliate;


        raisedFeePercent = feeInfo.raisedFeePercent;
        raisedTokenFeePercent = feeInfo.raisedTokenFeePercent;
        penaltyFee = feeInfo.penaltyFee;


        state = 1;
        whiteListUsers.add(settingAccount.deployer);
        whiteListUsers.add(settingAccount.superAccount);
        superAccounts.add(settingAccount.superAccount);

        signer = settingAccount.signer;
        fundAddress = settingAccount.fundAddress;
        transferOwnership(settingAccount.deployer);
        lptoLock = ILPTOLock(settingAccount.lptoLock);
    }

    mapping(address => uint256) public award;
    uint256 totalReferred = 0;

    function setAffiliate(uint256 _percent) public onlyWhiteListUser {
        require(block.timestamp <= endTime, "Invalid Time");
        require(state == 1, "Can not update affiliate");
        require(_percent >= 100 && _percent <= 1000, "Invalid percent");
        affiliate = true;
        percentAffiliate = _percent;
    }

    function contribute(uint256 _amount, address _leader) external payable onlyRunningPool {
        require(startTime <= block.timestamp && endTime >= block.timestamp, 'Invalid time');
        require(_leader != _msgSender(), "Invalid leader");

        JoinInfo storage joinInfo = joinInfos[_msgSender()];
        if (isMaxinvest) {
            require(joinInfo.totalInvestment.add(_amount) <= maxInvest, 'Invalid amount');
        }

        uint256 feeTokenDecimals = 18;
        uint256 feeRaisedTokenDecimals = icoToken.decimals();
        if (feeToken != address(0)) {
            feeTokenDecimals = ISPERC20(feeToken).decimals();
        }

        joinInfo.totalInvestment = joinInfo.totalInvestment.add(_amount);

        raisedAmount = raisedAmount.add(_amount);
        currentPrice = (totalRaise.mul(10 **(18 - feeRaisedTokenDecimals))).div(raisedAmount.mul(10 ** (18 - feeTokenDecimals)));
        _joinedUsers.add(_msgSender());

        if (feeToken == address(0)) {
            require(msg.value >= _amount, 'Invalid Amount');
        } else {
            ISPERC20 feeTokenErc20 = ISPERC20(feeToken);
            feeTokenErc20.safeTransferFrom(_msgSender(), address(this), _amount);
        }
        if (_leader != address(0) && affiliate){
            award[_leader] = award[_leader].add(_amount);
            totalReferred = totalReferred.add(_amount);
        }
    }

    function cancelLaunchpad() external onlyWhiteListUser onlyRunningPool {
        state = 3;
    }

    function finalizeFairLaunch() external onlyWhiteListUser onlyRunningPool {
        require(block.timestamp > startTime, 'Not start');

        if (block.timestamp >= endTime) {
            require(raisedAmount >= softCap, 'Not meet soft cap');
        }
        state = 2;
        affiliateReward = raisedAmount.mul(percentAffiliate).div(BASIS_POINTS_DIVISOR);
      
        uint256 totalRaisedFeeTokens = totalRaise.mul(raisedTokenFeePercent).div(BASIS_POINTS_DIVISOR);
        uint256 totalRaisedFee = raisedAmount.mul(raisedFeePercent).div(BASIS_POINTS_DIVISOR);
        if (totalRaisedFeeTokens > 0) {
            icoToken.safeTransfer(fundAddress, totalRaisedFeeTokens);
        }
        if (totalRaisedFee > 0) {
            if (feeToken == address(0)) {
                payable(fundAddress).transfer(totalRaisedFee);
            } else {
                ISPERC20(feeToken).safeTransfer(fundAddress, totalRaisedFee);
            }
        }
        uint256 raisedAmountToOwner = raisedAmount.sub(affiliateReward).sub(totalRaisedFee); 

        if (raisedAmountToOwner > 0) {
            if (feeToken == address(0)) {
                payable(owner()).transfer(raisedAmountToOwner);
            } else {
                ISPERC20(feeToken).safeTransfer(owner(), raisedAmountToOwner);
            }
        }
    }

    function claimCommission() public {
        require(state == 2 && award[_msgSender()] >0 ,"You can not claim awards");
        uint256 amount = award[_msgSender()].mul(affiliateReward).div(totalReferred);
        award[_msgSender()] = 0;
        if (feeToken == address(0)) {
            payable(_msgSender()).transfer(amount);
        }
        else {
            ISPERC20 token = ISPERC20(feeToken);
            token.safeTransfer(_msgSender(), amount);
        }
    }

    function claimCanceledTokens() external onlyWhiteListUser {
        require(state == 3, 'Not cancel');
        uint256 balance = icoToken.balanceOf(address(this));
        require(balance > 0, "Claimed");
        if (balance > 0) {
            icoToken.safeTransfer(_msgSender(), balance);
        }
    }

    function withdrawContribute() external {
        JoinInfo storage joinInfo = joinInfos[_msgSender()];
        require((state == 3) || (raisedAmount < softCap && block.timestamp > endTime));
        require(joinInfo.totalInvestment > 0, 'Not Invest');

        uint256 totalWithdraw = joinInfo.totalInvestment;
        joinInfo.totalTokens = 0;
        joinInfo.totalInvestment = 0;

        raisedAmount = raisedAmount.sub(totalWithdraw);

        _joinedUsers.remove(_msgSender());

        if (feeToken == address(0)) {
            require(address(this).balance > 0, 'Insufficient blc');
            payable(_msgSender()).transfer(totalWithdraw);
        } else {
            ISPERC20 feeTokenErc20 = ISPERC20(feeToken);

            require(feeTokenErc20.balanceOf(address(this)) >= totalWithdraw, 'Insufficient Balance');
            feeTokenErc20.safeTransfer(_msgSender(), totalWithdraw);
        }
    }

    function emergencyWithdrawContribute() external onlyRunningPool {
        JoinInfo storage joinInfo = joinInfos[_msgSender()];
        require(startTime <= block.timestamp && endTime >= block.timestamp, 'Invalid time');
        require(joinInfo.totalInvestment > 0, 'Not contribute');

        uint256 penalty = joinInfo.totalInvestment.mul(penaltyFee).div(BASIS_POINTS_DIVISOR);
        uint256 refundTokens = joinInfo.totalInvestment.sub(penalty);
        raisedAmount = raisedAmount.sub(joinInfo.totalInvestment);


        //joinInfo.refund = true;
        joinInfo.totalTokens = 0;
        joinInfo.totalInvestment = 0;
        _joinedUsers.remove(_msgSender());

        require(refundTokens > 0, 'Invalid rf amount');

        if (feeToken == address(0)) {
            if (refundTokens > 0) {
                payable(_msgSender()).transfer(refundTokens);
            }

            if (penalty > 0) {
                payable(fundAddress).transfer(penalty);
            }

        } else {
            ISPERC20 feeTokenErc20 = ISPERC20(feeToken);
            if (refundTokens > 0) {
                feeTokenErc20.safeTransfer(_msgSender(), refundTokens);
            }

            if (penalty > 0) {
                feeTokenErc20.safeTransfer(fundAddress, penalty);
            }
        }
    }


    function claimTokens() external  {
        JoinInfo storage joinInfo = joinInfos[_msgSender()];
        require(state == 2, "Not finalize");

        uint256 claimableTokens = _getUserClaimAble(joinInfo);
        require(claimableTokens > 0, 'Zero token');
        joinInfo.totalInvestment = 0;

        joinInfo.totalTokens = claimableTokens;
        icoToken.safeTransfer(_msgSender(), claimableTokens);
        
    }

    function getUserClaimAble(address _sender) external view returns (uint256) {
        JoinInfo storage joinInfo = joinInfos[_sender];
        return _getUserClaimAble(joinInfo);
    }

    function _getUserClaimAble(JoinInfo memory joinInfo)
    internal
    view
    returns (uint256)
    {
        uint256 claimableTokens = 0;
        uint256 feeTokenDecimals = 18;
        uint256 feeRaisedTokenDecimals = icoToken.decimals();
        if (feeToken != address(0)) {
            feeTokenDecimals = ISPERC20(feeToken).decimals();
        }
        if (state != 2) {
            claimableTokens = 0;
        } else {
            claimableTokens = feeTokenDecimals >= feeRaisedTokenDecimals ? joinInfo.totalInvestment.mul(currentPrice).div((10 ** (feeTokenDecimals - feeRaisedTokenDecimals))) : joinInfo.totalInvestment.mul(currentPrice).mul(10 ** (feeRaisedTokenDecimals-feeTokenDecimals));
        }
        
        return claimableTokens;
    }


    function getFairlaunchInfo() external view returns (FairlaunchStructs.FairlaunchReturnInfo memory) {
        uint256 balance = icoToken.balanceOf(address(this));

        FairlaunchStructs.FairlaunchReturnInfo memory result;
        result.softCap = softCap;
        result.totalIcoToken = totalRaise;
        result.startTime = startTime;
        result.endTime = endTime;
        result.state = state;
        result.raisedAmount = raisedAmount;
        result.balance = balance;
        result.feeToken = feeToken;

        return result;
    }

    function getJoinedUsers()
    external
    view
    returns (address[] memory)
    {
        uint256 start = 0;
        uint256 end = _joinedUsers.length();
        if (end == 0) {
            return new address[](0);
        }
        uint256 length = end - start;
        address[] memory result = new address[](length);
        uint256 index = 0;
        for (uint256 i = end; i < start; i--) {
            result[index] = _joinedUsers.at(i);
            index++;
        }
        return result;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../libraries/math/SafeMath.sol";

import "./interfaces/ISPERC20.sol";
import "./structs/Fairlaunch.sol";
import "./TokenOfferingFairlaunch.sol";


contract TokenOfferingFairlaunchFactory is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ISPERC20;

    address public signer;
    address public superAccount;
    address public lptoLock;
    address payable public fundAddress;
    uint256 public percentAffiliate;

    event NewOfferingFairlaunch(address indexed launchpad);

    uint256 public constant BASIS_POINT_DIVISOR = 10000;

    constructor(address _signer, address _superAccount, address _lptoLock, address payable _fundAddress) public {
        require(_signer != address(0) && _signer != address(this), 'signer');
        require(_lptoLock != address(0) && _lptoLock != address(this), 'lptoLock');
        require(_superAccount != address(0) && _superAccount != address(this), 'superAccount');
        require(_fundAddress != address(0) && _fundAddress != address(this), 'fundAddress');

        signer = _signer;
        superAccount = _superAccount;
        fundAddress = _fundAddress;
        lptoLock = _lptoLock;
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function setSuperAccount(address _superAccount) public onlyOwner {
        superAccount = _superAccount;
    }

    function setlptoLock(address _lptoLock) public onlyOwner {
        lptoLock = _lptoLock;
    }

    function setFundAddress(address payable _fundAddress) public onlyOwner {
        fundAddress = _fundAddress;
    }

    function deployFairlaunch(
        FairlaunchStructs.FairlaunchInfo memory info, 
        FairlaunchStructs.FeeSystem memory feeInfo, 
        uint256 _percentAffiliate
    ) external payable {
        require(signer != address(0) && superAccount != address(0) && fundAddress != address(0), 'Can not create launchpad now!');
        require(msg.value >= feeInfo.initFee, 'Not enough fee!');
        if (!info.affiliate) {
            percentAffiliate = 0;
        } else {
            require(_percentAffiliate >= 100 && _percentAffiliate <= 1000, "invalid");
            percentAffiliate = _percentAffiliate;
        }

        FairlaunchStructs.SettingAccount memory settingAccount = FairlaunchStructs.SettingAccount(
            _msgSender(),
            signer,
            superAccount,
            payable(fundAddress),
            lptoLock
        );

        ISPERC20 icoToken = ISPERC20(info.icoToken);
        uint256 totalListing = info.totalIcoToken.mul(BASIS_POINT_DIVISOR.sub(feeInfo.raisedFeePercent)).div(BASIS_POINT_DIVISOR **2).add(info.totalIcoToken.mul(feeInfo.raisedTokenFeePercent).div(BASIS_POINT_DIVISOR));//0 if manual listing
        uint256 totalTokenNeeded = info.totalIcoToken.add(totalListing);

        Fairlaunch fairLaunch = new Fairlaunch(info, feeInfo, settingAccount, percentAffiliate);

        if (msg.value > 0) {
            payable(fundAddress).transfer(msg.value);
        }

        if (totalTokenNeeded > 0) {
            ISPERC20 icoTokenErc20 = ISPERC20(info.icoToken);

            require(icoTokenErc20.balanceOf(_msgSender()) >= totalTokenNeeded, 'Insufficient Balance');
            require(icoTokenErc20.allowance(_msgSender(), address(this)) >= totalTokenNeeded, 'Insufficient Allowance');
            require(icoToken.transferFrom(_msgSender(), address(fairLaunch), totalTokenNeeded),"transfer failed");
        }
        emit NewOfferingFairlaunch(address(fairLaunch));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../libraries/access/Ownable.sol";
import "../libraries/math/SafeMath.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/EnumerableSet.sol";


import "./structs/Launchpad.sol";
import "./interfaces/ILPTOLock.sol";
import "./interfaces/ISPERC20.sol";


contract Launchpad is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ISPERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private whiteListUsers;
    EnumerableSet.AddressSet private superAccounts;
    EnumerableSet.AddressSet private whiteListBuyers;

    modifier onlyWhiteListUser() {
        require(whiteListUsers.contains(msg.sender), "Only Admin");
        _;
    }

    modifier onlySuperAccount() {
        require(superAccounts.contains(msg.sender), "Only Super");
        _;
    }

    modifier onlyRunningPool() {
        require(state == 1, "Not available pool");
        _;
    }

    function addWhiteListUsers(address[] memory _user) public onlyWhiteListUser {
        for (uint i = 0; i < _user.length; i++) {
            whiteListUsers.add(_user[i]);
        }
    }


    function removeWhiteListUsers(address[] memory _user) public onlyWhiteListUser {
        for (uint i = 0; i < _user.length; i++) {
            whiteListUsers.remove(_user[i]);
        }
    }

    ISPERC20 public icoToken;
    address public feeToken; //USDT, ETH
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public presaleRate; // 1ETH or USDT ~ presaleRate
    uint256 public minInvest;
    uint256 public maxInvest;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public poolType; //0 burn, 1 refund
    uint256 public whitelistPool;  //0 public, 1 whitelist, 2 public anti bot
    address public holdingToken;
    uint256 public holdingTokenAmount;
    bool public affiliate; 
    uint256 public percentAffiliate;
    uint256 public affiliateReward;

    // contribute vesting
    uint256 public cliffVesting; //First gap release after listing (minutes)
    uint256 public lockAfterCliffVesting; //second gap release after cliff (minutes)
    uint256 public firstReleasePercent; // 0 is not vesting
    uint256 public vestingPeriodEachCycle; //0 is not vesting
    uint256 public tokenReleaseEachCycle; //percent: 0 is not vesting

    //team vesting
    uint256 public teamTotalVestingTokens; // if > 0, lock
    uint256 public teamCliffVesting; //First gap release after listing (minutes)
    uint256 public teamFirstReleasePercent; // 0 is not vesting
    uint256 public teamVestingPeriodEachCycle; // 0 is not vesting
    uint256 public teamTokenReleaseEachCycle; //percent: 0 is not vesting


    uint256 public listingTime;

    uint256 public state; // 1 running||available, 2 finalize, 3 cancel
    uint256 public raisedAmount; // 1 running, 2 cancel
    address public signer;
    uint256 public constant BASIS_POINT_DIVISOR = 10000;
    uint256 public penaltyFee = 1000;

    // dex
    bool public manualListing;
    address public factoryAddress;
    address public routerAddress;
    uint256 public listingPrice;
    uint256 public listingPercent; //1 => 10000
    uint256 public lpLockTime; //seconds

    ILPTOLock public lptoLock;
    uint256 public lpLockId;
    uint256 public teamLockId;

    //fee
    uint256 public raisedFeePercent; // % With Raised Amount
    uint256 public raisedTokenFeePercent;

    address payable public fundAddress;
    uint256 public totalSoldTokens;

    //address public deadAddress = address(0x0000dead);
    uint256 public maxLiquidity = 0;


    struct JoinInfo {
        uint256 totalInvestment;
        uint256 claimedTokens;
        uint256 totalTokens;
        bool refund;
    }

    mapping(address => JoinInfo) public joinInfos;
    EnumerableSet.AddressSet private _joinedUsers; // set of joined users

    struct InfoAffiliate {
        uint256 yourReward;
        uint256 poolReferrerCount;
        uint256 maxReward;
        uint256 totalRefAmount;
        uint256 totalReward;
        address[] users;
        uint256[] amounts;
    }

    mapping(address => InfoAffiliate) public award;
    uint256 totalReferred = 0;

    event Invest(address investor, uint value, uint tokens);
    event Buy(uint256 indexed _saleId, uint256 indexed _quantity, uint256 indexed _price, address _buyer, address _seller);
    event UpdateSaleQuantity(uint256 indexed _saleId, address indexed _seller, uint256 indexed _quantity, uint256 _status);
    event UpdateSalePrice(uint256 indexed _saleId, address indexed _seller, uint256 indexed _price);
    event CancelListed(uint256 indexed _saleId, address indexed _receiver);
    event List(uint indexed _saleId, uint256 indexed _price, uint256 indexed _quantity, address _owner, uint256 _tokenId, uint256 status);
    event TokenClaimed(address _address, uint256 tokensClaimed);

    constructor(
        LaunchpadStructs.LaunchpadInfo memory info, 
        LaunchpadStructs.ClaimInfo memory userClaimInfo, 
        LaunchpadStructs.TeamVestingInfo memory teamVestingInfo,
        LaunchpadStructs.FeeSystem memory feeInfo, 
        LaunchpadStructs.SettingAccount memory settingAccount,
        uint256 _percentAffiliate
    ) public {
        require(info.icoToken != address(0), 'TOKEN');
        require(info.presaleRate > 0, 'PRESALE');
        require(info.softCap < info.hardCap, 'CAP');
        require(info.startTime < info.endTime, 'TIME');
        require(info.minInvest < info.maxInvest, 'INVEST');
        require(userClaimInfo.firstReleasePercent.add(userClaimInfo.tokenReleaseEachCycle) <= BASIS_POINT_DIVISOR , 'VESTING');
        require(teamVestingInfo.teamFirstReleasePercent.add(teamVestingInfo.teamTokenReleaseEachCycle) <= BASIS_POINT_DIVISOR, 'Invalid team vst');
        
        icoToken = ISPERC20(info.icoToken);
        feeToken = info.feeToken;
        softCap = info.softCap;
        hardCap = info.hardCap;
        presaleRate = info.presaleRate;
        minInvest = info.minInvest;
        maxInvest = info.maxInvest;
        startTime = info.startTime;
        endTime = info.endTime;
        whitelistPool = info.whitelistPool;
        poolType = info.poolType;
        percentAffiliate = _percentAffiliate;
        affiliate = info.affiliate;

        cliffVesting = userClaimInfo.cliffVesting;
        lockAfterCliffVesting = userClaimInfo.lockAfterCliffVesting;
        firstReleasePercent = userClaimInfo.firstReleasePercent;
        vestingPeriodEachCycle = userClaimInfo.vestingPeriodEachCycle;
        tokenReleaseEachCycle = userClaimInfo.tokenReleaseEachCycle;

        teamTotalVestingTokens = teamVestingInfo.teamTotalVestingTokens;
        if (teamTotalVestingTokens > 0) {
            require(teamVestingInfo.teamFirstReleasePercent > 0 &&
            teamVestingInfo.teamVestingPeriodEachCycle > 0 &&
            teamVestingInfo.teamTokenReleaseEachCycle > 0 &&
                teamVestingInfo.teamFirstReleasePercent.add(teamVestingInfo.teamTokenReleaseEachCycle) <= BASIS_POINT_DIVISOR,"Invalid teamvestinginfo");
            teamCliffVesting = teamVestingInfo.teamCliffVesting;
            teamFirstReleasePercent = teamVestingInfo.teamFirstReleasePercent;
            teamVestingPeriodEachCycle = teamVestingInfo.teamVestingPeriodEachCycle;
            teamTokenReleaseEachCycle = teamVestingInfo.teamTokenReleaseEachCycle;
        }
        raisedFeePercent = feeInfo.raisedFeePercent;
        raisedTokenFeePercent = feeInfo.raisedTokenFeePercent;
        penaltyFee = feeInfo.penaltyFee;


        state = 1;
        whiteListUsers.add(settingAccount.deployer);
        whiteListUsers.add(settingAccount.superAccount);
        superAccounts.add(settingAccount.superAccount);

        fundAddress = settingAccount.fundAddress;
        transferOwnership(settingAccount.deployer);
        lptoLock = ILPTOLock(settingAccount.lptoLock);
    }

    function calculateUserTotalTokens(uint256 _amount) private view returns (uint256) {
        uint256 feeTokenDecimals = 18;
        if (feeToken != address(0)) {
            feeTokenDecimals = ISPERC20(feeToken).decimals();
        }
        return _amount.mul(presaleRate).div(10 ** feeTokenDecimals);
    }

    function setWhitelistBuyers(address[] memory _buyers) public onlyWhiteListUser {
        for (uint i = 0; i < _buyers.length; i++) {
            whiteListBuyers.add(_buyers[i]);
         }
    }

    function removeWhitelistBuyers(address[] memory _buyers) public onlyWhiteListUser {
        for (uint i = 0; i < _buyers.length; i++) {
            whiteListBuyers.remove(_buyers[i]);
         }
    }

    function allAllocationCount() public view returns (uint256) {
        return whiteListBuyers.length();
    }

    function getAllocations(uint256 start, uint256 end) 
        external
        view
        returns(address[] memory ) 
        
    {
        require(end > start && end <= allAllocationCount(), "Invalid");
        address[] memory allocations = new address[](end.sub(start));
        uint count = 0;
        for (uint256 i = start; i < end; i++) {
            allocations[count] = whiteListBuyers.at(i); 
            count++ ;
        }
        return allocations;
    }

    function setAffiliate(uint256 _percent) public onlyWhiteListUser {
        //require(block.timestamp <= endTime, "Invalid Time");
        require(state == 1, "Can not update affiliate");
        require(_percent >= 100 && _percent <= 1000, "Invalid percent");
        affiliate = true;
        percentAffiliate = _percent;
    }



    // function contribute(uint256 _amount, bytes calldata _sig) external payable onlyRunningPool {
    function contribute(uint256 _amount, address _presenter) external payable  onlyRunningPool {
        require(startTime <= block.timestamp && endTime >= block.timestamp, 'Invalid time');
        require(_presenter != _msgSender(), "Invalid presenter");
        if (whitelistPool == 1) {
            require(whiteListBuyers.contains(_msgSender()), "You are not in whitelist");
        } else if (whitelistPool == 2) {
            require(ISPERC20(holdingToken).balanceOf(_msgSender()) >= holdingTokenAmount, 'Insufficient holding');
        }
        JoinInfo storage joinInfo = joinInfos[_msgSender()];
        require(joinInfo.totalInvestment.add(_amount) >= minInvest && joinInfo.totalInvestment.add(_amount) <= maxInvest, 'Invalid amount');
        require(raisedAmount.add(_amount) <= hardCap, 'Meet hard cap');


        joinInfo.totalInvestment = joinInfo.totalInvestment.add(_amount);

        uint256 newTotalSoldTokens = calculateUserTotalTokens(_amount);
        totalSoldTokens = totalSoldTokens.add(newTotalSoldTokens);
        joinInfo.totalTokens = joinInfo.totalTokens.add(newTotalSoldTokens);
        joinInfo.refund = false;

        raisedAmount = raisedAmount.add(_amount);
        _joinedUsers.add(_msgSender());


        if (feeToken == address(0)) {
            require(msg.value >= _amount, 'Invalid Amount');
        } else {
            ISPERC20 feeTokenErc20 = ISPERC20(feeToken);
            feeTokenErc20.safeTransferFrom(_msgSender(), address(this), _amount);
        }
        if (_presenter != address(0) && affiliate){
            award[_presenter].totalRefAmount = award[_presenter].totalRefAmount.add(_amount);
            award[_presenter].poolReferrerCount = award[_presenter].poolReferrerCount.add(1);
            award[_presenter].users.push(_msgSender());
            award[_presenter].amounts.push(_amount);
            award[_presenter].yourReward = award[_presenter].totalRefAmount.mul(affiliateReward).div(totalReferred);
            award[_presenter].maxReward = hardCap.mul(percentAffiliate).div(BASIS_POINT_DIVISOR);
            award[_presenter].totalReward = affiliateReward;
            totalReferred = totalReferred.add(_amount);
        }
    }


    function cancelLaunchpad() external onlyWhiteListUser onlyRunningPool {
        state = 3;
    }

    function setClaimTime(uint256 _listingTime) external onlyWhiteListUser {
        require(state == 2 && _listingTime > 0, "TIME");
        listingTime = _listingTime;
    }


    function setWhitelistPool(uint256 _wlPool, address _holdingToken, uint256 _amount) external onlyWhiteListUser {
        require(_wlPool < 2 ||
            (_wlPool == 2 && _holdingToken != address(0) && ISPERC20(_holdingToken).totalSupply() > 0 && _amount > 0), 'Invalid setting');
        holdingToken = _holdingToken;
        holdingTokenAmount = _amount;
        whitelistPool = _wlPool;
    }

    function finalizeLaunchpad() external onlyWhiteListUser onlyRunningPool {
        require(block.timestamp > startTime, 'Not start');

        if (block.timestamp < endTime) {
            require(raisedAmount >= hardCap, 'Cant finalize');
        }
        if (block.timestamp >= endTime) {
            require(raisedAmount >= softCap, 'Not meet soft cap');
        }
        state = 2;

        uint256 feeTokenDecimals = 18;
        if (feeToken != address(0)) {
            feeTokenDecimals = ISPERC20(feeToken).decimals();
        }
        affiliateReward = raisedAmount.add(percentAffiliate).div(BASIS_POINT_DIVISOR);

        raisedAmount = raisedAmount.sub(affiliateReward); 

        uint256 totalRaisedFeeTokens = raisedAmount.mul(presaleRate).mul(raisedTokenFeePercent).div(10 ** feeTokenDecimals).div(BASIS_POINT_DIVISOR);

        uint256 totalRaisedFee = raisedAmount.mul(raisedFeePercent).div(BASIS_POINT_DIVISOR);

        // 0 if listingPercent = 0
        uint256 totalFeeTokensToOwner = raisedAmount.sub(totalRaisedFee);
        uint256 icoLaunchpadBalance = icoToken.balanceOf(address(this));
        uint256 totalRefundOrBurnTokens = icoLaunchpadBalance.sub(totalSoldTokens).sub(totalRaisedFeeTokens);

        if (totalRaisedFeeTokens > 0) {
            icoToken.safeTransfer(fundAddress, totalRaisedFeeTokens);
        }

        if (totalRefundOrBurnTokens > 0) {
            if (poolType == 0) {
                icoToken.safeTransfer(address(0), totalRefundOrBurnTokens);
            } else {
                icoToken.safeTransfer(owner(), totalRefundOrBurnTokens);
            }
        }


        if (feeToken == address(0)) {
            if (totalFeeTokensToOwner > 0) {
                payable(owner()).transfer(totalFeeTokensToOwner);
            }
            if (totalRaisedFee > 0) {
                payable(fundAddress).transfer(totalRaisedFee);
            }

        } else {
            if (totalFeeTokensToOwner > 0) {
                ISPERC20(feeToken).safeTransfer(owner(), totalFeeTokensToOwner);
            }
            if (totalRaisedFee > 0) {
                ISPERC20(feeToken).safeTransfer(fundAddress, totalRaisedFee);
            }
        }

        if (teamTotalVestingTokens > 0) {
            icoToken.approve(address(lptoLock), teamTotalVestingTokens);
            teamLockId = lptoLock.vestingLock(
                owner(),
                address(icoToken),
                false,
                teamTotalVestingTokens,
                listingTime+(teamCliffVesting),
                teamFirstReleasePercent,
                teamVestingPeriodEachCycle,
                teamTokenReleaseEachCycle,
                'TEAM'
            );
        }
    }

    function claimCommission() public {
        require(state == 2 && award[_msgSender()].totalRefAmount>0 ,"You can not claim awards");
        uint256 amount = award[_msgSender()].totalRefAmount.mul(affiliateReward).div(totalReferred);
        award[_msgSender()].totalRefAmount= 0;
        if (feeToken == address(0)) {
            payable(_msgSender()).transfer(amount);
        }
        else {
            ISPERC20 token = ISPERC20(feeToken);
            token.safeTransfer(_msgSender(), amount);
        }
    }

    function claimCanceledTokens() external onlyWhiteListUser {
        require(state == 3, 'Not cancel');
        uint256 balance = icoToken.balanceOf(address(this));
        require(balance > 0, "Claimed");
        if (balance > 0) {
            icoToken.safeTransfer(_msgSender(), balance);
        }
    }

    function emergencyWithdrawPool(address _token, uint256 _amount) external onlySuperAccount {
        require(_amount > 0, 'Invalid amount');
        if (_token == address(0)) {
            payable(_msgSender()).transfer(_amount);
        }
        else {
            ISPERC20 token = ISPERC20(_token);
            token.safeTransfer(_msgSender(), _amount);
        }
    }


    function withdrawContribute() external  {
        JoinInfo storage joinInfo = joinInfos[_msgSender()];
        require((state == 3) || (raisedAmount < softCap && block.timestamp > endTime));
        require(joinInfo.refund == false, 'Refunded');
        require(joinInfo.totalInvestment > 0, 'Not Invest');

        uint256 totalWithdraw = joinInfo.totalInvestment;
        joinInfo.refund = true;
        joinInfo.totalTokens = 0;
        joinInfo.totalInvestment = 0;

        raisedAmount = raisedAmount.sub(totalWithdraw);

        totalSoldTokens = totalSoldTokens.sub(joinInfo.totalTokens);

        _joinedUsers.remove(_msgSender());

        if (feeToken == address(0)) {
            require(address(this).balance > 0, 'Insufficient blc');
            payable(_msgSender()).transfer(totalWithdraw);
        } else {
            ISPERC20 feeTokenErc20 = ISPERC20(feeToken);

            require(feeTokenErc20.balanceOf(address(this)) >= totalWithdraw, 'Insufficient Balance');
            feeTokenErc20.safeTransfer(_msgSender(), totalWithdraw);
        }
    }

    function emergencyWithdrawContribute() external  onlyRunningPool {
        JoinInfo storage joinInfo = joinInfos[_msgSender()];
        require(startTime <= block.timestamp && endTime >= block.timestamp, 'Invalid time');
        require(joinInfo.refund == false, 'Refunded');
        require(joinInfo.totalInvestment > 0, 'Not contribute');

        uint256 penalty = joinInfo.totalInvestment.mul(penaltyFee).div(BASIS_POINT_DIVISOR);
        uint256 refundTokens = joinInfo.totalInvestment.sub(penalty);
        raisedAmount = raisedAmount.sub(joinInfo.totalInvestment);
        totalSoldTokens = totalSoldTokens.sub(joinInfo.totalTokens);


        joinInfo.refund = true;
        joinInfo.totalTokens = 0;
        joinInfo.totalInvestment = 0;
        _joinedUsers.remove(_msgSender());

        require(refundTokens > 0, 'Invalid rf amount');

        if (feeToken == address(0)) {
            if (refundTokens > 0) {
                payable(_msgSender()).transfer(refundTokens);
            }

            if (penalty > 0) {
                payable(fundAddress).transfer(penalty);
            }

        } else {
            ISPERC20 feeTokenErc20 = ISPERC20(feeToken);
            if (refundTokens > 0) {
                feeTokenErc20.safeTransfer(_msgSender(), refundTokens);
            }

            if (penalty > 0) {
                feeTokenErc20.safeTransfer(fundAddress, penalty);
            }
        }
    }


    function claimTokens() external  {
        JoinInfo storage joinInfo = joinInfos[_msgSender()];
        require(joinInfo.claimedTokens < joinInfo.totalTokens, "Claimed");
        require(state == 2, "Not finalize");
        require(joinInfo.refund == false, "Refunded!");


        uint256 claimableTokens = _getUserClaimAble(joinInfo);
        require(claimableTokens > 0, 'Zero token');

        uint256 claimedTokens = joinInfo.claimedTokens.add(claimableTokens);
        joinInfo.claimedTokens = claimedTokens;
        icoToken.safeTransfer(_msgSender(), claimableTokens);
    }

    function getUserClaimAble(address _sender) external view returns (uint256) {
        JoinInfo storage joinInfo = joinInfos[_sender];
        return _getUserClaimAble(joinInfo);
    }

    function _getUserClaimAble(JoinInfo memory joinInfo)
    internal
    view
    returns (uint256)
    {
        uint256 claimableTokens = 0;
        if (state != 2 || joinInfo.totalTokens == 0 || joinInfo.refund == true || joinInfo.claimedTokens >= joinInfo.totalTokens || listingTime == 0 || block.timestamp < listingTime.add(cliffVesting)) {
            return claimableTokens;
        }
        uint256 currentTotal = 0;
        if (firstReleasePercent == BASIS_POINT_DIVISOR) {
            currentTotal = joinInfo.totalTokens;
        } else {
            uint256 tgeReleaseAmount = joinInfo.totalTokens.mul(firstReleasePercent).div(BASIS_POINT_DIVISOR);
            uint256 cycleReleaseAmount = joinInfo.totalTokens.mul(tokenReleaseEachCycle).div(BASIS_POINT_DIVISOR);
            uint256 time = 0;

            uint256 firstVestingTime = listingTime.add(cliffVesting).add(lockAfterCliffVesting);
            if (lockAfterCliffVesting == 0) {
                firstVestingTime  = firstVestingTime.add(vestingPeriodEachCycle);
            }

            if (block.timestamp >= firstVestingTime) {
                time = (block.timestamp.sub(firstVestingTime).div(vestingPeriodEachCycle)).add(1);
            }

            currentTotal = (time.mul(cycleReleaseAmount)).add(tgeReleaseAmount);
            if (currentTotal > joinInfo.totalTokens) {
                currentTotal = joinInfo.totalTokens;
            }
        }

        claimableTokens = currentTotal.sub(joinInfo.claimedTokens);
        return claimableTokens;
    }


    function getLaunchpadInfo() external view returns (LaunchpadStructs.LaunchpadReturnInfo memory) {
        uint256 balance = icoToken.balanceOf(address(this));

        LaunchpadStructs.LaunchpadReturnInfo memory result;
        result.softCap = softCap;
        result.hardCap = hardCap;
        result.startTime = startTime;
        result.endTime = endTime;
        result.state = state;
        result.raisedAmount = raisedAmount;
        result.balance = balance;
        result.feeToken = feeToken;
        result.listingTime = listingTime;
        result.whitelistPool = whitelistPool;
        result.holdingToken = holdingToken;
        result.holdingTokenAmount = holdingTokenAmount;
        return result;
    }

    function getOwnerZoneInfo(address _user) external view returns (LaunchpadStructs.OwnerZoneInfo memory) {
        LaunchpadStructs.OwnerZoneInfo memory result;
        bool isOwner = _user == owner();
        if (!isOwner) {
            return result;
        }
        result.isOwner = isOwner;
        result.whitelistPool = whitelistPool;

        // if false => true,
        result.canCancel = state == 1;
        result.canFinalize = state == 1 &&
        ((block.timestamp < endTime && raisedAmount >= hardCap) ||
        (block.timestamp >= endTime && raisedAmount >= softCap));
        return result;
    }


    function getJoinedUsers()
    external
    view
    returns (address[] memory)
    {
        uint256 start = 0;
        uint256 end = _joinedUsers.length();
        if (end == 0) {
            return new address[](0);
        }
        uint256 length = end.sub(start);
        address[] memory result = new address[](length);
        uint256 index = 0;
        for (uint256 i = start; i < end; i++) {
            result[index] = _joinedUsers.at(i);
            index++;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../libraries/math/SafeMath.sol";

import "./interfaces/ISPERC20.sol";
import "./structs/Launchpad.sol";
import "./TokenOfferingLaunchpad.sol";

contract TokenOfferingLaunchpadFactory is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ISPERC20;

    address public signer;
    address public superAccount;
    address public lptoLock;
    address payable public fundAddress;
    uint256 public percentAffiliate;

    event NewTokenOfferingLaunchPad(address indexed launchpad);

    uint256 public constant BASIS_POINT_DIVISOR = 10000;

    constructor(address _signer, address _superAccount, address _lptoLock, address payable _fundAddress) public {
        require(_signer != address(0) && _signer != address(this), 'signer');
        require(_lptoLock != address(0) && _lptoLock != address(this), 'lptoLock');
        require(_superAccount != address(0) && _superAccount != address(this), 'superAccount');
        require(_fundAddress != address(0) && _fundAddress != address(this), 'fundAddress');

        signer = _signer;
        superAccount = _superAccount;
        fundAddress = _fundAddress;
        lptoLock = _lptoLock;
    }

    function setSuperAccount(address _superAccount) public onlyOwner {
        superAccount = _superAccount;
    }

    function setLPTOLock(address _lptoLock) public onlyOwner {
        lptoLock = _lptoLock;
    }

    function setFundAddress(address payable _fundAddress) public onlyOwner {
        fundAddress = _fundAddress;
    }


    function calculateTokens(LaunchpadStructs.CalculateTokenInput memory input) private view returns (uint256) {
        uint256 feeTokenDecimals = 18;
        if (input.feeToken != address(0)) {
            feeTokenDecimals = ISPERC20(input.feeToken).decimals();
        }

        uint256 totalPresaleTokens = input.presaleRate.mul(input.hardCap).div(10 ** feeTokenDecimals);
        uint256 totalFeeTokens = totalPresaleTokens.mul(input.raisedTokenFeePercent).div(BASIS_POINT_DIVISOR);
        uint256 result = totalPresaleTokens.add(totalFeeTokens);
        return result;
    }

    function deployLaunchpad(
        LaunchpadStructs.LaunchpadInfo memory info, 
        LaunchpadStructs.ClaimInfo memory claimInfo, 
        LaunchpadStructs.TeamVestingInfo memory teamVestingInfo, 
        LaunchpadStructs.FeeSystem memory feeInfo, 
        uint256 _percentAffiliate
    ) external payable {
        require(superAccount != address(0) && fundAddress != address(0), 'Can not create launchpad now!');
        require(msg.value >= feeInfo.initFee, 'Not enough fee!');
        if (!info.affiliate) {
            percentAffiliate = 0;
        } else {
            require(_percentAffiliate >= 100 && _percentAffiliate <= 1000, "invalid");
            percentAffiliate = _percentAffiliate;
        }

        LaunchpadStructs.SettingAccount memory settingAccount = LaunchpadStructs.SettingAccount(
            _msgSender(),
            superAccount,
            payable(fundAddress),
            lptoLock
        );


        ISPERC20 icoToken = ISPERC20(info.icoToken);
        uint256 feeTokenDecimals = 18;
        if (info.feeToken != address(0)) {
            feeTokenDecimals = ISPERC20(info.feeToken).decimals();
        }

        LaunchpadStructs.CalculateTokenInput memory input = LaunchpadStructs.CalculateTokenInput(
            info.feeToken,
            info.presaleRate,
            info.hardCap,
            feeInfo.raisedTokenFeePercent,
            feeInfo.raisedFeePercent
        );

        uint256 totalTokens = calculateTokens(input);
        Launchpad launchpad = new Launchpad(info, claimInfo, teamVestingInfo, feeInfo, settingAccount, percentAffiliate);

        if (msg.value > 0) {
            payable(fundAddress).transfer(msg.value);
        }

        if (totalTokens > 0) {
            ISPERC20 icoTokenErc20 = ISPERC20(info.icoToken);

            require(icoTokenErc20.balanceOf(_msgSender()) >= totalTokens, 'Insufficient Balance');
            require(icoTokenErc20.allowance(_msgSender(), address(this)) >= totalTokens, 'Insufficient Allowance');
            require(icoToken.transferFrom(_msgSender(), address(launchpad), totalTokens),"transfer failed");
        }
        emit NewTokenOfferingLaunchPad(address(launchpad));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "../tokens/interfaces/IBXD.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IVaultUtils.sol";
import "./interfaces/IVaultPriceFeed.sol";

contract Vault is ReentrancyGuard, IVault {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Position {
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        uint256 entryFundingRate;
        uint256 reserveAmount;
        int256 realisedPnl;
        uint256 lastIncreasedTime;
    }

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant FUNDING_RATE_PRECISION = 1000000;
    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant MIN_LEVERAGE = 10000; // 1x
    uint256 public constant BXD_DECIMALS = 18;
    uint256 public constant MAX_FEE_BASIS_POINTS = 500; // 5%
    uint256 public constant MAX_LIQUIDATION_FEE_USD = 100 * PRICE_PRECISION; // 100 USD
    uint256 public constant MIN_FUNDING_RATE_INTERVAL = 1 hours;
    uint256 public constant MAX_FUNDING_RATE_FACTOR = 10000; // 1%

    bool public override isInitialized;
    bool public override isSwapEnabled = true;
    bool public override isLeverageEnabled = true;

    IVaultUtils public vaultUtils;

    address public errorController;

    address public override router;
    address public override priceFeed;

    address public override bxd;
    address public override gov;

    uint256 public override whitelistedTokenCount;

    uint256 public override maxLeverage = 50 * 10000; // 50x

    uint256 public override liquidationFeeUsd;
    uint256 public override taxBasisPoints = 50; // 0.5%
    uint256 public override stableTaxBasisPoints = 20; // 0.2%
    uint256 public override mintBurnFeeBasisPoints = 30; // 0.3%
    uint256 public override swapFeeBasisPoints = 30; // 0.3%
    uint256 public override stableSwapFeeBasisPoints = 4; // 0.04%
    uint256 public override marginFeeBasisPoints = 10; // 0.1%

    uint256 public override minProfitTime;
    bool public override hasDynamicFees = false;

    uint256 public override fundingInterval = 8 hours;
    uint256 public override fundingRateFactor;
    uint256 public override stableFundingRateFactor;
    uint256 public override totalTokenWeights;

    bool public includeAmmPrice = true;
    bool public useSwapPricing = false;

    bool public override inManagerMode = false;
    bool public override inPrivateLiquidationMode = false;

    uint256 public override maxGasPrice;

    mapping (address => mapping (address => bool)) public override approvedRouters;
    mapping (address => bool) public override isLiquidator;
    mapping (address => bool) public override isManager;

    address[] public override allWhitelistedTokens;

    mapping (address => bool) public override whitelistedTokens;
    mapping (address => uint256) public override tokenDecimals;
    mapping (address => uint256) public override minProfitBasisPoints;
    mapping (address => bool) public override stableTokens;
    mapping (address => bool) public override shortableTokens;

    // tokenBalances is used only to determine _transferIn values
    mapping (address => uint256) public override tokenBalances;

    // tokenWeights allows customisation of index composition
    mapping (address => uint256) public override tokenWeights;

    // bxdAmounts tracks the amount of BXD debt for each whitelisted token
    mapping (address => uint256) public override bxdAmounts;

    // maxBxdAmounts allows setting a max amount of BXD debt for a token
    mapping (address => uint256) public override maxBxdAmounts;

    // poolAmounts tracks the number of received tokens that can be used for leverage
    // this is tracked separately from tokenBalances to exclude funds that are deposited as margin collateral
    mapping (address => uint256) public override poolAmounts;

    // reservedAmounts tracks the number of tokens reserved for open leverage positions
    mapping (address => uint256) public override reservedAmounts;

    // bufferAmounts allows specification of an amount to exclude from swaps
    // this can be used to ensure a certain amount of liquidity is available for leverage positions
    mapping (address => uint256) public override bufferAmounts;

    // guaranteedUsd tracks the amount of USD that is "guaranteed" by opened leverage positions
    // this value is used to calculate the redemption values for selling of BXD
    // this is an estimated amount, it is possible for the actual guaranteed value to be lower
    // in the case of sudden price decreases, the guaranteed value should be corrected
    // after liquidations are carried out
    mapping (address => uint256) public override guaranteedUsd;

    // cumulativeFundingRates tracks the funding rates based on utilization
    mapping (address => uint256) public override cumulativeFundingRates;
    // lastFundingTimes tracks the last time funding was updated for a token
    mapping (address => uint256) public override lastFundingTimes;

    // positions tracks all open positions
    mapping (bytes32 => Position) public positions;

    // feeReserves tracks the amount of fees per token
    mapping (address => uint256) public override feeReserves;

    mapping (address => uint256) public override globalShortSizes;
    mapping (address => uint256) public override globalShortAveragePrices;
    mapping (address => uint256) public override maxGlobalShortSizes;

    mapping (uint256 => string) public errors;

    event BuyBXD(address account, address token, uint256 tokenAmount, uint256 bxdAmount, uint256 feeBasisPoints);
    event SellBXD(address account, address token, uint256 bxdAmount, uint256 tokenAmount, uint256 feeBasisPoints);
    event Swap(address account, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut, uint256 amountOutAfterFees, uint256 feeBasisPoints);

    event IncreasePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 price,
        uint256 fee
    );
    event DecreasePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 price,
        uint256 fee
    );
    event LiquidatePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        bool isLong,
        uint256 size,
        uint256 collateral,
        uint256 reserveAmount,
        int256 realisedPnl,
        uint256 markPrice
    );
    event UpdatePosition(
        bytes32 key,
        uint256 size,
        uint256 collateral,
        uint256 averagePrice,
        uint256 entryFundingRate,
        uint256 reserveAmount,
        int256 realisedPnl,
        uint256 markPrice
    );
    event ClosePosition(
        bytes32 key,
        uint256 size,
        uint256 collateral,
        uint256 averagePrice,
        uint256 entryFundingRate,
        uint256 reserveAmount,
        int256 realisedPnl
    );

    event UpdateFundingRate(address token, uint256 fundingRate);
    event UpdatePnl(bytes32 key, bool hasProfit, uint256 delta);

    event CollectSwapFees(address token, uint256 feeUsd, uint256 feeTokens);
    event CollectMarginFees(address token, uint256 feeUsd, uint256 feeTokens);

    event DirectPoolDeposit(address token, uint256 amount);
    event IncreasePoolAmount(address token, uint256 amount);
    event DecreasePoolAmount(address token, uint256 amount);
    event IncreaseBxdAmount(address token, uint256 amount);
    event DecreaseBxdAmount(address token, uint256 amount);
    event IncreaseReservedAmount(address token, uint256 amount);
    event DecreaseReservedAmount(address token, uint256 amount);
    event IncreaseGuaranteedUsd(address token, uint256 amount);
    event DecreaseGuaranteedUsd(address token, uint256 amount);

    // once the parameters are verified to be working correctly,
    // gov should be set to a timelock contract or a governance contract
    constructor() public {
        gov = msg.sender;
    }

    function initialize(
        address _router,
        address _bxd,
        address _priceFeed,
        uint256 _liquidationFeeUsd,
        uint256 _fundingRateFactor,
        uint256 _stableFundingRateFactor
    ) external {
        _onlyGov();
        _validate(!isInitialized, 1);
        isInitialized = true;

        router = _router;
        bxd = _bxd;
        priceFeed = _priceFeed;
        liquidationFeeUsd = _liquidationFeeUsd;
        fundingRateFactor = _fundingRateFactor;
        stableFundingRateFactor = _stableFundingRateFactor;
    }

    function setVaultUtils(IVaultUtils _vaultUtils) external override {
        _onlyGov();
        vaultUtils = _vaultUtils;
    }

    function setErrorController(address _errorController) external {
        _onlyGov();
        errorController = _errorController;
    }

    function setError(uint256 _errorCode, string calldata _error) external override {
        require(msg.sender == errorController, "Vault: invalid errorController");
        errors[_errorCode] = _error;
    }

    function allWhitelistedTokensLength() external override view returns (uint256) {
        return allWhitelistedTokens.length;
    }

    function setInManagerMode(bool _inManagerMode) external override {
        _onlyGov();
        inManagerMode = _inManagerMode;
    }

    function setManager(address _manager, bool _isManager) external override {
        _onlyGov();
        isManager[_manager] = _isManager;
    }

    function setInPrivateLiquidationMode(bool _inPrivateLiquidationMode) external override {
        _onlyGov();
        inPrivateLiquidationMode = _inPrivateLiquidationMode;
    }

    function setLiquidator(address _liquidator, bool _isActive) external override {
        _onlyGov();
        isLiquidator[_liquidator] = _isActive;
    }

    function setIsSwapEnabled(bool _isSwapEnabled) external override {
        _onlyGov();
        isSwapEnabled = _isSwapEnabled;
    }

    function setIsLeverageEnabled(bool _isLeverageEnabled) external override {
        _onlyGov();
        isLeverageEnabled = _isLeverageEnabled;
    }

    function setMaxGasPrice(uint256 _maxGasPrice) external override {
        _onlyGov();
        maxGasPrice = _maxGasPrice;
    }

    function setGov(address _gov) external {
        _onlyGov();
        gov = _gov;
    }

    function setPriceFeed(address _priceFeed) external override {
        _onlyGov();
        priceFeed = _priceFeed;
    }

    function setMaxLeverage(uint256 _maxLeverage) external override {
        _onlyGov();
        _validate(_maxLeverage > MIN_LEVERAGE, 2);
        maxLeverage = _maxLeverage;
    }

    function setBufferAmount(address _token, uint256 _amount) external override {
        _onlyGov();
        bufferAmounts[_token] = _amount;
    }

    function setMaxGlobalShortSize(address _token, uint256 _amount) external override {
        _onlyGov();
        maxGlobalShortSizes[_token] = _amount;
    }

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external override {
        _onlyGov();
        _validate(_taxBasisPoints <= MAX_FEE_BASIS_POINTS, 3);
        _validate(_stableTaxBasisPoints <= MAX_FEE_BASIS_POINTS, 4);
        _validate(_mintBurnFeeBasisPoints <= MAX_FEE_BASIS_POINTS, 5);
        _validate(_swapFeeBasisPoints <= MAX_FEE_BASIS_POINTS, 6);
        _validate(_stableSwapFeeBasisPoints <= MAX_FEE_BASIS_POINTS, 7);
        _validate(_marginFeeBasisPoints <= MAX_FEE_BASIS_POINTS, 8);
        _validate(_liquidationFeeUsd <= MAX_LIQUIDATION_FEE_USD, 9);
        taxBasisPoints = _taxBasisPoints;
        stableTaxBasisPoints = _stableTaxBasisPoints;
        mintBurnFeeBasisPoints = _mintBurnFeeBasisPoints;
        swapFeeBasisPoints = _swapFeeBasisPoints;
        stableSwapFeeBasisPoints = _stableSwapFeeBasisPoints;
        marginFeeBasisPoints = _marginFeeBasisPoints;
        liquidationFeeUsd = _liquidationFeeUsd;
        minProfitTime = _minProfitTime;
        hasDynamicFees = _hasDynamicFees;
    }

    function setFundingRate(uint256 _fundingInterval, uint256 _fundingRateFactor, uint256 _stableFundingRateFactor) external override {
        _onlyGov();
        _validate(_fundingInterval >= MIN_FUNDING_RATE_INTERVAL, 10);
        _validate(_fundingRateFactor <= MAX_FUNDING_RATE_FACTOR, 11);
        _validate(_stableFundingRateFactor <= MAX_FUNDING_RATE_FACTOR, 12);
        fundingInterval = _fundingInterval;
        fundingRateFactor = _fundingRateFactor;
        stableFundingRateFactor = _stableFundingRateFactor;
    }

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _tokenWeight,
        uint256 _minProfitBps,
        uint256 _maxBxdAmount,
        bool _isStable,
        bool _isShortable
    ) external override {
        _onlyGov();
        // increment token count for the first time
        if (!whitelistedTokens[_token]) {
            whitelistedTokenCount = whitelistedTokenCount.add(1);
            allWhitelistedTokens.push(_token);
        }

        uint256 _totalTokenWeights = totalTokenWeights;
        _totalTokenWeights = _totalTokenWeights.sub(tokenWeights[_token]);

        whitelistedTokens[_token] = true;
        tokenDecimals[_token] = _tokenDecimals;
        tokenWeights[_token] = _tokenWeight;
        minProfitBasisPoints[_token] = _minProfitBps;
        maxBxdAmounts[_token] = _maxBxdAmount;
        stableTokens[_token] = _isStable;
        shortableTokens[_token] = _isShortable;

        totalTokenWeights = _totalTokenWeights.add(_tokenWeight);

        // validate price feed
        getMaxPrice(_token);
    }

    function clearTokenConfig(address _token) external {
        _onlyGov();
        _validate(whitelistedTokens[_token], 13);
        totalTokenWeights = totalTokenWeights.sub(tokenWeights[_token]);
        delete whitelistedTokens[_token];
        delete tokenDecimals[_token];
        delete tokenWeights[_token];
        delete minProfitBasisPoints[_token];
        delete maxBxdAmounts[_token];
        delete stableTokens[_token];
        delete shortableTokens[_token];
        whitelistedTokenCount = whitelistedTokenCount.sub(1);
    }

    function withdrawFees(address _token, address _receiver) external override returns (uint256) {
        _onlyGov();
        uint256 amount = feeReserves[_token];
        if(amount == 0) { return 0; }
        feeReserves[_token] = 0;
        _transferOut(_token, amount, _receiver);
        return amount;
    }

    function addRouter(address _router) external {
        approvedRouters[msg.sender][_router] = true;
    }

    function removeRouter(address _router) external {
        approvedRouters[msg.sender][_router] = false;
    }

    function setBxdAmount(address _token, uint256 _amount) external override {
        _onlyGov();

        uint256 bxdAmount = bxdAmounts[_token];
        if (_amount > bxdAmount) {
            _increaseBxdAmount(_token, _amount.sub(bxdAmount));
            return;
        }

        _decreaseBxdAmount(_token, bxdAmount.sub(_amount));
    }

    // the governance controlling this function should have a timelock
    function upgradeVault(address _newVault, address _token, uint256 _amount) external {
        _onlyGov();
        IERC20(_token).safeTransfer(_newVault, _amount);
    }

    // deposit into the pool without minting BXD tokens
    // useful in allowing the pool to become over-collaterised
    function directPoolDeposit(address _token) external override nonReentrant {
        _validate(whitelistedTokens[_token], 14);
        uint256 tokenAmount = _transferIn(_token);
        _validate(tokenAmount > 0, 15);
        _increasePoolAmount(_token, tokenAmount);
        emit DirectPoolDeposit(_token, tokenAmount);
    }

    function buyBXD(address _token, address _receiver) external override nonReentrant returns (uint256) {
        _validateManager();
        _validate(whitelistedTokens[_token], 16);
        useSwapPricing = true;

        uint256 tokenAmount = _transferIn(_token);
        _validate(tokenAmount > 0, 17);

        updateCumulativeFundingRate(_token, _token);

        uint256 price = getMinPrice(_token);

        uint256 bxdAmount = tokenAmount.mul(price).div(PRICE_PRECISION);
        bxdAmount = adjustForDecimals(bxdAmount, _token, bxd);
        _validate(bxdAmount > 0, 18);

        uint256 feeBasisPoints = vaultUtils.getBuyBxdFeeBasisPoints(_token, bxdAmount);
        uint256 amountAfterFees = _collectSwapFees(_token, tokenAmount, feeBasisPoints);
        uint256 mintAmount = amountAfterFees.mul(price).div(PRICE_PRECISION);
        mintAmount = adjustForDecimals(mintAmount, _token, bxd);

        _increaseBxdAmount(_token, mintAmount);
        _increasePoolAmount(_token, amountAfterFees);

        IBXD(bxd).mint(_receiver, mintAmount);

        emit BuyBXD(_receiver, _token, tokenAmount, mintAmount, feeBasisPoints);

        useSwapPricing = false;
        return mintAmount;
    }

    function sellBXD(address _token, address _receiver) external override nonReentrant returns (uint256) {
        _validateManager();
        _validate(whitelistedTokens[_token], 19);
        useSwapPricing = true;

        uint256 bxdAmount = _transferIn(bxd);
        _validate(bxdAmount > 0, 20);

        updateCumulativeFundingRate(_token, _token);

        uint256 redemptionAmount = getRedemptionAmount(_token, bxdAmount);
        _validate(redemptionAmount > 0, 21);

        _decreaseBxdAmount(_token, bxdAmount);
        _decreasePoolAmount(_token, redemptionAmount);

        IBXD(bxd).burn(address(this), bxdAmount);

        // the _transferIn call increased the value of tokenBalances[bxd]
        // usually decreases in token balances are synced by calling _transferOut
        // however, for bxd, the tokens are burnt, so _updateTokenBalance should
        // be manually called to record the decrease in tokens
        _updateTokenBalance(bxd);

        uint256 feeBasisPoints = vaultUtils.getSellBxdFeeBasisPoints(_token, bxdAmount);
        uint256 amountOut = _collectSwapFees(_token, redemptionAmount, feeBasisPoints);
        _validate(amountOut > 0, 22);

        _transferOut(_token, amountOut, _receiver);

        emit SellBXD(_receiver, _token, bxdAmount, amountOut, feeBasisPoints);

        useSwapPricing = false;
        return amountOut;
    }

    function swap(address _tokenIn, address _tokenOut, address _receiver) external override nonReentrant returns (uint256) {
        _validate(isSwapEnabled, 23);
        _validate(whitelistedTokens[_tokenIn], 24);
        _validate(whitelistedTokens[_tokenOut], 25);
        _validate(_tokenIn != _tokenOut, 26);

        useSwapPricing = true;

        updateCumulativeFundingRate(_tokenIn, _tokenIn);
        updateCumulativeFundingRate(_tokenOut, _tokenOut);

        uint256 amountIn = _transferIn(_tokenIn);
        _validate(amountIn > 0, 27);

        uint256 priceIn = getMinPrice(_tokenIn);
        uint256 priceOut = getMaxPrice(_tokenOut);

        uint256 amountOut = amountIn.mul(priceIn).div(priceOut);
        amountOut = adjustForDecimals(amountOut, _tokenIn, _tokenOut);

        // adjust bxdAmounts by the same bxdAmount as debt is shifted between the assets
        uint256 bxdAmount = amountIn.mul(priceIn).div(PRICE_PRECISION);
        bxdAmount = adjustForDecimals(bxdAmount, _tokenIn, bxd);

        uint256 feeBasisPoints = vaultUtils.getSwapFeeBasisPoints(_tokenIn, _tokenOut, bxdAmount);
        uint256 amountOutAfterFees = _collectSwapFees(_tokenOut, amountOut, feeBasisPoints);

        _increaseBxdAmount(_tokenIn, bxdAmount);
        _decreaseBxdAmount(_tokenOut, bxdAmount);

        _increasePoolAmount(_tokenIn, amountIn);
        _decreasePoolAmount(_tokenOut, amountOut);

        _validateBufferAmount(_tokenOut);

        _transferOut(_tokenOut, amountOutAfterFees, _receiver);

        emit Swap(_receiver, _tokenIn, _tokenOut, amountIn, amountOut, amountOutAfterFees, feeBasisPoints);

        useSwapPricing = false;
        return amountOutAfterFees;
    }

    function increasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external override nonReentrant {
        _validate(isLeverageEnabled, 28);
        _validateGasPrice();
        _validateRouter(_account);
        _validateTokens(_collateralToken, _indexToken, _isLong);
        vaultUtils.validateIncreasePosition(_account, _collateralToken, _indexToken, _sizeDelta, _isLong);

        updateCumulativeFundingRate(_collateralToken, _indexToken);

        bytes32 key = getPositionKey(_account, _collateralToken, _indexToken, _isLong);
        Position storage position = positions[key];

        uint256 price = _isLong ? getMaxPrice(_indexToken) : getMinPrice(_indexToken);

        if (position.size == 0) {
            position.averagePrice = price;
        }

        if (position.size > 0 && _sizeDelta > 0) {
            position.averagePrice = getNextAveragePrice(_indexToken, position.size, position.averagePrice, _isLong, price, _sizeDelta, position.lastIncreasedTime);
        }

        uint256 fee = _collectMarginFees(_account, _collateralToken, _indexToken, _isLong, _sizeDelta, position.size, position.entryFundingRate);
        uint256 collateralDelta = _transferIn(_collateralToken);
        uint256 collateralDeltaUsd = tokenToUsdMin(_collateralToken, collateralDelta);

        position.collateral = position.collateral.add(collateralDeltaUsd);
        _validate(position.collateral >= fee, 29);

        position.collateral = position.collateral.sub(fee);
        position.entryFundingRate = getEntryFundingRate(_collateralToken, _indexToken, _isLong);
        position.size = position.size.add(_sizeDelta);
        position.lastIncreasedTime = block.timestamp;

        _validate(position.size > 0, 30);
        _validatePosition(position.size, position.collateral);
        validateLiquidation(_account, _collateralToken, _indexToken, _isLong, true);

        // reserve tokens to pay profits on the position
        uint256 reserveDelta = usdToTokenMax(_collateralToken, _sizeDelta);
        position.reserveAmount = position.reserveAmount.add(reserveDelta);
        _increaseReservedAmount(_collateralToken, reserveDelta);

        if (_isLong) {
            // guaranteedUsd stores the sum of (position.size - position.collateral) for all positions
            // if a fee is charged on the collateral then guaranteedUsd should be increased by that fee amount
            // since (position.size - position.collateral) would have increased by `fee`
            _increaseGuaranteedUsd(_collateralToken, _sizeDelta.add(fee));
            _decreaseGuaranteedUsd(_collateralToken, collateralDeltaUsd);
            // treat the deposited collateral as part of the pool
            _increasePoolAmount(_collateralToken, collateralDelta);
            // fees need to be deducted from the pool since fees are deducted from position.collateral
            // and collateral is treated as part of the pool
            _decreasePoolAmount(_collateralToken, usdToTokenMin(_collateralToken, fee));
        } else {
            if (globalShortSizes[_indexToken] == 0) {
                globalShortAveragePrices[_indexToken] = price;
            } else {
                globalShortAveragePrices[_indexToken] = getNextGlobalShortAveragePrice(_indexToken, price, _sizeDelta);
            }

            _increaseGlobalShortSize(_indexToken, _sizeDelta);
        }

        emit IncreasePosition(key, _account, _collateralToken, _indexToken, collateralDeltaUsd, _sizeDelta, _isLong, price, fee);
        emit UpdatePosition(key, position.size, position.collateral, position.averagePrice, position.entryFundingRate, position.reserveAmount, position.realisedPnl, price);
    }

    function decreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external override nonReentrant returns (uint256) {
        _validateGasPrice();
        _validateRouter(_account);
        return _decreasePosition(_account, _collateralToken, _indexToken, _collateralDelta, _sizeDelta, _isLong, _receiver);
    }

    function _decreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) private returns (uint256) {
        vaultUtils.validateDecreasePosition(_account, _collateralToken, _indexToken, _collateralDelta, _sizeDelta, _isLong, _receiver);
        updateCumulativeFundingRate(_collateralToken, _indexToken);

        bytes32 key = getPositionKey(_account, _collateralToken, _indexToken, _isLong);
        Position storage position = positions[key];
        _validate(position.size > 0, 31);
        _validate(position.size >= _sizeDelta, 32);
        _validate(position.collateral >= _collateralDelta, 33);

        uint256 collateral = position.collateral;
        // scrop variables to avoid stack too deep errors
        {
        uint256 reserveDelta = position.reserveAmount.mul(_sizeDelta).div(position.size);
        position.reserveAmount = position.reserveAmount.sub(reserveDelta);
        _decreaseReservedAmount(_collateralToken, reserveDelta);
        }

        (uint256 usdOut, uint256 usdOutAfterFee) = _reduceCollateral(_account, _collateralToken, _indexToken, _collateralDelta, _sizeDelta, _isLong);

        if (position.size != _sizeDelta) {
            position.entryFundingRate = getEntryFundingRate(_collateralToken, _indexToken, _isLong);
            position.size = position.size.sub(_sizeDelta);

            _validatePosition(position.size, position.collateral);
            validateLiquidation(_account, _collateralToken, _indexToken, _isLong, true);

            if (_isLong) {
                _increaseGuaranteedUsd(_collateralToken, collateral.sub(position.collateral));
                _decreaseGuaranteedUsd(_collateralToken, _sizeDelta);
            }

            uint256 price = _isLong ? getMinPrice(_indexToken) : getMaxPrice(_indexToken);
            emit DecreasePosition(key, _account, _collateralToken, _indexToken, _collateralDelta, _sizeDelta, _isLong, price, usdOut.sub(usdOutAfterFee));
            emit UpdatePosition(key, position.size, position.collateral, position.averagePrice, position.entryFundingRate, position.reserveAmount, position.realisedPnl, price);
        } else {
            if (_isLong) {
                _increaseGuaranteedUsd(_collateralToken, collateral);
                _decreaseGuaranteedUsd(_collateralToken, _sizeDelta);
            }

            uint256 price = _isLong ? getMinPrice(_indexToken) : getMaxPrice(_indexToken);
            emit DecreasePosition(key, _account, _collateralToken, _indexToken, _collateralDelta, _sizeDelta, _isLong, price, usdOut.sub(usdOutAfterFee));
            emit ClosePosition(key, position.size, position.collateral, position.averagePrice, position.entryFundingRate, position.reserveAmount, position.realisedPnl);

            delete positions[key];
        }

        if (!_isLong) {
            _decreaseGlobalShortSize(_indexToken, _sizeDelta);
        }

        if (usdOut > 0) {
            if (_isLong) {
                _decreasePoolAmount(_collateralToken, usdToTokenMin(_collateralToken, usdOut));
            }
            uint256 amountOutAfterFees = usdToTokenMin(_collateralToken, usdOutAfterFee);
            _transferOut(_collateralToken, amountOutAfterFees, _receiver);
            return amountOutAfterFees;
        }

        return 0;
    }

    function liquidatePosition(address _account, address _collateralToken, address _indexToken, bool _isLong, address _feeReceiver) external override nonReentrant {
        if (inPrivateLiquidationMode) {
            _validate(isLiquidator[msg.sender], 34);
        }

        // set includeAmmPrice to false to prevent manipulated liquidations
        includeAmmPrice = false;

        updateCumulativeFundingRate(_collateralToken, _indexToken);

        bytes32 key = getPositionKey(_account, _collateralToken, _indexToken, _isLong);
        Position memory position = positions[key];
        _validate(position.size > 0, 35);

        (uint256 liquidationState, uint256 marginFees) = validateLiquidation(_account, _collateralToken, _indexToken, _isLong, false);
        _validate(liquidationState != 0, 36);
        if (liquidationState == 2) {
            // max leverage exceeded but there is collateral remaining after deducting losses so decreasePosition instead
            _decreasePosition(_account, _collateralToken, _indexToken, 0, position.size, _isLong, _account);
            includeAmmPrice = true;
            return;
        }

        uint256 feeTokens = usdToTokenMin(_collateralToken, marginFees);
        feeReserves[_collateralToken] = feeReserves[_collateralToken].add(feeTokens);
        emit CollectMarginFees(_collateralToken, marginFees, feeTokens);

        _decreaseReservedAmount(_collateralToken, position.reserveAmount);
        if (_isLong) {
            _decreaseGuaranteedUsd(_collateralToken, position.size.sub(position.collateral));
            _decreasePoolAmount(_collateralToken, usdToTokenMin(_collateralToken, marginFees));
        }

        uint256 markPrice = _isLong ? getMinPrice(_indexToken) : getMaxPrice(_indexToken);
        emit LiquidatePosition(key, _account, _collateralToken, _indexToken, _isLong, position.size, position.collateral, position.reserveAmount, position.realisedPnl, markPrice);

        if (!_isLong && marginFees < position.collateral) {
            uint256 remainingCollateral = position.collateral.sub(marginFees);
            _increasePoolAmount(_collateralToken, usdToTokenMin(_collateralToken, remainingCollateral));
        }

        if (!_isLong) {
            _decreaseGlobalShortSize(_indexToken, position.size);
        }

        delete positions[key];

        // pay the fee receiver using the pool, we assume that in general the liquidated amount should be sufficient to cover
        // the liquidation fees
        _decreasePoolAmount(_collateralToken, usdToTokenMin(_collateralToken, liquidationFeeUsd));
        _transferOut(_collateralToken, usdToTokenMin(_collateralToken, liquidationFeeUsd), _feeReceiver);

        includeAmmPrice = true;
    }

    // validateLiquidation returns (state, fees)
    function validateLiquidation(address _account, address _collateralToken, address _indexToken, bool _isLong, bool _raise) override public view returns (uint256, uint256) {
        return vaultUtils.validateLiquidation(_account, _collateralToken, _indexToken, _isLong, _raise);
    }

    function getMaxPrice(address _token) public override view returns (uint256) {
        return IVaultPriceFeed(priceFeed).getPrice(_token, true, includeAmmPrice, useSwapPricing);
    }

    function getMinPrice(address _token) public override view returns (uint256) {
        return IVaultPriceFeed(priceFeed).getPrice(_token, false, includeAmmPrice, useSwapPricing);
    }

    function getRedemptionAmount(address _token, uint256 _bxdAmount) public override view returns (uint256) {
        uint256 price = getMaxPrice(_token);
        uint256 redemptionAmount = _bxdAmount.mul(PRICE_PRECISION).div(price);
        return adjustForDecimals(redemptionAmount, bxd, _token);
    }

    function getRedemptionCollateral(address _token) public view returns (uint256) {
        if (stableTokens[_token]) {
            return poolAmounts[_token];
        }
        uint256 collateral = usdToTokenMin(_token, guaranteedUsd[_token]);
        return collateral.add(poolAmounts[_token]).sub(reservedAmounts[_token]);
    }

    function getRedemptionCollateralUsd(address _token) public view returns (uint256) {
        return tokenToUsdMin(_token, getRedemptionCollateral(_token));
    }

    function adjustForDecimals(uint256 _amount, address _tokenDiv, address _tokenMul) public view override returns (uint256) {
        uint256 decimalsDiv = _tokenDiv == bxd ? BXD_DECIMALS : tokenDecimals[_tokenDiv];
        uint256 decimalsMul = _tokenMul == bxd ? BXD_DECIMALS : tokenDecimals[_tokenMul];
        return _amount.mul(10 ** decimalsMul).div(10 ** decimalsDiv);
    }

    function tokenToUsdMin(address _token, uint256 _tokenAmount) public override view returns (uint256) {
        if (_tokenAmount == 0) { return 0; }
        uint256 price = getMinPrice(_token);
        uint256 decimals = tokenDecimals[_token];
        return _tokenAmount.mul(price).div(10 ** decimals);
    }

    function usdToTokenMax(address _token, uint256 _usdAmount) public view returns (uint256) {
        if (_usdAmount == 0) { return 0; }
        return usdToToken(_token, _usdAmount, getMinPrice(_token));
    }

    function usdToTokenMin(address _token, uint256 _usdAmount) public view returns (uint256) {
        if (_usdAmount == 0) { return 0; }
        return usdToToken(_token, _usdAmount, getMaxPrice(_token));
    }

    function usdToToken(address _token, uint256 _usdAmount, uint256 _price) public view returns (uint256) {
        if (_usdAmount == 0) { return 0; }
        uint256 decimals = tokenDecimals[_token];
        return _usdAmount.mul(10 ** decimals).div(_price);
    }

    function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong) public override view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256) {
        bytes32 key = getPositionKey(_account, _collateralToken, _indexToken, _isLong);
        Position memory position = positions[key];
        uint256 realisedPnl = position.realisedPnl > 0 ? uint256(position.realisedPnl) : uint256(-position.realisedPnl);
        return (
            position.size, // 0
            position.collateral, // 1
            position.averagePrice, // 2
            position.entryFundingRate, // 3
            position.reserveAmount, // 4
            realisedPnl, // 5
            position.realisedPnl >= 0, // 6
            position.lastIncreasedTime // 7
        );
    }

    function getPositionKey(address _account, address _collateralToken, address _indexToken, bool _isLong) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            _account,
            _collateralToken,
            _indexToken,
            _isLong
        ));
    }

    function updateCumulativeFundingRate(address _collateralToken, address _indexToken) public {
        bool shouldUpdate = vaultUtils.updateCumulativeFundingRate(_collateralToken, _indexToken);
        if (!shouldUpdate) {
            return;
        }

        if (lastFundingTimes[_collateralToken] == 0) {
            lastFundingTimes[_collateralToken] = block.timestamp.div(fundingInterval).mul(fundingInterval);
            return;
        }

        if (lastFundingTimes[_collateralToken].add(fundingInterval) > block.timestamp) {
            return;
        }

        uint256 fundingRate = getNextFundingRate(_collateralToken);
        cumulativeFundingRates[_collateralToken] = cumulativeFundingRates[_collateralToken].add(fundingRate);
        lastFundingTimes[_collateralToken] = block.timestamp.div(fundingInterval).mul(fundingInterval);

        emit UpdateFundingRate(_collateralToken, cumulativeFundingRates[_collateralToken]);
    }

    function getNextFundingRate(address _token) public override view returns (uint256) {
        if (lastFundingTimes[_token].add(fundingInterval) > block.timestamp) { return 0; }

        uint256 intervals = block.timestamp.sub(lastFundingTimes[_token]).div(fundingInterval);
        uint256 poolAmount = poolAmounts[_token];
        if (poolAmount == 0) { return 0; }

        uint256 _fundingRateFactor = stableTokens[_token] ? stableFundingRateFactor : fundingRateFactor;
        return _fundingRateFactor.mul(reservedAmounts[_token]).mul(intervals).div(poolAmount);
    }

    function getUtilisation(address _token) public view returns (uint256) {
        uint256 poolAmount = poolAmounts[_token];
        if (poolAmount == 0) { return 0; }

        return reservedAmounts[_token].mul(FUNDING_RATE_PRECISION).div(poolAmount);
    }

    function getPositionLeverage(address _account, address _collateralToken, address _indexToken, bool _isLong) public view returns (uint256) {
        bytes32 key = getPositionKey(_account, _collateralToken, _indexToken, _isLong);
        Position memory position = positions[key];
        _validate(position.collateral > 0, 37);
        return position.size.mul(BASIS_POINTS_DIVISOR).div(position.collateral);
    }

    // for longs: nextAveragePrice = (nextPrice * nextSize)/ (nextSize + delta)
    // for shorts: nextAveragePrice = (nextPrice * nextSize) / (nextSize - delta)
    function getNextAveragePrice(address _indexToken, uint256 _size, uint256 _averagePrice, bool _isLong, uint256 _nextPrice, uint256 _sizeDelta, uint256 _lastIncreasedTime) public view returns (uint256) {
        (bool hasProfit, uint256 delta) = getDelta(_indexToken, _size, _averagePrice, _isLong, _lastIncreasedTime);
        uint256 nextSize = _size.add(_sizeDelta);
        uint256 divisor;
        if (_isLong) {
            divisor = hasProfit ? nextSize.add(delta) : nextSize.sub(delta);
        } else {
            divisor = hasProfit ? nextSize.sub(delta) : nextSize.add(delta);
        }
        return _nextPrice.mul(nextSize).div(divisor);
    }

    // for longs: nextAveragePrice = (nextPrice * nextSize)/ (nextSize + delta)
    // for shorts: nextAveragePrice = (nextPrice * nextSize) / (nextSize - delta)
    function getNextGlobalShortAveragePrice(address _indexToken, uint256 _nextPrice, uint256 _sizeDelta) public view returns (uint256) {
        uint256 size = globalShortSizes[_indexToken];
        uint256 averagePrice = globalShortAveragePrices[_indexToken];
        uint256 priceDelta = averagePrice > _nextPrice ? averagePrice.sub(_nextPrice) : _nextPrice.sub(averagePrice);
        uint256 delta = size.mul(priceDelta).div(averagePrice);
        bool hasProfit = averagePrice > _nextPrice;

        uint256 nextSize = size.add(_sizeDelta);
        uint256 divisor = hasProfit ? nextSize.sub(delta) : nextSize.add(delta);

        return _nextPrice.mul(nextSize).div(divisor);
    }

    function getGlobalShortDelta(address _token) public view returns (bool, uint256) {
        uint256 size = globalShortSizes[_token];
        if (size == 0) { return (false, 0); }

        uint256 nextPrice = getMaxPrice(_token);
        uint256 averagePrice = globalShortAveragePrices[_token];
        uint256 priceDelta = averagePrice > nextPrice ? averagePrice.sub(nextPrice) : nextPrice.sub(averagePrice);
        uint256 delta = size.mul(priceDelta).div(averagePrice);
        bool hasProfit = averagePrice > nextPrice;

        return (hasProfit, delta);
    }

    function getPositionDelta(address _account, address _collateralToken, address _indexToken, bool _isLong) public view returns (bool, uint256) {
        bytes32 key = getPositionKey(_account, _collateralToken, _indexToken, _isLong);
        Position memory position = positions[key];
        return getDelta(_indexToken, position.size, position.averagePrice, _isLong, position.lastIncreasedTime);
    }

    function getDelta(address _indexToken, uint256 _size, uint256 _averagePrice, bool _isLong, uint256 _lastIncreasedTime) public override view returns (bool, uint256) {
        _validate(_averagePrice > 0, 38);
        uint256 price = _isLong ? getMinPrice(_indexToken) : getMaxPrice(_indexToken);
        uint256 priceDelta = _averagePrice > price ? _averagePrice.sub(price) : price.sub(_averagePrice);
        uint256 delta = _size.mul(priceDelta).div(_averagePrice);

        bool hasProfit;

        if (_isLong) {
            hasProfit = price > _averagePrice;
        } else {
            hasProfit = _averagePrice > price;
        }

        // if the minProfitTime has passed then there will be no min profit threshold
        // the min profit threshold helps to prevent front-running issues
        uint256 minBps = block.timestamp > _lastIncreasedTime.add(minProfitTime) ? 0 : minProfitBasisPoints[_indexToken];
        if (hasProfit && delta.mul(BASIS_POINTS_DIVISOR) <= _size.mul(minBps)) {
            delta = 0;
        }

        return (hasProfit, delta);
    }

    function getEntryFundingRate(address _collateralToken, address _indexToken, bool _isLong) public view returns (uint256) {
        return vaultUtils.getEntryFundingRate(_collateralToken, _indexToken, _isLong);
    }

    function getFundingFee(address _account, address _collateralToken, address _indexToken, bool _isLong, uint256 _size, uint256 _entryFundingRate) public view returns (uint256) {
        return vaultUtils.getFundingFee(_account, _collateralToken, _indexToken, _isLong, _size, _entryFundingRate);
    }

    function getPositionFee(address _account, address _collateralToken, address _indexToken, bool _isLong, uint256 _sizeDelta) public view returns (uint256) {
        return vaultUtils.getPositionFee(_account, _collateralToken, _indexToken, _isLong, _sizeDelta);
    }

    // cases to consider
    // 1. initialAmount is far from targetAmount, action increases balance slightly => high rebate
    // 2. initialAmount is far from targetAmount, action increases balance largely => high rebate
    // 3. initialAmount is close to targetAmount, action increases balance slightly => low rebate
    // 4. initialAmount is far from targetAmount, action reduces balance slightly => high tax
    // 5. initialAmount is far from targetAmount, action reduces balance largely => high tax
    // 6. initialAmount is close to targetAmount, action reduces balance largely => low tax
    // 7. initialAmount is above targetAmount, nextAmount is below targetAmount and vice versa
    // 8. a large swap should have similar fees as the same trade split into multiple smaller swaps
    function getFeeBasisPoints(address _token, uint256 _bxdDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) public override view returns (uint256) {
        return vaultUtils.getFeeBasisPoints(_token, _bxdDelta, _feeBasisPoints, _taxBasisPoints, _increment);
    }

    function getTargetBxdAmount(address _token) public override view returns (uint256) {
        uint256 supply = IERC20(bxd).totalSupply();
        if (supply == 0) { return 0; }
        uint256 weight = tokenWeights[_token];
        return weight.mul(supply).div(totalTokenWeights);
    }

    function _reduceCollateral(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong) private returns (uint256, uint256) {
        bytes32 key = getPositionKey(_account, _collateralToken, _indexToken, _isLong);
        Position storage position = positions[key];

        uint256 fee = _collectMarginFees(_account, _collateralToken, _indexToken, _isLong, _sizeDelta, position.size, position.entryFundingRate);
        bool hasProfit;
        uint256 adjustedDelta;

        // scope variables to avoid stack too deep errors
        {
        (bool _hasProfit, uint256 delta) = getDelta(_indexToken, position.size, position.averagePrice, _isLong, position.lastIncreasedTime);
        hasProfit = _hasProfit;
        // get the proportional change in pnl
        adjustedDelta = _sizeDelta.mul(delta).div(position.size);
        }

        uint256 usdOut;
        // transfer profits out
        if (hasProfit && adjustedDelta > 0) {
            usdOut = adjustedDelta;
            position.realisedPnl = position.realisedPnl + int256(adjustedDelta);

            // pay out realised profits from the pool amount for short positions
            if (!_isLong) {
                uint256 tokenAmount = usdToTokenMin(_collateralToken, adjustedDelta);
                _decreasePoolAmount(_collateralToken, tokenAmount);
            }
        }

        if (!hasProfit && adjustedDelta > 0) {
            position.collateral = position.collateral.sub(adjustedDelta);

            // transfer realised losses to the pool for short positions
            // realised losses for long positions are not transferred here as
            // _increasePoolAmount was already called in increasePosition for longs
            if (!_isLong) {
                uint256 tokenAmount = usdToTokenMin(_collateralToken, adjustedDelta);
                _increasePoolAmount(_collateralToken, tokenAmount);
            }

            position.realisedPnl = position.realisedPnl - int256(adjustedDelta);
        }

        // reduce the position's collateral by _collateralDelta
        // transfer _collateralDelta out
        if (_collateralDelta > 0) {
            usdOut = usdOut.add(_collateralDelta);
            position.collateral = position.collateral.sub(_collateralDelta);
        }

        // if the position will be closed, then transfer the remaining collateral out
        if (position.size == _sizeDelta) {
            usdOut = usdOut.add(position.collateral);
            position.collateral = 0;
        }

        // if the usdOut is more than the fee then deduct the fee from the usdOut directly
        // else deduct the fee from the position's collateral
        uint256 usdOutAfterFee = usdOut;
        if (usdOut > fee) {
            usdOutAfterFee = usdOut.sub(fee);
        } else {
            position.collateral = position.collateral.sub(fee);
            if (_isLong) {
                uint256 feeTokens = usdToTokenMin(_collateralToken, fee);
                _decreasePoolAmount(_collateralToken, feeTokens);
            }
        }

        emit UpdatePnl(key, hasProfit, adjustedDelta);

        return (usdOut, usdOutAfterFee);
    }

    function _validatePosition(uint256 _size, uint256 _collateral) private view {
        if (_size == 0) {
            _validate(_collateral == 0, 39);
            return;
        }
        _validate(_size >= _collateral, 40);
    }

    function _validateRouter(address _account) private view {
        if (msg.sender == _account) { return; }
        if (msg.sender == router) { return; }
        _validate(approvedRouters[_account][msg.sender], 41);
    }

    function _validateTokens(address _collateralToken, address _indexToken, bool _isLong) private view {
        if (_isLong) {
            _validate(_collateralToken == _indexToken, 42);
            _validate(whitelistedTokens[_collateralToken], 43);
            _validate(!stableTokens[_collateralToken], 44);
            return;
        }

        _validate(whitelistedTokens[_collateralToken], 45);
        _validate(stableTokens[_collateralToken], 46);
        _validate(!stableTokens[_indexToken], 47);
        _validate(shortableTokens[_indexToken], 48);
    }

    function _collectSwapFees(address _token, uint256 _amount, uint256 _feeBasisPoints) private returns (uint256) {
        uint256 afterFeeAmount = _amount.mul(BASIS_POINTS_DIVISOR.sub(_feeBasisPoints)).div(BASIS_POINTS_DIVISOR);
        uint256 feeAmount = _amount.sub(afterFeeAmount);
        feeReserves[_token] = feeReserves[_token].add(feeAmount);
        emit CollectSwapFees(_token, tokenToUsdMin(_token, feeAmount), feeAmount);
        return afterFeeAmount;
    }

    function _collectMarginFees(address _account, address _collateralToken, address _indexToken, bool _isLong, uint256 _sizeDelta, uint256 _size, uint256 _entryFundingRate) private returns (uint256) {
        uint256 feeUsd = getPositionFee(_account, _collateralToken, _indexToken, _isLong, _sizeDelta);

        uint256 fundingFee = getFundingFee(_account, _collateralToken, _indexToken, _isLong, _size, _entryFundingRate);
        feeUsd = feeUsd.add(fundingFee);

        uint256 feeTokens = usdToTokenMin(_collateralToken, feeUsd);
        feeReserves[_collateralToken] = feeReserves[_collateralToken].add(feeTokens);

        emit CollectMarginFees(_collateralToken, feeUsd, feeTokens);
        return feeUsd;
    }

    function _transferIn(address _token) private returns (uint256) {
        uint256 prevBalance = tokenBalances[_token];
        uint256 nextBalance = IERC20(_token).balanceOf(address(this));
        tokenBalances[_token] = nextBalance;

        return nextBalance.sub(prevBalance);
    }

    function _transferOut(address _token, uint256 _amount, address _receiver) private {
        IERC20(_token).safeTransfer(_receiver, _amount);
        tokenBalances[_token] = IERC20(_token).balanceOf(address(this));
    }

    function _updateTokenBalance(address _token) private {
        uint256 nextBalance = IERC20(_token).balanceOf(address(this));
        tokenBalances[_token] = nextBalance;
    }

    function _increasePoolAmount(address _token, uint256 _amount) private {
        poolAmounts[_token] = poolAmounts[_token].add(_amount);
        uint256 balance = IERC20(_token).balanceOf(address(this));
        _validate(poolAmounts[_token] <= balance, 49);
        emit IncreasePoolAmount(_token, _amount);
    }

    function _decreasePoolAmount(address _token, uint256 _amount) private {
        poolAmounts[_token] = poolAmounts[_token].sub(_amount, "Vault: poolAmount exceeded");
        _validate(reservedAmounts[_token] <= poolAmounts[_token], 50);
        emit DecreasePoolAmount(_token, _amount);
    }

    function _validateBufferAmount(address _token) private view {
        if (poolAmounts[_token] < bufferAmounts[_token]) {
            revert("Vault: poolAmount < buffer");
        }
    }

    function _increaseBxdAmount(address _token, uint256 _amount) private {
        bxdAmounts[_token] = bxdAmounts[_token].add(_amount);
        uint256 maxBxdAmount = maxBxdAmounts[_token];
        if (maxBxdAmount != 0) {
            _validate(bxdAmounts[_token] <= maxBxdAmount, 51);
        }
        emit IncreaseBxdAmount(_token, _amount);
    }

    function _decreaseBxdAmount(address _token, uint256 _amount) private {
        uint256 value = bxdAmounts[_token];
        // since BXD can be minted using multiple assets
        // it is possible for the BXD debt for a single asset to be less than zero
        // the BXD debt is capped to zero for this case
        if (value <= _amount) {
            bxdAmounts[_token] = 0;
            emit DecreaseBxdAmount(_token, value);
            return;
        }
        bxdAmounts[_token] = value.sub(_amount);
        emit DecreaseBxdAmount(_token, _amount);
    }

    function _increaseReservedAmount(address _token, uint256 _amount) private {
        reservedAmounts[_token] = reservedAmounts[_token].add(_amount);
        _validate(reservedAmounts[_token] <= poolAmounts[_token], 52);
        emit IncreaseReservedAmount(_token, _amount);
    }

    function _decreaseReservedAmount(address _token, uint256 _amount) private {
        reservedAmounts[_token] = reservedAmounts[_token].sub(_amount, "Vault: insufficient reserve");
        emit DecreaseReservedAmount(_token, _amount);
    }

    function _increaseGuaranteedUsd(address _token, uint256 _usdAmount) private {
        guaranteedUsd[_token] = guaranteedUsd[_token].add(_usdAmount);
        emit IncreaseGuaranteedUsd(_token, _usdAmount);
    }

    function _decreaseGuaranteedUsd(address _token, uint256 _usdAmount) private {
        guaranteedUsd[_token] = guaranteedUsd[_token].sub(_usdAmount);
        emit DecreaseGuaranteedUsd(_token, _usdAmount);
    }

    function _increaseGlobalShortSize(address _token, uint256 _amount) internal {
        globalShortSizes[_token] = globalShortSizes[_token].add(_amount);

        uint256 maxSize = maxGlobalShortSizes[_token];
        if (maxSize != 0) {
            require(globalShortSizes[_token] <= maxSize, "Vault: max shorts exceeded");
        }
    }

    function _decreaseGlobalShortSize(address _token, uint256 _amount) private {
        uint256 size = globalShortSizes[_token];
        if (_amount > size) {
          globalShortSizes[_token] = 0;
          return;
        }

        globalShortSizes[_token] = size.sub(_amount);
    }

    // we have this validation as a function instead of a modifier to reduce contract size
    function _onlyGov() private view {
        _validate(msg.sender == gov, 53);
    }

    // we have this validation as a function instead of a modifier to reduce contract size
    function _validateManager() private view {
        if (inManagerMode) {
            _validate(isManager[msg.sender], 54);
        }
    }

    // we have this validation as a function instead of a modifier to reduce contract size
    function _validateGasPrice() private view {
        if (maxGasPrice == 0) { return; }
        _validate(tx.gasprice <= maxGasPrice, 55);
    }

    function _validate(bool _condition, uint256 _errorCode) private view {
        require(_condition, errors[_errorCode]);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./interfaces/IVault.sol";
import "../access/Governable.sol";

contract VaultErrorController is Governable {
    function setErrors(IVault _vault, string[] calldata _errors) external onlyGov {
        for (uint256 i = 0; i < _errors.length; i++) {
            _vault.setError(i, _errors[i]);
        }
    }
}

// SPDX-License-Identifier: MIT

import "../libraries/math/SafeMath.sol";

import "./interfaces/IVaultPriceFeed.sol";
import "../oracle/interfaces/IPriceFeed.sol";
import "../oracle/interfaces/ISecondaryPriceFeed.sol";
import "../oracle/interfaces/IChainlinkFlags.sol";
import "../amm/interfaces/IAmmPair.sol";

pragma solidity 0.6.12;

contract VaultPriceFeed is IVaultPriceFeed {
    using SafeMath for uint256;

    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant ONE_USD = PRICE_PRECISION;
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant MAX_SPREAD_BASIS_POINTS = 50;
    uint256 public constant MAX_ADJUSTMENT_INTERVAL = 2 hours;
    uint256 public constant MAX_ADJUSTMENT_BASIS_POINTS = 20;

    // Identifier of the Sequencer offline flag on the Flags contract
    address constant private FLAG_ARBITRUM_SEQ_OFFLINE = address(bytes20(bytes32(uint256(keccak256("chainlink.flags.arbitrum-seq-offline")) - 1)));

    address public gov;
    address public chainlinkFlags;

    bool public isAmmEnabled = true;
    bool public isSecondaryPriceEnabled = true;
    bool public useV2Pricing = false;
    bool public favorPrimaryPrice = false;
    uint256 public priceSampleSpace = 3;
    uint256 public maxStrictPriceDeviation = 0;
    address public secondaryPriceFeed;
    uint256 public spreadThresholdBasisPoints = 30;

    address public btc;
    address public eth;
    address public bnb;
    address public bnbBusd;
    address public ethBnb;
    address public btcBnb;

    mapping (address => address) public priceFeeds;
    mapping (address => uint256) public priceDecimals;
    mapping (address => uint256) public spreadBasisPoints;
    // Chainlink can return prices for stablecoins
    // that differs from 1 USD by a larger percentage than stableSwapFeeBasisPoints
    // we use strictStableTokens to cap the price to 1 USD
    // this allows us to configure stablecoins like DAI as being a stableToken
    // while not being a strictStableToken
    mapping (address => bool) public strictStableTokens;

    mapping (address => uint256) public override adjustmentBasisPoints;
    mapping (address => bool) public override isAdjustmentAdditive;
    mapping (address => uint256) public lastAdjustmentTimings;

    modifier onlyGov() {
        require(msg.sender == gov, "VaultPriceFeed: forbidden");
        _;
    }

    constructor() public {
        gov = msg.sender;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function setChainlinkFlags(address _chainlinkFlags) external onlyGov {
        chainlinkFlags = _chainlinkFlags;
    }

    function setAdjustment(address _token, bool _isAdditive, uint256 _adjustmentBps) external override onlyGov {
        require(
            lastAdjustmentTimings[_token].add(MAX_ADJUSTMENT_INTERVAL) < block.timestamp,
            "VaultPriceFeed: adjustment frequency exceeded"
        );
        require(_adjustmentBps <= MAX_ADJUSTMENT_BASIS_POINTS, "invalid _adjustmentBps");
        isAdjustmentAdditive[_token] = _isAdditive;
        adjustmentBasisPoints[_token] = _adjustmentBps;
        lastAdjustmentTimings[_token] = block.timestamp;
    }

    function setUseV2Pricing(bool _useV2Pricing) external override onlyGov {
        useV2Pricing = _useV2Pricing;
    }

    function setIsAmmEnabled(bool _isEnabled) external override onlyGov {
        isAmmEnabled = _isEnabled;
    }

    function setIsSecondaryPriceEnabled(bool _isEnabled) external override onlyGov {
        isSecondaryPriceEnabled = _isEnabled;
    }

    function setSecondaryPriceFeed(address _secondaryPriceFeed) external onlyGov {
        secondaryPriceFeed = _secondaryPriceFeed;
    }

    function setTokens(address _btc, address _eth, address _bnb) external onlyGov {
        btc = _btc;
        eth = _eth;
        bnb = _bnb;
    }

    function setPairs(address _bnbBusd, address _ethBnb, address _btcBnb) external onlyGov {
        bnbBusd = _bnbBusd;
        ethBnb = _ethBnb;
        btcBnb = _btcBnb;
    }

    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints) external override onlyGov {
        require(_spreadBasisPoints <= MAX_SPREAD_BASIS_POINTS, "VaultPriceFeed: invalid _spreadBasisPoints");
        spreadBasisPoints[_token] = _spreadBasisPoints;
    }

    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints) external override onlyGov {
        spreadThresholdBasisPoints = _spreadThresholdBasisPoints;
    }

    function setFavorPrimaryPrice(bool _favorPrimaryPrice) external override onlyGov {
        favorPrimaryPrice = _favorPrimaryPrice;
    }

    function setPriceSampleSpace(uint256 _priceSampleSpace) external override onlyGov {
        require(_priceSampleSpace > 0, "VaultPriceFeed: invalid _priceSampleSpace");
        priceSampleSpace = _priceSampleSpace;
    }

    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation) external override onlyGov {
        maxStrictPriceDeviation = _maxStrictPriceDeviation;
    }

    function setTokenConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable
    ) external override onlyGov {
        priceFeeds[_token] = _priceFeed;
        priceDecimals[_token] = _priceDecimals;
        strictStableTokens[_token] = _isStrictStable;
    }

    function getPrice(address _token, bool _maximise, bool _includeAmmPrice, bool /* _useSwapPricing */) public override view returns (uint256) {
        uint256 price = useV2Pricing ? getPriceV2(_token, _maximise, _includeAmmPrice) : getPriceV1(_token, _maximise, _includeAmmPrice);

        uint256 adjustmentBps = adjustmentBasisPoints[_token];
        if (adjustmentBps > 0) {
            bool isAdditive = isAdjustmentAdditive[_token];
            if (isAdditive) {
                price = price.mul(BASIS_POINTS_DIVISOR.add(adjustmentBps)).div(BASIS_POINTS_DIVISOR);
            } else {
                price = price.mul(BASIS_POINTS_DIVISOR.sub(adjustmentBps)).div(BASIS_POINTS_DIVISOR);
            }
        }

        return price;
    }

    function getPriceV1(address _token, bool _maximise, bool _includeAmmPrice) public view returns (uint256) {
        uint256 price = getPrimaryPrice(_token, _maximise);

        if (_includeAmmPrice && isAmmEnabled) {
            uint256 ammPrice = getAmmPrice(_token);
            if (ammPrice > 0) {
                if (_maximise && ammPrice > price) {
                    price = ammPrice;
                }
                if (!_maximise && ammPrice < price) {
                    price = ammPrice;
                }
            }
        }

        if (isSecondaryPriceEnabled) {
            price = getSecondaryPrice(_token, price, _maximise);
        }

        if (strictStableTokens[_token]) {
            uint256 delta = price > ONE_USD ? price.sub(ONE_USD) : ONE_USD.sub(price);
            if (delta <= maxStrictPriceDeviation) {
                return ONE_USD;
            }

            // if _maximise and price is e.g. 1.02, return 1.02
            if (_maximise && price > ONE_USD) {
                return price;
            }

            // if !_maximise and price is e.g. 0.98, return 0.98
            if (!_maximise && price < ONE_USD) {
                return price;
            }

            return ONE_USD;
        }

        uint256 _spreadBasisPoints = spreadBasisPoints[_token];

        if (_maximise) {
            return price.mul(BASIS_POINTS_DIVISOR.add(_spreadBasisPoints)).div(BASIS_POINTS_DIVISOR);
        }

        return price.mul(BASIS_POINTS_DIVISOR.sub(_spreadBasisPoints)).div(BASIS_POINTS_DIVISOR);
    }

    function getPriceV2(address _token, bool _maximise, bool _includeAmmPrice) public view returns (uint256) {
        uint256 price = getPrimaryPrice(_token, _maximise);

        if (_includeAmmPrice && isAmmEnabled) {
            price = getAmmPriceV2(_token, _maximise, price);
        }

        if (isSecondaryPriceEnabled) {
            price = getSecondaryPrice(_token, price, _maximise);
        }

        if (strictStableTokens[_token]) {
            uint256 delta = price > ONE_USD ? price.sub(ONE_USD) : ONE_USD.sub(price);
            if (delta <= maxStrictPriceDeviation) {
                return ONE_USD;
            }

            // if _maximise and price is e.g. 1.02, return 1.02
            if (_maximise && price > ONE_USD) {
                return price;
            }

            // if !_maximise and price is e.g. 0.98, return 0.98
            if (!_maximise && price < ONE_USD) {
                return price;
            }

            return ONE_USD;
        }

        uint256 _spreadBasisPoints = spreadBasisPoints[_token];

        if (_maximise) {
            return price.mul(BASIS_POINTS_DIVISOR.add(_spreadBasisPoints)).div(BASIS_POINTS_DIVISOR);
        }

        return price.mul(BASIS_POINTS_DIVISOR.sub(_spreadBasisPoints)).div(BASIS_POINTS_DIVISOR);
    }

    function getAmmPriceV2(address _token, bool _maximise, uint256 _primaryPrice) public view returns (uint256) {
        uint256 ammPrice = getAmmPrice(_token);
        if (ammPrice == 0) {
            return _primaryPrice;
        }

        uint256 diff = ammPrice > _primaryPrice ? ammPrice.sub(_primaryPrice) : _primaryPrice.sub(ammPrice);
        if (diff.mul(BASIS_POINTS_DIVISOR) < _primaryPrice.mul(spreadThresholdBasisPoints)) {
            if (favorPrimaryPrice) {
                return _primaryPrice;
            }
            return ammPrice;
        }

        if (_maximise && ammPrice > _primaryPrice) {
            return ammPrice;
        }

        if (!_maximise && ammPrice < _primaryPrice) {
            return ammPrice;
        }

        return _primaryPrice;
    }

    function getLatestPrimaryPrice(address _token) public override view returns (uint256) {
        address priceFeedAddress = priceFeeds[_token];
        require(priceFeedAddress != address(0), "VaultPriceFeed: invalid price feed");

        IPriceFeed priceFeed = IPriceFeed(priceFeedAddress);

        int256 price = priceFeed.latestAnswer();
        require(price > 0, "VaultPriceFeed: invalid price");

        return uint256(price);
    }

    function getPrimaryPrice(address _token, bool _maximise) public override view returns (uint256) {
        address priceFeedAddress = priceFeeds[_token];
        require(priceFeedAddress != address(0), "VaultPriceFeed: invalid price feed");

        if (chainlinkFlags != address(0)) {
            bool isRaised = IChainlinkFlags(chainlinkFlags).getFlag(FLAG_ARBITRUM_SEQ_OFFLINE);
            if (isRaised) {
                    // If flag is raised we shouldn't perform any critical operations
                revert("Chainlink feeds are not being updated");
            }
        }

        IPriceFeed priceFeed = IPriceFeed(priceFeedAddress);

        uint256 price = 0;
        uint80 roundId = priceFeed.latestRound();

        for (uint80 i = 0; i < priceSampleSpace; i++) {
            if (roundId <= i) { break; }
            uint256 p;

            if (i == 0) {
                int256 _p = priceFeed.latestAnswer();
                require(_p > 0, "VaultPriceFeed: invalid price");
                p = uint256(_p);
            } else {
                (, int256 _p, , ,) = priceFeed.getRoundData(roundId - i);
                require(_p > 0, "VaultPriceFeed: invalid price");
                p = uint256(_p);
            }

            if (price == 0) {
                price = p;
                continue;
            }

            if (_maximise && p > price) {
                price = p;
                continue;
            }

            if (!_maximise && p < price) {
                price = p;
            }
        }

        require(price > 0, "VaultPriceFeed: could not fetch price");
        // normalise price precision
        uint256 _priceDecimals = priceDecimals[_token];
        return price.mul(PRICE_PRECISION).div(10 ** _priceDecimals);
    }

    function getSecondaryPrice(address _token, uint256 _referencePrice, bool _maximise) public view returns (uint256) {
        if (secondaryPriceFeed == address(0)) { return _referencePrice; }
        return ISecondaryPriceFeed(secondaryPriceFeed).getPrice(_token, _referencePrice, _maximise);
    }

    function getAmmPrice(address _token) public override view returns (uint256) {
        if (_token == bnb) {
            // for bnbBusd, reserve0: BNB, reserve1: BUSD
            return getPairPrice(bnbBusd, true);
        }

        if (_token == eth) {
            uint256 price0 = getPairPrice(bnbBusd, true);
            // for ethBnb, reserve0: ETH, reserve1: BNB
            uint256 price1 = getPairPrice(ethBnb, true);
            // this calculation could overflow if (price0 / 10**30) * (price1 / 10**30) is more than 10**17
            return price0.mul(price1).div(PRICE_PRECISION);
        }

        if (_token == btc) {
            uint256 price0 = getPairPrice(bnbBusd, true);
            // for btcBnb, reserve0: BTC, reserve1: BNB
            uint256 price1 = getPairPrice(btcBnb, true);
            // this calculation could overflow if (price0 / 10**30) * (price1 / 10**30) is more than 10**17
            return price0.mul(price1).div(PRICE_PRECISION);
        }

        return 0;
    }

    // if divByReserve0: calculate price as reserve1 / reserve0
    // if !divByReserve1: calculate price as reserve0 / reserve1
    function getPairPrice(address _pair, bool _divByReserve0) public view returns (uint256) {
        (uint256 reserve0, uint256 reserve1, ) = IAmmPair(_pair).getReserves();
        if (_divByReserve0) {
            if (reserve0 == 0) { return 0; }
            return reserve1.mul(PRICE_PRECISION).div(reserve0);
        }
        if (reserve1 == 0) { return 0; }
        return reserve0.mul(PRICE_PRECISION).div(reserve1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IVaultUtils.sol";

import "../access/Governable.sol";

contract VaultUtils is IVaultUtils, Governable {
    using SafeMath for uint256;

    struct Position {
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        uint256 entryFundingRate;
        uint256 reserveAmount;
        int256 realisedPnl;
        uint256 lastIncreasedTime;
    }

    IVault public vault;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant FUNDING_RATE_PRECISION = 1000000;

    constructor(IVault _vault) public {
        vault = _vault;
    }

    function updateCumulativeFundingRate(address /* _collateralToken */, address /* _indexToken */) public override returns (bool) {
        return true;
    }

    function validateIncreasePosition(address /* _account */, address /* _collateralToken */, address /* _indexToken */, uint256 /* _sizeDelta */, bool /* _isLong */) external override view {
        // no additional validations
    }

    function validateDecreasePosition(address /* _account */, address /* _collateralToken */, address /* _indexToken */ , uint256 /* _collateralDelta */, uint256 /* _sizeDelta */, bool /* _isLong */, address /* _receiver */) external override view {
        // no additional validations
    }

    function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong) internal view returns (Position memory) {
        IVault _vault = vault;
        Position memory position;
        {
            (uint256 size, uint256 collateral, uint256 averagePrice, uint256 entryFundingRate, /* reserveAmount */, /* realisedPnl */, /* hasProfit */, uint256 lastIncreasedTime) = _vault.getPosition(_account, _collateralToken, _indexToken, _isLong);
            position.size = size;
            position.collateral = collateral;
            position.averagePrice = averagePrice;
            position.entryFundingRate = entryFundingRate;
            position.lastIncreasedTime = lastIncreasedTime;
        }
        return position;
    }

    function validateLiquidation(address _account, address _collateralToken, address _indexToken, bool _isLong, bool _raise) public view override returns (uint256, uint256) {
        Position memory position = getPosition(_account, _collateralToken, _indexToken, _isLong);
        IVault _vault = vault;

        (bool hasProfit, uint256 delta) = _vault.getDelta(_indexToken, position.size, position.averagePrice, _isLong, position.lastIncreasedTime);
        uint256 marginFees = getFundingFee(_account, _collateralToken, _indexToken, _isLong, position.size, position.entryFundingRate);
        marginFees = marginFees.add(getPositionFee(_account, _collateralToken, _indexToken, _isLong, position.size));

        if (!hasProfit && position.collateral < delta) {
            if (_raise) { revert("Vault: losses exceed collateral"); }
            return (1, marginFees);
        }

        uint256 remainingCollateral = position.collateral;
        if (!hasProfit) {
            remainingCollateral = position.collateral.sub(delta);
        }

        if (remainingCollateral < marginFees) {
            if (_raise) { revert("Vault: fees exceed collateral"); }
            // cap the fees to the remainingCollateral
            return (1, remainingCollateral);
        }

        if (remainingCollateral < marginFees.add(_vault.liquidationFeeUsd())) {
            if (_raise) { revert("Vault: liquidation fees exceed collateral"); }
            return (1, marginFees);
        }

        if (remainingCollateral.mul(_vault.maxLeverage()) < position.size.mul(BASIS_POINTS_DIVISOR)) {
            if (_raise) { revert("Vault: maxLeverage exceeded"); }
            return (2, marginFees);
        }

        return (0, marginFees);
    }

    function getEntryFundingRate(address _collateralToken, address /* _indexToken */, bool /* _isLong */) public override view returns (uint256) {
        return vault.cumulativeFundingRates(_collateralToken);
    }

    function getPositionFee(address /* _account */, address /* _collateralToken */, address /* _indexToken */, bool /* _isLong */, uint256 _sizeDelta) public override view returns (uint256) {
        if (_sizeDelta == 0) { return 0; }
        uint256 afterFeeUsd = _sizeDelta.mul(BASIS_POINTS_DIVISOR.sub(vault.marginFeeBasisPoints())).div(BASIS_POINTS_DIVISOR);
        return _sizeDelta.sub(afterFeeUsd);
    }

    function getFundingFee(address /* _account */, address _collateralToken, address /* _indexToken */, bool /* _isLong */, uint256 _size, uint256 _entryFundingRate) public override view returns (uint256) {
        if (_size == 0) { return 0; }

        uint256 fundingRate = vault.cumulativeFundingRates(_collateralToken).sub(_entryFundingRate);
        if (fundingRate == 0) { return 0; }

        return _size.mul(fundingRate).div(FUNDING_RATE_PRECISION);
    }

    function getBuyBxdFeeBasisPoints(address _token, uint256 _bxdAmount) public override view returns (uint256) {
        return getFeeBasisPoints(_token, _bxdAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), true);
    }

    function getSellBxdFeeBasisPoints(address _token, uint256 _bxdAmount) public override view returns (uint256) {
        return getFeeBasisPoints(_token, _bxdAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), false);
    }

    function getSwapFeeBasisPoints(address _tokenIn, address _tokenOut, uint256 _bxdAmount) public override view returns (uint256) {
        bool isStableSwap = vault.stableTokens(_tokenIn) && vault.stableTokens(_tokenOut);
        uint256 baseBps = isStableSwap ? vault.stableSwapFeeBasisPoints() : vault.swapFeeBasisPoints();
        uint256 taxBps = isStableSwap ? vault.stableTaxBasisPoints() : vault.taxBasisPoints();
        uint256 feesBasisPoints0 = getFeeBasisPoints(_tokenIn, _bxdAmount, baseBps, taxBps, true);
        uint256 feesBasisPoints1 = getFeeBasisPoints(_tokenOut, _bxdAmount, baseBps, taxBps, false);
        // use the higher of the two fee basis points
        return feesBasisPoints0 > feesBasisPoints1 ? feesBasisPoints0 : feesBasisPoints1;
    }

    // cases to consider
    // 1. initialAmount is far from targetAmount, action increases balance slightly => high rebate
    // 2. initialAmount is far from targetAmount, action increases balance largely => high rebate
    // 3. initialAmount is close to targetAmount, action increases balance slightly => low rebate
    // 4. initialAmount is far from targetAmount, action reduces balance slightly => high tax
    // 5. initialAmount is far from targetAmount, action reduces balance largely => high tax
    // 6. initialAmount is close to targetAmount, action reduces balance largely => low tax
    // 7. initialAmount is above targetAmount, nextAmount is below targetAmount and vice versa
    // 8. a large swap should have similar fees as the same trade split into multiple smaller swaps
    function getFeeBasisPoints(address _token, uint256 _bxdDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) public override view returns (uint256) {
        if (!vault.hasDynamicFees()) { return _feeBasisPoints; }

        uint256 initialAmount = vault.bxdAmounts(_token);
        uint256 nextAmount = initialAmount.add(_bxdDelta);
        if (!_increment) {
            nextAmount = _bxdDelta > initialAmount ? 0 : initialAmount.sub(_bxdDelta);
        }

        uint256 targetAmount = vault.getTargetBxdAmount(_token);
        if (targetAmount == 0) { return _feeBasisPoints; }

        uint256 initialDiff = initialAmount > targetAmount ? initialAmount.sub(targetAmount) : targetAmount.sub(initialAmount);
        uint256 nextDiff = nextAmount > targetAmount ? nextAmount.sub(targetAmount) : targetAmount.sub(nextAmount);

        // action improves relative asset balance
        if (nextDiff < initialDiff) {
            uint256 rebateBps = _taxBasisPoints.mul(initialDiff).div(targetAmount);
            return rebateBps > _feeBasisPoints ? 0 : _feeBasisPoints.sub(rebateBps);
        }

        uint256 averageDiff = initialDiff.add(nextDiff).div(2);
        if (averageDiff > targetAmount) {
            averageDiff = targetAmount;
        }
        uint256 taxBps = _taxBasisPoints.mul(averageDiff).div(targetAmount);
        return _feeBasisPoints.add(taxBps);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "./interfaces/IGMT.sol";
import "../peripherals/interfaces/ITimelockTarget.sol";

contract GMT is IERC20, IGMT, ITimelockTarget {
    using SafeMath for uint256;

    string public constant name = "Gambit";
    string public constant symbol = "GMT";
    uint8 public constant decimals = 18;

    uint256 public override totalSupply;
    address public gov;

    bool public hasActiveMigration;
    uint256 public migrationTime;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowances;

    mapping (address => bool) public admins;

    // only checked when hasActiveMigration is true
    // this can be used to block the AMM pair as a recipient
    // and protect liquidity providers during a migration
    // by disabling the selling of GMT
    mapping (address => bool) public blockedRecipients;

    // only checked when hasActiveMigration is true
    // this can be used for:
    // - only allowing tokens to be transferred by the distribution contract
    // during the initial distribution phase, this would prevent token buyers
    // from adding liquidity before the initial liquidity is seeded
    // - only allowing removal of GMT liquidity and no other actions
    // during the migration phase
    mapping (address => bool) public allowedMsgSenders;

    modifier onlyGov() {
        require(msg.sender == gov, "GMT: forbidden");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "GMT: forbidden");
        _;
    }

    constructor(uint256 _initialSupply) public {
        gov = msg.sender;
        admins[msg.sender] = true;
        _mint(msg.sender, _initialSupply);
    }

    function setGov(address _gov) external override onlyGov {
        gov = _gov;
    }

    function addAdmin(address _account) external onlyGov {
        admins[_account] = true;
    }

    function removeAdmin(address _account) external onlyGov {
        admins[_account] = false;
    }

    function setNextMigrationTime(uint256 _migrationTime) external onlyGov {
        require(_migrationTime > migrationTime, "GMT: invalid _migrationTime");
        migrationTime = _migrationTime;
    }

    function beginMigration() external override onlyAdmin {
        require(block.timestamp > migrationTime, "GMT: migrationTime not yet passed");
        hasActiveMigration = true;
    }

    function endMigration() external override onlyAdmin {
        hasActiveMigration = false;
    }

    function addBlockedRecipient(address _recipient) external onlyGov {
        blockedRecipients[_recipient] = true;
    }

    function removeBlockedRecipient(address _recipient) external onlyGov {
        blockedRecipients[_recipient] = false;
    }

    function addMsgSender(address _msgSender) external onlyGov {
        allowedMsgSenders[_msgSender] = true;
    }

    function removeMsgSender(address _msgSender) external onlyGov {
        allowedMsgSenders[_msgSender] = false;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external override onlyGov {
        IERC20(_token).transfer(_account, _amount);
    }

    function balanceOf(address _account) external view override returns (uint256) {
        return balances[_account];
    }

    function transfer(address _recipient, uint256 _amount) external override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) external view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) external override returns (bool) {
        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "GMT: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "GMT: transfer from the zero address");
        require(_recipient != address(0), "GMT: transfer to the zero address");

        if (hasActiveMigration) {
            require(allowedMsgSenders[msg.sender], "GMT: forbidden msg.sender");
            require(!blockedRecipients[_recipient], "GMT: forbidden recipient");
        }

        balances[_sender] = balances[_sender].sub(_amount, "GMT: transfer amount exceeds balance");
        balances[_recipient] = balances[_recipient].add(_amount);

        emit Transfer(_sender, _recipient,_amount);
    }

    function _mint(address _account, uint256 _amount) private {
        require(_account != address(0), "GMT: mint to the zero address");

        totalSupply = totalSupply.add(_amount);
        balances[_account] = balances[_account].add(_amount);

        emit Transfer(address(0), _account, _amount);
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "GMT: approve from the zero address");
        require(_spender != address(0), "GMT: approve to the zero address");

        allowances[_owner][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IGMT {
    function beginMigration() external;
    function endMigration() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "../amm/interfaces/IAmmRouter.sol";
import "./interfaces/IGMT.sol";
import "../peripherals/interfaces/ITimelockTarget.sol";

contract Treasury is ReentrancyGuard, ITimelockTarget {
    using SafeMath for uint256;

    uint256 constant PRECISION = 1000000;
    uint256 constant BASIS_POINTS_DIVISOR = 10000;

    bool public isInitialized;
    bool public isSwapActive = true;
    bool public isLiquidityAdded = false;

    address public gmt;
    address public busd;
    address public router;
    address public fund;

    uint256 public gmtPresalePrice;
    uint256 public gmtListingPrice;
    uint256 public busdSlotCap;
    uint256 public busdHardCap;
    uint256 public busdBasisPoints;
    uint256 public unlockTime;

    uint256 public busdReceived;

    address public gov;

    mapping (address => uint256) public swapAmounts;
    mapping (address => bool) public swapWhitelist;

    modifier onlyGov() {
        require(msg.sender == gov, "Treasury: forbidden");
        _;
    }

    constructor() public {
        gov = msg.sender;
    }

    function initialize(
        address[] memory _addresses,
        uint256[] memory _values
    ) external onlyGov {
        require(!isInitialized, "Treasury: already initialized");
        isInitialized = true;

        gmt = _addresses[0];
        busd = _addresses[1];
        router = _addresses[2];
        fund = _addresses[3];

        gmtPresalePrice = _values[0];
        gmtListingPrice = _values[1];
        busdSlotCap = _values[2];
        busdHardCap = _values[3];
        busdBasisPoints = _values[4];
        unlockTime = _values[5];
    }

    function setGov(address _gov) external override onlyGov nonReentrant {
        gov = _gov;
    }

    function setFund(address _fund) external onlyGov nonReentrant {
        fund = _fund;
    }

    function extendUnlockTime(uint256 _unlockTime) external onlyGov nonReentrant {
        require(_unlockTime > unlockTime, "Treasury: invalid _unlockTime");
        unlockTime = _unlockTime;
    }

    function addWhitelists(address[] memory _accounts) external onlyGov nonReentrant {
        for (uint256 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];
            swapWhitelist[account] = true;
        }
    }

    function removeWhitelists(address[] memory _accounts) external onlyGov nonReentrant {
        for (uint256 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];
            swapWhitelist[account] = false;
        }
    }

    function updateWhitelist(address prevAccount, address nextAccount) external onlyGov nonReentrant {
        require(swapWhitelist[prevAccount], "Treasury: invalid prevAccount");
        swapWhitelist[prevAccount] = false;
        swapWhitelist[nextAccount] = true;
    }

    function swap(uint256 _busdAmount) external nonReentrant {
        address account = msg.sender;
        require(swapWhitelist[account], "Treasury: forbidden");
        require(isSwapActive, "Treasury: swap is no longer active");
        require(_busdAmount > 0, "Treasury: invalid _busdAmount");

        busdReceived = busdReceived.add(_busdAmount);
        require(busdReceived <= busdHardCap, "Treasury: busdHardCap exceeded");

        swapAmounts[account] = swapAmounts[account].add(_busdAmount);
        require(swapAmounts[account] <= busdSlotCap, "Treasury: busdSlotCap exceeded");

        // receive BUSD
        uint256 busdBefore = IERC20(busd).balanceOf(address(this));
        IERC20(busd).transferFrom(account, address(this), _busdAmount);
        uint256 busdAfter = IERC20(busd).balanceOf(address(this));
        require(busdAfter.sub(busdBefore) == _busdAmount, "Treasury: invalid transfer");

        // send GMT
        uint256 gmtAmount = _busdAmount.mul(PRECISION).div(gmtPresalePrice);
        IERC20(gmt).transfer(account, gmtAmount);
    }

    function addLiquidity() external onlyGov nonReentrant {
        require(!isLiquidityAdded, "Treasury: liquidity already added");
        isLiquidityAdded = true;

        uint256 busdAmount = busdReceived.mul(busdBasisPoints).div(BASIS_POINTS_DIVISOR);
        uint256 gmtAmount = busdAmount.mul(PRECISION).div(gmtListingPrice);

        IERC20(busd).approve(router, busdAmount);
        IERC20(gmt).approve(router, gmtAmount);

        IGMT(gmt).endMigration();

        IAmmRouter(router).addLiquidity(
            busd, // tokenA
            gmt, // tokenB
            busdAmount, // amountADesired
            gmtAmount, // amountBDesired
            0, // amountAMin
            0, // amountBMin
            address(this), // to
            block.timestamp // deadline
        );

        IGMT(gmt).beginMigration();

        uint256 fundAmount = busdReceived.sub(busdAmount);
        IERC20(busd).transfer(fund, fundAmount);
    }

    function withdrawToken(address _token, address _account, uint256 _amount) external override onlyGov nonReentrant {
        require(block.timestamp > unlockTime, "Treasury: unlockTime not yet passed");
        IERC20(_token).transfer(_account, _amount);
    }

    function increaseBusdBasisPoints(uint256 _busdBasisPoints) external onlyGov nonReentrant {
        require(_busdBasisPoints > busdBasisPoints, "Treasury: invalid _busdBasisPoints");
        busdBasisPoints = _busdBasisPoints;
    }

    function endSwap() external onlyGov nonReentrant {
        isSwapActive = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../GSN/Context.sol";
import "./IERC20.sol";
import "../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "../math/SafeMath.sol";
import "../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

import "../libraries/math/SafeMath.sol";

import "./interfaces/IFastPriceEvents.sol";
import "../access/Governable.sol";

pragma solidity 0.6.12;

contract FastPriceEvents is IFastPriceEvents, Governable {

    mapping (address => bool) public isPriceFeed;
    event PriceUpdate(address token, uint256 price, address priceFeed);

    function setIsPriceFeed(address _priceFeed, bool _isPriceFeed) external onlyGov {
      isPriceFeed[_priceFeed] = _isPriceFeed;
    }

    function emitPriceEvent(address _token, uint256 _price) external override {
      require(isPriceFeed[msg.sender], "FastPriceEvents: invalid sender");
      emit PriceUpdate(_token, _price, msg.sender);
    }
}

// SPDX-License-Identifier: MIT

import "../libraries/math/SafeMath.sol";

import "./interfaces/ISecondaryPriceFeed.sol";
import "./interfaces/IFastPriceFeed.sol";
import "./interfaces/IFastPriceEvents.sol";
import "../core/interfaces/IVaultPriceFeed.sol";
import "../core/interfaces/IPositionRouter.sol";
import "../access/Governable.sol";

pragma solidity 0.6.12;

contract FastPriceFeed is ISecondaryPriceFeed, IFastPriceFeed, Governable {
    using SafeMath for uint256;

    // fit data in a uint256 slot to save gas costs
    struct PriceDataItem {
        uint160 refPrice; // Chainlink price
        uint32 refTime; // last updated at time
        uint32 cumulativeRefDelta; // cumulative Chainlink price delta
        uint32 cumulativeFastDelta; // cumulative fast price delta
    }

    uint256 public constant PRICE_PRECISION = 10 ** 30;

    uint256 public constant CUMULATIVE_DELTA_PRECISION = 10 * 1000 * 1000;

    uint256 public constant MAX_REF_PRICE = type(uint160).max;
    uint256 public constant MAX_CUMULATIVE_REF_DELTA = type(uint32).max;
    uint256 public constant MAX_CUMULATIVE_FAST_DELTA = type(uint32).max;

    // uint256(~0) is 256 bits of 1s
    // shift the 1s by (256 - 32) to get (256 - 32) 0s followed by 32 1s
    uint256 constant public BITMASK_32 = uint256(~0) >> (256 - 32);

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    uint256 public constant MAX_PRICE_DURATION = 30 minutes;

    bool public isInitialized;
    bool public isSpreadEnabled = false;

    address public vaultPriceFeed;
    address public fastPriceEvents;

    address public tokenManager;

    uint256 public override lastUpdatedAt;
    uint256 public override lastUpdatedBlock;

    uint256 public priceDuration;
    uint256 public maxPriceUpdateDelay;
    uint256 public spreadBasisPointsIfInactive;
    uint256 public spreadBasisPointsIfChainError;
    uint256 public minBlockInterval;
    uint256 public maxTimeDeviation;

    uint256 public priceDataInterval;

    // allowed deviation from primary price
    uint256 public maxDeviationBasisPoints;

    uint256 public minAuthorizations;
    uint256 public disableFastPriceVoteCount = 0;

    mapping (address => bool) public isUpdater;

    mapping (address => uint256) public prices;
    mapping (address => PriceDataItem) public priceData;
    mapping (address => uint256) public maxCumulativeDeltaDiffs;

    mapping (address => bool) public isSigner;
    mapping (address => bool) public disableFastPriceVotes;

    // array of tokens used in setCompactedPrices, saves L1 calldata gas costs
    address[] public tokens;
    // array of tokenPrecisions used in setCompactedPrices, saves L1 calldata gas costs
    // if the token price will be sent with 3 decimals, then tokenPrecision for that token
    // should be 10 ** 3
    uint256[] public tokenPrecisions;

    event DisableFastPrice(address signer);
    event EnableFastPrice(address signer);
    event PriceData(address token, uint256 refPrice, uint256 fastPrice, uint256 cumulativeRefDelta, uint256 cumulativeFastDelta);
    event MaxCumulativeDeltaDiffExceeded(address token, uint256 refPrice, uint256 fastPrice, uint256 cumulativeRefDelta, uint256 cumulativeFastDelta);

    modifier onlySigner() {
        require(isSigner[msg.sender], "FastPriceFeed: forbidden");
        _;
    }

    modifier onlyUpdater() {
        require(isUpdater[msg.sender], "FastPriceFeed: forbidden");
        _;
    }

    modifier onlyTokenManager() {
        require(msg.sender == tokenManager, "FastPriceFeed: forbidden");
        _;
    }

    constructor(
      uint256 _priceDuration,
      uint256 _maxPriceUpdateDelay,
      uint256 _minBlockInterval,
      uint256 _maxDeviationBasisPoints,
      address _fastPriceEvents,
      address _tokenManager
    ) public {
        require(_priceDuration <= MAX_PRICE_DURATION, "FastPriceFeed: invalid _priceDuration");
        priceDuration = _priceDuration;
        maxPriceUpdateDelay = _maxPriceUpdateDelay;
        minBlockInterval = _minBlockInterval;
        maxDeviationBasisPoints = _maxDeviationBasisPoints;
        fastPriceEvents = _fastPriceEvents;
        tokenManager = _tokenManager;
    }

    function initialize(uint256 _minAuthorizations, address[] memory _signers, address[] memory _updaters) public onlyGov {
        require(!isInitialized, "FastPriceFeed: already initialized");
        isInitialized = true;

        minAuthorizations = _minAuthorizations;

        for (uint256 i = 0; i < _signers.length; i++) {
            address signer = _signers[i];
            isSigner[signer] = true;
        }

        for (uint256 i = 0; i < _updaters.length; i++) {
            address updater = _updaters[i];
            isUpdater[updater] = true;
        }
    }

    function setSigner(address _account, bool _isActive) external override onlyGov {
        isSigner[_account] = _isActive;
    }

    function setUpdater(address _account, bool _isActive) external override onlyGov {
        isUpdater[_account] = _isActive;
    }

    function setFastPriceEvents(address _fastPriceEvents) external onlyGov {
      fastPriceEvents = _fastPriceEvents;
    }

    function setVaultPriceFeed(address _vaultPriceFeed) external override onlyGov {
      vaultPriceFeed = _vaultPriceFeed;
    }

    function setMaxTimeDeviation(uint256 _maxTimeDeviation) external onlyGov {
        maxTimeDeviation = _maxTimeDeviation;
    }

    function setPriceDuration(uint256 _priceDuration) external override onlyGov {
        require(_priceDuration <= MAX_PRICE_DURATION, "FastPriceFeed: invalid _priceDuration");
        priceDuration = _priceDuration;
    }

    function setMaxPriceUpdateDelay(uint256 _maxPriceUpdateDelay) external override onlyGov {
        maxPriceUpdateDelay = _maxPriceUpdateDelay;
    }

    function setSpreadBasisPointsIfInactive(uint256 _spreadBasisPointsIfInactive) external override onlyGov {
        spreadBasisPointsIfInactive = _spreadBasisPointsIfInactive;
    }

    function setSpreadBasisPointsIfChainError(uint256 _spreadBasisPointsIfChainError) external override onlyGov {
        spreadBasisPointsIfChainError = _spreadBasisPointsIfChainError;
    }

    function setMinBlockInterval(uint256 _minBlockInterval) external override onlyGov {
        minBlockInterval = _minBlockInterval;
    }

    function setIsSpreadEnabled(bool _isSpreadEnabled) external override onlyGov {
        isSpreadEnabled = _isSpreadEnabled;
    }

    function setLastUpdatedAt(uint256 _lastUpdatedAt) external onlyGov {
        lastUpdatedAt = _lastUpdatedAt;
    }

    function setTokenManager(address _tokenManager) external onlyTokenManager {
        tokenManager = _tokenManager;
    }

    function setMaxDeviationBasisPoints(uint256 _maxDeviationBasisPoints) external override onlyTokenManager {
        maxDeviationBasisPoints = _maxDeviationBasisPoints;
    }

    function setMaxCumulativeDeltaDiffs(address[] memory _tokens,  uint256[] memory _maxCumulativeDeltaDiffs) external override onlyTokenManager {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            maxCumulativeDeltaDiffs[token] = _maxCumulativeDeltaDiffs[i];
        }
    }

    function setPriceDataInterval(uint256 _priceDataInterval) external override onlyTokenManager {
        priceDataInterval = _priceDataInterval;
    }

    function setMinAuthorizations(uint256 _minAuthorizations) external onlyTokenManager {
        minAuthorizations = _minAuthorizations;
    }

    function setTokens(address[] memory _tokens, uint256[] memory _tokenPrecisions) external onlyGov {
        require(_tokens.length == _tokenPrecisions.length, "FastPriceFeed: invalid lengths");
        tokens = _tokens;
        tokenPrecisions = _tokenPrecisions;
    }

    function setPrices(address[] memory _tokens, uint256[] memory _prices, uint256 _timestamp) external onlyUpdater {
        bool shouldUpdate = _setLastUpdatedValues(_timestamp);

        if (shouldUpdate) {
            address _fastPriceEvents = fastPriceEvents;
            address _vaultPriceFeed = vaultPriceFeed;

            for (uint256 i = 0; i < _tokens.length; i++) {
                address token = _tokens[i];
                _setPrice(token, _prices[i], _vaultPriceFeed, _fastPriceEvents);
            }
        }
    }

    function setCompactedPrices(uint256[] memory _priceBitArray, uint256 _timestamp) external onlyUpdater {
        bool shouldUpdate = _setLastUpdatedValues(_timestamp);

        if (shouldUpdate) {
            address _fastPriceEvents = fastPriceEvents;
            address _vaultPriceFeed = vaultPriceFeed;

            for (uint256 i = 0; i < _priceBitArray.length; i++) {
                uint256 priceBits = _priceBitArray[i];

                for (uint256 j = 0; j < 8; j++) {
                    uint256 index = i * 8 + j;
                    if (index >= tokens.length) { return; }

                    uint256 startBit = 32 * j;
                    uint256 price = (priceBits >> startBit) & BITMASK_32;

                    address token = tokens[i * 8 + j];
                    uint256 tokenPrecision = tokenPrecisions[i * 8 + j];
                    uint256 adjustedPrice = price.mul(PRICE_PRECISION).div(tokenPrecision);

                    _setPrice(token, adjustedPrice, _vaultPriceFeed, _fastPriceEvents);
                }
            }
        }
    }

    function setPricesWithBits(uint256 _priceBits, uint256 _timestamp) external onlyUpdater {
        _setPricesWithBits(_priceBits, _timestamp);
    }

    function setPricesWithBitsAndExecute(
        address _positionRouter,
        uint256 _priceBits,
        uint256 _timestamp,
        uint256 _endIndexForIncreasePositions,
        uint256 _endIndexForDecreasePositions,
        uint256 _maxIncreasePositions,
        uint256 _maxDecreasePositions
    ) external onlyUpdater {
        _setPricesWithBits(_priceBits, _timestamp);

        IPositionRouter positionRouter = IPositionRouter(_positionRouter);
        uint256 maxEndIndexForIncrease = positionRouter.increasePositionRequestKeysStart().add(_maxIncreasePositions);
        uint256 maxEndIndexForDecrease = positionRouter.decreasePositionRequestKeysStart().add(_maxDecreasePositions);

        if (_endIndexForIncreasePositions > maxEndIndexForIncrease) {
            _endIndexForIncreasePositions = maxEndIndexForIncrease;
        }

        if (_endIndexForDecreasePositions > maxEndIndexForDecrease) {
            _endIndexForDecreasePositions = maxEndIndexForDecrease;
        }

        positionRouter.executeIncreasePositions(_endIndexForIncreasePositions, payable(msg.sender));
        positionRouter.executeDecreasePositions(_endIndexForDecreasePositions, payable(msg.sender));
    }

    function disableFastPrice() external onlySigner {
        require(!disableFastPriceVotes[msg.sender], "FastPriceFeed: already voted");
        disableFastPriceVotes[msg.sender] = true;
        disableFastPriceVoteCount = disableFastPriceVoteCount.add(1);

        emit DisableFastPrice(msg.sender);
    }

    function enableFastPrice() external onlySigner {
        require(disableFastPriceVotes[msg.sender], "FastPriceFeed: already enabled");
        disableFastPriceVotes[msg.sender] = false;
        disableFastPriceVoteCount = disableFastPriceVoteCount.sub(1);

        emit EnableFastPrice(msg.sender);
    }

    // under regular operation, the fastPrice (prices[token]) is returned and there is no spread returned from this function,
    // though VaultPriceFeed might apply its own spread
    //
    // if the fastPrice has not been updated within priceDuration then it is ignored and only _refPrice with a spread is used (spread: spreadBasisPointsIfInactive)
    // in case the fastPrice has not been updated for maxPriceUpdateDelay then the _refPrice with a larger spread is used (spread: spreadBasisPointsIfChainError)
    //
    // there will be a spread from the _refPrice to the fastPrice in the following cases:
    // - in case isSpreadEnabled is set to true
    // - in case the maxDeviationBasisPoints between _refPrice and fastPrice is exceeded
    // - in case watchers flag an issue
    // - in case the cumulativeFastDelta exceeds the cumulativeRefDelta by the maxCumulativeDeltaDiff
    function getPrice(address _token, uint256 _refPrice, bool _maximise) external override view returns (uint256) {
        if (block.timestamp > lastUpdatedAt.add(maxPriceUpdateDelay)) {
            if (_maximise) {
                return _refPrice.mul(BASIS_POINTS_DIVISOR.add(spreadBasisPointsIfChainError)).div(BASIS_POINTS_DIVISOR);
            }

            return _refPrice.mul(BASIS_POINTS_DIVISOR.sub(spreadBasisPointsIfChainError)).div(BASIS_POINTS_DIVISOR);
        }

        if (block.timestamp > lastUpdatedAt.add(priceDuration)) {
            if (_maximise) {
                return _refPrice.mul(BASIS_POINTS_DIVISOR.add(spreadBasisPointsIfInactive)).div(BASIS_POINTS_DIVISOR);
            }

            return _refPrice.mul(BASIS_POINTS_DIVISOR.sub(spreadBasisPointsIfInactive)).div(BASIS_POINTS_DIVISOR);
        }

        uint256 fastPrice = prices[_token];
        if (fastPrice == 0) { return _refPrice; }

        uint256 diffBasisPoints = _refPrice > fastPrice ? _refPrice.sub(fastPrice) : fastPrice.sub(_refPrice);
        diffBasisPoints = diffBasisPoints.mul(BASIS_POINTS_DIVISOR).div(_refPrice);

        // create a spread between the _refPrice and the fastPrice if the maxDeviationBasisPoints is exceeded
        // or if watchers have flagged an issue with the fast price
        bool hasSpread = !favorFastPrice(_token) || diffBasisPoints > maxDeviationBasisPoints;

        if (hasSpread) {
            // return the higher of the two prices
            if (_maximise) {
                return _refPrice > fastPrice ? _refPrice : fastPrice;
            }

            // return the lower of the two prices
            return _refPrice < fastPrice ? _refPrice : fastPrice;
        }

        return fastPrice;
    }

    function favorFastPrice(address _token) public view returns (bool) {
        if (isSpreadEnabled) {
            return false;
        }

        if (disableFastPriceVoteCount >= minAuthorizations) {
            // force a spread if watchers have flagged an issue with the fast price
            return false;
        }

        (/* uint256 prevRefPrice */, /* uint256 refTime */, uint256 cumulativeRefDelta, uint256 cumulativeFastDelta) = getPriceData(_token);
        if (cumulativeFastDelta > cumulativeRefDelta && cumulativeFastDelta.sub(cumulativeRefDelta) > maxCumulativeDeltaDiffs[_token]) {
            // force a spread if the cumulative delta for the fast price feed exceeds the cumulative delta
            // for the Chainlink price feed by the maxCumulativeDeltaDiff allowed
            return false;
        }

        return true;
    }

    function getPriceData(address _token) public view returns (uint256, uint256, uint256, uint256) {
        PriceDataItem memory data = priceData[_token];
        return (uint256(data.refPrice), uint256(data.refTime), uint256(data.cumulativeRefDelta), uint256(data.cumulativeFastDelta));
    }

    function _setPricesWithBits(uint256 _priceBits, uint256 _timestamp) private {
        bool shouldUpdate = _setLastUpdatedValues(_timestamp);

        if (shouldUpdate) {
            address _fastPriceEvents = fastPriceEvents;
            address _vaultPriceFeed = vaultPriceFeed;

            for (uint256 j = 0; j < 8; j++) {
                uint256 index = j;
                if (index >= tokens.length) { return; }

                uint256 startBit = 32 * j;
                uint256 price = (_priceBits >> startBit) & BITMASK_32;

                address token = tokens[j];
                uint256 tokenPrecision = tokenPrecisions[j];
                uint256 adjustedPrice = price.mul(PRICE_PRECISION).div(tokenPrecision);

                _setPrice(token, adjustedPrice, _vaultPriceFeed, _fastPriceEvents);
            }
        }
    }

    function _setPrice(address _token, uint256 _price, address _vaultPriceFeed, address _fastPriceEvents) private {
        if (_vaultPriceFeed != address(0)) {
            uint256 refPrice = IVaultPriceFeed(_vaultPriceFeed).getLatestPrimaryPrice(_token);
            uint256 fastPrice = prices[_token];

            (uint256 prevRefPrice, uint256 refTime, uint256 cumulativeRefDelta, uint256 cumulativeFastDelta) = getPriceData(_token);

            if (prevRefPrice > 0) {
                uint256 refDeltaAmount = refPrice > prevRefPrice ? refPrice.sub(prevRefPrice) : prevRefPrice.sub(refPrice);
                uint256 fastDeltaAmount = fastPrice > _price ? fastPrice.sub(_price) : _price.sub(fastPrice);

                // reset cumulative delta values if it is a new time window
                if (refTime.div(priceDataInterval) != block.timestamp.div(priceDataInterval)) {
                    cumulativeRefDelta = 0;
                    cumulativeFastDelta = 0;
                }

                cumulativeRefDelta = cumulativeRefDelta.add(refDeltaAmount.mul(CUMULATIVE_DELTA_PRECISION).div(prevRefPrice));
                cumulativeFastDelta = cumulativeFastDelta.add(fastDeltaAmount.mul(CUMULATIVE_DELTA_PRECISION).div(fastPrice));
            }

            if (cumulativeFastDelta > cumulativeRefDelta && cumulativeFastDelta.sub(cumulativeRefDelta) > maxCumulativeDeltaDiffs[_token]) {
                emit MaxCumulativeDeltaDiffExceeded(_token, refPrice, fastPrice, cumulativeRefDelta, cumulativeFastDelta);
            }

            _setPriceData(_token, refPrice, cumulativeRefDelta, cumulativeFastDelta);
            emit PriceData(_token, refPrice, fastPrice, cumulativeRefDelta, cumulativeFastDelta);
        }

        prices[_token] = _price;
        _emitPriceEvent(_fastPriceEvents, _token, _price);
    }

    function _setPriceData(address _token, uint256 _refPrice, uint256 _cumulativeRefDelta, uint256 _cumulativeFastDelta) private {
        require(_refPrice < MAX_REF_PRICE, "FastPriceFeed: invalid refPrice");
        // skip validation of block.timestamp, it should only be out of range after the year 2100
        require(_cumulativeRefDelta < MAX_CUMULATIVE_REF_DELTA, "FastPriceFeed: invalid cumulativeRefDelta");
        require(_cumulativeFastDelta < MAX_CUMULATIVE_FAST_DELTA, "FastPriceFeed: invalid cumulativeFastDelta");

        priceData[_token] = PriceDataItem(
            uint160(_refPrice),
            uint32(block.timestamp),
            uint32(_cumulativeRefDelta),
            uint32(_cumulativeFastDelta)
        );
    }

    function _emitPriceEvent(address _fastPriceEvents, address _token, uint256 _price) private {
        if (_fastPriceEvents == address(0)) {
            return;
        }

        IFastPriceEvents(_fastPriceEvents).emitPriceEvent(_token, _price);
    }

    function _setLastUpdatedValues(uint256 _timestamp) private returns (bool) {
        if (minBlockInterval > 0) {
            require(block.number.sub(lastUpdatedBlock) >= minBlockInterval, "FastPriceFeed: minBlockInterval not yet passed");
        }

        uint256 _maxTimeDeviation = maxTimeDeviation;
        require(_timestamp > block.timestamp.sub(_maxTimeDeviation), "FastPriceFeed: _timestamp below allowed range");
        require(_timestamp < block.timestamp.add(_maxTimeDeviation), "FastPriceFeed: _timestamp exceeds allowed range");

        // do not update prices if _timestamp is before the current lastUpdatedAt value
        if (_timestamp < lastUpdatedAt) {
            return false;
        }

        lastUpdatedAt = _timestamp;
        lastUpdatedBlock = block.number;

        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IChainlinkFlags {
  function getFlag(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IFastPriceEvents {
    function emitPriceEvent(address _token, uint256 _price) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IFastPriceFeed {
    function lastUpdatedAt() external view returns (uint256);
    function lastUpdatedBlock() external view returns (uint256);
    function setSigner(address _account, bool _isActive) external;
    function setUpdater(address _account, bool _isActive) external;
    function setPriceDuration(uint256 _priceDuration) external;
    function setMaxPriceUpdateDelay(uint256 _maxPriceUpdateDelay) external;
    function setSpreadBasisPointsIfInactive(uint256 _spreadBasisPointsIfInactive) external;
    function setSpreadBasisPointsIfChainError(uint256 _spreadBasisPointsIfChainError) external;
    function setMinBlockInterval(uint256 _minBlockInterval) external;
    function setIsSpreadEnabled(bool _isSpreadEnabled) external;
    function setMaxDeviationBasisPoints(uint256 _maxDeviationBasisPoints) external;
    function setMaxCumulativeDeltaDiffs(address[] memory _tokens,  uint256[] memory _maxCumulativeDeltaDiffs) external;
    function setPriceDataInterval(uint256 _priceDataInterval) external;
    function setVaultPriceFeed(address _vaultPriceFeed) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IPriceFeed {
    function description() external view returns (string memory);
    function aggregator() external view returns (address);
    function latestAnswer() external view returns (int256);
    function latestRound() external view returns (uint80);
    function getRoundData(uint80 roundId) external view returns (uint80, int256, uint256, uint256, uint80);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ISecondaryPriceFeed {
    function getPrice(address _token, uint256 _referencePrice, bool _maximise) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./interfaces/IPriceFeed.sol";

contract PriceFeed is IPriceFeed {
    int256 public answer;
    uint80 public roundId;
    string public override description = "PriceFeed";
    address public override aggregator;

    uint256 public decimals;

    address public gov;

    mapping (uint80 => int256) public answers;
    mapping (address => bool) public isAdmin;

    constructor() public {
        gov = msg.sender;
        isAdmin[msg.sender] = true;
    }

    function setAdmin(address _account, bool _isAdmin) public {
        require(msg.sender == gov, "PriceFeed: forbidden");
        isAdmin[_account] = _isAdmin;
    }

    function latestAnswer() public override view returns (int256) {
        return answer;
    }

    function latestRound() public override view returns (uint80) {
        return roundId;
    }

    function setLatestAnswer(int256 _answer) public {
        require(isAdmin[msg.sender], "PriceFeed: forbidden");
        roundId = roundId + 1;
        answer = _answer;
        answers[roundId] = _answer;
    }

    // returns roundId, answer, startedAt, updatedAt, answeredInRound
    function getRoundData(uint80 _roundId) public override view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (_roundId, answers[_roundId], 0, 0, 0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/math/SafeMath.sol";
import "../core/interfaces/IVault.sol";

contract BalanceUpdater {
    using SafeMath for uint256;

    function updateBalance(
        address _vault,
        address _token,
        address _bxd,
        uint256 _bxdAmount
    ) public {
        IVault vault = IVault(_vault);
        IERC20 token = IERC20(_token);
        uint256 poolAmount = vault.poolAmounts(_token);
        uint256 fee = vault.feeReserves(_token);
        uint256 balance = token.balanceOf(_vault);

        uint256 transferAmount = poolAmount.add(fee).sub(balance);
        token.transferFrom(msg.sender, _vault, transferAmount);
        IERC20(_bxd).transferFrom(msg.sender, _vault, _bxdAmount);

        vault.sellBXD(_token, msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/math/SafeMath.sol";

import "../access/Governable.sol";

contract BatchSender is Governable {
    using SafeMath for uint256;

    mapping (address => bool) public isHandler;

    event BatchSend(
        uint256 indexed typeId,
        address indexed token,
        address[] accounts,
        uint256[] amounts
    );

    modifier onlyHandler() {
        require(isHandler[msg.sender], "BatchSender: forbidden");
        _;
    }

    constructor() public {
        isHandler[msg.sender] = true;
    }

    function setHandler(address _handler, bool _isActive) external onlyGov {
        isHandler[_handler] = _isActive;
    }

    function send(IERC20 _token, address[] memory _accounts, uint256[] memory _amounts) public onlyHandler {
        _send(_token, _accounts, _amounts, 0);
    }

    function sendAndEmit(IERC20 _token, address[] memory _accounts, uint256[] memory _amounts, uint256 _typeId) public onlyHandler {
        _send(_token, _accounts, _amounts, _typeId);
    }

    function _send(IERC20 _token, address[] memory _accounts, uint256[] memory _amounts, uint256 _typeId) private {
        for (uint256 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];
            uint256 amount = _amounts[i];
            _token.transferFrom(msg.sender, account, amount);
        }

        emit BatchSend(_typeId, address(_token), _accounts, _amounts);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./interfaces/ITimelockTarget.sol";
import "./interfaces/IBxpTimelock.sol";
import "./interfaces/IHandlerTarget.sol";
import "../access/interfaces/IAdmin.sol";
import "../core/interfaces/IVault.sol";
import "../core/interfaces/IVaultUtils.sol";
import "../core/interfaces/IVaultPriceFeed.sol";
import "../core/interfaces/IRouter.sol";
import "../tokens/interfaces/IYieldToken.sol";
import "../tokens/interfaces/IBaseToken.sol";
import "../tokens/interfaces/IMintable.sol";
import "../tokens/interfaces/IBXD.sol";
import "../staking/interfaces/IVester.sol";

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";

contract BxpTimelock is IBxpTimelock {
    using SafeMath for uint256;

    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant MAX_BUFFER = 7 days;
    uint256 public constant MAX_FEE_BASIS_POINTS = 300; // 3%
    uint256 public constant MAX_FUNDING_RATE_FACTOR = 200; // 0.02%
    uint256 public constant MAX_LEVERAGE_VALIDATION = 500000; // 50x

    uint256 public buffer;
    uint256 public longBuffer;
    address public admin;

    address public tokenManager;
    address public rewardManager;
    address public mintReceiver;
    uint256 public maxTokenSupply;

    mapping (bytes32 => uint256) public pendingActions;
    mapping (address => bool) public excludedTokens;

    mapping (address => bool) public isHandler;

    event SignalPendingAction(bytes32 action);
    event SignalApprove(address token, address spender, uint256 amount, bytes32 action);
    event SignalWithdrawToken(address target, address token, address receiver, uint256 amount, bytes32 action);
    event SignalMint(address token, address receiver, uint256 amount, bytes32 action);
    event SignalSetGov(address target, address gov, bytes32 action);
    event SignalSetPriceFeed(address vault, address priceFeed, bytes32 action);
    event SignalAddPlugin(address router, address plugin, bytes32 action);
    event SignalRedeemBxd(address vault, address token, uint256 amount);
    event SignalVaultSetTokenConfig(
        address vault,
        address token,
        uint256 tokenDecimals,
        uint256 tokenWeight,
        uint256 minProfitBps,
        uint256 maxBxdAmount,
        bool isStable,
        bool isShortable
    );
    event SignalPriceFeedSetTokenConfig(
        address vaultPriceFeed,
        address token,
        address priceFeed,
        uint256 priceDecimals,
        bool isStrictStable
    );
    event ClearAction(bytes32 action);

    modifier onlyAdmin() {
        require(msg.sender == admin, "BxpTimelock: forbidden");
        _;
    }

    modifier onlyAdminOrHandler() {
        require(msg.sender == admin || isHandler[msg.sender], "BxpTimelock: forbidden");
        _;
    }

    modifier onlyTokenManager() {
        require(msg.sender == tokenManager, "BxpTimelock: forbidden");
        _;
    }

    modifier onlyRewardManager() {
        require(msg.sender == rewardManager, "BxpTimelock: forbidden");
        _;
    }

    constructor(
        address _admin,
        uint256 _buffer,
        uint256 _longBuffer,
        address _rewardManager,
        address _tokenManager,
        address _mintReceiver,
        uint256 _maxTokenSupply
    ) public {
        require(_buffer <= MAX_BUFFER, "BxpTimelock: invalid _buffer");
        require(_longBuffer <= MAX_BUFFER, "BxpTimelock: invalid _longBuffer");
        admin = _admin;
        buffer = _buffer;
        longBuffer = _longBuffer;
        rewardManager = _rewardManager;
        tokenManager = _tokenManager;
        mintReceiver = _mintReceiver;
        maxTokenSupply = _maxTokenSupply;
    }

    function setAdmin(address _admin) external override onlyTokenManager {
        admin = _admin;
    }

    function setExternalAdmin(address _target, address _admin) external onlyAdmin {
        require(_target != address(this), "BxpTimelock: invalid _target");
        IAdmin(_target).setAdmin(_admin);
    }

    function setContractHandler(address _handler, bool _isActive) external onlyAdmin {
        isHandler[_handler] = _isActive;
    }

    function setBuffer(uint256 _buffer) external onlyAdmin {
        require(_buffer <= MAX_BUFFER, "BxpTimelock: invalid _buffer");
        require(_buffer > buffer, "BxpTimelock: buffer cannot be decreased");
        buffer = _buffer;
    }

    function setMaxLeverage(address _vault, uint256 _maxLeverage) external onlyAdmin {
      require(_maxLeverage > MAX_LEVERAGE_VALIDATION, "BxpTimelock: invalid _maxLeverage");
      IVault(_vault).setMaxLeverage(_maxLeverage);
    }

    function setFundingRate(address _vault, uint256 _fundingInterval, uint256 _fundingRateFactor, uint256 _stableFundingRateFactor) external onlyAdmin {
        require(_fundingRateFactor < MAX_FUNDING_RATE_FACTOR, "BxpTimelock: invalid _fundingRateFactor");
        require(_stableFundingRateFactor < MAX_FUNDING_RATE_FACTOR, "BxpTimelock: invalid _stableFundingRateFactor");
        IVault(_vault).setFundingRate(_fundingInterval, _fundingRateFactor, _stableFundingRateFactor);
    }

    function setFees(
        address _vault,
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external onlyAdmin {
        require(_taxBasisPoints < MAX_FEE_BASIS_POINTS, "BxpTimelock: invalid _taxBasisPoints");
        require(_stableTaxBasisPoints < MAX_FEE_BASIS_POINTS, "BxpTimelock: invalid _stableTaxBasisPoints");
        require(_mintBurnFeeBasisPoints < MAX_FEE_BASIS_POINTS, "BxpTimelock: invalid _mintBurnFeeBasisPoints");
        require(_swapFeeBasisPoints < MAX_FEE_BASIS_POINTS, "BxpTimelock: invalid _swapFeeBasisPoints");
        require(_stableSwapFeeBasisPoints < MAX_FEE_BASIS_POINTS, "BxpTimelock: invalid _stableSwapFeeBasisPoints");
        require(_marginFeeBasisPoints < MAX_FEE_BASIS_POINTS, "BxpTimelock: invalid _marginFeeBasisPoints");
        require(_liquidationFeeUsd < 10 * PRICE_PRECISION, "BxpTimelock: invalid _liquidationFeeUsd");

        IVault(_vault).setFees(
            _taxBasisPoints,
            _stableTaxBasisPoints,
            _mintBurnFeeBasisPoints,
            _swapFeeBasisPoints,
            _stableSwapFeeBasisPoints,
            _marginFeeBasisPoints,
            _liquidationFeeUsd,
            _minProfitTime,
            _hasDynamicFees
        );
    }

    function setTokenConfig(
        address _vault,
        address _token,
        uint256 _tokenWeight,
        uint256 _minProfitBps,
        uint256 _maxBxdAmount,
        uint256 _bufferAmount,
        uint256 _bxdAmount
    ) external onlyAdmin {
        require(_minProfitBps <= 500, "BxpTimelock: invalid _minProfitBps");

        IVault vault = IVault(_vault);
        require(vault.whitelistedTokens(_token), "BxpTimelock: token not yet whitelisted");

        uint256 tokenDecimals = vault.tokenDecimals(_token);
        bool isStable = vault.stableTokens(_token);
        bool isShortable = vault.shortableTokens(_token);

        IVault(_vault).setTokenConfig(
            _token,
            tokenDecimals,
            _tokenWeight,
            _minProfitBps,
            _maxBxdAmount,
            isStable,
            isShortable
        );

        IVault(_vault).setBufferAmount(_token, _bufferAmount);

        IVault(_vault).setBxdAmount(_token, _bxdAmount);
    }

    function setMaxGlobalShortSize(address _vault, address _token, uint256 _amount) external onlyAdmin {
        IVault(_vault).setMaxGlobalShortSize(_token, _amount);
    }

    function removeAdmin(address _token, address _account) external onlyAdmin {
        IYieldToken(_token).removeAdmin(_account);
    }

    function setIsAmmEnabled(address _priceFeed, bool _isEnabled) external onlyAdmin {
        IVaultPriceFeed(_priceFeed).setIsAmmEnabled(_isEnabled);
    }

    function setIsSecondaryPriceEnabled(address _priceFeed, bool _isEnabled) external onlyAdmin {
        IVaultPriceFeed(_priceFeed).setIsSecondaryPriceEnabled(_isEnabled);
    }

    function setMaxStrictPriceDeviation(address _priceFeed, uint256 _maxStrictPriceDeviation) external onlyAdmin {
        IVaultPriceFeed(_priceFeed).setMaxStrictPriceDeviation(_maxStrictPriceDeviation);
    }

    function setUseV2Pricing(address _priceFeed, bool _useV2Pricing) external onlyAdmin {
        IVaultPriceFeed(_priceFeed).setUseV2Pricing(_useV2Pricing);
    }

    function setAdjustment(address _priceFeed, address _token, bool _isAdditive, uint256 _adjustmentBps) external onlyAdmin {
        IVaultPriceFeed(_priceFeed).setAdjustment(_token, _isAdditive, _adjustmentBps);
    }

    function setSpreadBasisPoints(address _priceFeed, address _token, uint256 _spreadBasisPoints) external onlyAdmin {
        IVaultPriceFeed(_priceFeed).setSpreadBasisPoints(_token, _spreadBasisPoints);
    }

    function setSpreadThresholdBasisPoints(address _priceFeed, uint256 _spreadThresholdBasisPoints) external onlyAdmin {
        IVaultPriceFeed(_priceFeed).setSpreadThresholdBasisPoints(_spreadThresholdBasisPoints);
    }

    function setFavorPrimaryPrice(address _priceFeed, bool _favorPrimaryPrice) external onlyAdmin {
        IVaultPriceFeed(_priceFeed).setFavorPrimaryPrice(_favorPrimaryPrice);
    }

    function setPriceSampleSpace(address _priceFeed,uint256 _priceSampleSpace) external onlyAdmin {
        require(_priceSampleSpace <= 5, "Invalid _priceSampleSpace");
        IVaultPriceFeed(_priceFeed).setPriceSampleSpace(_priceSampleSpace);
    }

    function setIsSwapEnabled(address _vault, bool _isSwapEnabled) external onlyAdmin {
        IVault(_vault).setIsSwapEnabled(_isSwapEnabled);
    }

    function setIsLeverageEnabled(address _vault, bool _isLeverageEnabled) external override onlyAdminOrHandler {
        IVault(_vault).setIsLeverageEnabled(_isLeverageEnabled);
    }

    function setVaultUtils(address _vault, IVaultUtils _vaultUtils) external onlyAdmin {
        IVault(_vault).setVaultUtils(_vaultUtils);
    }

    function setMaxGasPrice(address _vault,uint256 _maxGasPrice) external onlyAdmin {
        require(_maxGasPrice > 5000000000, "Invalid _maxGasPrice");
        IVault(_vault).setMaxGasPrice(_maxGasPrice);
    }

    function withdrawFees(address _vault,address _token, address _receiver) external onlyAdmin {
        IVault(_vault).withdrawFees(_token, _receiver);
    }

    function setInPrivateLiquidationMode(address _vault, bool _inPrivateLiquidationMode) external onlyAdmin {
        IVault(_vault).setInPrivateLiquidationMode(_inPrivateLiquidationMode);
    }

    function setLiquidator(address _vault, address _liquidator, bool _isActive) external onlyAdmin {
        IVault(_vault).setLiquidator(_liquidator, _isActive);
    }

    function addExcludedToken(address _token) external onlyAdmin {
        excludedTokens[_token] = true;
    }

    function setInPrivateTransferMode(address _token, bool _inPrivateTransferMode) external onlyAdmin {
        if (excludedTokens[_token]) {
            // excludedTokens can only have their transfers enabled
            require(_inPrivateTransferMode == false, "BxpTimelock: invalid _inPrivateTransferMode");
        }

        IBaseToken(_token).setInPrivateTransferMode(_inPrivateTransferMode);
    }

    function transferIn(address _sender, address _token, uint256 _amount) external onlyAdmin {
        IERC20(_token).transferFrom(_sender, address(this), _amount);
    }

    function signalApprove(address _token, address _spender, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("approve", _token, _spender, _amount));
        _setPendingAction(action);
        emit SignalApprove(_token, _spender, _amount, action);
    }

    function approve(address _token, address _spender, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("approve", _token, _spender, _amount));
        _validateAction(action);
        _clearAction(action);
        IERC20(_token).approve(_spender, _amount);
    }

    function signalWithdrawToken(address _target, address _token, address _receiver, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("withdrawToken", _target, _token, _receiver, _amount));
        _setPendingAction(action);
        emit SignalWithdrawToken(_target, _token, _receiver, _amount, action);
    }

    function withdrawToken(address _target, address _token, address _receiver, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("withdrawToken", _target, _token, _receiver, _amount));
        _validateAction(action);
        _clearAction(action);
        IBaseToken(_target).withdrawToken(_token, _receiver, _amount);
    }

    function signalMint(address _token, address _receiver, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("mint", _token, _receiver, _amount));
        _setPendingAction(action);
        emit SignalMint(_token, _receiver, _amount, action);
    }

    function processMint(address _token, address _receiver, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("mint", _token, _receiver, _amount));
        _validateAction(action);
        _clearAction(action);

        _mint(_token, _receiver, _amount);
    }

    function signalSetGov(address _target, address _gov) external override onlyTokenManager {
        bytes32 action = keccak256(abi.encodePacked("setGov", _target, _gov));
        _setLongPendingAction(action);
        emit SignalSetGov(_target, _gov, action);
    }

    function setGov(address _target, address _gov) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setGov", _target, _gov));
        _validateAction(action);
        _clearAction(action);
        ITimelockTarget(_target).setGov(_gov);
    }

    function signalSetPriceFeed(address _vault, address _priceFeed) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setPriceFeed", _vault, _priceFeed));
        _setPendingAction(action);
        emit SignalSetPriceFeed(_vault, _priceFeed, action);
    }

    function setPriceFeed(address _vault, address _priceFeed) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setPriceFeed", _vault, _priceFeed));
        _validateAction(action);
        _clearAction(action);
        IVault(_vault).setPriceFeed(_priceFeed);
    }

    function signalAddPlugin(address _router, address _plugin) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("addPlugin", _router, _plugin));
        _setPendingAction(action);
        emit SignalAddPlugin(_router, _plugin, action);
    }

    function addPlugin(address _router, address _plugin) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("addPlugin", _router, _plugin));
        _validateAction(action);
        _clearAction(action);
        IRouter(_router).addPlugin(_plugin);
    }

    function signalRedeemBxd(address _vault, address _token, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("redeemBxd", _vault, _token, _amount));
        _setPendingAction(action);
        emit SignalRedeemBxd(_vault, _token, _amount);
    }

    function redeemBxd(address _vault, address _token, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("redeemBxd", _vault, _token, _amount));
        _validateAction(action);
        _clearAction(action);

        address bxd = IVault(_vault).bxd();
        IVault(_vault).setManager(address(this), true);
        IBXD(bxd).addVault(address(this));

        IBXD(bxd).mint(address(this), _amount);
        IERC20(bxd).transfer(address(_vault), _amount);

        IVault(_vault).sellBXD(_token, mintReceiver);

        IVault(_vault).setManager(address(this), false);
        IBXD(bxd).removeVault(address(this));
    }

    function signalVaultSetTokenConfig(
        address _vault,
        address _token,
        uint256 _tokenDecimals,
        uint256 _tokenWeight,
        uint256 _minProfitBps,
        uint256 _maxBxdAmount,
        bool _isStable,
        bool _isShortable
    ) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked(
            "vaultSetTokenConfig",
            _vault,
            _token,
            _tokenDecimals,
            _tokenWeight,
            _minProfitBps,
            _maxBxdAmount,
            _isStable,
            _isShortable
        ));

        _setPendingAction(action);

        emit SignalVaultSetTokenConfig(
            _vault,
            _token,
            _tokenDecimals,
            _tokenWeight,
            _minProfitBps,
            _maxBxdAmount,
            _isStable,
            _isShortable
        );
    }

    function vaultSetTokenConfig(
        address _vault,
        address _token,
        uint256 _tokenDecimals,
        uint256 _tokenWeight,
        uint256 _minProfitBps,
        uint256 _maxBxdAmount,
        bool _isStable,
        bool _isShortable
    ) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked(
            "vaultSetTokenConfig",
            _vault,
            _token,
            _tokenDecimals,
            _tokenWeight,
            _minProfitBps,
            _maxBxdAmount,
            _isStable,
            _isShortable
        ));

        _validateAction(action);
        _clearAction(action);

        IVault(_vault).setTokenConfig(
            _token,
            _tokenDecimals,
            _tokenWeight,
            _minProfitBps,
            _maxBxdAmount,
            _isStable,
            _isShortable
        );
    }

    function signalPriceFeedSetTokenConfig(
        address _vaultPriceFeed,
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable
    ) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked(
            "priceFeedSetTokenConfig",
            _vaultPriceFeed,
            _token,
            _priceFeed,
            _priceDecimals,
            _isStrictStable
        ));

        _setPendingAction(action);

        emit SignalPriceFeedSetTokenConfig(
            _vaultPriceFeed,
            _token,
            _priceFeed,
            _priceDecimals,
            _isStrictStable
        );
    }

    function priceFeedSetTokenConfig(
        address _vaultPriceFeed,
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable
    ) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked(
            "priceFeedSetTokenConfig",
            _vaultPriceFeed,
            _token,
            _priceFeed,
            _priceDecimals,
            _isStrictStable
        ));

        _validateAction(action);
        _clearAction(action);

        IVaultPriceFeed(_vaultPriceFeed).setTokenConfig(
            _token,
            _priceFeed,
            _priceDecimals,
            _isStrictStable
        );
    }

    function cancelAction(bytes32 _action) external onlyAdmin {
        _clearAction(_action);
    }

    function _mint(address _token, address _receiver, uint256 _amount) private {
        IMintable mintable = IMintable(_token);

        if (!mintable.isMinter(address(this))) {
            mintable.setMinter(address(this), true);
        }

        mintable.mint(_receiver, _amount);
        require(IERC20(_token).totalSupply() <= maxTokenSupply, "BxpTimelock: maxTokenSupply exceeded");
    }

    function _setPendingAction(bytes32 _action) private {
        pendingActions[_action] = block.timestamp.add(buffer);
        emit SignalPendingAction(_action);
    }

    function _setLongPendingAction(bytes32 _action) private {
        pendingActions[_action] = block.timestamp.add(longBuffer);
        emit SignalPendingAction(_action);
    }

    function _validateAction(bytes32 _action) private view {
        require(pendingActions[_action] != 0, "BxpTimelock: action not signalled");
        require(pendingActions[_action] < block.timestamp, "BxpTimelock: action time not yet passed");
    }

    function _clearAction(bytes32 _action) private {
        require(pendingActions[_action] != 0, "BxpTimelock: invalid _action");
        delete pendingActions[_action];
        emit ClearAction(_action);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/math/SafeMath.sol";

import "../staking/interfaces/IVester.sol";
import "../staking/interfaces/IRewardTracker.sol";

contract HtdBxpBatchSender {
    using SafeMath for uint256;

    address public admin;
    address public htdBxp;

    constructor(address _htdBxp) public {
        admin = msg.sender;
        htdBxp = _htdBxp;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "HtdBxpBatchSender: forbidden");
        _;
    }

    function send(
        IVester _vester,
        uint256 _minRatio,
        address[] memory _accounts,
        uint256[] memory _amounts
    ) external onlyAdmin {
        IRewardTracker rewardTracker = IRewardTracker(_vester.rewardTracker());

        for (uint256 i = 0; i < _accounts.length; i++) {
            IERC20(htdBxp).transferFrom(msg.sender, _accounts[i], _amounts[i]);

            uint256 nextTransferredCumulativeReward = _vester.transferredCumulativeRewards(_accounts[i]).add(_amounts[i]);
            _vester.setTransferredCumulativeRewards(_accounts[i], nextTransferredCumulativeReward);

            uint256 cumulativeReward = rewardTracker.cumulativeRewards(_accounts[i]);
            uint256 totalCumulativeReward = cumulativeReward.add(nextTransferredCumulativeReward);

            uint256 combinedAverageStakedAmount = _vester.getCombinedAverageStakedAmount(_accounts[i]);

            if (combinedAverageStakedAmount > totalCumulativeReward.mul(_minRatio)) {
                continue;
            }

            uint256 nextTransferredAverageStakedAmount = _minRatio.mul(totalCumulativeReward);
            nextTransferredAverageStakedAmount = nextTransferredAverageStakedAmount.sub(
                rewardTracker.averageStakedAmounts(_accounts[i]).mul(cumulativeReward).div(totalCumulativeReward)
            );

            nextTransferredAverageStakedAmount = nextTransferredAverageStakedAmount.mul(totalCumulativeReward).div(nextTransferredCumulativeReward);

            _vester.setTransferredAverageStakedAmounts(_accounts[i], nextTransferredAverageStakedAmount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IBxpTimelock {
    function setAdmin(address _admin) external;
    function setIsLeverageEnabled(address _vault, bool _isLeverageEnabled) external;
    function signalSetGov(address _target, address _gov) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IHandlerTarget {
    function isHandler(address _account) external returns (bool);
    function setHandler(address _handler, bool _isActive) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ITimelock {
    function marginFeeBasisPoints() external returns (uint256);
    function setAdmin(address _admin) external;
    function enableLeverage(address _vault) external;
    function disableLeverage(address _vault) external;
    function setIsLeverageEnabled(address _vault, bool _isLeverageEnabled) external;
    function signalSetGov(address _target, address _gov) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ITimelockTarget {
    function setGov(address _gov) external;
    function withdrawToken(address _token, address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";

import "../core/interfaces/IOrderBook.sol";

contract OrderBookReader {
    using SafeMath for uint256;

    struct Vars {
        uint256 i;
        uint256 index;
        address account;
        uint256 uintLength;
        uint256 addressLength;
    }

    function getIncreaseOrders(
        address payable _orderBookAddress, 
        address _account,
        uint256[] memory _indices
    ) external view returns (uint256[] memory, address[] memory) {
        Vars memory vars = Vars(0, 0, _account, 5, 3);

        uint256[] memory uintProps = new uint256[](vars.uintLength * _indices.length);
        address[] memory addressProps = new address[](vars.addressLength * _indices.length);

        IOrderBook orderBook = IOrderBook(_orderBookAddress);

        while (vars.i < _indices.length) {
            vars.index = _indices[vars.i];
            (
                address purchaseToken,
                uint256 purchaseTokenAmount,
                address collateralToken,
                address indexToken,
                uint256 sizeDelta,
                bool isLong,
                uint256 triggerPrice,
                bool triggerAboveThreshold,
                // uint256 executionFee
            ) = orderBook.getIncreaseOrder(vars.account, vars.index);

            uintProps[vars.i * vars.uintLength] = uint256(purchaseTokenAmount);
            uintProps[vars.i * vars.uintLength + 1] = uint256(sizeDelta);
            uintProps[vars.i * vars.uintLength + 2] = uint256(isLong ? 1 : 0);
            uintProps[vars.i * vars.uintLength + 3] = uint256(triggerPrice);
            uintProps[vars.i * vars.uintLength + 4] = uint256(triggerAboveThreshold ? 1 : 0);

            addressProps[vars.i * vars.addressLength] = (purchaseToken);
            addressProps[vars.i * vars.addressLength + 1] = (collateralToken);
            addressProps[vars.i * vars.addressLength + 2] = (indexToken);

            vars.i++;
        }

        return (uintProps, addressProps);
    }

    function getDecreaseOrders(
        address payable _orderBookAddress, 
        address _account,
        uint256[] memory _indices
    ) external view returns (uint256[] memory, address[] memory) {
        Vars memory vars = Vars(0, 0, _account, 5, 2);

        uint256[] memory uintProps = new uint256[](vars.uintLength * _indices.length);
        address[] memory addressProps = new address[](vars.addressLength * _indices.length);

        IOrderBook orderBook = IOrderBook(_orderBookAddress);

        while (vars.i < _indices.length) {
            vars.index = _indices[vars.i];
            (
                address collateralToken,
                uint256 collateralDelta,
                address indexToken,
                uint256 sizeDelta,
                bool isLong,
                uint256 triggerPrice,
                bool triggerAboveThreshold,
                // uint256 executionFee
            ) = orderBook.getDecreaseOrder(vars.account, vars.index);

            uintProps[vars.i * vars.uintLength] = uint256(collateralDelta);
            uintProps[vars.i * vars.uintLength + 1] = uint256(sizeDelta);
            uintProps[vars.i * vars.uintLength + 2] = uint256(isLong ? 1 : 0);
            uintProps[vars.i * vars.uintLength + 3] = uint256(triggerPrice);
            uintProps[vars.i * vars.uintLength + 4] = uint256(triggerAboveThreshold ? 1 : 0);

            addressProps[vars.i * vars.addressLength] = (collateralToken);
            addressProps[vars.i * vars.addressLength + 1] = (indexToken);

            vars.i++;
        }

        return (uintProps, addressProps);
    }

    function getSwapOrders(
        address payable _orderBookAddress, 
        address _account,
        uint256[] memory _indices
    ) external view returns (uint256[] memory, address[] memory) {
        Vars memory vars = Vars(0, 0, _account, 5, 3);

        uint256[] memory uintProps = new uint256[](vars.uintLength * _indices.length);
        address[] memory addressProps = new address[](vars.addressLength * _indices.length);

        IOrderBook orderBook = IOrderBook(_orderBookAddress);

        while (vars.i < _indices.length) {
            vars.index = _indices[vars.i];
            (
                address path0,
                address path1,
                address path2,
                uint256 amountIn, 
                uint256 minOut, 
                uint256 triggerRatio, 
                bool triggerAboveThreshold,
                bool shouldUnwrap,
                // uint256 executionFee
            ) = orderBook.getSwapOrder(vars.account, vars.index);

            uintProps[vars.i * vars.uintLength] = uint256(amountIn);
            uintProps[vars.i * vars.uintLength + 1] = uint256(minOut);
            uintProps[vars.i * vars.uintLength + 2] = uint256(triggerRatio);
            uintProps[vars.i * vars.uintLength + 3] = uint256(triggerAboveThreshold ? 1 : 0);
            uintProps[vars.i * vars.uintLength + 4] = uint256(shouldUnwrap ? 1 : 0);

            addressProps[vars.i * vars.addressLength] = (path0);
            addressProps[vars.i * vars.addressLength + 1] = (path1);
            addressProps[vars.i * vars.addressLength + 2] = (path2);

            vars.i++;
        }

        return (uintProps, addressProps);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../core/PositionRouter.sol";

contract PositionRouterReader {
    function getTransferTokenOfIncreasePositionRequests(
        address _positionRouter,
        uint256 _endIndex
    ) external view returns (uint256[] memory, address[] memory) {
        IPositionRouter positionRouter = IPositionRouter(_positionRouter);

        // increasePositionRequestKeysStart,
        // increasePositionRequestKeys.length,
        // decreasePositionRequestKeysStart,
        // decreasePositionRequestKeys.length
        (uint256 index, uint256 length, ,) = positionRouter.getRequestQueueLengths();

        if (_endIndex > length) { _endIndex = length; }

        uint256[] memory requestIndexes = new uint256[](_endIndex - index);
        address[] memory transferTokens = new address[](_endIndex - index);

        uint256 transferTokenIndex = 0;

        while (index < _endIndex) {
            bytes32 key = positionRouter.increasePositionRequestKeys(index);
            address[] memory path = positionRouter.getIncreasePositionRequestPath(key);
            if (path.length > 0) {
                transferTokens[transferTokenIndex] = path[0];
            }

            requestIndexes[transferTokenIndex] = index;

            transferTokenIndex++;
            index++;
        }

        return (requestIndexes, transferTokens);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./interfaces/ITimelockTarget.sol";
import "./interfaces/IHandlerTarget.sol";
import "../access/interfaces/IAdmin.sol";
import "../core/interfaces/IVaultPriceFeed.sol";
import "../oracle/interfaces/IFastPriceFeed.sol";
import "../referrals/interfaces/IReferralStorage.sol";
import "../tokens/interfaces/IYieldToken.sol";
import "../tokens/interfaces/IBaseToken.sol";
import "../tokens/interfaces/IMintable.sol";
import "../tokens/interfaces/IBXD.sol";
import "../staking/interfaces/IVester.sol";

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";

contract PriceFeedTimelock {
    using SafeMath for uint256;

    uint256 public constant MAX_BUFFER = 5 days;

    uint256 public buffer;
    address public admin;

    address public tokenManager;

    mapping (bytes32 => uint256) public pendingActions;

    mapping (address => bool) public isHandler;
    mapping (address => bool) public isKeeper;

    event SignalPendingAction(bytes32 action);
    event SignalApprove(address token, address spender, uint256 amount, bytes32 action);
    event SignalWithdrawToken(address target, address token, address receiver, uint256 amount, bytes32 action);
    event SignalSetGov(address target, address gov, bytes32 action);
    event SignalSetPriceFeedWatcher(address fastPriceFeed, address account, bool isActive);
    event SignalPriceFeedSetTokenConfig(
        address vaultPriceFeed,
        address token,
        address priceFeed,
        uint256 priceDecimals,
        bool isStrictStable
    );
    event ClearAction(bytes32 action);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Timelock: forbidden");
        _;
    }

    modifier onlyHandlerAndAbove() {
        require(msg.sender == admin || isHandler[msg.sender], "Timelock: forbidden");
        _;
    }

    modifier onlyKeeperAndAbove() {
        require(msg.sender == admin || isHandler[msg.sender] || isKeeper[msg.sender], "Timelock: forbidden");
        _;
    }

    modifier onlyTokenManager() {
        require(msg.sender == tokenManager, "Timelock: forbidden");
        _;
    }

    constructor(
        address _admin,
        uint256 _buffer,
        address _tokenManager
    ) public {
        require(_buffer <= MAX_BUFFER, "Timelock: invalid _buffer");
        admin = _admin;
        buffer = _buffer;
        tokenManager = _tokenManager;
    }

    function setAdmin(address _admin) external onlyTokenManager {
        admin = _admin;
    }

    function setExternalAdmin(address _target, address _admin) external onlyAdmin {
        require(_target != address(this), "Timelock: invalid _target");
        IAdmin(_target).setAdmin(_admin);
    }

    function setContractHandler(address _handler, bool _isActive) external onlyAdmin {
        isHandler[_handler] = _isActive;
    }

    function setKeeper(address _keeper, bool _isActive) external onlyAdmin {
        isKeeper[_keeper] = _isActive;
    }

    function setBuffer(uint256 _buffer) external onlyAdmin {
        require(_buffer <= MAX_BUFFER, "Timelock: invalid _buffer");
        require(_buffer > buffer, "Timelock: buffer cannot be decreased");
        buffer = _buffer;
    }

    function setIsAmmEnabled(address _priceFeed, bool _isEnabled) external onlyAdmin {
        IVaultPriceFeed(_priceFeed).setIsAmmEnabled(_isEnabled);
    }

    function setIsSecondaryPriceEnabled(address _priceFeed, bool _isEnabled) external onlyAdmin {
        IVaultPriceFeed(_priceFeed).setIsSecondaryPriceEnabled(_isEnabled);
    }

    function setMaxStrictPriceDeviation(address _priceFeed, uint256 _maxStrictPriceDeviation) external onlyAdmin {
        IVaultPriceFeed(_priceFeed).setMaxStrictPriceDeviation(_maxStrictPriceDeviation);
    }

    function setUseV2Pricing(address _priceFeed, bool _useV2Pricing) external onlyAdmin {
        IVaultPriceFeed(_priceFeed).setUseV2Pricing(_useV2Pricing);
    }

    function setAdjustment(address _priceFeed, address _token, bool _isAdditive, uint256 _adjustmentBps) external onlyKeeperAndAbove {
        IVaultPriceFeed(_priceFeed).setAdjustment(_token, _isAdditive, _adjustmentBps);
    }

    function setSpreadBasisPoints(address _priceFeed, address _token, uint256 _spreadBasisPoints) external onlyKeeperAndAbove {
        IVaultPriceFeed(_priceFeed).setSpreadBasisPoints(_token, _spreadBasisPoints);
    }

    function setPriceSampleSpace(address _priceFeed,uint256 _priceSampleSpace) external onlyHandlerAndAbove {
        require(_priceSampleSpace <= 5, "Invalid _priceSampleSpace");
        IVaultPriceFeed(_priceFeed).setPriceSampleSpace(_priceSampleSpace);
    }

    function setVaultPriceFeed(address _fastPriceFeed, address _vaultPriceFeed) external onlyAdmin {
        IFastPriceFeed(_fastPriceFeed).setVaultPriceFeed(_vaultPriceFeed);
    }

    function setPriceDuration(address _fastPriceFeed, uint256 _priceDuration) external onlyHandlerAndAbove {
        IFastPriceFeed(_fastPriceFeed).setPriceDuration(_priceDuration);
    }

    function setMaxPriceUpdateDelay(address _fastPriceFeed, uint256 _maxPriceUpdateDelay) external onlyHandlerAndAbove {
        IFastPriceFeed(_fastPriceFeed).setMaxPriceUpdateDelay(_maxPriceUpdateDelay);
    }

    function setSpreadBasisPointsIfInactive(address _fastPriceFeed, uint256 _spreadBasisPointsIfInactive) external onlyAdmin {
        IFastPriceFeed(_fastPriceFeed).setSpreadBasisPointsIfInactive(_spreadBasisPointsIfInactive);
    }

    function setSpreadBasisPointsIfChainError(address _fastPriceFeed, uint256 _spreadBasisPointsIfChainError) external onlyAdmin {
        IFastPriceFeed(_fastPriceFeed).setSpreadBasisPointsIfChainError(_spreadBasisPointsIfChainError);
    }

    function setMinBlockInterval(address _fastPriceFeed, uint256 _minBlockInterval) external onlyAdmin {
        IFastPriceFeed(_fastPriceFeed).setMinBlockInterval(_minBlockInterval);
    }

    function setIsSpreadEnabled(address _fastPriceFeed, bool _isSpreadEnabled) external onlyAdmin {
        IFastPriceFeed(_fastPriceFeed).setIsSpreadEnabled(_isSpreadEnabled);
    }

    function transferIn(address _sender, address _token, uint256 _amount) external onlyAdmin {
        IERC20(_token).transferFrom(_sender, address(this), _amount);
    }

    function signalApprove(address _token, address _spender, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("approve", _token, _spender, _amount));
        _setPendingAction(action);
        emit SignalApprove(_token, _spender, _amount, action);
    }

    function approve(address _token, address _spender, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("approve", _token, _spender, _amount));
        _validateAction(action);
        _clearAction(action);
        IERC20(_token).approve(_spender, _amount);
    }

    function signalWithdrawToken(address _target, address _token, address _receiver, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("withdrawToken", _target, _token, _receiver, _amount));
        _setPendingAction(action);
        emit SignalWithdrawToken(_target, _token, _receiver, _amount, action);
    }

    function withdrawToken(address _target, address _token, address _receiver, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("withdrawToken", _target, _token, _receiver, _amount));
        _validateAction(action);
        _clearAction(action);
        IBaseToken(_target).withdrawToken(_token, _receiver, _amount);
    }

    function signalSetGov(address _target, address _gov) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setGov", _target, _gov));
        _setPendingAction(action);
        emit SignalSetGov(_target, _gov, action);
    }

    function setGov(address _target, address _gov) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setGov", _target, _gov));
        _validateAction(action);
        _clearAction(action);
        ITimelockTarget(_target).setGov(_gov);
    }

    function signalSetPriceFeedWatcher(address _fastPriceFeed, address _account, bool _isActive) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setPriceFeedWatcher", _fastPriceFeed, _account, _isActive));
        _setPendingAction(action);
        emit SignalSetPriceFeedWatcher(_fastPriceFeed, _account, _isActive);
    }

    function setPriceFeedWatcher(address _fastPriceFeed, address _account, bool _isActive) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setPriceFeedWatcher", _fastPriceFeed, _account, _isActive));
        _validateAction(action);
        _clearAction(action);
        IFastPriceFeed(_fastPriceFeed).setSigner(_account, _isActive);
    }

    function signalSetPriceFeedUpdater(address _fastPriceFeed, address _account, bool _isActive) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setPriceFeedUpdater", _fastPriceFeed, _account, _isActive));
        _setPendingAction(action);
        emit SignalSetPriceFeedWatcher(_fastPriceFeed, _account, _isActive);
    }

    function setPriceFeedUpdater(address _fastPriceFeed, address _account, bool _isActive) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setPriceFeedUpdater", _fastPriceFeed, _account, _isActive));
        _validateAction(action);
        _clearAction(action);
        IFastPriceFeed(_fastPriceFeed).setUpdater(_account, _isActive);
    }

    function signalPriceFeedSetTokenConfig(
        address _vaultPriceFeed,
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable
    ) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked(
            "priceFeedSetTokenConfig",
            _vaultPriceFeed,
            _token,
            _priceFeed,
            _priceDecimals,
            _isStrictStable
        ));

        _setPendingAction(action);

        emit SignalPriceFeedSetTokenConfig(
            _vaultPriceFeed,
            _token,
            _priceFeed,
            _priceDecimals,
            _isStrictStable
        );
    }

    function priceFeedSetTokenConfig(
        address _vaultPriceFeed,
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable
    ) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked(
            "priceFeedSetTokenConfig",
            _vaultPriceFeed,
            _token,
            _priceFeed,
            _priceDecimals,
            _isStrictStable
        ));

        _validateAction(action);
        _clearAction(action);

        IVaultPriceFeed(_vaultPriceFeed).setTokenConfig(
            _token,
            _priceFeed,
            _priceDecimals,
            _isStrictStable
        );
    }

    function cancelAction(bytes32 _action) external onlyAdmin {
        _clearAction(_action);
    }

    function _setPendingAction(bytes32 _action) private {
        pendingActions[_action] = block.timestamp.add(buffer);
        emit SignalPendingAction(_action);
    }

    function _validateAction(bytes32 _action) private view {
        require(pendingActions[_action] != 0, "Timelock: action not signalled");
        require(pendingActions[_action] < block.timestamp, "Timelock: action time not yet passed");
    }

    function _clearAction(bytes32 _action) private {
        require(pendingActions[_action] != 0, "Timelock: invalid _action");
        delete pendingActions[_action];
        emit ClearAction(_action);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/math/SafeMath.sol";

import "../core/interfaces/IVault.sol";
import "../core/interfaces/IVaultPriceFeed.sol";
import "../tokens/interfaces/IYieldTracker.sol";
import "../tokens/interfaces/IYieldToken.sol";
import "../amm/interfaces/IAmmFactory.sol";

import "../staking/interfaces/IVester.sol";
import "../access/Governable.sol";

contract Reader is Governable {
    using SafeMath for uint256;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant POSITION_PROPS_LENGTH = 9;
    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant BXD_DECIMALS = 18;

    bool public hasMaxGlobalShortSizes;

    function setConfig(bool _hasMaxGlobalShortSizes) public onlyGov {
        hasMaxGlobalShortSizes = _hasMaxGlobalShortSizes;
    }

    function getMaxAmountIn(IVault _vault, address _tokenIn, address _tokenOut) public view returns (uint256) {
        uint256 priceIn = _vault.getMinPrice(_tokenIn);
        uint256 priceOut = _vault.getMaxPrice(_tokenOut);

        uint256 tokenInDecimals = _vault.tokenDecimals(_tokenIn);
        uint256 tokenOutDecimals = _vault.tokenDecimals(_tokenOut);

        uint256 amountIn;

        {
            uint256 poolAmount = _vault.poolAmounts(_tokenOut);
            uint256 reservedAmount = _vault.reservedAmounts(_tokenOut);
            uint256 bufferAmount = _vault.bufferAmounts(_tokenOut);
            uint256 subAmount = reservedAmount > bufferAmount ? reservedAmount : bufferAmount;
            if (subAmount >= poolAmount) {
                return 0;
            }
            uint256 availableAmount = poolAmount.sub(subAmount);
            amountIn = availableAmount.mul(priceOut).div(priceIn).mul(10 ** tokenInDecimals).div(10 ** tokenOutDecimals);
        }

        uint256 maxBxdAmount = _vault.maxBxdAmounts(_tokenIn);

        if (maxBxdAmount != 0) {
            if (maxBxdAmount < _vault.bxdAmounts(_tokenIn)) {
                return 0;
            }

            uint256 maxAmountIn = maxBxdAmount.sub(_vault.bxdAmounts(_tokenIn));
            maxAmountIn = maxAmountIn.mul(10 ** tokenInDecimals).div(10 ** BXD_DECIMALS);
            maxAmountIn = maxAmountIn.mul(PRICE_PRECISION).div(priceIn);

            if (amountIn > maxAmountIn) {
                return maxAmountIn;
            }
        }

        return amountIn;
    }

    function getAmountOut(IVault _vault, address _tokenIn, address _tokenOut, uint256 _amountIn) public view returns (uint256, uint256) {
        uint256 priceIn = _vault.getMinPrice(_tokenIn);

        uint256 tokenInDecimals = _vault.tokenDecimals(_tokenIn);
        uint256 tokenOutDecimals = _vault.tokenDecimals(_tokenOut);

        uint256 feeBasisPoints;
        {
            uint256 bxdAmount = _amountIn.mul(priceIn).div(PRICE_PRECISION);
            bxdAmount = bxdAmount.mul(10 ** BXD_DECIMALS).div(10 ** tokenInDecimals);

            bool isStableSwap = _vault.stableTokens(_tokenIn) && _vault.stableTokens(_tokenOut);
            uint256 baseBps = isStableSwap ? _vault.stableSwapFeeBasisPoints() : _vault.swapFeeBasisPoints();
            uint256 taxBps = isStableSwap ? _vault.stableTaxBasisPoints() : _vault.taxBasisPoints();
            uint256 feesBasisPoints0 = _vault.getFeeBasisPoints(_tokenIn, bxdAmount, baseBps, taxBps, true);
            uint256 feesBasisPoints1 = _vault.getFeeBasisPoints(_tokenOut, bxdAmount, baseBps, taxBps, false);
            // use the higher of the two fee basis points
            feeBasisPoints = feesBasisPoints0 > feesBasisPoints1 ? feesBasisPoints0 : feesBasisPoints1;
        }

        uint256 priceOut = _vault.getMaxPrice(_tokenOut);
        uint256 amountOut = _amountIn.mul(priceIn).div(priceOut);
        amountOut = amountOut.mul(10 ** tokenOutDecimals).div(10 ** tokenInDecimals);

        uint256 amountOutAfterFees = amountOut.mul(BASIS_POINTS_DIVISOR.sub(feeBasisPoints)).div(BASIS_POINTS_DIVISOR);
        uint256 feeAmount = amountOut.sub(amountOutAfterFees);

        return (amountOutAfterFees, feeAmount);
    }

    function getFeeBasisPoints(IVault _vault, address _tokenIn, address _tokenOut, uint256 _amountIn) public view returns (uint256, uint256, uint256) {
        uint256 priceIn = _vault.getMinPrice(_tokenIn);
        uint256 tokenInDecimals = _vault.tokenDecimals(_tokenIn);

        uint256 bxdAmount = _amountIn.mul(priceIn).div(PRICE_PRECISION);
        bxdAmount = bxdAmount.mul(10 ** BXD_DECIMALS).div(10 ** tokenInDecimals);

        bool isStableSwap = _vault.stableTokens(_tokenIn) && _vault.stableTokens(_tokenOut);
        uint256 baseBps = isStableSwap ? _vault.stableSwapFeeBasisPoints() : _vault.swapFeeBasisPoints();
        uint256 taxBps = isStableSwap ? _vault.stableTaxBasisPoints() : _vault.taxBasisPoints();
        uint256 feesBasisPoints0 = _vault.getFeeBasisPoints(_tokenIn, bxdAmount, baseBps, taxBps, true);
        uint256 feesBasisPoints1 = _vault.getFeeBasisPoints(_tokenOut, bxdAmount, baseBps, taxBps, false);
        // use the higher of the two fee basis points
        uint256 feeBasisPoints = feesBasisPoints0 > feesBasisPoints1 ? feesBasisPoints0 : feesBasisPoints1;

        return (feeBasisPoints, feesBasisPoints0, feesBasisPoints1);
    }

    function getFees(address _vault, address[] memory _tokens) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            amounts[i] = IVault(_vault).feeReserves(_tokens[i]);
        }
        return amounts;
    }

    function getTotalStaked(address[] memory _yieldTokens) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](_yieldTokens.length);
        for (uint256 i = 0; i < _yieldTokens.length; i++) {
            IYieldToken yieldToken = IYieldToken(_yieldTokens[i]);
            amounts[i] = yieldToken.totalStaked();
        }
        return amounts;
    }

    function getStakingInfo(address _account, address[] memory _yieldTrackers) public view returns (uint256[] memory) {
        uint256 propsLength = 2;
        uint256[] memory amounts = new uint256[](_yieldTrackers.length * propsLength);
        for (uint256 i = 0; i < _yieldTrackers.length; i++) {
            IYieldTracker yieldTracker = IYieldTracker(_yieldTrackers[i]);
            amounts[i * propsLength] = yieldTracker.claimable(_account);
            amounts[i * propsLength + 1] = yieldTracker.getTokensPerInterval();
        }
        return amounts;
    }

    function getVestingInfo(address _account, address[] memory _vesters) public view returns (uint256[] memory) {
        uint256 propsLength = 7;
        uint256[] memory amounts = new uint256[](_vesters.length * propsLength);
        for (uint256 i = 0; i < _vesters.length; i++) {
            IVester vester = IVester(_vesters[i]);
            amounts[i * propsLength] = vester.pairAmounts(_account);
            amounts[i * propsLength + 1] = vester.getVestedAmount(_account);
            amounts[i * propsLength + 2] = IERC20(_vesters[i]).balanceOf(_account);
            amounts[i * propsLength + 3] = vester.claimedAmounts(_account);
            amounts[i * propsLength + 4] = vester.claimable(_account);
            amounts[i * propsLength + 5] = vester.getMaxVestableAmount(_account);
            amounts[i * propsLength + 6] = vester.getCombinedAverageStakedAmount(_account);
        }
        return amounts;
    }

    function getPairInfo(address _factory, address[] memory _tokens) public view returns (uint256[] memory) {
        uint256 inputLength = 2;
        uint256 propsLength = 2;
        uint256[] memory amounts = new uint256[](_tokens.length / inputLength * propsLength);
        for (uint256 i = 0; i < _tokens.length / inputLength; i++) {
            address token0 = _tokens[i * inputLength];
            address token1 = _tokens[i * inputLength + 1];
            address pair = IAmmFactory(_factory).getPair(token0, token1);

            amounts[i * propsLength] = IERC20(token0).balanceOf(pair);
            amounts[i * propsLength + 1] = IERC20(token1).balanceOf(pair);
        }
        return amounts;
    }

    function getFundingRates(address _vault, address _weth, address[] memory _tokens) public view returns (uint256[] memory) {
        uint256 propsLength = 2;
        uint256[] memory fundingRates = new uint256[](_tokens.length * propsLength);
        IVault vault = IVault(_vault);

        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                token = _weth;
            }

            uint256 fundingRateFactor = vault.stableTokens(token) ? vault.stableFundingRateFactor() : vault.fundingRateFactor();
            uint256 reservedAmount = vault.reservedAmounts(token);
            uint256 poolAmount = vault.poolAmounts(token);

            if (poolAmount > 0) {
                fundingRates[i * propsLength] = fundingRateFactor.mul(reservedAmount).div(poolAmount);
            }

            if (vault.cumulativeFundingRates(token) > 0) {
                uint256 nextRate = vault.getNextFundingRate(token);
                uint256 baseRate = vault.cumulativeFundingRates(token);
                fundingRates[i * propsLength + 1] = baseRate.add(nextRate);
            }
        }

        return fundingRates;
    }

    function getTokenSupply(IERC20 _token, address[] memory _excludedAccounts) public view returns (uint256) {
        uint256 supply = _token.totalSupply();
        for (uint256 i = 0; i < _excludedAccounts.length; i++) {
            address account = _excludedAccounts[i];
            uint256 balance = _token.balanceOf(account);
            supply = supply.sub(balance);
        }
        return supply;
    }

    function getTotalBalance(IERC20 _token, address[] memory _accounts) public view returns (uint256) {
        uint256 totalBalance = 0;
        for (uint256 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];
            uint256 balance = _token.balanceOf(account);
            totalBalance = totalBalance.add(balance);
        }
        return totalBalance;
    }

    function getTokenBalances(address _account, address[] memory _tokens) public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                balances[i] = _account.balance;
                continue;
            }
            balances[i] = IERC20(token).balanceOf(_account);
        }
        return balances;
    }

    function getTokenBalancesWithSupplies(address _account, address[] memory _tokens) public view returns (uint256[] memory) {
        uint256 propsLength = 2;
        uint256[] memory balances = new uint256[](_tokens.length * propsLength);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                balances[i * propsLength] = _account.balance;
                balances[i * propsLength + 1] = 0;
                continue;
            }
            balances[i * propsLength] = IERC20(token).balanceOf(_account);
            balances[i * propsLength + 1] = IERC20(token).totalSupply();
        }
        return balances;
    }

    function getPrices(IVaultPriceFeed _priceFeed, address[] memory _tokens) public view returns (uint256[] memory) {
        uint256 propsLength = 6;

        uint256[] memory amounts = new uint256[](_tokens.length * propsLength);

        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            amounts[i * propsLength] = _priceFeed.getPrice(token, true, true, false);
            amounts[i * propsLength + 1] = _priceFeed.getPrice(token, false, true, false);
            amounts[i * propsLength + 2] = _priceFeed.getPrimaryPrice(token, true);
            amounts[i * propsLength + 3] = _priceFeed.getPrimaryPrice(token, false);
            amounts[i * propsLength + 4] = _priceFeed.isAdjustmentAdditive(token) ? 1 : 0;
            amounts[i * propsLength + 5] = _priceFeed.adjustmentBasisPoints(token);
        }

        return amounts;
    }

    function getVaultTokenInfo(address _vault, address _weth, uint256 _bxdAmount, address[] memory _tokens) public view returns (uint256[] memory) {
        uint256 propsLength = 10;

        IVault vault = IVault(_vault);
        IVaultPriceFeed priceFeed = IVaultPriceFeed(vault.priceFeed());

        uint256[] memory amounts = new uint256[](_tokens.length * propsLength);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                token = _weth;
            }
            amounts[i * propsLength] = vault.poolAmounts(token);
            amounts[i * propsLength + 1] = vault.reservedAmounts(token);
            amounts[i * propsLength + 2] = vault.bxdAmounts(token);
            amounts[i * propsLength + 3] = vault.getRedemptionAmount(token, _bxdAmount);
            amounts[i * propsLength + 4] = vault.tokenWeights(token);
            amounts[i * propsLength + 5] = vault.getMinPrice(token);
            amounts[i * propsLength + 6] = vault.getMaxPrice(token);
            amounts[i * propsLength + 7] = vault.guaranteedUsd(token);
            amounts[i * propsLength + 8] = priceFeed.getPrimaryPrice(token, false);
            amounts[i * propsLength + 9] = priceFeed.getPrimaryPrice(token, true);
        }

        return amounts;
    }

    function getFullVaultTokenInfo(address _vault, address _weth, uint256 _bxdAmount, address[] memory _tokens) public view returns (uint256[] memory) {
        uint256 propsLength = 12;

        IVault vault = IVault(_vault);
        IVaultPriceFeed priceFeed = IVaultPriceFeed(vault.priceFeed());

        uint256[] memory amounts = new uint256[](_tokens.length * propsLength);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                token = _weth;
            }
            amounts[i * propsLength] = vault.poolAmounts(token);
            amounts[i * propsLength + 1] = vault.reservedAmounts(token);
            amounts[i * propsLength + 2] = vault.bxdAmounts(token);
            amounts[i * propsLength + 3] = vault.getRedemptionAmount(token, _bxdAmount);
            amounts[i * propsLength + 4] = vault.tokenWeights(token);
            amounts[i * propsLength + 5] = vault.bufferAmounts(token);
            amounts[i * propsLength + 6] = vault.maxBxdAmounts(token);
            amounts[i * propsLength + 7] = vault.getMinPrice(token);
            amounts[i * propsLength + 8] = vault.getMaxPrice(token);
            amounts[i * propsLength + 9] = vault.guaranteedUsd(token);
            amounts[i * propsLength + 10] = priceFeed.getPrimaryPrice(token, false);
            amounts[i * propsLength + 11] = priceFeed.getPrimaryPrice(token, true);
        }

        return amounts;
    }

    function getVaultTokenInfoV2(address _vault, address _weth, uint256 _bxdAmount, address[] memory _tokens) public view returns (uint256[] memory) {
        uint256 propsLength = 14;

        IVault vault = IVault(_vault);
        IVaultPriceFeed priceFeed = IVaultPriceFeed(vault.priceFeed());

        uint256[] memory amounts = new uint256[](_tokens.length * propsLength);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                token = _weth;
            }

            uint256 maxGlobalShortSize = hasMaxGlobalShortSizes ? vault.maxGlobalShortSizes(token) : 0;
            amounts[i * propsLength] = vault.poolAmounts(token);
            amounts[i * propsLength + 1] = vault.reservedAmounts(token);
            amounts[i * propsLength + 2] = vault.bxdAmounts(token);
            amounts[i * propsLength + 3] = vault.getRedemptionAmount(token, _bxdAmount);
            amounts[i * propsLength + 4] = vault.tokenWeights(token);
            amounts[i * propsLength + 5] = vault.bufferAmounts(token);
            amounts[i * propsLength + 6] = vault.maxBxdAmounts(token);
            amounts[i * propsLength + 7] = vault.globalShortSizes(token);
            amounts[i * propsLength + 8] = maxGlobalShortSize;
            amounts[i * propsLength + 9] = vault.getMinPrice(token);
            amounts[i * propsLength + 10] = vault.getMaxPrice(token);
            amounts[i * propsLength + 11] = vault.guaranteedUsd(token);
            amounts[i * propsLength + 12] = priceFeed.getPrimaryPrice(token, false);
            amounts[i * propsLength + 13] = priceFeed.getPrimaryPrice(token, true);
        }

        return amounts;
    }

    function getPositions(address _vault, address _account, address[] memory _collateralTokens, address[] memory _indexTokens, bool[] memory _isLong) public view returns(uint256[] memory) {
        uint256[] memory amounts = new uint256[](_collateralTokens.length * POSITION_PROPS_LENGTH);

        for (uint256 i = 0; i < _collateralTokens.length; i++) {
            {
            (uint256 size,
             uint256 collateral,
             uint256 averagePrice,
             uint256 entryFundingRate,
             /* reserveAmount */,
             uint256 realisedPnl,
             bool hasRealisedProfit,
             uint256 lastIncreasedTime) = IVault(_vault).getPosition(_account, _collateralTokens[i], _indexTokens[i], _isLong[i]);

            amounts[i * POSITION_PROPS_LENGTH] = size;
            amounts[i * POSITION_PROPS_LENGTH + 1] = collateral;
            amounts[i * POSITION_PROPS_LENGTH + 2] = averagePrice;
            amounts[i * POSITION_PROPS_LENGTH + 3] = entryFundingRate;
            amounts[i * POSITION_PROPS_LENGTH + 4] = hasRealisedProfit ? 1 : 0;
            amounts[i * POSITION_PROPS_LENGTH + 5] = realisedPnl;
            amounts[i * POSITION_PROPS_LENGTH + 6] = lastIncreasedTime;
            }

            uint256 size = amounts[i * POSITION_PROPS_LENGTH];
            uint256 averagePrice = amounts[i * POSITION_PROPS_LENGTH + 2];
            uint256 lastIncreasedTime = amounts[i * POSITION_PROPS_LENGTH + 6];
            if (averagePrice > 0) {
                (bool hasProfit, uint256 delta) = IVault(_vault).getDelta(_indexTokens[i], size, averagePrice, _isLong[i], lastIncreasedTime);
                amounts[i * POSITION_PROPS_LENGTH + 7] = hasProfit ? 1 : 0;
                amounts[i * POSITION_PROPS_LENGTH + 8] = delta;
            }
        }

        return amounts;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/math/SafeMath.sol";

import "../staking/interfaces/IVester.sol";
import "../staking/interfaces/IRewardTracker.sol";

contract RewardReader {
    using SafeMath for uint256;

    function getDepositBalances(address _account, address[] memory _depositTokens, address[] memory _rewardTrackers) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](_rewardTrackers.length);
        for (uint256 i = 0; i < _rewardTrackers.length; i++) {
            IRewardTracker rewardTracker = IRewardTracker(_rewardTrackers[i]);
            amounts[i] = rewardTracker.depositBalances(_account, _depositTokens[i]);
        }
        return amounts;
    }

    function getStakingInfo(address _account, address[] memory _rewardTrackers) public view returns (uint256[] memory) {
        uint256 propsLength = 5;
        uint256[] memory amounts = new uint256[](_rewardTrackers.length * propsLength);
        for (uint256 i = 0; i < _rewardTrackers.length; i++) {
            IRewardTracker rewardTracker = IRewardTracker(_rewardTrackers[i]);
            amounts[i * propsLength] = rewardTracker.claimable(_account);
            amounts[i * propsLength + 1] = rewardTracker.tokensPerInterval();
            amounts[i * propsLength + 2] = rewardTracker.averageStakedAmounts(_account);
            amounts[i * propsLength + 3] = rewardTracker.cumulativeRewards(_account);
            amounts[i * propsLength + 4] = IERC20(_rewardTrackers[i]).totalSupply();
        }
        return amounts;
    }

    function getVestingInfoV2(address _account, address[] memory _vesters) public view returns (uint256[] memory) {
        uint256 propsLength = 12;
        uint256[] memory amounts = new uint256[](_vesters.length * propsLength);
        for (uint256 i = 0; i < _vesters.length; i++) {
            IVester vester = IVester(_vesters[i]);
            IRewardTracker rewardTracker = IRewardTracker(vester.rewardTracker());
            amounts[i * propsLength] = vester.pairAmounts(_account);
            amounts[i * propsLength + 1] = vester.getVestedAmount(_account);
            amounts[i * propsLength + 2] = IERC20(_vesters[i]).balanceOf(_account);
            amounts[i * propsLength + 3] = vester.claimedAmounts(_account);
            amounts[i * propsLength + 4] = vester.claimable(_account);
            amounts[i * propsLength + 5] = vester.getMaxVestableAmount(_account);
            amounts[i * propsLength + 6] = vester.getCombinedAverageStakedAmount(_account);
            amounts[i * propsLength + 7] = rewardTracker.cumulativeRewards(_account);
            amounts[i * propsLength + 8] = vester.transferredCumulativeRewards(_account);
            amounts[i * propsLength + 9] = vester.bonusRewards(_account);
            amounts[i * propsLength + 10] = rewardTracker.averageStakedAmounts(_account);
            amounts[i * propsLength + 11] = vester.transferredAverageStakedAmounts(_account);
        }
        return amounts;
    }
}

// SPDX-License-Identifier: MIT

import "../libraries/math/SafeMath.sol";
import "../access/Governable.sol";
import "../core/interfaces/IShortsTracker.sol";
import "./interfaces/IHandlerTarget.sol";

pragma solidity 0.6.12;

contract ShortsTrackerTimelock {
    using SafeMath for uint256;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant MAX_BUFFER = 5 days;

    mapping (bytes32 => uint256) public pendingActions;

    address public admin;
    uint256 public buffer;

    mapping (address => bool) public isHandler;
    mapping (address => uint256) public lastUpdated;
    uint256 public averagePriceUpdateDelay;
    uint256 public maxAveragePriceChange;

    event GlobalShortAveragePriceUpdated(address indexed token, uint256 oldAveragePrice, uint256 newAveragePrice);

    event SignalSetGov(address target, address gov);
    event SetGov(address target, address gov);

    event SignalSetAdmin(address admin);
    event SetAdmin(address admin);

    event SetContractHandler(address indexed handler, bool isHandler);
    event SignalSetHandler(address target, address handler, bool isActive, bytes32 action);

    event SignalSetMaxAveragePriceChange(uint256 maxAveragePriceChange);
    event SetMaxAveragePriceChange(uint256 maxAveragePriceChange);

    event SignalSetAveragePriceUpdateDelay(uint256 averagePriceUpdateDelay);
    event SetAveragePriceUpdateDelay(uint256 averagePriceUpdateDelay);

    event SignalSetIsGlobalShortDataReady(address target, bool isGlobalShortDataReady);
    event SetIsGlobalShortDataReady(address target, bool isGlobalShortDataReady);

    event SignalPendingAction(bytes32 action);
    event ClearAction(bytes32 action);

    constructor(
        address _admin,
        uint256 _buffer,
        uint256 _averagePriceUpdateDelay,
        uint256 _maxAveragePriceChange
    ) public {
        admin = _admin;
        buffer = _buffer;
        averagePriceUpdateDelay = _averagePriceUpdateDelay;
        maxAveragePriceChange = _maxAveragePriceChange;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "ShortsTrackerTimelock: admin forbidden");
        _;
    }

    modifier onlyHandler() {
        require(isHandler[msg.sender] || msg.sender == admin, "ShortsTrackerTimelock: handler forbidden");
        _;
    }

    function setBuffer(uint256 _buffer) external onlyAdmin {
        require(_buffer <= MAX_BUFFER, "ShortsTrackerTimelock: invalid buffer");
        require(_buffer > buffer, "ShortsTrackerTimelock: buffer cannot be decreased");
        buffer = _buffer;
    }

    function signalSetAdmin(address _admin) external onlyAdmin {
        require(_admin != address(0), "ShortsTrackerTimelock: invalid admin");

        bytes32 action = keccak256(abi.encodePacked("setAdmin", _admin));
        _setPendingAction(action);

        emit SignalSetAdmin(_admin);
    }

    function setAdmin(address _admin) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setAdmin", _admin));
        _validateAction(action);
        _clearAction(action);

        admin = _admin;

        emit SetAdmin(_admin);
    }

    function setContractHandler(address _handler, bool _isActive) external onlyAdmin {
        isHandler[_handler] = _isActive;

        emit SetContractHandler(_handler, _isActive);
    }

    function signalSetGov(address _shortsTracker, address _gov) external onlyAdmin {
        require(_gov != address(0), "ShortsTrackerTimelock: invalid gov");

        bytes32 action = keccak256(abi.encodePacked("setGov", _shortsTracker, _gov));
        _setPendingAction(action);

        emit SignalSetGov(_shortsTracker, _gov);
    }

    function setGov(address _shortsTracker, address _gov) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setGov", _shortsTracker, _gov));
        _validateAction(action);
        _clearAction(action);

        Governable(_shortsTracker).setGov(_gov);

        emit SetGov(_shortsTracker, _gov);
    }

    function signalSetHandler(address _target, address _handler, bool _isActive) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setHandler", _target, _handler, _isActive));
        _setPendingAction(action);
        emit SignalSetHandler(_target, _handler, _isActive, action);
    }

    function setHandler(address _target, address _handler, bool _isActive) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setHandler", _target, _handler, _isActive));
        _validateAction(action);
        _clearAction(action);
        IHandlerTarget(_target).setHandler(_handler, _isActive);
    }

    function signalSetAveragePriceUpdateDelay(uint256 _averagePriceUpdateDelay) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setAveragePriceUpdateDelay", _averagePriceUpdateDelay));
        _setPendingAction(action);

        emit SignalSetAveragePriceUpdateDelay(_averagePriceUpdateDelay);
    }

    function setAveragePriceUpdateDelay(uint256 _averagePriceUpdateDelay) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setAveragePriceUpdateDelay", _averagePriceUpdateDelay));
        _validateAction(action);
        _clearAction(action);

        averagePriceUpdateDelay = _averagePriceUpdateDelay;

        emit SetAveragePriceUpdateDelay(_averagePriceUpdateDelay);
    }

    function signalSetMaxAveragePriceChange(uint256 _maxAveragePriceChange) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setMaxAveragePriceChange", _maxAveragePriceChange));
        _setPendingAction(action);

        emit SignalSetMaxAveragePriceChange(_maxAveragePriceChange);
    }

    function setMaxAveragePriceChange(uint256 _maxAveragePriceChange) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setMaxAveragePriceChange", _maxAveragePriceChange));
        _validateAction(action);
        _clearAction(action);

        maxAveragePriceChange = _maxAveragePriceChange;

        emit SetMaxAveragePriceChange(_maxAveragePriceChange);
    }

    function signalSetIsGlobalShortDataReady(IShortsTracker _shortsTracker, bool _value) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setIsGlobalShortDataReady", address(_shortsTracker), _value));
        _setPendingAction(action);

        emit SignalSetIsGlobalShortDataReady(address(_shortsTracker), _value);
    }

    function setIsGlobalShortDataReady(IShortsTracker _shortsTracker, bool _value) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setIsGlobalShortDataReady", address(_shortsTracker), _value));
        _validateAction(action);
        _clearAction(action);

        _shortsTracker.setIsGlobalShortDataReady(_value);

        emit SetIsGlobalShortDataReady(address(_shortsTracker), _value);
    }

    function disableIsGlobalShortDataReady(IShortsTracker _shortsTracker) external onlyAdmin {
        _shortsTracker.setIsGlobalShortDataReady(false);

        emit SetIsGlobalShortDataReady(address(_shortsTracker), false);
    }

    function setGlobalShortAveragePrices(IShortsTracker _shortsTracker, address[] calldata _tokens, uint256[] calldata _averagePrices) external onlyHandler {
        _shortsTracker.setIsGlobalShortDataReady(false);

        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            uint256 oldAveragePrice = _shortsTracker.globalShortAveragePrices(token);
            uint256 newAveragePrice = _averagePrices[i];
            uint256 diff = newAveragePrice > oldAveragePrice ? newAveragePrice.sub(oldAveragePrice) : oldAveragePrice.sub(newAveragePrice);
            require(diff.mul(BASIS_POINTS_DIVISOR).div(oldAveragePrice) < maxAveragePriceChange, "ShortsTrackerTimelock: too big change");

            require(block.timestamp >= lastUpdated[token].add(averagePriceUpdateDelay), "ShortsTrackerTimelock: too early");
            lastUpdated[token] = block.timestamp;

            emit GlobalShortAveragePriceUpdated(token, oldAveragePrice, newAveragePrice);
        }

        _shortsTracker.setInitData(_tokens, _averagePrices);
    }

    function cancelAction(bytes32 _action) external onlyAdmin {
        _clearAction(_action);
    }

    function _setPendingAction(bytes32 _action) private {
        require(pendingActions[_action] == 0, "ShortsTrackerTimelock: action already signalled");
        pendingActions[_action] = block.timestamp.add(buffer);
        emit SignalPendingAction(_action);
    }

    function _validateAction(bytes32 _action) private view {
        require(pendingActions[_action] != 0, "ShortsTrackerTimelock: action not signalled");
        require(pendingActions[_action] <= block.timestamp, "ShortsTrackerTimelock: action time not yet passed");
    }

    function _clearAction(bytes32 _action) private {
        require(pendingActions[_action] != 0, "ShortsTrackerTimelock: invalid _action");
        delete pendingActions[_action];
        emit ClearAction(_action);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./interfaces/ITimelockTarget.sol";
import "./interfaces/ITimelock.sol";
import "./interfaces/IHandlerTarget.sol";
import "../access/interfaces/IAdmin.sol";
import "../core/interfaces/IVault.sol";
import "../core/interfaces/IVaultUtils.sol";
import "../core/interfaces/IBlpManager.sol";
import "../referrals/interfaces/IReferralStorage.sol";
import "../tokens/interfaces/IYieldToken.sol";
import "../tokens/interfaces/IBaseToken.sol";
import "../tokens/interfaces/IMintable.sol";
import "../tokens/interfaces/IBXD.sol";
import "../staking/interfaces/IVester.sol";
import "../staking/interfaces/IRewardRouterV2.sol";

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";

contract Timelock is ITimelock {
    using SafeMath for uint256;

    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant MAX_BUFFER = 5 days;
    uint256 public constant MAX_FUNDING_RATE_FACTOR = 200; // 0.02%
    uint256 public constant MAX_LEVERAGE_VALIDATION = 500000; // 50x

    uint256 public buffer;
    address public admin;

    address public tokenManager;
    address public mintReceiver;
    address public blpManager;
    address public rewardRouter;
    uint256 public maxTokenSupply;

    uint256 public override marginFeeBasisPoints;
    uint256 public maxMarginFeeBasisPoints;
    bool public shouldToggleIsLeverageEnabled;

    mapping (bytes32 => uint256) public pendingActions;

    mapping (address => bool) public isHandler;
    mapping (address => bool) public isKeeper;

    event SignalPendingAction(bytes32 action);
    event SignalApprove(address token, address spender, uint256 amount, bytes32 action);
    event SignalWithdrawToken(address target, address token, address receiver, uint256 amount, bytes32 action);
    event SignalMint(address token, address receiver, uint256 amount, bytes32 action);
    event SignalSetGov(address target, address gov, bytes32 action);
    event SignalSetHandler(address target, address handler, bool isActive, bytes32 action);
    event SignalSetPriceFeed(address vault, address priceFeed, bytes32 action);
    event SignalRedeemBxd(address vault, address token, uint256 amount);
    event SignalVaultSetTokenConfig(
        address vault,
        address token,
        uint256 tokenDecimals,
        uint256 tokenWeight,
        uint256 minProfitBps,
        uint256 maxBxdAmount,
        bool isStable,
        bool isShortable
    );
    event ClearAction(bytes32 action);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Timelock: forbidden");
        _;
    }

    modifier onlyHandlerAndAbove() {
        require(msg.sender == admin || isHandler[msg.sender], "Timelock: forbidden");
        _;
    }

    modifier onlyKeeperAndAbove() {
        require(msg.sender == admin || isHandler[msg.sender] || isKeeper[msg.sender], "Timelock: forbidden");
        _;
    }

    modifier onlyTokenManager() {
        require(msg.sender == tokenManager, "Timelock: forbidden");
        _;
    }

    constructor(
        address _admin,
        uint256 _buffer,
        address _tokenManager,
        address _mintReceiver,
        address _blpManager,
        address _rewardRouter,
        uint256 _maxTokenSupply,
        uint256 _marginFeeBasisPoints,
        uint256 _maxMarginFeeBasisPoints
    ) public {
        require(_buffer <= MAX_BUFFER, "Timelock: invalid _buffer");
        admin = _admin;
        buffer = _buffer;
        tokenManager = _tokenManager;
        mintReceiver = _mintReceiver;
        blpManager = _blpManager;
        rewardRouter = _rewardRouter;
        maxTokenSupply = _maxTokenSupply;

        marginFeeBasisPoints = _marginFeeBasisPoints;
        maxMarginFeeBasisPoints = _maxMarginFeeBasisPoints;
    }

    function setAdmin(address _admin) external override onlyTokenManager {
        admin = _admin;
    }

    function setExternalAdmin(address _target, address _admin) external onlyAdmin {
        require(_target != address(this), "Timelock: invalid _target");
        IAdmin(_target).setAdmin(_admin);
    }

    function setContractHandler(address _handler, bool _isActive) external onlyAdmin {
        isHandler[_handler] = _isActive;
    }

    function initBlpManager() external onlyAdmin {
        IBlpManager _blpManager = IBlpManager(blpManager);

        IMintable blp = IMintable(_blpManager.blp());
        blp.setMinter(blpManager, true);

        IBXD bxd = IBXD(_blpManager.bxd());
        bxd.addVault(blpManager);

        IVault vault = _blpManager.vault();
        vault.setManager(blpManager, true);
    }

    function initRewardRouter() external onlyAdmin {
        IRewardRouterV2 _rewardRouter = IRewardRouterV2(rewardRouter);

        IHandlerTarget(_rewardRouter.feeBlpTracker()).setHandler(rewardRouter, true);
        IHandlerTarget(_rewardRouter.stakedBlpTracker()).setHandler(rewardRouter, true);
        IHandlerTarget(blpManager).setHandler(rewardRouter, true);
    }

    function setKeeper(address _keeper, bool _isActive) external onlyAdmin {
        isKeeper[_keeper] = _isActive;
    }

    function setBuffer(uint256 _buffer) external onlyAdmin {
        require(_buffer <= MAX_BUFFER, "Timelock: invalid _buffer");
        require(_buffer > buffer, "Timelock: buffer cannot be decreased");
        buffer = _buffer;
    }

    function setMaxLeverage(address _vault, uint256 _maxLeverage) external onlyAdmin {
      require(_maxLeverage > MAX_LEVERAGE_VALIDATION, "Timelock: invalid _maxLeverage");
      IVault(_vault).setMaxLeverage(_maxLeverage);
    }

    function setFundingRate(address _vault, uint256 _fundingInterval, uint256 _fundingRateFactor, uint256 _stableFundingRateFactor) external onlyKeeperAndAbove {
        require(_fundingRateFactor < MAX_FUNDING_RATE_FACTOR, "Timelock: invalid _fundingRateFactor");
        require(_stableFundingRateFactor < MAX_FUNDING_RATE_FACTOR, "Timelock: invalid _stableFundingRateFactor");
        IVault(_vault).setFundingRate(_fundingInterval, _fundingRateFactor, _stableFundingRateFactor);
    }

    function setShouldToggleIsLeverageEnabled(bool _shouldToggleIsLeverageEnabled) external onlyHandlerAndAbove {
        shouldToggleIsLeverageEnabled = _shouldToggleIsLeverageEnabled;
    }

    function setMarginFeeBasisPoints(uint256 _marginFeeBasisPoints, uint256 _maxMarginFeeBasisPoints) external onlyHandlerAndAbove {
        marginFeeBasisPoints = _marginFeeBasisPoints;
        maxMarginFeeBasisPoints = _maxMarginFeeBasisPoints;
    }

    function setSwapFees(
        address _vault,
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints
    ) external onlyKeeperAndAbove {
        IVault vault = IVault(_vault);

        vault.setFees(
            _taxBasisPoints,
            _stableTaxBasisPoints,
            _mintBurnFeeBasisPoints,
            _swapFeeBasisPoints,
            _stableSwapFeeBasisPoints,
            maxMarginFeeBasisPoints,
            vault.liquidationFeeUsd(),
            vault.minProfitTime(),
            vault.hasDynamicFees()
        );
    }

    // assign _marginFeeBasisPoints to this.marginFeeBasisPoints
    // because enableLeverage would update Vault.marginFeeBasisPoints to this.marginFeeBasisPoints
    // and disableLeverage would reset the Vault.marginFeeBasisPoints to this.maxMarginFeeBasisPoints
    function setFees(
        address _vault,
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external onlyKeeperAndAbove {
        marginFeeBasisPoints = _marginFeeBasisPoints;

        IVault(_vault).setFees(
            _taxBasisPoints,
            _stableTaxBasisPoints,
            _mintBurnFeeBasisPoints,
            _swapFeeBasisPoints,
            _stableSwapFeeBasisPoints,
            maxMarginFeeBasisPoints,
            _liquidationFeeUsd,
            _minProfitTime,
            _hasDynamicFees
        );
    }

    function enableLeverage(address _vault) external override onlyHandlerAndAbove {
        IVault vault = IVault(_vault);

        if (shouldToggleIsLeverageEnabled) {
            vault.setIsLeverageEnabled(true);
        }

        vault.setFees(
            vault.taxBasisPoints(),
            vault.stableTaxBasisPoints(),
            vault.mintBurnFeeBasisPoints(),
            vault.swapFeeBasisPoints(),
            vault.stableSwapFeeBasisPoints(),
            marginFeeBasisPoints,
            vault.liquidationFeeUsd(),
            vault.minProfitTime(),
            vault.hasDynamicFees()
        );
    }

    function disableLeverage(address _vault) external override onlyHandlerAndAbove {
        IVault vault = IVault(_vault);

        if (shouldToggleIsLeverageEnabled) {
            vault.setIsLeverageEnabled(false);
        }

        vault.setFees(
            vault.taxBasisPoints(),
            vault.stableTaxBasisPoints(),
            vault.mintBurnFeeBasisPoints(),
            vault.swapFeeBasisPoints(),
            vault.stableSwapFeeBasisPoints(),
            maxMarginFeeBasisPoints, // marginFeeBasisPoints
            vault.liquidationFeeUsd(),
            vault.minProfitTime(),
            vault.hasDynamicFees()
        );
    }

    function setIsLeverageEnabled(address _vault, bool _isLeverageEnabled) external override onlyHandlerAndAbove {
        IVault(_vault).setIsLeverageEnabled(_isLeverageEnabled);
    }

    function setTokenConfig(
        address _vault,
        address _token,
        uint256 _tokenWeight,
        uint256 _minProfitBps,
        uint256 _maxBxdAmount,
        uint256 _bufferAmount,
        uint256 _bxdAmount
    ) external onlyKeeperAndAbove {
        require(_minProfitBps <= 500, "Timelock: invalid _minProfitBps");

        IVault vault = IVault(_vault);
        require(vault.whitelistedTokens(_token), "Timelock: token not yet whitelisted");

        uint256 tokenDecimals = vault.tokenDecimals(_token);
        bool isStable = vault.stableTokens(_token);
        bool isShortable = vault.shortableTokens(_token);

        IVault(_vault).setTokenConfig(
            _token,
            tokenDecimals,
            _tokenWeight,
            _minProfitBps,
            _maxBxdAmount,
            isStable,
            isShortable
        );

        IVault(_vault).setBufferAmount(_token, _bufferAmount);

        IVault(_vault).setBxdAmount(_token, _bxdAmount);
    }

    function setBxdAmounts(address _vault, address[] memory _tokens, uint256[] memory _bxdAmounts) external onlyKeeperAndAbove {
        for (uint256 i = 0; i < _tokens.length; i++) {
            IVault(_vault).setBxdAmount(_tokens[i], _bxdAmounts[i]);
        }
    }

    function updateBxdSupply(uint256 bxdAmount) external onlyKeeperAndAbove {
        address bxd = IBlpManager(blpManager).bxd();
        uint256 balance = IERC20(bxd).balanceOf(blpManager);

        IBXD(bxd).addVault(address(this));

        if (bxdAmount > balance) {
            uint256 mintAmount = bxdAmount.sub(balance);
            IBXD(bxd).mint(blpManager, mintAmount);
        } else {
            uint256 burnAmount = balance.sub(bxdAmount);
            IBXD(bxd).burn(blpManager, burnAmount);
        }

        IBXD(bxd).removeVault(address(this));
    }

    function setShortsTrackerAveragePriceWeight(uint256 _shortsTrackerAveragePriceWeight) external onlyAdmin {
        IBlpManager(blpManager).setShortsTrackerAveragePriceWeight(_shortsTrackerAveragePriceWeight);
    }

    function setBlpCooldownDuration(uint256 _cooldownDuration) external onlyAdmin {
        require(_cooldownDuration < 2 hours, "Timelock: invalid _cooldownDuration");
        IBlpManager(blpManager).setCooldownDuration(_cooldownDuration);
    }

    function setMaxGlobalShortSize(address _vault, address _token, uint256 _amount) external onlyAdmin {
        IVault(_vault).setMaxGlobalShortSize(_token, _amount);
    }

    function removeAdmin(address _token, address _account) external onlyAdmin {
        IYieldToken(_token).removeAdmin(_account);
    }

    function setIsSwapEnabled(address _vault, bool _isSwapEnabled) external onlyKeeperAndAbove {
        IVault(_vault).setIsSwapEnabled(_isSwapEnabled);
    }

    function setTier(address _referralStorage, uint256 _tierId, uint256 _totalRebate, uint256 _discountShare) external onlyKeeperAndAbove {
        IReferralStorage(_referralStorage).setTier(_tierId, _totalRebate, _discountShare);
    }

    function setReferrerTier(address _referralStorage, address _referrer, uint256 _tierId) external onlyKeeperAndAbove {
        IReferralStorage(_referralStorage).setReferrerTier(_referrer, _tierId);
    }

    function govSetCodeOwner(address _referralStorage, bytes32 _code, address _newAccount) external onlyKeeperAndAbove {
        IReferralStorage(_referralStorage).govSetCodeOwner(_code, _newAccount);
    }

    function setVaultUtils(address _vault, IVaultUtils _vaultUtils) external onlyAdmin {
        IVault(_vault).setVaultUtils(_vaultUtils);
    }

    function setMaxGasPrice(address _vault, uint256 _maxGasPrice) external onlyAdmin {
        require(_maxGasPrice > 5000000000, "Invalid _maxGasPrice");
        IVault(_vault).setMaxGasPrice(_maxGasPrice);
    }

    function withdrawFees(address _vault, address _token, address _receiver) external onlyAdmin {
        IVault(_vault).withdrawFees(_token, _receiver);
    }

    function batchWithdrawFees(address _vault, address[] memory _tokens) external onlyKeeperAndAbove {
        for (uint256 i = 0; i < _tokens.length; i++) {
            IVault(_vault).withdrawFees(_tokens[i], admin);
        }
    }

    function setInPrivateLiquidationMode(address _vault, bool _inPrivateLiquidationMode) external onlyAdmin {
        IVault(_vault).setInPrivateLiquidationMode(_inPrivateLiquidationMode);
    }

    function setLiquidator(address _vault, address _liquidator, bool _isActive) external onlyAdmin {
        IVault(_vault).setLiquidator(_liquidator, _isActive);
    }

    function setInPrivateTransferMode(address _token, bool _inPrivateTransferMode) external onlyAdmin {
        IBaseToken(_token).setInPrivateTransferMode(_inPrivateTransferMode);
    }

    function batchSetBonusRewards(address _vester, address[] memory _accounts, uint256[] memory _amounts) external onlyKeeperAndAbove {
        require(_accounts.length == _amounts.length, "Timelock: invalid lengths");

        IHandlerTarget(_vester).setHandler(address(this), true);

        for (uint256 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];
            uint256 amount = _amounts[i];
            IVester(_vester).setBonusRewards(account, amount);
        }

        IHandlerTarget(_vester).setHandler(address(this), false);
    }

    function transferIn(address _sender, address _token, uint256 _amount) external onlyAdmin {
        IERC20(_token).transferFrom(_sender, address(this), _amount);
    }

    function signalApprove(address _token, address _spender, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("approve", _token, _spender, _amount));
        _setPendingAction(action);
        emit SignalApprove(_token, _spender, _amount, action);
    }

    function approve(address _token, address _spender, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("approve", _token, _spender, _amount));
        _validateAction(action);
        _clearAction(action);
        IERC20(_token).approve(_spender, _amount);
    }

    function signalWithdrawToken(address _target, address _token, address _receiver, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("withdrawToken", _target, _token, _receiver, _amount));
        _setPendingAction(action);
        emit SignalWithdrawToken(_target, _token, _receiver, _amount, action);
    }

    function withdrawToken(address _target, address _token, address _receiver, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("withdrawToken", _target, _token, _receiver, _amount));
        _validateAction(action);
        _clearAction(action);
        IBaseToken(_target).withdrawToken(_token, _receiver, _amount);
    }

    function signalMint(address _token, address _receiver, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("mint", _token, _receiver, _amount));
        _setPendingAction(action);
        emit SignalMint(_token, _receiver, _amount, action);
    }

    function processMint(address _token, address _receiver, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("mint", _token, _receiver, _amount));
        _validateAction(action);
        _clearAction(action);

        _mint(_token, _receiver, _amount);
    }

    function signalSetGov(address _target, address _gov) external override onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setGov", _target, _gov));
        _setPendingAction(action);
        emit SignalSetGov(_target, _gov, action);
    }

    function setGov(address _target, address _gov) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setGov", _target, _gov));
        _validateAction(action);
        _clearAction(action);
        ITimelockTarget(_target).setGov(_gov);
    }

    function signalSetHandler(address _target, address _handler, bool _isActive) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setHandler", _target, _handler, _isActive));
        _setPendingAction(action);
        emit SignalSetHandler(_target, _handler, _isActive, action);
    }

    function setHandler(address _target, address _handler, bool _isActive) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setHandler", _target, _handler, _isActive));
        _validateAction(action);
        _clearAction(action);
        IHandlerTarget(_target).setHandler(_handler, _isActive);
    }

    function signalSetPriceFeed(address _vault, address _priceFeed) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setPriceFeed", _vault, _priceFeed));
        _setPendingAction(action);
        emit SignalSetPriceFeed(_vault, _priceFeed, action);
    }

    function setPriceFeed(address _vault, address _priceFeed) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setPriceFeed", _vault, _priceFeed));
        _validateAction(action);
        _clearAction(action);
        IVault(_vault).setPriceFeed(_priceFeed);
    }

    function signalRedeemBxd(address _vault, address _token, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("redeemBxd", _vault, _token, _amount));
        _setPendingAction(action);
        emit SignalRedeemBxd(_vault, _token, _amount);
    }

    function redeemBxd(address _vault, address _token, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("redeemBxd", _vault, _token, _amount));
        _validateAction(action);
        _clearAction(action);

        address bxd = IVault(_vault).bxd();
        IVault(_vault).setManager(address(this), true);
        IBXD(bxd).addVault(address(this));

        IBXD(bxd).mint(address(this), _amount);
        IERC20(bxd).transfer(address(_vault), _amount);

        IVault(_vault).sellBXD(_token, mintReceiver);

        IVault(_vault).setManager(address(this), false);
        IBXD(bxd).removeVault(address(this));
    }

    function signalVaultSetTokenConfig(
        address _vault,
        address _token,
        uint256 _tokenDecimals,
        uint256 _tokenWeight,
        uint256 _minProfitBps,
        uint256 _maxBxdAmount,
        bool _isStable,
        bool _isShortable
    ) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked(
            "vaultSetTokenConfig",
            _vault,
            _token,
            _tokenDecimals,
            _tokenWeight,
            _minProfitBps,
            _maxBxdAmount,
            _isStable,
            _isShortable
        ));

        _setPendingAction(action);

        emit SignalVaultSetTokenConfig(
            _vault,
            _token,
            _tokenDecimals,
            _tokenWeight,
            _minProfitBps,
            _maxBxdAmount,
            _isStable,
            _isShortable
        );
    }

    function vaultSetTokenConfig(
        address _vault,
        address _token,
        uint256 _tokenDecimals,
        uint256 _tokenWeight,
        uint256 _minProfitBps,
        uint256 _maxBxdAmount,
        bool _isStable,
        bool _isShortable
    ) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked(
            "vaultSetTokenConfig",
            _vault,
            _token,
            _tokenDecimals,
            _tokenWeight,
            _minProfitBps,
            _maxBxdAmount,
            _isStable,
            _isShortable
        ));

        _validateAction(action);
        _clearAction(action);

        IVault(_vault).setTokenConfig(
            _token,
            _tokenDecimals,
            _tokenWeight,
            _minProfitBps,
            _maxBxdAmount,
            _isStable,
            _isShortable
        );
    }

    function cancelAction(bytes32 _action) external onlyAdmin {
        _clearAction(_action);
    }

    function _mint(address _token, address _receiver, uint256 _amount) private {
        IMintable mintable = IMintable(_token);

        mintable.setMinter(address(this), true);

        mintable.mint(_receiver, _amount);
        require(IERC20(_token).totalSupply() <= maxTokenSupply, "Timelock: maxTokenSupply exceeded");

        mintable.setMinter(address(this), false);
    }

    function _setPendingAction(bytes32 _action) private {
        require(pendingActions[_action] == 0, "Timelock: action already signalled");
        pendingActions[_action] = block.timestamp.add(buffer);
        emit SignalPendingAction(_action);
    }

    function _validateAction(bytes32 _action) private view {
        require(pendingActions[_action] != 0, "Timelock: action not signalled");
        require(pendingActions[_action] < block.timestamp, "Timelock: action time not yet passed");
    }

    function _clearAction(bytes32 _action) private {
        require(pendingActions[_action] != 0, "Timelock: invalid _action");
        delete pendingActions[_action];
        emit ClearAction(_action);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../core/interfaces/IVault.sol";
import "../core/interfaces/IVaultPriceFeed.sol";
import "../core/interfaces/IBasePositionManager.sol";

contract VaultReader {
    function getVaultTokenInfoV3(address _vault, address _positionManager, address _weth, uint256 _bxdAmount, address[] memory _tokens) public view returns (uint256[] memory) {
        uint256 propsLength = 14;

        IVault vault = IVault(_vault);
        IVaultPriceFeed priceFeed = IVaultPriceFeed(vault.priceFeed());
        IBasePositionManager positionManager = IBasePositionManager(_positionManager);

        uint256[] memory amounts = new uint256[](_tokens.length * propsLength);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                token = _weth;
            }

            amounts[i * propsLength] = vault.poolAmounts(token);
            amounts[i * propsLength + 1] = vault.reservedAmounts(token);
            amounts[i * propsLength + 2] = vault.bxdAmounts(token);
            amounts[i * propsLength + 3] = vault.getRedemptionAmount(token, _bxdAmount);
            amounts[i * propsLength + 4] = vault.tokenWeights(token);
            amounts[i * propsLength + 5] = vault.bufferAmounts(token);
            amounts[i * propsLength + 6] = vault.maxBxdAmounts(token);
            amounts[i * propsLength + 7] = vault.globalShortSizes(token);
            amounts[i * propsLength + 8] = positionManager.maxGlobalShortSizes(token);
            amounts[i * propsLength + 9] = vault.getMinPrice(token);
            amounts[i * propsLength + 10] = vault.getMaxPrice(token);
            amounts[i * propsLength + 11] = vault.guaranteedUsd(token);
            amounts[i * propsLength + 12] = priceFeed.getPrimaryPrice(token, false);
            amounts[i * propsLength + 13] = priceFeed.getPrimaryPrice(token, true);
        }

        return amounts;
    }

    function getVaultTokenInfoV4(address _vault, address _positionManager, address _weth, uint256 _bxdAmount, address[] memory _tokens) public view returns (uint256[] memory) {
        uint256 propsLength = 15;

        IVault vault = IVault(_vault);
        IVaultPriceFeed priceFeed = IVaultPriceFeed(vault.priceFeed());
        IBasePositionManager positionManager = IBasePositionManager(_positionManager);

        uint256[] memory amounts = new uint256[](_tokens.length * propsLength);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                token = _weth;
            }

            amounts[i * propsLength] = vault.poolAmounts(token);
            amounts[i * propsLength + 1] = vault.reservedAmounts(token);
            amounts[i * propsLength + 2] = vault.bxdAmounts(token);
            amounts[i * propsLength + 3] = vault.getRedemptionAmount(token, _bxdAmount);
            amounts[i * propsLength + 4] = vault.tokenWeights(token);
            amounts[i * propsLength + 5] = vault.bufferAmounts(token);
            amounts[i * propsLength + 6] = vault.maxBxdAmounts(token);
            amounts[i * propsLength + 7] = vault.globalShortSizes(token);
            amounts[i * propsLength + 8] = positionManager.maxGlobalShortSizes(token);
            amounts[i * propsLength + 9] = positionManager.maxGlobalLongSizes(token);
            amounts[i * propsLength + 10] = vault.getMinPrice(token);
            amounts[i * propsLength + 11] = vault.getMaxPrice(token);
            amounts[i * propsLength + 12] = vault.guaranteedUsd(token);
            amounts[i * propsLength + 13] = priceFeed.getPrimaryPrice(token, false);
            amounts[i * propsLength + 14] = priceFeed.getPrimaryPrice(token, true);
        }

        return amounts;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IReferralStorage {
    function codeOwners(bytes32 _code) external view returns (address);
    function traderReferralCodes(address _account) external view returns (bytes32);
    function referrerDiscountShares(address _account) external view returns (uint256);
    function referrerTiers(address _account) external view returns (uint256);
    function getTraderReferralInfo(address _account) external view returns (bytes32, address);
    function setTraderReferralCode(address _account, bytes32 _code) external;
    function setTier(uint256 _tierId, uint256 _totalRebate, uint256 _discountShare) external;
    function setReferrerTier(address _referrer, uint256 _tierId) external;
    function govSetCodeOwner(bytes32 _code, address _newAccount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./interfaces/IReferralStorage.sol";

contract ReferralReader {
    function getCodeOwners(IReferralStorage _referralStorage, bytes32[] memory _codes) public view returns (address[] memory) {
        address[] memory owners = new address[](_codes.length);

        for (uint256 i = 0; i < _codes.length; i++) {
            bytes32 code = _codes[i];
            owners[i] = _referralStorage.codeOwners(code);
        }

        return owners;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../libraries/math/SafeMath.sol";

import "../access/Governable.sol";
import "../peripherals/interfaces/ITimelock.sol";

import "./interfaces/IReferralStorage.sol";

contract ReferralStorage is Governable, IReferralStorage {
    using SafeMath for uint256;

    struct Tier {
        uint256 totalRebate; // e.g. 2400 for 24%
        uint256 discountShare; // 5000 for 50%/50%, 7000 for 30% rebates/70% discount
    }

    uint256 public constant BASIS_POINTS = 10000;

    mapping (address => uint256) public override referrerDiscountShares; // to override default value in tier
    mapping (address => uint256) public override referrerTiers; // link between user <> tier
    mapping (uint256 => Tier) public tiers;

    mapping (address => bool) public isHandler;

    mapping (bytes32 => address) public override codeOwners;
    mapping (address => bytes32) public override traderReferralCodes;

    event SetHandler(address handler, bool isActive);
    event SetTraderReferralCode(address account, bytes32 code);
    event SetTier(uint256 tierId, uint256 totalRebate, uint256 discountShare);
    event SetReferrerTier(address referrer, uint256 tierId);
    event SetReferrerDiscountShare(address referrer, uint256 discountShare);
    event RegisterCode(address account, bytes32 code);
    event SetCodeOwner(address account, address newAccount, bytes32 code);
    event GovSetCodeOwner(bytes32 code, address newAccount);

    modifier onlyHandler() {
        require(isHandler[msg.sender], "ReferralStorage: forbidden");
        _;
    }

    function setHandler(address _handler, bool _isActive) external onlyGov {
        isHandler[_handler] = _isActive;
        emit SetHandler(_handler, _isActive);
    }

    function setTier(uint256 _tierId, uint256 _totalRebate, uint256 _discountShare) external override onlyGov {
        require(_totalRebate <= BASIS_POINTS, "ReferralStorage: invalid totalRebate");
        require(_discountShare <= BASIS_POINTS, "ReferralStorage: invalid discountShare");

        Tier memory tier = tiers[_tierId];
        tier.totalRebate = _totalRebate;
        tier.discountShare = _discountShare;
        tiers[_tierId] = tier;
        emit SetTier(_tierId, _totalRebate, _discountShare);
    }

    function setReferrerTier(address _referrer, uint256 _tierId) external override onlyGov {
        referrerTiers[_referrer] = _tierId;
        emit SetReferrerTier(_referrer, _tierId);
    }

    function setReferrerDiscountShare(uint256 _discountShare) external {
        require(_discountShare <= BASIS_POINTS, "ReferralStorage: invalid discountShare");

        referrerDiscountShares[msg.sender] = _discountShare;
        emit SetReferrerDiscountShare(msg.sender, _discountShare);
    }

    function setTraderReferralCode(address _account, bytes32 _code) external override onlyHandler {
        _setTraderReferralCode(_account, _code);
    }

    function setTraderReferralCodeByUser(bytes32 _code) external {
        _setTraderReferralCode(msg.sender, _code);
    }

    function registerCode(bytes32 _code) external {
        require(_code != bytes32(0), "ReferralStorage: invalid _code");
        require(codeOwners[_code] == address(0), "ReferralStorage: code already exists");

        codeOwners[_code] = msg.sender;
        emit RegisterCode(msg.sender, _code);
    }

    function setCodeOwner(bytes32 _code, address _newAccount) external {
        require(_code != bytes32(0), "ReferralStorage: invalid _code");

        address account = codeOwners[_code];
        require(msg.sender == account, "ReferralStorage: forbidden");

        codeOwners[_code] = _newAccount;
        emit SetCodeOwner(msg.sender, _newAccount, _code);
    }

    function govSetCodeOwner(bytes32 _code, address _newAccount) external override onlyGov {
        require(_code != bytes32(0), "ReferralStorage: invalid _code");

        codeOwners[_code] = _newAccount;
        emit GovSetCodeOwner(_code, _newAccount);
    }

    function getTraderReferralInfo(address _account) external override view returns (bytes32, address) {
        bytes32 code = traderReferralCodes[_account];
        address referrer;
        if (code != bytes32(0)) {
            referrer = codeOwners[code];
        }
        return (code, referrer);
    }

    function _setTraderReferralCode(address _account, bytes32 _code) private {
        traderReferralCodes[_account] = _code;
        emit SetTraderReferralCode(_account, _code);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../core/interfaces/IBlpManager.sol";

contract BlpBalance {
    using SafeMath for uint256;

    IBlpManager public blpManager;
    address public stakedBlpTracker;

    mapping (address => mapping (address => uint256)) public allowances;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        IBlpManager _blpManager,
        address _stakedBlpTracker
    ) public {
        blpManager = _blpManager;
        stakedBlpTracker = _stakedBlpTracker;
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transfer(address _recipient, uint256 _amount) external returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool) {
        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "BlpBalance: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "BlpBalance: approve from the zero address");
        require(_spender != address(0), "BlpBalance: approve to the zero address");

        allowances[_owner][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "BlpBalance: transfer from the zero address");
        require(_recipient != address(0), "BlpBalance: transfer to the zero address");

        require(
            blpManager.lastAddedAt(_sender).add(blpManager.cooldownDuration()) <= block.timestamp,
            "BlpBalance: cooldown duration not yet passed"
        );

        IERC20(stakedBlpTracker).transferFrom(_sender, _recipient, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IRewardDistributor.sol";
import "./interfaces/IRewardTracker.sol";
import "../access/Governable.sol";

contract BonusDistributor is IRewardDistributor, ReentrancyGuard, Governable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant BONUS_DURATION = 365 days;

    uint256 public bonusMultiplierBasisPoints;

    address public override rewardToken;
    uint256 public lastDistributionTime;
    address public rewardTracker;

    address public admin;

    event Distribute(uint256 amount);
    event BonusMultiplierChange(uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "BonusDistributor: forbidden");
        _;
    }

    constructor(address _rewardToken, address _rewardTracker) public {
        rewardToken = _rewardToken;
        rewardTracker = _rewardTracker;
        admin = msg.sender;
    }

    function setAdmin(address _admin) external onlyGov {
        admin = _admin;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function updateLastDistributionTime() external onlyAdmin {
        lastDistributionTime = block.timestamp;
    }

    function setBonusMultiplier(uint256 _bonusMultiplierBasisPoints) external onlyAdmin {
        require(lastDistributionTime != 0, "BonusDistributor: invalid lastDistributionTime");
        IRewardTracker(rewardTracker).updateRewards();
        bonusMultiplierBasisPoints = _bonusMultiplierBasisPoints;
        emit BonusMultiplierChange(_bonusMultiplierBasisPoints);
    }

    function tokensPerInterval() public view override returns (uint256) {
        uint256 supply = IERC20(rewardTracker).totalSupply();
        return supply.mul(bonusMultiplierBasisPoints).div(BASIS_POINTS_DIVISOR).div(BONUS_DURATION);
    }

    function pendingRewards() public view override returns (uint256) {
        if (block.timestamp == lastDistributionTime) {
            return 0;
        }

        uint256 supply = IERC20(rewardTracker).totalSupply();
        uint256 timeDiff = block.timestamp.sub(lastDistributionTime);

        return timeDiff.mul(supply).mul(bonusMultiplierBasisPoints).div(BASIS_POINTS_DIVISOR).div(BONUS_DURATION);
    }

    function distribute() external override returns (uint256) {
        require(msg.sender == rewardTracker, "BonusDistributor: invalid msg.sender");
        uint256 amount = pendingRewards();
        if (amount == 0) { return 0; }

        lastDistributionTime = block.timestamp;

        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        if (amount > balance) { amount = balance; }

        IERC20(rewardToken).safeTransfer(msg.sender, amount);

        emit Distribute(amount);
        return amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IRewardDistributor {
    function rewardToken() external view returns (address);
    function tokensPerInterval() external view returns (uint256);
    function pendingRewards() external view returns (uint256);
    function distribute() external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IRewardRouterV2 {
    function feeBlpTracker() external view returns (address);
    function stakedBlpTracker() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IRewardTracker {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);
    function stakedAmounts(address _account) external view returns (uint256);
    function updateRewards() external;
    function stake(address _depositToken, uint256 _amount) external;
    function stakeForAccount(address _fundingAccount, address _account, address _depositToken, uint256 _amount) external;
    function unstake(address _depositToken, uint256 _amount) external;
    function unstakeForAccount(address _account, address _depositToken, uint256 _amount, address _receiver) external;
    function tokensPerInterval() external view returns (uint256);
    function claim(address _receiver) external returns (uint256);
    function claimForAccount(address _account, address _receiver) external returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function averageStakedAmounts(address _account) external view returns (uint256);
    function cumulativeRewards(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IVester {
    function rewardTracker() external view returns (address);

    function claimForAccount(address _account, address _receiver) external returns (uint256);

    function claimable(address _account) external view returns (uint256);
    function cumulativeClaimAmounts(address _account) external view returns (uint256);
    function claimedAmounts(address _account) external view returns (uint256);
    function pairAmounts(address _account) external view returns (uint256);
    function getVestedAmount(address _account) external view returns (uint256);
    function transferredAverageStakedAmounts(address _account) external view returns (uint256);
    function transferredCumulativeRewards(address _account) external view returns (uint256);
    function cumulativeRewardDeductions(address _account) external view returns (uint256);
    function bonusRewards(address _account) external view returns (uint256);

    function transferStakeValues(address _sender, address _receiver) external;
    function setTransferredAverageStakedAmounts(address _account, uint256 _amount) external;
    function setTransferredCumulativeRewards(address _account, uint256 _amount) external;
    function setCumulativeRewardDeductions(address _account, uint256 _amount) external;
    function setBonusRewards(address _account, uint256 _amount) external;

    function getMaxVestableAmount(address _account) external view returns (uint256);
    function getCombinedAverageStakedAmount(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IRewardDistributor.sol";
import "./interfaces/IRewardTracker.sol";
import "../access/Governable.sol";

contract RewardDistributor is IRewardDistributor, ReentrancyGuard, Governable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public override rewardToken;
    uint256 public override tokensPerInterval;
    uint256 public lastDistributionTime;
    address public rewardTracker;

    address public admin;

    event Distribute(uint256 amount);
    event TokensPerIntervalChange(uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "RewardDistributor: forbidden");
        _;
    }

    constructor(address _rewardToken, address _rewardTracker) public {
        rewardToken = _rewardToken;
        rewardTracker = _rewardTracker;
        admin = msg.sender;
    }

    function setAdmin(address _admin) external onlyGov {
        admin = _admin;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function updateLastDistributionTime() external onlyAdmin {
        lastDistributionTime = block.timestamp;
    }

    function setTokensPerInterval(uint256 _amount) external onlyAdmin {
        require(lastDistributionTime != 0, "RewardDistributor: invalid lastDistributionTime");
        IRewardTracker(rewardTracker).updateRewards();
        tokensPerInterval = _amount;
        emit TokensPerIntervalChange(_amount);
    }

    function pendingRewards() public view override returns (uint256) {
        if (block.timestamp == lastDistributionTime) {
            return 0;
        }

        uint256 timeDiff = block.timestamp.sub(lastDistributionTime);
        return tokensPerInterval.mul(timeDiff);
    }

    function distribute() external override returns (uint256) {
        require(msg.sender == rewardTracker, "RewardDistributor: invalid msg.sender");
        uint256 amount = pendingRewards();
        if (amount == 0) { return 0; }

        lastDistributionTime = block.timestamp;

        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        if (amount > balance) { amount = balance; }

        IERC20(rewardToken).safeTransfer(msg.sender, amount);

        emit Distribute(amount);
        return amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";
import "../libraries/utils/Address.sol";

import "./interfaces/IRewardTracker.sol";
import "../tokens/interfaces/IMintable.sol";
import "../tokens/interfaces/IWETH.sol";
import "../core/interfaces/IBlpManager.sol";
import "../access/Governable.sol";

contract RewardRouter is ReentrancyGuard, Governable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    bool public isInitialized;

    address public weth;

    address public bxp;
    address public htdBxp;
    address public bnBxp;

    address public blp; // BXP Liquidity Provider token

    address public stakedBxpTracker;
    address public bonusBxpTracker;
    address public feeBxpTracker;

    address public stakedBlpTracker;
    address public feeBlpTracker;

    address public blpManager;

    event StakeBxp(address account, uint256 amount);
    event UnstakeBxp(address account, uint256 amount);

    event StakeBlp(address account, uint256 amount);
    event UnstakeBlp(address account, uint256 amount);

    receive() external payable {
        require(msg.sender == weth, "Router: invalid sender");
    }

    function initialize(
        address _weth,
        address _bxp,
        address _htdBxp,
        address _bnBxp,
        address _blp,
        address _stakedBxpTracker,
        address _bonusBxpTracker,
        address _feeBxpTracker,
        address _feeBlpTracker,
        address _stakedBlpTracker,
        address _blpManager
    ) external onlyGov {
        require(!isInitialized, "RewardRouter: already initialized");
        isInitialized = true;

        weth = _weth;

        bxp = _bxp;
        htdBxp = _htdBxp;
        bnBxp = _bnBxp;

        blp = _blp;

        stakedBxpTracker = _stakedBxpTracker;
        bonusBxpTracker = _bonusBxpTracker;
        feeBxpTracker = _feeBxpTracker;

        feeBlpTracker = _feeBlpTracker;
        stakedBlpTracker = _stakedBlpTracker;

        blpManager = _blpManager;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function batchStakeBxpForAccount(address[] memory _accounts, uint256[] memory _amounts) external nonReentrant onlyGov {
        address _bxp = bxp;
        for (uint256 i = 0; i < _accounts.length; i++) {
            _stakeBxp(msg.sender, _accounts[i], _bxp, _amounts[i]);
        }
    }

    function stakeBxpForAccount(address _account, uint256 _amount) external nonReentrant onlyGov {
        _stakeBxp(msg.sender, _account, bxp, _amount);
    }

    function stakeBxp(uint256 _amount) external nonReentrant {
        _stakeBxp(msg.sender, msg.sender, bxp, _amount);
    }

    function stakeHtdBxp(uint256 _amount) external nonReentrant {
        _stakeBxp(msg.sender, msg.sender, htdBxp, _amount);
    }

    function unstakeBxp(uint256 _amount) external nonReentrant {
        _unstakeBxp(msg.sender, bxp, _amount);
    }

    function unstakeHtdBxp(uint256 _amount) external nonReentrant {
        _unstakeBxp(msg.sender, htdBxp, _amount);
    }

    function mintAndStakeBlp(address _token, uint256 _amount, uint256 _minBxd, uint256 _minBlp) external nonReentrant returns (uint256) {
        require(_amount > 0, "RewardRouter: invalid _amount");

        address account = msg.sender;
        uint256 blpAmount = IBlpManager(blpManager).addLiquidityForAccount(account, account, _token, _amount, _minBxd, _minBlp);
        IRewardTracker(feeBlpTracker).stakeForAccount(account, account, blp, blpAmount);
        IRewardTracker(stakedBlpTracker).stakeForAccount(account, account, feeBlpTracker, blpAmount);

        emit StakeBlp(account, blpAmount);

        return blpAmount;
    }

    function mintAndStakeBlpETH(uint256 _minBxd, uint256 _minBlp) external payable nonReentrant returns (uint256) {
        require(msg.value > 0, "RewardRouter: invalid msg.value");

        IWETH(weth).deposit{value: msg.value}();
        IERC20(weth).approve(blpManager, msg.value);

        address account = msg.sender;
        uint256 blpAmount = IBlpManager(blpManager).addLiquidityForAccount(address(this), account, weth, msg.value, _minBxd, _minBlp);

        IRewardTracker(feeBlpTracker).stakeForAccount(account, account, blp, blpAmount);
        IRewardTracker(stakedBlpTracker).stakeForAccount(account, account, feeBlpTracker, blpAmount);

        emit StakeBlp(account, blpAmount);

        return blpAmount;
    }

    function unstakeAndRedeemBlp(address _tokenOut, uint256 _blpAmount, uint256 _minOut, address _receiver) external nonReentrant returns (uint256) {
        require(_blpAmount > 0, "RewardRouter: invalid _blpAmount");

        address account = msg.sender;
        IRewardTracker(stakedBlpTracker).unstakeForAccount(account, feeBlpTracker, _blpAmount, account);
        IRewardTracker(feeBlpTracker).unstakeForAccount(account, blp, _blpAmount, account);
        uint256 amountOut = IBlpManager(blpManager).removeLiquidityForAccount(account, _tokenOut, _blpAmount, _minOut, _receiver);

        emit UnstakeBlp(account, _blpAmount);

        return amountOut;
    }

    function unstakeAndRedeemBlpETH(uint256 _blpAmount, uint256 _minOut, address payable _receiver) external nonReentrant returns (uint256) {
        require(_blpAmount > 0, "RewardRouter: invalid _blpAmount");

        address account = msg.sender;
        IRewardTracker(stakedBlpTracker).unstakeForAccount(account, feeBlpTracker, _blpAmount, account);
        IRewardTracker(feeBlpTracker).unstakeForAccount(account, blp, _blpAmount, account);
        uint256 amountOut = IBlpManager(blpManager).removeLiquidityForAccount(account, weth, _blpAmount, _minOut, address(this));

        IWETH(weth).withdraw(amountOut);

        _receiver.sendValue(amountOut);

        emit UnstakeBlp(account, _blpAmount);

        return amountOut;
    }

    function claim() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(feeBxpTracker).claimForAccount(account, account);
        IRewardTracker(feeBlpTracker).claimForAccount(account, account);

        IRewardTracker(stakedBxpTracker).claimForAccount(account, account);
        IRewardTracker(stakedBlpTracker).claimForAccount(account, account);
    }

    function claimHtdBxp() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(stakedBxpTracker).claimForAccount(account, account);
        IRewardTracker(stakedBlpTracker).claimForAccount(account, account);
    }

    function claimFees() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(feeBxpTracker).claimForAccount(account, account);
        IRewardTracker(feeBlpTracker).claimForAccount(account, account);
    }

    function compound() external nonReentrant {
        _compound(msg.sender);
    }

    function compoundForAccount(address _account) external nonReentrant onlyGov {
        _compound(_account);
    }

    function batchCompoundForAccounts(address[] memory _accounts) external nonReentrant onlyGov {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _compound(_accounts[i]);
        }
    }

    function _compound(address _account) private {
        _compoundBxp(_account);
        _compoundBlp(_account);
    }

    function _compoundBxp(address _account) private {
        uint256 htdBxpAmount = IRewardTracker(stakedBxpTracker).claimForAccount(_account, _account);
        if (htdBxpAmount > 0) {
            _stakeBxp(_account, _account, htdBxp, htdBxpAmount);
        }

        uint256 bnBxpAmount = IRewardTracker(bonusBxpTracker).claimForAccount(_account, _account);
        if (bnBxpAmount > 0) {
            IRewardTracker(feeBxpTracker).stakeForAccount(_account, _account, bnBxp, bnBxpAmount);
        }
    }

    function _compoundBlp(address _account) private {
        uint256 htdBxpAmount = IRewardTracker(stakedBlpTracker).claimForAccount(_account, _account);
        if (htdBxpAmount > 0) {
            _stakeBxp(_account, _account, htdBxp, htdBxpAmount);
        }
    }

    function _stakeBxp(address _fundingAccount, address _account, address _token, uint256 _amount) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        IRewardTracker(stakedBxpTracker).stakeForAccount(_fundingAccount, _account, _token, _amount);
        IRewardTracker(bonusBxpTracker).stakeForAccount(_account, _account, stakedBxpTracker, _amount);
        IRewardTracker(feeBxpTracker).stakeForAccount(_account, _account, bonusBxpTracker, _amount);

        emit StakeBxp(_account, _amount);
    }

    function _unstakeBxp(address _account, address _token, uint256 _amount) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        uint256 balance = IRewardTracker(stakedBxpTracker).stakedAmounts(_account);

        IRewardTracker(feeBxpTracker).unstakeForAccount(_account, bonusBxpTracker, _amount, _account);
        IRewardTracker(bonusBxpTracker).unstakeForAccount(_account, stakedBxpTracker, _amount, _account);
        IRewardTracker(stakedBxpTracker).unstakeForAccount(_account, _token, _amount, _account);

        uint256 bnBxpAmount = IRewardTracker(bonusBxpTracker).claimForAccount(_account, _account);
        if (bnBxpAmount > 0) {
            IRewardTracker(feeBxpTracker).stakeForAccount(_account, _account, bnBxp, bnBxpAmount);
        }

        uint256 stakedBnBxp = IRewardTracker(feeBxpTracker).depositBalances(_account, bnBxp);
        if (stakedBnBxp > 0) {
            uint256 reductionAmount = stakedBnBxp.mul(_amount).div(balance);
            IRewardTracker(feeBxpTracker).unstakeForAccount(_account, bnBxp, reductionAmount, _account);
            IMintable(bnBxp).burn(_account, reductionAmount);
        }

        emit UnstakeBxp(_account, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";
import "../libraries/utils/Address.sol";

import "./interfaces/IRewardTracker.sol";
import "./interfaces/IRewardRouterV2.sol";
import "./interfaces/IVester.sol";
import "../tokens/interfaces/IMintable.sol";
import "../tokens/interfaces/IWETH.sol";
import "../core/interfaces/IBlpManager.sol";
import "../access/Governable.sol";

contract RewardRouterV2 is IRewardRouterV2, ReentrancyGuard, Governable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    bool public isInitialized;

    address public weth;

    address public bxp;
    address public htdBxp;
    address public bnBxp;

    address public blp; // BXP Liquidity Provider token

    address public stakedBxpTracker;
    address public bonusBxpTracker;
    address public feeBxpTracker;

    address public override stakedBlpTracker;
    address public override feeBlpTracker;

    address public blpManager;

    address public bxpVester;
    address public blpVester;

    mapping (address => address) public pendingReceivers;

    event StakeBxp(address account, address token, uint256 amount);
    event UnstakeBxp(address account, address token, uint256 amount);

    event StakeBlp(address account, uint256 amount);
    event UnstakeBlp(address account, uint256 amount);

    receive() external payable {
        require(msg.sender == weth, "Router: invalid sender");
    }

    function initialize(
        address _weth,
        address _bxp,
        address _htdBxp,
        address _bnBxp,
        address _blp,
        address _stakedBxpTracker,
        address _bonusBxpTracker,
        address _feeBxpTracker,
        address _feeBlpTracker,
        address _stakedBlpTracker,
        address _blpManager,
        address _bxpVester,
        address _blpVester
    ) external onlyGov {
        require(!isInitialized, "RewardRouter: already initialized");
        isInitialized = true;

        weth = _weth;

        bxp = _bxp;
        htdBxp = _htdBxp;
        bnBxp = _bnBxp;

        blp = _blp;

        stakedBxpTracker = _stakedBxpTracker;
        bonusBxpTracker = _bonusBxpTracker;
        feeBxpTracker = _feeBxpTracker;

        feeBlpTracker = _feeBlpTracker;
        stakedBlpTracker = _stakedBlpTracker;

        blpManager = _blpManager;

        bxpVester = _bxpVester;
        blpVester = _blpVester;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function batchStakeBxpForAccount(address[] memory _accounts, uint256[] memory _amounts) external nonReentrant onlyGov {
        address _bxp = bxp;
        for (uint256 i = 0; i < _accounts.length; i++) {
            _stakeBxp(msg.sender, _accounts[i], _bxp, _amounts[i]);
        }
    }

    function stakeBxpForAccount(address _account, uint256 _amount) external nonReentrant onlyGov {
        _stakeBxp(msg.sender, _account, bxp, _amount);
    }

    function stakeBxp(uint256 _amount) external nonReentrant {
        _stakeBxp(msg.sender, msg.sender, bxp, _amount);
    }

    function stakeHtdBxp(uint256 _amount) external nonReentrant {
        _stakeBxp(msg.sender, msg.sender, htdBxp, _amount);
    }

    function unstakeBxp(uint256 _amount) external nonReentrant {
        _unstakeBxp(msg.sender, bxp, _amount, true);
    }

    function unstakeHtdBxp(uint256 _amount) external nonReentrant {
        _unstakeBxp(msg.sender, htdBxp, _amount, true);
    }

    function mintAndStakeBlp(address _token, uint256 _amount, uint256 _minBxd, uint256 _minBlp) external nonReentrant returns (uint256) {
        require(_amount > 0, "RewardRouter: invalid _amount");

        address account = msg.sender;
        uint256 blpAmount = IBlpManager(blpManager).addLiquidityForAccount(account, account, _token, _amount, _minBxd, _minBlp);
        IRewardTracker(feeBlpTracker).stakeForAccount(account, account, blp, blpAmount);
        IRewardTracker(stakedBlpTracker).stakeForAccount(account, account, feeBlpTracker, blpAmount);

        emit StakeBlp(account, blpAmount);

        return blpAmount;
    }


    function mintAndStakeBlpETH(uint256 _minBxd, uint256 _minBlp) external payable nonReentrant returns (uint256) {
        require(msg.value > 0, "RewardRouter: invalid msg.value");

        IWETH(weth).deposit{value: msg.value}();
        IERC20(weth).approve(blpManager, msg.value);

        address account = msg.sender;
        uint256 blpAmount = IBlpManager(blpManager).addLiquidityForAccount(address(this), account, weth, msg.value, _minBxd, _minBlp);

        IRewardTracker(feeBlpTracker).stakeForAccount(account, account, blp, blpAmount);
        IRewardTracker(stakedBlpTracker).stakeForAccount(account, account, feeBlpTracker, blpAmount);

        emit StakeBlp(account, blpAmount);

        return blpAmount;
    }

    function unstakeAndRedeemBlp(address _tokenOut, uint256 _blpAmount, uint256 _minOut, address _receiver) external nonReentrant returns (uint256) {
        require(_blpAmount > 0, "RewardRouter: invalid _blpAmount");

        address account = msg.sender;
        IRewardTracker(stakedBlpTracker).unstakeForAccount(account, feeBlpTracker, _blpAmount, account);
        IRewardTracker(feeBlpTracker).unstakeForAccount(account, blp, _blpAmount, account);
        uint256 amountOut = IBlpManager(blpManager).removeLiquidityForAccount(account, _tokenOut, _blpAmount, _minOut, _receiver);

        emit UnstakeBlp(account, _blpAmount);

        return amountOut;
    }


    function unstakeAndRedeemBlpETH(uint256 _blpAmount, uint256 _minOut, address payable _receiver) external nonReentrant returns (uint256) {
        require(_blpAmount > 0, "RewardRouter: invalid _blpAmount");

        address account = msg.sender;
        IRewardTracker(stakedBlpTracker).unstakeForAccount(account, feeBlpTracker, _blpAmount, account);
        IRewardTracker(feeBlpTracker).unstakeForAccount(account, blp, _blpAmount, account);
        uint256 amountOut = IBlpManager(blpManager).removeLiquidityForAccount(account, weth, _blpAmount, _minOut, address(this));

        IWETH(weth).withdraw(amountOut);

        _receiver.sendValue(amountOut);

        emit UnstakeBlp(account, _blpAmount);

        return amountOut;
    }


    function claim() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(feeBxpTracker).claimForAccount(account, account);
        IRewardTracker(feeBlpTracker).claimForAccount(account, account);

        IRewardTracker(stakedBxpTracker).claimForAccount(account, account);
        IRewardTracker(stakedBlpTracker).claimForAccount(account, account);
    }

    function claimHtdBxp() public nonReentrant {
        address account = msg.sender;

        IRewardTracker(stakedBxpTracker).claimForAccount(account, account);
        IRewardTracker(stakedBlpTracker).claimForAccount(account, account);
    }

    function claimHtdBXP() external nonReentrant {
        claimHtdBxp();
    }

    function claimFees() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(feeBxpTracker).claimForAccount(account, account);
        IRewardTracker(feeBlpTracker).claimForAccount(account, account);
    }

    function compound() external nonReentrant {
        _compound(msg.sender);
    }

    function compoundForAccount(address _account) external nonReentrant onlyGov {
        _compound(_account);
    }

    function handleRewards(
        bool _shouldClaimBxp,
        bool _shouldStakeBxp,
        bool _shouldClaimHtdBxp,
        bool _shouldStakeHtdBxp,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external nonReentrant {
        address account = msg.sender;

        uint256 bxpAmount = 0;
        if (_shouldClaimBxp) {
            uint256 bxpAmount0 = IVester(bxpVester).claimForAccount(account, account);
            uint256 bxpAmount1 = IVester(blpVester).claimForAccount(account, account);
            bxpAmount = bxpAmount0.add(bxpAmount1);
        }

        if (_shouldStakeBxp && bxpAmount > 0) {
            _stakeBxp(account, account, bxp, bxpAmount);
        }

        uint256 htdBxpAmount = 0;
        if (_shouldClaimHtdBxp) {
            uint256 htdBxpAmount0 = IRewardTracker(stakedBxpTracker).claimForAccount(account, account);
            uint256 htdBxpAmount1 = IRewardTracker(stakedBlpTracker).claimForAccount(account, account);
            htdBxpAmount = htdBxpAmount0.add(htdBxpAmount1);
        }

        if (_shouldStakeHtdBxp && htdBxpAmount > 0) {
            _stakeBxp(account, account, htdBxp, htdBxpAmount);
        }

        if (_shouldStakeMultiplierPoints) {
            uint256 bnBxpAmount = IRewardTracker(bonusBxpTracker).claimForAccount(account, account);
            if (bnBxpAmount > 0) {
                IRewardTracker(feeBxpTracker).stakeForAccount(account, account, bnBxp, bnBxpAmount);
            }
        }

        if (_shouldClaimWeth) {
            if (_shouldConvertWethToEth) {
                uint256 weth0 = IRewardTracker(feeBxpTracker).claimForAccount(account, address(this));
                uint256 weth1 = IRewardTracker(feeBlpTracker).claimForAccount(account, address(this));

                uint256 wethAmount = weth0.add(weth1);
                IWETH(weth).withdraw(wethAmount);

                payable(account).sendValue(wethAmount);
            } else {
                IRewardTracker(feeBxpTracker).claimForAccount(account, account);
                IRewardTracker(feeBlpTracker).claimForAccount(account, account);
            }
        }
    }

    function batchCompoundForAccounts(address[] memory _accounts) external nonReentrant onlyGov {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _compound(_accounts[i]);
        }
    }

    // the _validateReceiver function checks that the averageStakedAmounts and cumulativeRewards
    // values of an account are zero, this is to help ensure that vesting calculations can be
    // done correctly
    // averageStakedAmounts and cumulativeRewards are updated if the claimable reward for an account
    // is more than zero
    // it is possible for multiple transfers to be sent into a single account, using signalTransfer and
    // acceptTransfer, if those values have not been updated yet
    // for BLP transfers it is also possible to transfer BLP into an account using the StakedBlp contract
    function signalTransfer(address _receiver) external nonReentrant {
        require(IERC20(bxpVester).balanceOf(msg.sender) == 0, "RewardRouter: sender has vested tokens");
        require(IERC20(blpVester).balanceOf(msg.sender) == 0, "RewardRouter: sender has vested tokens");

        _validateReceiver(_receiver);
        pendingReceivers[msg.sender] = _receiver;
    }

    function acceptTransfer(address _sender) external nonReentrant {
        require(IERC20(bxpVester).balanceOf(_sender) == 0, "RewardRouter: sender has vested tokens");
        require(IERC20(blpVester).balanceOf(_sender) == 0, "RewardRouter: sender has vested tokens");

        address receiver = msg.sender;
        require(pendingReceivers[_sender] == receiver, "RewardRouter: transfer not signalled");
        delete pendingReceivers[_sender];

        _validateReceiver(receiver);
        _compound(_sender);

        uint256 stakedBxp = IRewardTracker(stakedBxpTracker).depositBalances(_sender, bxp);
        if (stakedBxp > 0) {
            _unstakeBxp(_sender, bxp, stakedBxp, false);
            _stakeBxp(_sender, receiver, bxp, stakedBxp);
        }

        uint256 stakedHtdBxp = IRewardTracker(stakedBxpTracker).depositBalances(_sender, htdBxp);
        if (stakedHtdBxp > 0) {
            _unstakeBxp(_sender, htdBxp, stakedHtdBxp, false);
            _stakeBxp(_sender, receiver, htdBxp, stakedHtdBxp);
        }

        uint256 stakedBnBxp = IRewardTracker(feeBxpTracker).depositBalances(_sender, bnBxp);
        if (stakedBnBxp > 0) {
            IRewardTracker(feeBxpTracker).unstakeForAccount(_sender, bnBxp, stakedBnBxp, _sender);
            IRewardTracker(feeBxpTracker).stakeForAccount(_sender, receiver, bnBxp, stakedBnBxp);
        }

        uint256 htdBxpBalance = IERC20(htdBxp).balanceOf(_sender);
        if (htdBxpBalance > 0) {
            IERC20(htdBxp).transferFrom(_sender, receiver, htdBxpBalance);
        }

        uint256 blpAmount = IRewardTracker(feeBlpTracker).depositBalances(_sender, blp);
        if (blpAmount > 0) {
            IRewardTracker(stakedBlpTracker).unstakeForAccount(_sender, feeBlpTracker, blpAmount, _sender);
            IRewardTracker(feeBlpTracker).unstakeForAccount(_sender, blp, blpAmount, _sender);

            IRewardTracker(feeBlpTracker).stakeForAccount(_sender, receiver, blp, blpAmount);
            IRewardTracker(stakedBlpTracker).stakeForAccount(receiver, receiver, feeBlpTracker, blpAmount);
        }

        IVester(bxpVester).transferStakeValues(_sender, receiver);
        IVester(blpVester).transferStakeValues(_sender, receiver);
    }

    function _validateReceiver(address _receiver) private view {
        require(IRewardTracker(stakedBxpTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: stakedBxpTracker.averageStakedAmounts > 0");
        require(IRewardTracker(stakedBxpTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: stakedBxpTracker.cumulativeRewards > 0");

        require(IRewardTracker(bonusBxpTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: bonusBxpTracker.averageStakedAmounts > 0");
        require(IRewardTracker(bonusBxpTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: bonusBxpTracker.cumulativeRewards > 0");

        require(IRewardTracker(feeBxpTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: feeBxpTracker.averageStakedAmounts > 0");
        require(IRewardTracker(feeBxpTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: feeBxpTracker.cumulativeRewards > 0");

        require(IVester(bxpVester).transferredAverageStakedAmounts(_receiver) == 0, "RewardRouter: bxpVester.transferredAverageStakedAmounts > 0");
        require(IVester(bxpVester).transferredCumulativeRewards(_receiver) == 0, "RewardRouter: bxpVester.transferredCumulativeRewards > 0");

        require(IRewardTracker(stakedBlpTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: stakedBlpTracker.averageStakedAmounts > 0");
        require(IRewardTracker(stakedBlpTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: stakedBlpTracker.cumulativeRewards > 0");

        require(IRewardTracker(feeBlpTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: feeBlpTracker.averageStakedAmounts > 0");
        require(IRewardTracker(feeBlpTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: feeBlpTracker.cumulativeRewards > 0");

        require(IVester(blpVester).transferredAverageStakedAmounts(_receiver) == 0, "RewardRouter: bxpVester.transferredAverageStakedAmounts > 0");
        require(IVester(blpVester).transferredCumulativeRewards(_receiver) == 0, "RewardRouter: bxpVester.transferredCumulativeRewards > 0");

        require(IERC20(bxpVester).balanceOf(_receiver) == 0, "RewardRouter: bxpVester.balance > 0");
        require(IERC20(blpVester).balanceOf(_receiver) == 0, "RewardRouter: blpVester.balance > 0");
    }

    function _compound(address _account) private {
        _compoundBxp(_account);
        _compoundBlp(_account);
    }

    function _compoundBxp(address _account) private {
        uint256 htdBxpAmount = IRewardTracker(stakedBxpTracker).claimForAccount(_account, _account);
        if (htdBxpAmount > 0) {
            _stakeBxp(_account, _account, htdBxp, htdBxpAmount);
        }

        uint256 bnBxpAmount = IRewardTracker(bonusBxpTracker).claimForAccount(_account, _account);
        if (bnBxpAmount > 0) {
            IRewardTracker(feeBxpTracker).stakeForAccount(_account, _account, bnBxp, bnBxpAmount);
        }
    }

    function _compoundBlp(address _account) private {
        uint256 htdBxpAmount = IRewardTracker(stakedBlpTracker).claimForAccount(_account, _account);
        if (htdBxpAmount > 0) {
            _stakeBxp(_account, _account, htdBxp, htdBxpAmount);
        }
    }

    function _stakeBxp(address _fundingAccount, address _account, address _token, uint256 _amount) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        IRewardTracker(stakedBxpTracker).stakeForAccount(_fundingAccount, _account, _token, _amount);
        IRewardTracker(bonusBxpTracker).stakeForAccount(_account, _account, stakedBxpTracker, _amount);
        IRewardTracker(feeBxpTracker).stakeForAccount(_account, _account, bonusBxpTracker, _amount);

        emit StakeBxp(_account, _token, _amount);
    }

    function _unstakeBxp(address _account, address _token, uint256 _amount, bool _shouldReduceBnBxp) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        uint256 balance = IRewardTracker(stakedBxpTracker).stakedAmounts(_account);

        IRewardTracker(feeBxpTracker).unstakeForAccount(_account, bonusBxpTracker, _amount, _account);
        IRewardTracker(bonusBxpTracker).unstakeForAccount(_account, stakedBxpTracker, _amount, _account);
        IRewardTracker(stakedBxpTracker).unstakeForAccount(_account, _token, _amount, _account);

        if (_shouldReduceBnBxp) {
            uint256 bnBxpAmount = IRewardTracker(bonusBxpTracker).claimForAccount(_account, _account);
            if (bnBxpAmount > 0) {
                IRewardTracker(feeBxpTracker).stakeForAccount(_account, _account, bnBxp, bnBxpAmount);
            }

            uint256 stakedBnBxp = IRewardTracker(feeBxpTracker).depositBalances(_account, bnBxp);
            if (stakedBnBxp > 0) {
                uint256 reductionAmount = stakedBnBxp.mul(_amount).div(balance);
                IRewardTracker(feeBxpTracker).unstakeForAccount(_account, bnBxp, reductionAmount, _account);
                IMintable(bnBxp).burn(_account, reductionAmount);
            }
        }

        emit UnstakeBxp(_account, _token, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IRewardDistributor.sol";
import "./interfaces/IRewardTracker.sol";
import "../access/Governable.sol";

contract RewardTracker is IERC20, ReentrancyGuard, IRewardTracker, Governable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant PRECISION = 1e30;

    uint8 public constant decimals = 18;

    bool public isInitialized;

    string public name;
    string public symbol;

    address public distributor;
    mapping (address => bool) public isDepositToken;
    mapping (address => mapping (address => uint256)) public override depositBalances;
    mapping (address => uint256) public totalDepositSupply;

    uint256 public override totalSupply;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowances;

    uint256 public cumulativeRewardPerToken;
    mapping (address => uint256) public override stakedAmounts;
    mapping (address => uint256) public claimableReward;
    mapping (address => uint256) public previousCumulatedRewardPerToken;
    mapping (address => uint256) public override cumulativeRewards;
    mapping (address => uint256) public override averageStakedAmounts;

    bool public inPrivateTransferMode;
    bool public inPrivateStakingMode;
    bool public inPrivateClaimingMode;
    mapping (address => bool) public isHandler;

    event Claim(address receiver, uint256 amount);

    constructor(string memory _name, string memory _symbol) public {
        name = _name;
        symbol = _symbol;
    }

    function initialize(
        address[] memory _depositTokens,
        address _distributor
    ) external onlyGov {
        require(!isInitialized, "RewardTracker: already initialized");
        isInitialized = true;

        for (uint256 i = 0; i < _depositTokens.length; i++) {
            address depositToken = _depositTokens[i];
            isDepositToken[depositToken] = true;
        }

        distributor = _distributor;
    }

    function setDepositToken(address _depositToken, bool _isDepositToken) external onlyGov {
        isDepositToken[_depositToken] = _isDepositToken;
    }

    function setInPrivateTransferMode(bool _inPrivateTransferMode) external onlyGov {
        inPrivateTransferMode = _inPrivateTransferMode;
    }

    function setInPrivateStakingMode(bool _inPrivateStakingMode) external onlyGov {
        inPrivateStakingMode = _inPrivateStakingMode;
    }

    function setInPrivateClaimingMode(bool _inPrivateClaimingMode) external onlyGov {
        inPrivateClaimingMode = _inPrivateClaimingMode;
    }

    function setHandler(address _handler, bool _isActive) external onlyGov {
        isHandler[_handler] = _isActive;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function balanceOf(address _account) external view override returns (uint256) {
        return balances[_account];
    }

    function stake(address _depositToken, uint256 _amount) external override nonReentrant {
        if (inPrivateStakingMode) { revert("RewardTracker: action not enabled"); }
        _stake(msg.sender, msg.sender, _depositToken, _amount);
    }

    function stakeForAccount(address _fundingAccount, address _account, address _depositToken, uint256 _amount) external override nonReentrant {
        _validateHandler();
        _stake(_fundingAccount, _account, _depositToken, _amount);
    }

    function unstake(address _depositToken, uint256 _amount) external override nonReentrant {
        if (inPrivateStakingMode) { revert("RewardTracker: action not enabled"); }
        _unstake(msg.sender, _depositToken, _amount, msg.sender);
    }

    function unstakeForAccount(address _account, address _depositToken, uint256 _amount, address _receiver) external override nonReentrant {
        _validateHandler();
        _unstake(_account, _depositToken, _amount, _receiver);
    }

    function transfer(address _recipient, uint256 _amount) external override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) external view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) external override returns (bool) {
        if (isHandler[msg.sender]) {
            _transfer(_sender, _recipient, _amount);
            return true;
        }

        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "RewardTracker: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function tokensPerInterval() external override view returns (uint256) {
        return IRewardDistributor(distributor).tokensPerInterval();
    }

    function updateRewards() external override nonReentrant {
        _updateRewards(address(0));
    }

    function claim(address _receiver) external override nonReentrant returns (uint256) {
        if (inPrivateClaimingMode) { revert("RewardTracker: action not enabled"); }
        return _claim(msg.sender, _receiver);
    }

    function claimForAccount(address _account, address _receiver) external override nonReentrant returns (uint256) {
        _validateHandler();
        return _claim(_account, _receiver);
    }

    function claimable(address _account) public override view returns (uint256) {
        uint256 stakedAmount = stakedAmounts[_account];
        if (stakedAmount == 0) {
            return claimableReward[_account];
        }
        uint256 supply = totalSupply;
        uint256 pendingRewards = IRewardDistributor(distributor).pendingRewards().mul(PRECISION);
        uint256 nextCumulativeRewardPerToken = cumulativeRewardPerToken.add(pendingRewards.div(supply));
        return claimableReward[_account].add(
            stakedAmount.mul(nextCumulativeRewardPerToken.sub(previousCumulatedRewardPerToken[_account])).div(PRECISION));
    }

    function rewardToken() public view returns (address) {
        return IRewardDistributor(distributor).rewardToken();
    }

    function _claim(address _account, address _receiver) private returns (uint256) {
        _updateRewards(_account);

        uint256 tokenAmount = claimableReward[_account];
        claimableReward[_account] = 0;

        if (tokenAmount > 0) {
            IERC20(rewardToken()).safeTransfer(_receiver, tokenAmount);
            emit Claim(_account, tokenAmount);
        }

        return tokenAmount;
    }

    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0), "RewardTracker: mint to the zero address");

        totalSupply = totalSupply.add(_amount);
        balances[_account] = balances[_account].add(_amount);

        emit Transfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _amount) internal {
        require(_account != address(0), "RewardTracker: burn from the zero address");

        balances[_account] = balances[_account].sub(_amount, "RewardTracker: burn amount exceeds balance");
        totalSupply = totalSupply.sub(_amount);

        emit Transfer(_account, address(0), _amount);
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "RewardTracker: transfer from the zero address");
        require(_recipient != address(0), "RewardTracker: transfer to the zero address");

        if (inPrivateTransferMode) { _validateHandler(); }

        balances[_sender] = balances[_sender].sub(_amount, "RewardTracker: transfer amount exceeds balance");
        balances[_recipient] = balances[_recipient].add(_amount);

        emit Transfer(_sender, _recipient,_amount);
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "RewardTracker: approve from the zero address");
        require(_spender != address(0), "RewardTracker: approve to the zero address");

        allowances[_owner][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);
    }

    function _validateHandler() private view {
        require(isHandler[msg.sender], "RewardTracker: forbidden");
    }

    function _stake(address _fundingAccount, address _account, address _depositToken, uint256 _amount) private {
        require(_amount > 0, "RewardTracker: invalid _amount");
        require(isDepositToken[_depositToken], "RewardTracker: invalid _depositToken");

        IERC20(_depositToken).safeTransferFrom(_fundingAccount, address(this), _amount);

        _updateRewards(_account);

        stakedAmounts[_account] = stakedAmounts[_account].add(_amount);
        depositBalances[_account][_depositToken] = depositBalances[_account][_depositToken].add(_amount);
        totalDepositSupply[_depositToken] = totalDepositSupply[_depositToken].add(_amount);

        _mint(_account, _amount);
    }

    function _unstake(address _account, address _depositToken, uint256 _amount, address _receiver) private {
        require(_amount > 0, "RewardTracker: invalid _amount");
        require(isDepositToken[_depositToken], "RewardTracker: invalid _depositToken");

        _updateRewards(_account);

        uint256 stakedAmount = stakedAmounts[_account];
        require(stakedAmounts[_account] >= _amount, "RewardTracker: _amount exceeds stakedAmount");

        stakedAmounts[_account] = stakedAmount.sub(_amount);

        uint256 depositBalance = depositBalances[_account][_depositToken];
        require(depositBalance >= _amount, "RewardTracker: _amount exceeds depositBalance");
        depositBalances[_account][_depositToken] = depositBalance.sub(_amount);
        totalDepositSupply[_depositToken] = totalDepositSupply[_depositToken].sub(_amount);

        _burn(_account, _amount);
        IERC20(_depositToken).safeTransfer(_receiver, _amount);
    }

    function _updateRewards(address _account) private {
        uint256 blockReward = IRewardDistributor(distributor).distribute();

        uint256 supply = totalSupply;
        uint256 _cumulativeRewardPerToken = cumulativeRewardPerToken;
        if (supply > 0 && blockReward > 0) {
            _cumulativeRewardPerToken = _cumulativeRewardPerToken.add(blockReward.mul(PRECISION).div(supply));
            cumulativeRewardPerToken = _cumulativeRewardPerToken;
        }

        // cumulativeRewardPerToken can only increase
        // so if cumulativeRewardPerToken is zero, it means there are no rewards yet
        if (_cumulativeRewardPerToken == 0) {
            return;
        }

        if (_account != address(0)) {
            uint256 stakedAmount = stakedAmounts[_account];
            uint256 accountReward = stakedAmount.mul(_cumulativeRewardPerToken.sub(previousCumulatedRewardPerToken[_account])).div(PRECISION);
            uint256 _claimableReward = claimableReward[_account].add(accountReward);

            claimableReward[_account] = _claimableReward;
            previousCumulatedRewardPerToken[_account] = _cumulativeRewardPerToken;

            if (_claimableReward > 0 && stakedAmounts[_account] > 0) {
                uint256 nextCumulativeReward = cumulativeRewards[_account].add(accountReward);

                averageStakedAmounts[_account] = averageStakedAmounts[_account].mul(cumulativeRewards[_account]).div(nextCumulativeReward)
                    .add(stakedAmount.mul(accountReward).div(nextCumulativeReward));

                cumulativeRewards[_account] = nextCumulativeReward;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";

import "../core/interfaces/IBlpManager.sol";

import "./interfaces/IRewardTracker.sol";
import "./interfaces/IRewardTracker.sol";

// provide a way to transfer staked BLP tokens by unstaking from the sender
// and staking for the receiver
// tests in RewardRouterV2.js
contract StakedBlp {
    using SafeMath for uint256;

    string public constant name = "StakedBlp";
    string public constant symbol = "sBLP";
    uint8 public constant decimals = 18;

    address public blp;
    IBlpManager public blpManager;
    address public stakedBlpTracker;
    address public feeBlpTracker;

    mapping (address => mapping (address => uint256)) public allowances;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        address _blp,
        IBlpManager _blpManager,
        address _stakedBlpTracker,
        address _feeBlpTracker
    ) public {
        blp = _blp;
        blpManager = _blpManager;
        stakedBlpTracker = _stakedBlpTracker;
        feeBlpTracker = _feeBlpTracker;
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transfer(address _recipient, uint256 _amount) external returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool) {
        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "StakedBlp: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function balanceOf(address _account) external view returns (uint256) {
        return IRewardTracker(feeBlpTracker).depositBalances(_account, blp);
    }

    function totalSupply() external view returns (uint256) {
        return IERC20(stakedBlpTracker).totalSupply();
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "StakedBlp: approve from the zero address");
        require(_spender != address(0), "StakedBlp: approve to the zero address");

        allowances[_owner][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "StakedBlp: transfer from the zero address");
        require(_recipient != address(0), "StakedBlp: transfer to the zero address");

        require(
            blpManager.lastAddedAt(_sender).add(blpManager.cooldownDuration()) <= block.timestamp,
            "StakedBlp: cooldown duration not yet passed"
        );

        IRewardTracker(stakedBlpTracker).unstakeForAccount(_sender, feeBlpTracker, _amount, _sender);
        IRewardTracker(feeBlpTracker).unstakeForAccount(_sender, blp, _amount, _sender);

        IRewardTracker(feeBlpTracker).stakeForAccount(_sender, _recipient, blp, _amount);
        IRewardTracker(stakedBlpTracker).stakeForAccount(_recipient, _recipient, feeBlpTracker, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";

import "../core/interfaces/IBlpManager.sol";

import "./interfaces/IRewardTracker.sol";
import "./interfaces/IRewardTracker.sol";

import "../access/Governable.sol";

// provide a way to migrate staked BLP tokens by unstaking from the sender
// and staking for the receiver
// meant for a one-time use for a specified sender
// requires the contract to be added as a handler for stakedBlpTracker and feeBlpTracker
contract StakedBlpMigrator is Governable {
    using SafeMath for uint256;

    address public sender;
    address public blp;
    address public stakedBlpTracker;
    address public feeBlpTracker;
    bool public isEnabled = true;

    constructor(
        address _sender,
        address _blp,
        address _stakedBlpTracker,
        address _feeBlpTracker
    ) public {
        sender = _sender;
        blp = _blp;
        stakedBlpTracker = _stakedBlpTracker;
        feeBlpTracker = _feeBlpTracker;
    }

    function disable() external onlyGov {
        isEnabled = false;
    }

    function transfer(address _recipient, uint256 _amount) external onlyGov {
        _transfer(sender, _recipient, _amount);
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(isEnabled, "StakedBlpMigrator: not enabled");
        require(_sender != address(0), "StakedBlpMigrator: transfer from the zero address");
        require(_recipient != address(0), "StakedBlpMigrator: transfer to the zero address");

        IRewardTracker(stakedBlpTracker).unstakeForAccount(_sender, feeBlpTracker, _amount, _sender);
        IRewardTracker(feeBlpTracker).unstakeForAccount(_sender, blp, _amount, _sender);

        IRewardTracker(feeBlpTracker).stakeForAccount(_sender, _recipient, blp, _amount);
        IRewardTracker(stakedBlpTracker).stakeForAccount(_recipient, _recipient, feeBlpTracker, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./interfaces/IRewardTracker.sol";
import "../access/Governable.sol";

contract StakeManager is Governable {
    function stakeForAccount(
        address _rewardTracker,
        address _account,
        address _token,
        uint256 _amount
    ) external onlyGov {
        IRewardTracker(_rewardTracker).stakeForAccount(_account, _account, _token, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IRewardTracker.sol";
import "./interfaces/IVester.sol";
import "../tokens/interfaces/IMintable.sol";
import "../access/Governable.sol";

contract Vester is IVester, IERC20, ReentrancyGuard, Governable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string public name;
    string public symbol;
    uint8 public decimals = 18;

    uint256 public vestingDuration;

    address public esToken;
    address public pairToken;
    address public claimableToken;

    address public override rewardTracker;

    uint256 public override totalSupply;
    uint256 public pairSupply;

    bool public hasMaxVestableAmount;

    mapping (address => uint256) public balances;
    mapping (address => uint256) public override pairAmounts;
    mapping (address => uint256) public override cumulativeClaimAmounts;
    mapping (address => uint256) public override claimedAmounts;
    mapping (address => uint256) public lastVestingTimes;

    mapping (address => uint256) public override transferredAverageStakedAmounts;
    mapping (address => uint256) public override transferredCumulativeRewards;
    mapping (address => uint256) public override cumulativeRewardDeductions;
    mapping (address => uint256) public override bonusRewards;

    mapping (address => bool) public isHandler;

    event Claim(address receiver, uint256 amount);
    event Deposit(address account, uint256 amount);
    event Withdraw(address account, uint256 claimedAmount, uint256 balance);
    event PairTransfer(address indexed from, address indexed to, uint256 value);

    constructor (
        string memory _name,
        string memory _symbol,
        uint256 _vestingDuration,
        address _esToken,
        address _pairToken,
        address _claimableToken,
        address _rewardTracker
    ) public {
        name = _name;
        symbol = _symbol;

        vestingDuration = _vestingDuration;

        esToken = _esToken;
        pairToken = _pairToken;
        claimableToken = _claimableToken;

        rewardTracker = _rewardTracker;

        if (rewardTracker != address(0)) {
            hasMaxVestableAmount = true;
        }
    }

    function setHandler(address _handler, bool _isActive) external onlyGov {
        isHandler[_handler] = _isActive;
    }

    function setHasMaxVestableAmount(bool _hasMaxVestableAmount) external onlyGov {
        hasMaxVestableAmount = _hasMaxVestableAmount;
    }

    function deposit(uint256 _amount) external nonReentrant {
        _deposit(msg.sender, _amount);
    }

    function depositForAccount(address _account, uint256 _amount) external nonReentrant {
        _validateHandler();
        _deposit(_account, _amount);
    }

    function claim() external nonReentrant returns (uint256) {
        return _claim(msg.sender, msg.sender);
    }

    function claimForAccount(address _account, address _receiver) external override nonReentrant returns (uint256) {
        _validateHandler();
        return _claim(_account, _receiver);
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function withdraw() external nonReentrant {
        address account = msg.sender;
        address _receiver = account;
        _claim(account, _receiver);

        uint256 claimedAmount = cumulativeClaimAmounts[account];
        uint256 balance = balances[account];
        uint256 totalVested = balance.add(claimedAmount);
        require(totalVested > 0, "Vester: vested amount is zero");

        if (hasPairToken()) {
            uint256 pairAmount = pairAmounts[account];
            _burnPair(account, pairAmount);
            IERC20(pairToken).safeTransfer(_receiver, pairAmount);
        }

        IERC20(esToken).safeTransfer(_receiver, balance);
        _burn(account, balance);

        delete cumulativeClaimAmounts[account];
        delete claimedAmounts[account];
        delete lastVestingTimes[account];

        emit Withdraw(account, claimedAmount, balance);
    }

    function transferStakeValues(address _sender, address _receiver) external override nonReentrant {
        _validateHandler();

        transferredAverageStakedAmounts[_receiver] = getCombinedAverageStakedAmount(_sender);
        transferredAverageStakedAmounts[_sender] = 0;

        uint256 transferredCumulativeReward = transferredCumulativeRewards[_sender];
        uint256 cumulativeReward = IRewardTracker(rewardTracker).cumulativeRewards(_sender);

        transferredCumulativeRewards[_receiver] = transferredCumulativeReward.add(cumulativeReward);
        cumulativeRewardDeductions[_sender] = cumulativeReward;
        transferredCumulativeRewards[_sender] = 0;

        bonusRewards[_receiver] = bonusRewards[_sender];
        bonusRewards[_sender] = 0;
    }

    function setTransferredAverageStakedAmounts(address _account, uint256 _amount) external override nonReentrant {
        _validateHandler();
        transferredAverageStakedAmounts[_account] = _amount;
    }

    function setTransferredCumulativeRewards(address _account, uint256 _amount) external override nonReentrant {
        _validateHandler();
        transferredCumulativeRewards[_account] = _amount;
    }

    function setCumulativeRewardDeductions(address _account, uint256 _amount) external override nonReentrant {
        _validateHandler();
        cumulativeRewardDeductions[_account] = _amount;
    }

    function setBonusRewards(address _account, uint256 _amount) external override nonReentrant {
        _validateHandler();
        bonusRewards[_account] = _amount;
    }

    function claimable(address _account) public override view returns (uint256) {
        uint256 amount = cumulativeClaimAmounts[_account].sub(claimedAmounts[_account]);
        uint256 nextClaimable = _getNextClaimableAmount(_account);
        return amount.add(nextClaimable);
    }

    function getMaxVestableAmount(address _account) public override view returns (uint256) {
        if (!hasRewardTracker()) { return 0; }

        uint256 transferredCumulativeReward = transferredCumulativeRewards[_account];
        uint256 bonusReward = bonusRewards[_account];
        uint256 cumulativeReward = IRewardTracker(rewardTracker).cumulativeRewards(_account);
        uint256 maxVestableAmount = cumulativeReward.add(transferredCumulativeReward).add(bonusReward);

        uint256 cumulativeRewardDeduction = cumulativeRewardDeductions[_account];

        if (maxVestableAmount < cumulativeRewardDeduction) {
            return 0;
        }

        return maxVestableAmount.sub(cumulativeRewardDeduction);
    }

    function getCombinedAverageStakedAmount(address _account) public override view returns (uint256) {
        uint256 cumulativeReward = IRewardTracker(rewardTracker).cumulativeRewards(_account);
        uint256 transferredCumulativeReward = transferredCumulativeRewards[_account];
        uint256 totalCumulativeReward = cumulativeReward.add(transferredCumulativeReward);
        if (totalCumulativeReward == 0) { return 0; }

        uint256 averageStakedAmount = IRewardTracker(rewardTracker).averageStakedAmounts(_account);
        uint256 transferredAverageStakedAmount = transferredAverageStakedAmounts[_account];

        return averageStakedAmount
            .mul(cumulativeReward)
            .div(totalCumulativeReward)
            .add(
                transferredAverageStakedAmount.mul(transferredCumulativeReward).div(totalCumulativeReward)
            );
    }

    function getPairAmount(address _account, uint256 _esAmount) public view returns (uint256) {
        if (!hasRewardTracker()) { return 0; }

        uint256 combinedAverageStakedAmount = getCombinedAverageStakedAmount(_account);
        if (combinedAverageStakedAmount == 0) {
            return 0;
        }

        uint256 maxVestableAmount = getMaxVestableAmount(_account);
        if (maxVestableAmount == 0) {
            return 0;
        }

        return _esAmount.mul(combinedAverageStakedAmount).div(maxVestableAmount);
    }

    function hasRewardTracker() public view returns (bool) {
        return rewardTracker != address(0);
    }

    function hasPairToken() public view returns (bool) {
        return pairToken != address(0);
    }

    function getTotalVested(address _account) public view returns (uint256) {
        return balances[_account].add(cumulativeClaimAmounts[_account]);
    }

    function balanceOf(address _account) public view override returns (uint256) {
        return balances[_account];
    }

    // empty implementation, tokens are non-transferrable
    function transfer(address /* recipient */, uint256 /* amount */) public override returns (bool) {
        revert("Vester: non-transferrable");
    }

    // empty implementation, tokens are non-transferrable
    function allowance(address /* owner */, address /* spender */) public view virtual override returns (uint256) {
        return 0;
    }

    // empty implementation, tokens are non-transferrable
    function approve(address /* spender */, uint256 /* amount */) public virtual override returns (bool) {
        revert("Vester: non-transferrable");
    }

    // empty implementation, tokens are non-transferrable
    function transferFrom(address /* sender */, address /* recipient */, uint256 /* amount */) public virtual override returns (bool) {
        revert("Vester: non-transferrable");
    }

    function getVestedAmount(address _account) public override view returns (uint256) {
        uint256 balance = balances[_account];
        uint256 cumulativeClaimAmount = cumulativeClaimAmounts[_account];
        return balance.add(cumulativeClaimAmount);
    }

    function _mint(address _account, uint256 _amount) private {
        require(_account != address(0), "Vester: mint to the zero address");

        totalSupply = totalSupply.add(_amount);
        balances[_account] = balances[_account].add(_amount);

        emit Transfer(address(0), _account, _amount);
    }

    function _mintPair(address _account, uint256 _amount) private {
        require(_account != address(0), "Vester: mint to the zero address");

        pairSupply = pairSupply.add(_amount);
        pairAmounts[_account] = pairAmounts[_account].add(_amount);

        emit PairTransfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _amount) private {
        require(_account != address(0), "Vester: burn from the zero address");

        balances[_account] = balances[_account].sub(_amount, "Vester: burn amount exceeds balance");
        totalSupply = totalSupply.sub(_amount);

        emit Transfer(_account, address(0), _amount);
    }

    function _burnPair(address _account, uint256 _amount) private {
        require(_account != address(0), "Vester: burn from the zero address");

        pairAmounts[_account] = pairAmounts[_account].sub(_amount, "Vester: burn amount exceeds balance");
        pairSupply = pairSupply.sub(_amount);

        emit PairTransfer(_account, address(0), _amount);
    }

    function _deposit(address _account, uint256 _amount) private {
        require(_amount > 0, "Vester: invalid _amount");

        _updateVesting(_account);

        IERC20(esToken).safeTransferFrom(_account, address(this), _amount);

        _mint(_account, _amount);

        if (hasPairToken()) {
            uint256 pairAmount = pairAmounts[_account];
            uint256 nextPairAmount = getPairAmount(_account, balances[_account]);
            if (nextPairAmount > pairAmount) {
                uint256 pairAmountDiff = nextPairAmount.sub(pairAmount);
                IERC20(pairToken).safeTransferFrom(_account, address(this), pairAmountDiff);
                _mintPair(_account, pairAmountDiff);
            }
        }

        if (hasMaxVestableAmount) {
            uint256 maxAmount = getMaxVestableAmount(_account);
            require(getTotalVested(_account) <= maxAmount, "Vester: max vestable amount exceeded");
        }

        emit Deposit(_account, _amount);
    }

    function _updateVesting(address _account) private {
        uint256 amount = _getNextClaimableAmount(_account);
        lastVestingTimes[_account] = block.timestamp;

        if (amount == 0) {
            return;
        }

        // transfer claimableAmount from balances to cumulativeClaimAmounts
        _burn(_account, amount);
        cumulativeClaimAmounts[_account] = cumulativeClaimAmounts[_account].add(amount);

        IMintable(esToken).burn(address(this), amount);
    }

    function _getNextClaimableAmount(address _account) private view returns (uint256) {
        uint256 timeDiff = block.timestamp.sub(lastVestingTimes[_account]);

        uint256 balance = balances[_account];
        if (balance == 0) { return 0; }

        uint256 vestedAmount = getVestedAmount(_account);
        uint256 claimableAmount = vestedAmount.mul(timeDiff).div(vestingDuration);

        if (claimableAmount < balance) {
            return claimableAmount;
        }

        return balance;
    }

    function _claim(address _account, address _receiver) private returns (uint256) {
        _updateVesting(_account);
        uint256 amount = claimable(_account);
        claimedAmounts[_account] = claimedAmounts[_account].add(amount);
        IERC20(claimableToken).safeTransfer(_receiver, amount);
        emit Claim(_account, amount);
        return amount;
    }

    function _validateHandler() private view {
        require(isHandler[msg.sender], "Vester: forbidden");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";

import "./interfaces/IYieldTracker.sol";
import "./interfaces/IBaseToken.sol";

contract BaseToken is IERC20, IBaseToken {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    uint256 public override totalSupply;
    uint256 public nonStakingSupply;

    address public gov;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowances;

    address[] public yieldTrackers;
    mapping (address => bool) public nonStakingAccounts;
    mapping (address => bool) public admins;

    bool public inPrivateTransferMode;
    mapping (address => bool) public isHandler;

    modifier onlyGov() {
        require(msg.sender == gov, "BaseToken: forbidden");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "BaseToken: forbidden");
        _;
    }

    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) public {
        name = _name;
        symbol = _symbol;
        gov = msg.sender;
        _mint(msg.sender, _initialSupply);
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function setInfo(string memory _name, string memory _symbol) external onlyGov {
        name = _name;
        symbol = _symbol;
    }

    function setYieldTrackers(address[] memory _yieldTrackers) external onlyGov {
        yieldTrackers = _yieldTrackers;
    }

    function addAdmin(address _account) external onlyGov {
        admins[_account] = true;
    }

    function removeAdmin(address _account) external override onlyGov {
        admins[_account] = false;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external override onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function setInPrivateTransferMode(bool _inPrivateTransferMode) external override onlyGov {
        inPrivateTransferMode = _inPrivateTransferMode;
    }

    function setHandler(address _handler, bool _isActive) external onlyGov {
        isHandler[_handler] = _isActive;
    }

    function addNonStakingAccount(address _account) external onlyAdmin {
        require(!nonStakingAccounts[_account], "BaseToken: _account already marked");
        _updateRewards(_account);
        nonStakingAccounts[_account] = true;
        nonStakingSupply = nonStakingSupply.add(balances[_account]);
    }

    function removeNonStakingAccount(address _account) external onlyAdmin {
        require(nonStakingAccounts[_account], "BaseToken: _account not marked");
        _updateRewards(_account);
        nonStakingAccounts[_account] = false;
        nonStakingSupply = nonStakingSupply.sub(balances[_account]);
    }

    function recoverClaim(address _account, address _receiver) external onlyAdmin {
        for (uint256 i = 0; i < yieldTrackers.length; i++) {
            address yieldTracker = yieldTrackers[i];
            IYieldTracker(yieldTracker).claim(_account, _receiver);
        }
    }

    function claim(address _receiver) external {
        for (uint256 i = 0; i < yieldTrackers.length; i++) {
            address yieldTracker = yieldTrackers[i];
            IYieldTracker(yieldTracker).claim(msg.sender, _receiver);
        }
    }

    function totalStaked() external view override returns (uint256) {
        return totalSupply.sub(nonStakingSupply);
    }

    function balanceOf(address _account) external view override returns (uint256) {
        return balances[_account];
    }

    function stakedBalance(address _account) external view override returns (uint256) {
        if (nonStakingAccounts[_account]) {
            return 0;
        }
        return balances[_account];
    }

    function transfer(address _recipient, uint256 _amount) external override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) external view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) external override returns (bool) {
        if (isHandler[msg.sender]) {
            _transfer(_sender, _recipient, _amount);
            return true;
        }
        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "BaseToken: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0), "BaseToken: mint to the zero address");

        _updateRewards(_account);

        totalSupply = totalSupply.add(_amount);
        balances[_account] = balances[_account].add(_amount);

        if (nonStakingAccounts[_account]) {
            nonStakingSupply = nonStakingSupply.add(_amount);
        }

        emit Transfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _amount) internal {
        require(_account != address(0), "BaseToken: burn from the zero address");

        _updateRewards(_account);

        balances[_account] = balances[_account].sub(_amount, "BaseToken: burn amount exceeds balance");
        totalSupply = totalSupply.sub(_amount);

        if (nonStakingAccounts[_account]) {
            nonStakingSupply = nonStakingSupply.sub(_amount);
        }

        emit Transfer(_account, address(0), _amount);
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "BaseToken: transfer from the zero address");
        require(_recipient != address(0), "BaseToken: transfer to the zero address");

        if (inPrivateTransferMode) {
            require(isHandler[msg.sender], "BaseToken: msg.sender not whitelisted");
        }

        _updateRewards(_sender);
        _updateRewards(_recipient);

        balances[_sender] = balances[_sender].sub(_amount, "BaseToken: transfer amount exceeds balance");
        balances[_recipient] = balances[_recipient].add(_amount);

        if (nonStakingAccounts[_sender]) {
            nonStakingSupply = nonStakingSupply.sub(_amount);
        }
        if (nonStakingAccounts[_recipient]) {
            nonStakingSupply = nonStakingSupply.add(_amount);
        }

        emit Transfer(_sender, _recipient,_amount);
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "BaseToken: approve from the zero address");
        require(_spender != address(0), "BaseToken: approve to the zero address");

        allowances[_owner][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);
    }

    function _updateRewards(address _account) private {
        for (uint256 i = 0; i < yieldTrackers.length; i++) {
            address yieldTracker = yieldTrackers[i];
            IYieldTracker(yieldTracker).updateRewards(_account);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/math/SafeMath.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "../access/Governable.sol";

contract Bridge is ReentrancyGuard, Governable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public token;
    address public wToken;

    constructor(address _token, address _wToken) public {
        token = _token;
        wToken = _wToken;
    }

    function wrap(uint256 _amount, address _receiver) external nonReentrant {
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(wToken).safeTransfer(_receiver, _amount);
    }

    function unwrap(uint256 _amount, address _receiver) external nonReentrant {
        IERC20(wToken).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(token).safeTransfer(_receiver, _amount);
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./interfaces/IBXD.sol";
import "./YieldToken.sol";

contract BXD is YieldToken, IBXD {

    mapping (address => bool) public vaults;

    modifier onlyVault() {
        require(vaults[msg.sender], "BXD: forbidden");
        _;
    }

    constructor(address _vault) public YieldToken("BXD", "BlockX Dollar", 0) {
        vaults[_vault] = true;
    }

    function addVault(address _vault) external override onlyGov {
        vaults[_vault] = true;
    }

    function removeVault(address _vault) external override onlyGov {
        vaults[_vault] = false;
    }

    function mint(address _account, uint256 _amount) external override onlyVault {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external override onlyVault {
        _burn(_account, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract FaucetToken is IERC20 {
    using SafeMath for uint256;

    uint256 public DROPLET_INTERVAL = 8 hours;

    address public _gov;
    uint256 public _dropletAmount;
    bool public _isFaucetEnabled;

    mapping (address => uint256) public _claimedAt;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 dropletAmount
    ) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _gov = msg.sender;
        _dropletAmount = dropletAmount;
    }

    function mint(address account, uint256 amount) public {
        require(msg.sender == _gov, "FaucetToken: forbidden");
        _mint(account, amount);
    }

    function enableFaucet() public {
        require(msg.sender == _gov, "FaucetToken: forbidden");
        _isFaucetEnabled = true;
    }

    function disableFaucet() public {
        require(msg.sender == _gov, "FaucetToken: forbidden");
        _isFaucetEnabled = false;
    }

    function setDropletAmount(uint256 dropletAmount) public {
        require(msg.sender == _gov, "FaucetToken: forbidden");
        _dropletAmount = dropletAmount;
    }

    function claimDroplet() public {
        require(_isFaucetEnabled, "FaucetToken: faucet not enabled");
        require(_claimedAt[msg.sender].add(DROPLET_INTERVAL) <= block.timestamp, "FaucetToken: droplet not available yet");
        _claimedAt[msg.sender] = block.timestamp;
        _mint(msg.sender, _dropletAmount);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IBaseToken {
    function totalStaked() external view returns (uint256);
    function stakedBalance(address _account) external view returns (uint256);
    function removeAdmin(address _account) external;
    function setInPrivateTransferMode(bool _inPrivateTransferMode) external;
    function withdrawToken(address _token, address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IBXD {
    function addVault(address _vault) external;
    function removeVault(address _vault) external;
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IDistributor {
    function distribute() external returns (uint256);
    function getRewardToken(address _receiver) external view returns (address);
    function getDistributionAmount(address _receiver) external view returns (uint256);
    function tokensPerInterval(address _receiver) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IMintable {
    function isMinter(address _account) external returns (bool);
    function setMinter(address _minter, bool _isActive) external;
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IYieldToken {
    function totalStaked() external view returns (uint256);
    function stakedBalance(address _account) external view returns (uint256);
    function removeAdmin(address _account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IYieldTracker {
    function claim(address _account, address _receiver) external returns (uint256);
    function updateRewards(address _account) external;
    function getTokensPerInterval() external view returns (uint256);
    function claimable(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./BaseToken.sol";
import "./interfaces/IMintable.sol";

contract MintableBaseToken is BaseToken, IMintable {

    mapping (address => bool) public override isMinter;

    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) public BaseToken(_name, _symbol, _initialSupply) {
    }

    modifier onlyMinter() {
        require(isMinter[msg.sender], "MintableBaseToken: forbidden");
        _;
    }

    function setMinter(address _minter, bool _isActive) external override onlyGov {
        isMinter[_minter] = _isActive;
    }

    function mint(address _account, uint256 _amount) external override onlyMinter {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external override onlyMinter {
        _burn(_account, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./MintableBaseToken.sol";

contract SnapshotToken is MintableBaseToken {
    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) public MintableBaseToken(_name, _symbol, _initialSupply) {
    }

    function batchMint(address[] memory _accounts, uint256[] memory _amounts) external onlyMinter {
        for (uint256 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];
            uint256 amount = _amounts[i];
            _mint(account, amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";

import "./interfaces/IDistributor.sol";

contract TimeDistributor is IDistributor {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant DISTRIBUTION_INTERVAL = 1 hours;
    address public gov;
    address public admin;

    mapping (address => address) public rewardTokens;
    mapping (address => uint256) public override tokensPerInterval;
    mapping (address => uint256) public lastDistributionTime;

    event Distribute(address receiver, uint256 amount);
    event DistributionChange(address receiver, uint256 amount, address rewardToken);
    event TokensPerIntervalChange(address receiver, uint256 amount);

    modifier onlyGov() {
        require(msg.sender == gov, "TimeDistributor: forbidden");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "TimeDistributor: forbidden");
        _;
    }

    constructor() public {
        gov = msg.sender;
        admin = msg.sender;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function setTokensPerInterval(address _receiver, uint256 _amount) external onlyAdmin {
        if (lastDistributionTime[_receiver] != 0) {
            uint256 intervals = getIntervals(_receiver);
            require(intervals == 0, "TimeDistributor: pending distribution");
        }

        tokensPerInterval[_receiver] = _amount;
        _updateLastDistributionTime(_receiver);
        emit TokensPerIntervalChange(_receiver, _amount);
    }

    function updateLastDistributionTime(address _receiver) external onlyAdmin {
        _updateLastDistributionTime(_receiver);
    }

    function setDistribution(
        address[] calldata _receivers,
        uint256[] calldata _amounts,
        address[] calldata _rewardTokens
    ) external onlyGov {
        for (uint256 i = 0; i < _receivers.length; i++) {
            address receiver = _receivers[i];

            if (lastDistributionTime[receiver] != 0) {
                uint256 intervals = getIntervals(receiver);
                require(intervals == 0, "TimeDistributor: pending distribution");
            }

            uint256 amount = _amounts[i];
            address rewardToken = _rewardTokens[i];
            tokensPerInterval[receiver] = amount;
            rewardTokens[receiver] = rewardToken;
            _updateLastDistributionTime(receiver);
            emit DistributionChange(receiver, amount, rewardToken);
        }
    }

    function distribute() external override returns (uint256) {
        address receiver = msg.sender;
        uint256 intervals = getIntervals(receiver);

        if (intervals == 0) { return 0; }

        uint256 amount = getDistributionAmount(receiver);
        _updateLastDistributionTime(receiver);

        if (amount == 0) { return 0; }

        IERC20(rewardTokens[receiver]).safeTransfer(receiver, amount);

        emit Distribute(receiver, amount);
        return amount;
    }

    function getRewardToken(address _receiver) external override view returns (address) {
        return rewardTokens[_receiver];
    }

    function getDistributionAmount(address _receiver) public override view returns (uint256) {
        uint256 _tokensPerInterval = tokensPerInterval[_receiver];
        if (_tokensPerInterval == 0) { return 0; }

        uint256 intervals = getIntervals(_receiver);
        uint256 amount = _tokensPerInterval.mul(intervals);

        if (IERC20(rewardTokens[_receiver]).balanceOf(address(this)) < amount) { return 0; }

        return amount;
    }

    function getIntervals(address _receiver) public view returns (uint256) {
        uint256 timeDiff = block.timestamp.sub(lastDistributionTime[_receiver]);
        return timeDiff.div(DISTRIBUTION_INTERVAL);
    }

    function _updateLastDistributionTime(address _receiver) private {
        lastDistributionTime[_receiver] = block.timestamp.div(DISTRIBUTION_INTERVAL).mul(DISTRIBUTION_INTERVAL);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract Token is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() public {
        _name = "Token";
        _symbol = "TOKEN";
        _decimals = 18;
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function withdrawToken(address token, address account, uint256 amount) public {
        IERC20(token).transfer(account, amount);
    }

    function deposit() public payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        require(_balances[msg.sender] >= amount, "Token: insufficient balance");
        _burn(msg.sender, amount);
        msg.sender.transfer(amount);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract WETH is IERC20 {
    using SafeMath for uint256;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function deposit() public payable {
        _balances[msg.sender] = _balances[msg.sender].add(msg.value);
    }

    function withdraw(uint256 amount) public {
        require(_balances[msg.sender] >= amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        msg.sender.transfer(amount);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./YieldToken.sol";

contract YieldFarm is YieldToken, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public stakingToken;

    constructor(string memory _name, string memory _symbol, address _stakingToken) public YieldToken(_name, _symbol, 0) {
        stakingToken = _stakingToken;
    }

    function stake(uint256 _amount) external nonReentrant {
        IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
    }

    function unstake(uint256 _amount) external nonReentrant {
        _burn(msg.sender, _amount);
        IERC20(stakingToken).safeTransfer(msg.sender, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";

import "./interfaces/IYieldTracker.sol";
import "./interfaces/IYieldToken.sol";

contract YieldToken is IERC20, IYieldToken {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    uint256 public override totalSupply;
    uint256 public nonStakingSupply;

    address public gov;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowances;

    address[] public yieldTrackers;
    mapping (address => bool) public nonStakingAccounts;
    mapping (address => bool) public admins;

    bool public inWhitelistMode;
    mapping (address => bool) public whitelistedHandlers;

    modifier onlyGov() {
        require(msg.sender == gov, "YieldToken: forbidden");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "YieldToken: forbidden");
        _;
    }

    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) public {
        name = _name;
        symbol = _symbol;
        gov = msg.sender;
        admins[msg.sender] = true;
        _mint(msg.sender, _initialSupply);
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function setInfo(string memory _name, string memory _symbol) external onlyGov {
        name = _name;
        symbol = _symbol;
    }

    function setYieldTrackers(address[] memory _yieldTrackers) external onlyGov {
        yieldTrackers = _yieldTrackers;
    }

    function addAdmin(address _account) external onlyGov {
        admins[_account] = true;
    }

    function removeAdmin(address _account) external override onlyGov {
        admins[_account] = false;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function setInWhitelistMode(bool _inWhitelistMode) external onlyGov {
        inWhitelistMode = _inWhitelistMode;
    }

    function setWhitelistedHandler(address _handler, bool _isWhitelisted) external onlyGov {
        whitelistedHandlers[_handler] = _isWhitelisted;
    }

    function addNonStakingAccount(address _account) external onlyAdmin {
        require(!nonStakingAccounts[_account], "YieldToken: _account already marked");
        _updateRewards(_account);
        nonStakingAccounts[_account] = true;
        nonStakingSupply = nonStakingSupply.add(balances[_account]);
    }

    function removeNonStakingAccount(address _account) external onlyAdmin {
        require(nonStakingAccounts[_account], "YieldToken: _account not marked");
        _updateRewards(_account);
        nonStakingAccounts[_account] = false;
        nonStakingSupply = nonStakingSupply.sub(balances[_account]);
    }

    function recoverClaim(address _account, address _receiver) external onlyAdmin {
        for (uint256 i = 0; i < yieldTrackers.length; i++) {
            address yieldTracker = yieldTrackers[i];
            IYieldTracker(yieldTracker).claim(_account, _receiver);
        }
    }

    function claim(address _receiver) external {
        for (uint256 i = 0; i < yieldTrackers.length; i++) {
            address yieldTracker = yieldTrackers[i];
            IYieldTracker(yieldTracker).claim(msg.sender, _receiver);
        }
    }

    function totalStaked() external view override returns (uint256) {
        return totalSupply.sub(nonStakingSupply);
    }

    function balanceOf(address _account) external view override returns (uint256) {
        return balances[_account];
    }

    function stakedBalance(address _account) external view override returns (uint256) {
        if (nonStakingAccounts[_account]) {
            return 0;
        }
        return balances[_account];
    }

    function transfer(address _recipient, uint256 _amount) external override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) external view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) external override returns (bool) {
        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "YieldToken: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0), "YieldToken: mint to the zero address");

        _updateRewards(_account);

        totalSupply = totalSupply.add(_amount);
        balances[_account] = balances[_account].add(_amount);

        if (nonStakingAccounts[_account]) {
            nonStakingSupply = nonStakingSupply.add(_amount);
        }

        emit Transfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _amount) internal {
        require(_account != address(0), "YieldToken: burn from the zero address");

        _updateRewards(_account);

        balances[_account] = balances[_account].sub(_amount, "YieldToken: burn amount exceeds balance");
        totalSupply = totalSupply.sub(_amount);

        if (nonStakingAccounts[_account]) {
            nonStakingSupply = nonStakingSupply.sub(_amount);
        }

        emit Transfer(_account, address(0), _amount);
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "YieldToken: transfer from the zero address");
        require(_recipient != address(0), "YieldToken: transfer to the zero address");

        if (inWhitelistMode) {
            require(whitelistedHandlers[msg.sender], "YieldToken: msg.sender not whitelisted");
        }

        _updateRewards(_sender);
        _updateRewards(_recipient);

        balances[_sender] = balances[_sender].sub(_amount, "YieldToken: transfer amount exceeds balance");
        balances[_recipient] = balances[_recipient].add(_amount);

        if (nonStakingAccounts[_sender]) {
            nonStakingSupply = nonStakingSupply.sub(_amount);
        }
        if (nonStakingAccounts[_recipient]) {
            nonStakingSupply = nonStakingSupply.add(_amount);
        }

        emit Transfer(_sender, _recipient,_amount);
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "YieldToken: approve from the zero address");
        require(_spender != address(0), "YieldToken: approve to the zero address");

        allowances[_owner][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);
    }

    function _updateRewards(address _account) private {
        for (uint256 i = 0; i < yieldTrackers.length; i++) {
            address yieldTracker = yieldTrackers[i];
            IYieldTracker(yieldTracker).updateRewards(_account);
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IDistributor.sol";
import "./interfaces/IYieldTracker.sol";
import "./interfaces/IYieldToken.sol";

// code adapated from https://github.com/trusttoken/smart-contracts/blob/master/contracts/truefi/TrueFarm.sol
contract YieldTracker is IYieldTracker, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant PRECISION = 1e30;

    address public gov;
    address public yieldToken;
    address public distributor;

    uint256 public cumulativeRewardPerToken;
    mapping (address => uint256) public claimableReward;
    mapping (address => uint256) public previousCumulatedRewardPerToken;

    event Claim(address receiver, uint256 amount);

    modifier onlyGov() {
        require(msg.sender == gov, "YieldTracker: forbidden");
        _;
    }

    constructor(address _yieldToken) public {
        gov = msg.sender;
        yieldToken = _yieldToken;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function setDistributor(address _distributor) external onlyGov {
        distributor = _distributor;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function claim(address _account, address _receiver) external override returns (uint256) {
        require(msg.sender == yieldToken, "YieldTracker: forbidden");
        updateRewards(_account);

        uint256 tokenAmount = claimableReward[_account];
        claimableReward[_account] = 0;

        address rewardToken = IDistributor(distributor).getRewardToken(address(this));
        IERC20(rewardToken).safeTransfer(_receiver, tokenAmount);
        emit Claim(_account, tokenAmount);

        return tokenAmount;
    }

    function getTokensPerInterval() external override view returns (uint256) {
        return IDistributor(distributor).tokensPerInterval(address(this));
    }

    function claimable(address _account) external override view returns (uint256) {
        uint256 stakedBalance = IYieldToken(yieldToken).stakedBalance(_account);
        if (stakedBalance == 0) {
            return claimableReward[_account];
        }
        uint256 pendingRewards = IDistributor(distributor).getDistributionAmount(address(this)).mul(PRECISION);
        uint256 totalStaked = IYieldToken(yieldToken).totalStaked();
        uint256 nextCumulativeRewardPerToken = cumulativeRewardPerToken.add(pendingRewards.div(totalStaked));
        return claimableReward[_account].add(
            stakedBalance.mul(nextCumulativeRewardPerToken.sub(previousCumulatedRewardPerToken[_account])).div(PRECISION));
    }

    function updateRewards(address _account) public override nonReentrant {
        uint256 blockReward;

        if (distributor != address(0)) {
            blockReward = IDistributor(distributor).distribute();
        }

        uint256 _cumulativeRewardPerToken = cumulativeRewardPerToken;
        uint256 totalStaked = IYieldToken(yieldToken).totalStaked();
        // only update cumulativeRewardPerToken when there are stakers, i.e. when totalStaked > 0
        // if blockReward == 0, then there will be no change to cumulativeRewardPerToken
        if (totalStaked > 0 && blockReward > 0) {
            _cumulativeRewardPerToken = _cumulativeRewardPerToken.add(blockReward.mul(PRECISION).div(totalStaked));
            cumulativeRewardPerToken = _cumulativeRewardPerToken;
        }

        // cumulativeRewardPerToken can only increase
        // so if cumulativeRewardPerToken is zero, it means there are no rewards yet
        if (_cumulativeRewardPerToken == 0) {
            return;
        }

        if (_account != address(0)) {
            uint256 stakedBalance = IYieldToken(yieldToken).stakedBalance(_account);
            uint256 _previousCumulatedReward = previousCumulatedRewardPerToken[_account];
            uint256 _claimableReward = claimableReward[_account].add(
                stakedBalance.mul(_cumulativeRewardPerToken.sub(_previousCumulatedReward)).div(PRECISION)
            );

            claimableReward[_account] = _claimableReward;
            previousCumulatedRewardPerToken[_account] = _cumulativeRewardPerToken;
        }
    }
}