/**
 *Submitted for verification at Arbiscan on 2023-05-18
*/

// SPDX-License-Identifier: GPL-3.0-or-later
// File: Bridge/AnyCallAppBase/interfaces/IFeePool.sol

pragma solidity ^0.8.10;

interface IFeePool {
    function deposit(address _account) external payable;

    function withdraw(uint256 _amount) external;

    function executionBudget(address _account) external view returns (uint256);
}
// File: Bridge/AnyCallAppBase/interfaces/IAnycallExecutor.sol

pragma solidity ^0.8.10;

/// IAnycallExecutor interface of the anycall executor
interface IAnycallExecutor {
    function context()
        external
        view
        returns (
            address from,
            uint256 fromChainID,
            uint256 nonce
        );

    function execute(
        address _to,
        bytes calldata _data,
        address _from,
        uint256 _fromChainID,
        uint256 _nonce,
        uint256 _flags,
        bytes calldata _extdata
    ) external returns (bool success, bytes memory result);
}
// File: Bridge/AnyCallAppBase/interfaces/IAnycallProxy.sol

pragma solidity ^0.8.10;

/// IAnycallProxy interface of the anycall proxy
interface IAnycallProxy {
    function executor() external view returns (address);

    function config() external view returns (address);

    function anyCall(
        address _to,
        bytes calldata _data,
        uint256 _toChainID,
        uint256 _flags,
        bytes calldata _extdata
    ) external payable;
}
// File: Bridge/AnyCallAppBase/AdminControl.sol

pragma solidity ^0.8.10;

abstract contract AdminControl {
    address public admin;

    event ChangeAdmin(address indexed _old, address indexed _new);
    event ApplyAdmin(address indexed _old, address indexed _new);

    function initAdminControl(address _admin) internal {
        require(_admin != address(0), "AdminControl: address(0)");
        admin = _admin;
        emit ChangeAdmin(address(0), _admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "AdminControl: not admin");
        _;
    }

    function changeAdmin(address _admin) external onlyAdmin {
        require(_admin != address(0), "AdminControl: address(0)");
        admin = _admin;
        emit ChangeAdmin(admin, _admin);
    }
}
// File: Bridge/AnyCallAppBase/AnyCallApp.sol



pragma solidity ^0.8.10;





abstract contract AnyCallApp is AdminControl {
    address public callProxy;

    // associated client app on each chain
    mapping(uint256 => address) public clientPeers; // key is chainId

    modifier onlyExecutor() {
        require(
            msg.sender == IAnycallProxy(callProxy).executor(),
            "AppBase: onlyExecutor"
        );
        _;
    }

    function initAnyCallApp(address _callProxy, address _admin) internal {
        require(_callProxy != address(0));
        callProxy = _callProxy;
        initAdminControl(_admin);
    }

    receive() external payable {
        address _pool = IAnycallProxy(callProxy).config();
        IFeePool(_pool).deposit{value: msg.value}(address(this));
    }

    function withdraw(address _to, uint256 _amount) external onlyAdmin {
        (bool success, ) = _to.call{value: _amount}("");
        require(success);
    }

    function setCallProxy(address _callProxy) external onlyAdmin {
        require(_callProxy != address(0));
        callProxy = _callProxy;
    }

    function setClientPeers(
        uint256[] calldata _chainIds,
        address[] calldata _peers
    ) external onlyAdmin {
        require(_chainIds.length == _peers.length);
        for (uint256 i = 0; i < _chainIds.length; i++) {
            clientPeers[_chainIds[i]] = _peers[i];
        }
    }

    function depositFee() external payable {
        address _pool = IAnycallProxy(callProxy).config();
        IFeePool(_pool).deposit{value: msg.value}(address(this));
    }

    function withdrawFee(address _to, uint256 _amount) external onlyAdmin {
        address _pool = IAnycallProxy(callProxy).config();
        IFeePool(_pool).withdraw(_amount);

        (bool success, ) = _to.call{value: _amount}("");
        require(success);
    }

    function withdrawAllFee(address _pool, address _to) external onlyAdmin {
        uint256 _amount = IFeePool(_pool).executionBudget(address(this));
        IFeePool(_pool).withdraw(_amount);

        (bool success, ) = _to.call{value: _amount}("");
        require(success);
    }

    function executionBudget() external view returns (uint256) {
        address _pool = IAnycallProxy(callProxy).config();
        return IFeePool(_pool).executionBudget(address(this));
    }

    /// @dev Customized logic for processing incoming messages
    function _anyExecute(
        uint256 fromChainID,
        bytes memory data
    ) internal virtual returns (bool success, bytes memory result);

    /// @dev Customized logic for processing fallback messages
    function _anyFallback(
        uint256 fromChainID,
        bytes memory data
    ) internal virtual returns (bool success, bytes memory result);

    /// @dev Send anyCall
    function _anyCall(
        address _to,
        bytes memory _data,
        uint256 _toChainID,
        uint256 fee
    ) internal {
        // reserve 10 percent for fallback
        uint256 fee1 = fee / 10;
        uint256 fee2 = fee - fee1;
        address _pool = IAnycallProxy(callProxy).config();
        IFeePool(_pool).deposit{value: fee1}(address(this));
        IAnycallProxy(callProxy).anyCall{value: fee2}(
            _to,
            _data,
            _toChainID,
            4,
            ""
        );
    }

    function anyExecute(
        bytes memory data
    ) external onlyExecutor returns (bool success, bytes memory result) {
        (address from, uint256 fromChainID, ) = IAnycallExecutor(
            IAnycallProxy(callProxy).executor()
        ).context();
        require(clientPeers[fromChainID] == from, "AppBase: wrong context");
        return _anyExecute(fromChainID, data);
    }

    function anyFallback(
        bytes calldata data
    ) external onlyExecutor returns (bool success, bytes memory result) {
        (address from, uint256 fromChainID, ) = IAnycallExecutor(
            IAnycallProxy(callProxy).executor()
        ).context();
        require(clientPeers[fromChainID] == from, "AppBase: wrong context");
        return _anyFallback(fromChainID, data);
    }
}
// File: Bridge/ERC721Gateway.sol


pragma solidity ^0.8.0;


interface IERC721Gateway {
    function token() external view returns (address);

    function Swapout(
        uint256 tokenId,
        address receiver,
        uint256 toChainID
    ) external payable returns (uint256 swapoutSeq);
}

abstract contract ERC721Gateway is IERC721Gateway, AnyCallApp {
    address private _initiator;
    bool public initialized = false;

    constructor() {
        _initiator = msg.sender;
    }

    address public token;
    uint256 public swapoutSeq;

    function initERC20Gateway(
        address anyCallProxy,
        address token_,
        address admin
    ) public {
        require(_initiator == msg.sender && !initialized);
        initialized = true;
        token = token_;
        initAnyCallApp(anyCallProxy, admin);
    }

    function _swapout(
        uint256 tokenId
    ) internal virtual returns (bool, bytes memory);

    function _swapin(
        uint256 tokenId,
        address receiver,
        bytes memory extraMsg
    ) internal virtual returns (bool);

    event LogAnySwapOut(
        uint256 tokenId,
        address sender,
        address receiver,
        uint256 toChainID,
        uint256 swapoutSeq
    );

    function Swapout(
        uint256 tokenId,
        address receiver,
        uint256 destChainID
    ) external payable returns (uint256) {
        (bool ok, bytes memory extraMsg) = _swapout(tokenId);
        require(ok);
        swapoutSeq++;
        bytes memory data = abi.encode(
            tokenId,
            msg.sender,
            receiver,
            swapoutSeq,
            extraMsg
        );
        _anyCall(clientPeers[destChainID], data, destChainID, msg.value);
        emit LogAnySwapOut(
            tokenId,
            msg.sender,
            receiver,
            destChainID,
            swapoutSeq
        );
        return swapoutSeq;
    }

    /// @dev the name makes no sence, just to be compatible with nft gateway v6
    function Swapout_no_fallback(
        uint256 tokenId,
        address receiver,
        uint256 toChainID
    ) external payable returns (uint256) {
        return this.Swapout(tokenId, receiver, toChainID);
    }

    function _anyExecute(
        uint256 fromChainID,
        bytes memory data
    ) internal override returns (bool success, bytes memory result) {
        (uint256 tokenId, , address receiver, , bytes memory extraMsg) = abi
            .decode(data, (uint256, address, address, uint256, bytes));
        success = _swapin(tokenId, receiver, extraMsg);
    }

    function _anyFallback(
        uint256 fromChainID,
        bytes memory data
    ) internal override returns (bool success, bytes memory result) {
        (uint256 tokenId, address originSender, , , bytes memory extraMsg) = abi
            .decode(data, (uint256, address, address, uint256, bytes));
        success = _swapin(tokenId, originSender, extraMsg);
    }
}
// File: Bridge/ERC721Gateway_MintBurn.sol


pragma solidity ^0.8.0;


interface IERC721_MintBurn {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function mint(address account, uint256 tokenId) external;

    function burn(uint256 tokenId) external;
}

contract ERC721Gateway_MintBurn is ERC721Gateway {
    function _swapout(uint256 tokenId)
        internal
        virtual
        override
        returns (bool, bytes memory)
    {
        /// @dev Add custom logic for composing the data attached to the token ID
        bytes memory extraData = "";
        require(
            IERC721_MintBurn(token).ownerOf(tokenId) == msg.sender,
            "not allowed"
        );
        try IERC721_MintBurn(token).burn(tokenId) {
            return (true, extraData);
        } catch {
            return (false, "");
        }
    }

    function _swapin(
        uint256 tokenId,
        address receiver,
        bytes memory extraData
    ) internal override returns (bool) {
        /// @dev Add custom logic to consume the extraData
        try IERC721_MintBurn(token).mint(receiver, tokenId) {
            return true;
        } catch {
            return false;
        }
    }
}